// kakao_address_web_impl.dart - 웹 플랫폼용 카카오 주소 검색 구현
// dart.library.html 환경에서만 사용됨
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

// 뷰타입 등록 카운터 (매번 고유 ID 생성)
int _viewCounter = 0;

const String _kakaoHtml = '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #fff; }
    #layer { width: 100%; height: 100%; }
  </style>
</head>
<body>
<div id="layer"></div>
<script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
  function initPostcode() {
    new daum.Postcode({
      oncomplete: function(data) {
        var addr = data.userSelectedType === "R" ? data.roadAddress : data.jibunAddress;
        var payload = JSON.stringify({
          type: "KAKAO_ADDRESS",
          address: addr,
          zonecode: data.zonecode,
          roadAddress: data.roadAddress,
          jibunAddress: data.jibunAddress
        });
        window.parent.postMessage(payload, "*");
      },
      width: "100%",
      height: "100%",
      maxSuggestItems: 10
    }).embed(document.getElementById("layer"), { autoClose: false });
  }
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initPostcode);
  } else { initPostcode(); }
</script>
</body>
</html>''';

/// iframe postMessage 리스너 등록 + iframe 생성
/// 매 호출마다 새 iframe + 새 viewType ID를 사용해 확실한 동작 보장
void registerKakaoIframeListener(void Function(Map<String, dynamic>) onResult) {
  _viewCounter++;
  final viewType = 'kakao-postcode-view-$_viewCounter';

  // 새 iframe 생성
  final iframe = html.IFrameElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.border = 'none'
    ..setAttribute(
        'sandbox',
        'allow-scripts allow-same-origin allow-forms allow-popups')
    ..srcdoc = _kakaoHtml;

  // one-shot 리스너: 주소 선택 1회만 콜백 호출
  StreamSubscription? sub;
  sub = html.window.onMessage.listen((event) {
    try {
      final raw = event.data?.toString() ?? '';
      if (raw.contains('"KAKAO_ADDRESS"') && raw.contains('"address"')) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final addr = data['address'] as String? ?? '';
        if (addr.isNotEmpty) {
          sub?.cancel(); // 리스너 즉시 해제 (중복 방지)
          onResult(data);
        }
      }
    } catch (_) {}
  });

  // HtmlElementView 뷰타입 등록
  ui.platformViewRegistry.registerViewFactory(
    viewType,
    (_) => iframe,
  );

  // 현재 활성 viewType을 전역에 저장 (buildKakaoIframeView에서 사용)
  _activeViewType = viewType;
}

String _activeViewType = 'kakao-postcode-view-init';

/// HtmlElementView 위젯 반환
Widget buildKakaoIframeView() {
  return HtmlElementView(viewType: _activeViewType);
}

/// 하위 호환용
Widget buildKakaoWebView(BuildContext context) => buildKakaoIframeView();

Future<Map<String, String>?> showKakaoAddressPopup() async => null;
