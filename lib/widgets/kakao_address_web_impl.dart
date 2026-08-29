// kakao_address_web_impl.dart - 웹 플랫폼용 카카오 주소 검색 구현
// dart.library.html 환경에서만 사용됨
//
// 동작 방식:
//   web/kakao_postcode.html 을 같은 origin의 iframe으로 로드
//   → 카카오 스크립트 정상 실행
//   → window.parent.postMessage 로 결과 전송
//   → Flutter window.onMessage 수신 → Navigator.pop(result)
//
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

// ── 전역 상태 ──
final Set<String> _registeredViewTypes = {};
String _activeViewType = '';
StreamSubscription? _activeSub;

/// iframe + postMessage 리스너 등록
/// web/kakao_postcode.html 을 같은 origin iframe으로 사용
void registerKakaoIframeListener(
    void Function(Map<String, dynamic>) onResult) {
  // 기존 리스너 먼저 해제
  _activeSub?.cancel();
  _activeSub = null;

  final viewType =
      'kakao-postcode-${DateTime.now().millisecondsSinceEpoch}';

  // ── iframe 생성 ──
  // src = 같은 origin의 정적 HTML → sandbox 불필요, postMessage 정상 동작
  final iframe = html.IFrameElement()
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.border = 'none'
    ..style.display = 'block'
    ..src = '/kakao_postcode.html'; // ← 핵심: 같은 origin

  // HtmlElementView 등록 (중복 방지)
  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui.platformViewRegistry.registerViewFactory(viewType, (_) => iframe);
  }
  _activeViewType = viewType;

  // ── postMessage 리스너 ──
  bool called = false;
  _activeSub = html.window.onMessage.listen((event) {
    if (called) return;
    try {
      final raw = event.data?.toString() ?? '';
      if (raw.isEmpty) return;

      // 카카오 주소 결과만 처리
      if (!raw.contains('"KAKAO_ADDRESS"')) return;
      if (!raw.contains('"address"')) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);

      final addr = data['address']?.toString() ?? '';
      if (addr.isEmpty) return;

      called = true;
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
