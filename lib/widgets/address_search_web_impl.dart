// address_search_web_impl.dart
// 웹 전용: window.open으로 카카오 주소 팝업 열고 postMessage 수신
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';

StreamSubscription? _sub;

/// 카카오 주소 검색 팝업 열기 + 결과 수신
void openKakaoPopupAndListen(void Function(Map<String, dynamic>) onResult) {
  // 기존 리스너 취소
  _sub?.cancel();
  _sub = null;

  // 팝업 창 열기 (같은 origin의 정적 HTML)
  html.window.open(
    '/kakao_postcode.html',
    'kakao_postcode',
    'width=500,height=600,scrollbars=yes,resizable=yes',
  );

  // postMessage 리스너 등록
  bool called = false;
  _sub = html.window.onMessage.listen((event) {
    if (called) return;
    try {
      final raw = event.data?.toString() ?? '';
      if (raw.isEmpty) return;
      if (!raw.contains('"KAKAO_ADDRESS"')) return;
      if (!raw.contains('"address"')) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);

      final addr = data['address']?.toString() ?? '';
      if (addr.isEmpty) return;

      called = true;
      _sub?.cancel();
      _sub = null;
      onResult(data);
    } catch (_) {}
  });
}

/// 리스너 취소
void cancelAddressListener() {
  _sub?.cancel();
  _sub = null;
}
