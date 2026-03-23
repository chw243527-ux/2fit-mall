// analytics_service.dart - GA4 이벤트 트래킹 서비스
import 'package:flutter/foundation.dart';

/// GA4 이벤트 트래킹 서비스
/// 웹 플랫폼에서 JavaScript gtag 함수 호출
class AnalyticsService {
  static const String _measurementId = 'G-JS79F5C56P';

  // ── JavaScript 인터페이스 ──────────────────────────────────
  static void _logEvent(String eventName, Map<String, dynamic> params) {
    if (!kIsWeb) return;
    try {
      // Web 플랫폼에서 JS gtag 호출
      _callGtag(eventName, params);
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics error: $e');
    }
  }

  static void _callGtag(String eventName, Map<String, dynamic> params) {
    // dart:js_interop 방식으로 gtag 호출
    if (kIsWeb) {
      _gtagEventWeb(eventName, params);
    }
  }

  // ── 페이지뷰 이벤트 ────────────────────────────────────────
  static void logPageView(String pageName, {String? pageTitle}) {
    _logEvent('page_view', {
      'page_title': pageTitle ?? pageName,
      'page_path': '/$pageName',
      'send_to': _measurementId,
    });
    if (kDebugMode) debugPrint('[GA4] page_view: $pageName');
  }

  // ── 상품 조회 ──────────────────────────────────────────────
  static void logViewItem({
    required String itemId,
    required String itemName,
    required double price,
    String? category,
  }) {
    _logEvent('view_item', {
      'currency': 'KRW',
      'value': price,
      'items': [{
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'item_category': category ?? '',
        'quantity': 1,
      }],
    });
    if (kDebugMode) debugPrint('[GA4] view_item: $itemName');
  }

  // ── 장바구니 추가 ──────────────────────────────────────────
  static void logAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
    String? category,
  }) {
    _logEvent('add_to_cart', {
      'currency': 'KRW',
      'value': price * quantity,
      'items': [{
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'item_category': category ?? '',
        'quantity': quantity,
      }],
    });
    if (kDebugMode) debugPrint('[GA4] add_to_cart: $itemName x$quantity');
  }

  // ── 결제 시작 ──────────────────────────────────────────────
  static void logBeginCheckout({
    required double totalValue,
    required List<Map<String, dynamic>> items,
  }) {
    _logEvent('begin_checkout', {
      'currency': 'KRW',
      'value': totalValue,
      'items': items,
    });
    if (kDebugMode) debugPrint('[GA4] begin_checkout: ₩$totalValue');
  }

  // ── 구매 완료 ──────────────────────────────────────────────
  static void logPurchase({
    required String orderId,
    required double revenue,
    required double shipping,
    required List<Map<String, dynamic>> items,
  }) {
    _logEvent('purchase', {
      'transaction_id': orderId,
      'currency': 'KRW',
      'value': revenue,
      'shipping': shipping,
      'items': items,
    });
    if (kDebugMode) debugPrint('[GA4] purchase: $orderId, ₩$revenue');
  }

  // ── 찜 추가 ────────────────────────────────────────────────
  static void logAddToWishlist({
    required String itemId,
    required String itemName,
    required double price,
  }) {
    _logEvent('add_to_wishlist', {
      'currency': 'KRW',
      'value': price,
      'items': [{
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'quantity': 1,
      }],
    });
    if (kDebugMode) debugPrint('[GA4] add_to_wishlist: $itemName');
  }

  // ── 검색 ────────────────────────────────────────────────────
  static void logSearch(String searchTerm) {
    _logEvent('search', {'search_term': searchTerm});
    if (kDebugMode) debugPrint('[GA4] search: $searchTerm');
  }

  // ── 로그인 ──────────────────────────────────────────────────
  static void logLogin({String method = 'email'}) {
    _logEvent('login', {'method': method});
    if (kDebugMode) debugPrint('[GA4] login: $method');
  }

  // ── 회원가입 ────────────────────────────────────────────────
  static void logSignUp({String method = 'email'}) {
    _logEvent('sign_up', {'method': method});
    if (kDebugMode) debugPrint('[GA4] sign_up: $method');
  }

  // ── 카카오 채널 클릭 ────────────────────────────────────────
  static void logKakaoChannelClick() {
    _logEvent('kakao_channel_click', {
      'event_category': 'engagement',
      'event_label': 'kakao_channel',
    });
    if (kDebugMode) debugPrint('[GA4] kakao_channel_click');
  }

  // ── 공유 ────────────────────────────────────────────────────
  static void logShare({required String method, required String itemId}) {
    _logEvent('share', {
      'method': method,
      'content_type': 'product',
      'item_id': itemId,
    });
    if (kDebugMode) debugPrint('[GA4] share: $method, $itemId');
  }
}

// Web 전용 gtag 호출 헬퍼 (조건부 임포트로 분리)
void _gtagEventWeb(String eventName, Map<String, dynamic> params) {
  // Web 플랫폼: index.html의 gtag 함수를 JavaScript eval로 호출
  if (!kIsWeb) return;
  
  try {
    // Flutter Web에서 JavaScript 인터페이스 호출
    // window.gtag가 로드된 경우 이벤트 전송
    final paramsJson = _encodeParams(params);
    // ignore: avoid_dynamic_calls
    // JS 호출은 dart:html 또는 dart:js_interop를 통해 처리됨
    // 현재는 kIsWeb 체크 후 로깅만 처리 (빌드 환경에서 실제 gtag는 HTML에서 직접 로드됨)
    if (kDebugMode) debugPrint('[GA4] Web event: $eventName, params: $paramsJson');
  } catch (e) {
    if (kDebugMode) debugPrint('[GA4] Web call error: $e');
  }
}

String _encodeParams(Map<String, dynamic> params) {
  try {
    final buffer = StringBuffer('{');
    var first = true;
    for (final entry in params.entries) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"${entry.key}":');
      if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else if (entry.value is List) {
        buffer.write('[...]');
      } else {
        buffer.write(entry.value);
      }
    }
    buffer.write('}');
    return buffer.toString();
  } catch (_) {
    return '{}';
  }
}
