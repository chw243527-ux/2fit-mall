// kakao_address_web_impl.dart - 웹 플랫폼용 카카오 주소 검색 구현
// dart.library.html 환경에서만 사용됨
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';

bool _viewRegistered = false;

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
        window.parent.postMessage(JSON.stringify({
          address: addr,
          zonecode: data.zonecode,
          roadAddress: data.roadAddress,
          jibunAddress: data.jibunAddress
        }), "*");
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
  // iframe 요소 생성
  final iframe = html.IFrameElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.border = 'none'
    ..setAttribute('sandbox',
        'allow-scripts allow-same-origin allow-forms allow-popups allow-top-navigation')
    ..srcdoc = _kakaoHtml;

  // window.postMessage 리스너
  html.window.onMessage.listen((event) {
    try {
      final raw = event.data?.toString() ?? '';
      if (raw.startsWith('{') && raw.contains('"address"')) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final addr = data['address'] as String? ?? '';
        if (addr.isNotEmpty) {
          onResult(data);
        }
      }
    } catch (_) {}
  });

  // HtmlElementView 뷰타입 등록 (최초 1회)
  if (!_viewRegistered) {
    _viewRegistered = true;
    ui.platformViewRegistry.registerViewFactory(
      'kakao-postcode-view',
      (_) => iframe,
    );
  }
}

/// HtmlElementView 위젯 반환
Widget buildKakaoIframeView() {
  return const HtmlElementView(viewType: 'kakao-postcode-view');
}

/// 하위 호환용 (사용하지 않음)
Widget buildKakaoWebView(BuildContext context) {
  return buildKakaoIframeView();
}

Future<Map<String, String>?> showKakaoAddressPopup() async {
  return null;
}
