// kakao_address_web_impl.dart - 웹 플랫폼용 카카오 주소 검색 구현
// dart.library.html 환경에서만 사용됨
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

// 뷰타입 등록 추적 (중복 등록 방지)
final Set<String> _registeredViewTypes = {};

// 현재 활성 viewType
String _activeViewType = '';

// 현재 리스너 구독
StreamSubscription? _activeSub;

// ── 카카오 주소 검색 HTML (blob URL로 로드하기 위한 템플릿) ──
const String _kakaoHtml = '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #fff; overflow: hidden; }
    #wrap { width: 100%; height: 100%; }
  </style>
</head>
<body>
<div id="wrap"></div>
<script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
(function() {
  function init() {
    new daum.Postcode({
      oncomplete: function(data) {
        var addr = data.userSelectedType === "R" ? data.roadAddress : data.jibunAddress;
        var payload = JSON.stringify({
          type: "KAKAO_ADDRESS",
          address: addr,
          zonecode: data.zonecode,
          roadAddress: data.roadAddress || "",
          jibunAddress: data.jibunAddress || ""
        });
        try { window.parent.postMessage(payload, "*"); } catch(e) {}
        try { window.top.postMessage(payload, "*"); } catch(e) {}
        try { parent.postMessage(payload, "*"); } catch(e) {}
      },
      width: "100%",
      height: "100%",
      maxSuggestItems: 10,
      animation: false
    }).embed(document.getElementById("wrap"), { autoClose: false });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
</script>
</body>
</html>''';

/// blob URL 생성 (sandbox 없이 로드 가능)
String _createBlobUrl() {
  final blob = html.Blob([_kakaoHtml], 'text/html');
  return html.Url.createObjectUrl(blob);
}

/// iframe postMessage 리스너 등록 + iframe 생성
void registerKakaoIframeListener(void Function(Map<String, dynamic>) onResult) {
  // 기존 리스너 해제
  _activeSub?.cancel();
  _activeSub = null;

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final viewType = 'kakao-postcode-$timestamp';

  // blob URL 생성 (sandbox 없이 외부 스크립트 로드 가능)
  final blobUrl = _createBlobUrl();

  // iframe 생성 - sandbox 속성 제거, src에 blob URL 사용
  final iframe = html.IFrameElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.border = 'none'
    ..style.display = 'block'
    ..src = blobUrl;
  // ★ sandbox 속성을 사용하지 않음 → postMessage 차단 없음

  // HtmlElementView 뷰타입 등록 (중복 방지)
  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (_) => iframe,
    );
  }
  _activeViewType = viewType;

  // postMessage 리스너 - iframe 등록 후 window에 붙임
  bool _called = false;
  _activeSub = html.window.onMessage.listen((event) {
    if (_called) return;
    try {
      final raw = event.data?.toString() ?? '';
      if (raw.isEmpty) return;
      if (!raw.contains('"KAKAO_ADDRESS"')) return;
      if (!raw.contains('"address"')) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final addr = data['address'] as String? ?? '';
      if (addr.isEmpty) return;

      _called = true;
      _activeSub?.cancel();
      _activeSub = null;
      onResult(data);
    } catch (_) {}
  });
}

/// HtmlElementView 위젯 반환
Widget buildKakaoIframeView() {
  if (_activeViewType.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }
  return HtmlElementView(viewType: _activeViewType);
}

/// 리스너 수동 취소 (dispose 시 호출)
void cancelKakaoIframeListener() {
  _activeSub?.cancel();
  _activeSub = null;
}

/// 하위 호환용
Widget buildKakaoWebView(BuildContext context) => buildKakaoIframeView();

Future<Map<String, String>?> showKakaoAddressPopup() async => null;
