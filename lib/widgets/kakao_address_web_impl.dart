// kakao_address_web_impl.dart - 웹 플랫폼용 카카오 주소 검색 구현
// dart.library.html 환경에서만 사용됨
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

// 뷰타입 등록 추적 (타입별 중복 등록 방지)
final Set<String> _registeredViewTypes = {};

// 현재 활성 viewType
String _activeViewType = '';

// 현재 리스너 구독
StreamSubscription? _activeSub;

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
        // 여러 target에 postMessage 전송 (parent, top, opener)
        try { window.parent.postMessage(payload, "*"); } catch(e) {}
        try { window.top.postMessage(payload, "*"); } catch(e) {}
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
void registerKakaoIframeListener(void Function(Map<String, dynamic>) onResult) {
  // 기존 리스너 해제
  _activeSub?.cancel();
  _activeSub = null;

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final viewType = 'kakao-postcode-$timestamp';

  // iframe 생성
  final iframe = html.IFrameElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.border = 'none'
    ..setAttribute(
        'sandbox',
        'allow-scripts allow-same-origin allow-forms allow-popups allow-top-navigation')
    ..srcdoc = _kakaoHtml;

  // postMessage 리스너 등록
  bool _called = false;
  _activeSub = html.window.onMessage.listen((event) {
    if (_called) return;
    try {
      final raw = event.data?.toString() ?? '';
      if (raw.contains('"KAKAO_ADDRESS"') && raw.contains('"address"')) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final addr = data['address'] as String? ?? '';
        if (addr.isNotEmpty) {
          _called = true;
          _activeSub?.cancel();
          _activeSub = null;
          onResult(data);
        }
      }
    } catch (_) {}
  });

  // HtmlElementView 뷰타입 등록 (중복 방지)
  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (_) => iframe,
    );
  }

  _activeViewType = viewType;
}

/// HtmlElementView 위젯 반환
Widget buildKakaoIframeView() {
  if (_activeViewType.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }
  return HtmlElementView(viewType: _activeViewType);
}

/// 하위 호환용
Widget buildKakaoWebView(BuildContext context) => buildKakaoIframeView();

Future<Map<String, String>?> showKakaoAddressPopup() async => null;
