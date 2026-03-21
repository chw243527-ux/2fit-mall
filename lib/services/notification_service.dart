// notification_service.dart
// ══════════════════════════════════════════════════════════════
// 알림 서비스 — 카카오 알림톡 + 관리자 이메일 알림 + 브라우저 알림
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'supabase_service.dart';
import 'notification_web_stub.dart'
    if (dart.library.html) 'notification_web_impl.dart' as web_notif;

// ─── 🔑 카카오 알림톡 설정 ────────────────────────────────────
class KakaoConfig {
  // TODO: 카카오 비즈니스 API 키
  // 발급: https://business.kakao.com → 개발자 → API 키
  static const apiKey = '';

  // TODO: 발신 프로필 키 (plusFriendUserKey)
  static const senderKey = '';

  // ── 알림톡 템플릿 코드 (카카오 심사 후 발급) ──────────────────
  // 각 항목은 카카오 비즈니스에서 템플릿 작성·심사 후 코드 입력
  static const templateOrderConfirm = 'ORDER_CONFIRM'; // 주문 확인
  static const templateShipped      = 'ORDER_SHIPPED'; // 배송 시작
  static const templateDelivered    = 'ORDER_DELIVERED'; // 배송 완료
  static const templateCancelled    = 'ORDER_CANCELLED'; // 주문 취소

  static bool get isConfigured => apiKey.isNotEmpty && senderKey.isNotEmpty;

  // 카카오 알림톡 API 엔드포인트 (bizmessage)
  static const apiUrl = 'https://apis.aligo.in/send/';
}

// ─── 관리자 이메일 ────────────────────────────────────────────
class AdminConfig {
  // 주문 알림을 받을 관리자 이메일
  static const adminEmail = 'cs@2fitkorea.com';

  // Supabase Edge Function URL (이메일 발송용) — 사용 시 입력
  static const emailEdgeFunctionUrl = '';

  static bool get hasEmail => adminEmail.isNotEmpty;
  static bool get hasEdgeFunction => emailEdgeFunctionUrl.isNotEmpty;
}

// ══════════════════════════════════════════════════════════════
// NotificationService — 알림 발송 통합
// ══════════════════════════════════════════════════════════════
class NotificationService {

  // ─── 주문 접수 알림 (고객 + 관리자) ─────────────────────────
  static Future<void> sendOrderConfirmed(OrderModel order) async {
    await Future.wait([
      _sendKakaoAlimtalk(
        phone: order.userPhone,
        templateCode: KakaoConfig.templateOrderConfirm,
        params: {
          '#{주문번호}': order.id,
          '#{고객명}': order.userName,
          '#{상품명}': _buildItemSummary(order),
          '#{결제금액}': _formatPrice(order.totalAmount),
          '#{결제수단}': order.paymentMethod,
          '#{배송주소}': order.userAddress,
        },
      ),
      _notifyAdmin(
        subject: '[2FIT] 새 주문 접수 — ${order.id}',
        body: _buildAdminOrderEmail(order),
      ),
    ]);
  }

  // ─── 배송 시작 알림 ──────────────────────────────────────────
  static Future<void> sendShipped({
    required OrderModel order,
    required String trackingNumber,
    required String courierName,
  }) async {
    await _sendKakaoAlimtalk(
      phone: order.userPhone,
      templateCode: KakaoConfig.templateShipped,
      params: {
        '#{주문번호}': order.id,
        '#{고객명}': order.userName,
        '#{택배사}': courierName,
        '#{운송장번호}': trackingNumber,
        '#{배송조회URL}': 'https://www.cjlogistics.com/ko/tool/parcel/tracking?gnbInvcNo=$trackingNumber',
      },
    );
  }

  // ─── 배송 완료 알림 ──────────────────────────────────────────
  static Future<void> sendDelivered(OrderModel order) async {
    await _sendKakaoAlimtalk(
      phone: order.userPhone,
      templateCode: KakaoConfig.templateDelivered,
      params: {
        '#{주문번호}': order.id,
        '#{고객명}': order.userName,
        '#{상품명}': _buildItemSummary(order),
      },
    );
  }

  // ─── 주문 취소 알림 ──────────────────────────────────────────
  static Future<void> sendCancelled({
    required OrderModel order,
    required String reason,
  }) async {
    await _sendKakaoAlimtalk(
      phone: order.userPhone,
      templateCode: KakaoConfig.templateCancelled,
      params: {
        '#{주문번호}': order.id,
        '#{고객명}': order.userName,
        '#{취소사유}': reason,
        '#{환불금액}': _formatPrice(order.totalAmount),
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 카카오 알림톡 발송 (내부)
  // ══════════════════════════════════════════════════════════════
  static Future<void> _sendKakaoAlimtalk({
    required String phone,
    required String templateCode,
    required Map<String, String> params,
  }) async {
    if (!KakaoConfig.isConfigured) {
      // 설정 미완료 시 콘솔 로그만 출력
      if (kDebugMode) {
        debugPrint('📱 [알림톡 시뮬레이션] → $phone');
        debugPrint('   템플릿: $templateCode');
        params.forEach((k, v) => debugPrint('   $k = $v'));
      }
      return;
    }

    try {
      // 파라미터를 템플릿 문자열에 치환
      var message = _getTemplateText(templateCode);
      params.forEach((key, value) {
        message = message.replaceAll(key, value);
      });

      final response = await http.post(
        Uri.parse(KakaoConfig.apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'key': KakaoConfig.apiKey,
          'tpl_code': templateCode,
          'sender': '15881234', // TODO: 발신 번호 (사업자 번호)
          'receiver_1': phone,
          'recvname_1': params['#{고객명}'] ?? '',
          'msg_1': message,
        },
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (kDebugMode) debugPrint('📱 알림톡 발송: ${data['message']}');
    } catch (e) {
      // 알림톡 실패는 결제 흐름을 막지 않음
      if (kDebugMode) debugPrint('⚠️ 알림톡 발송 실패: $e');
    }
  }

  // ── 관리자 이메일 알림 ──────────────────────────────────────
  static Future<void> _notifyAdmin({
    required String subject,
    required String body,
  }) async {
    if (!AdminConfig.hasEmail) return;

    if (AdminConfig.hasEdgeFunction && SupabaseConfig.isConfigured) {
      try {
        await http.post(
          Uri.parse(AdminConfig.emailEdgeFunctionUrl),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          },
          body: jsonEncode({
            'to': AdminConfig.adminEmail,
            'subject': subject,
            'html': body,
          }),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ 관리자 이메일 발송 실패: $e');
      }
    } else {
      if (kDebugMode) {
        debugPrint('📧 [이메일 시뮬레이션] To: ${AdminConfig.adminEmail}');
        debugPrint('   제목: $subject');
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 유틸 함수
  // ══════════════════════════════════════════════════════════════
  static String _buildItemSummary(OrderModel order) {
    if (order.items.isEmpty) return '상품 없음';
    final first = order.items.first;
    final extra = order.items.length > 1 ? ' 외 ${order.items.length - 1}건' : '';
    return '${first.productName} (${first.size}·${first.color})$extra';
  }

  static String _formatPrice(double price) {
    return price
        .toInt()
        .toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  }

  static String _buildAdminOrderEmail(OrderModel order) {
    final items = order.items
        .map((i) =>
            '<tr><td>${i.productName}</td><td>${i.size}</td><td>${i.color}</td>'
            '<td>${i.quantity}</td><td>${_formatPrice(i.price * i.quantity)}원</td></tr>')
        .join('');

    return '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><style>
  body { font-family: sans-serif; color: #333; }
  table { border-collapse: collapse; width: 100%; }
  th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
  th { background: #1A1A2E; color: white; }
  .badge { display: inline-block; padding: 4px 10px; border-radius: 4px;
           background: #1A1A2E; color: white; font-weight: bold; }
</style></head>
<body>
<h2>🛍️ 새 주문이 접수되었습니다</h2>
<p><span class="badge">${order.id}</span></p>
<table>
  <tr><th colspan="2">주문자 정보</th></tr>
  <tr><td>이름</td><td>${order.userName}</td></tr>
  <tr><td>연락처</td><td>${order.userPhone}</td></tr>
  <tr><td>배송주소</td><td>${order.userAddress}</td></tr>
  <tr><td>결제수단</td><td>${order.paymentMethod}</td></tr>
  <tr><td>주문유형</td><td>${order.orderType}</td></tr>
</table>
<br>
<table>
  <tr><th>상품명</th><th>사이즈</th><th>컬러</th><th>수량</th><th>금액</th></tr>
  $items
  <tr><td colspan="4"><strong>배송비</strong></td><td>${_formatPrice(order.shippingFee)}원</td></tr>
  <tr><td colspan="4"><strong>합계</strong></td><td><strong>${_formatPrice(order.totalAmount)}원</strong></td></tr>
</table>
<br>
<p>주문 시각: ${order.createdAt.toLocal()}</p>
</body>
</html>''';
  }

  // ── 알림톡 템플릿 텍스트 (카카오 심사 완료 후 실제 내용으로 교체) ─
  static String _getTemplateText(String code) {
    switch (code) {
      case KakaoConfig.templateOrderConfirm:
        return '''안녕하세요, #{고객명}님!
2FIT MALL 주문이 확인되었습니다.

■ 주문번호: #{주문번호}
■ 주문상품: #{상품명}
■ 결제금액: #{결제금액}원
■ 결제수단: #{결제수단}
■ 배송주소: #{배송주소}

주문해 주셔서 감사합니다 :)''';

      case KakaoConfig.templateShipped:
        return '''안녕하세요, #{고객명}님!
주문하신 상품이 발송되었습니다.

■ 주문번호: #{주문번호}
■ 택배사: #{택배사}
■ 운송장번호: #{운송장번호}
■ 배송조회: #{배송조회URL}

빠른 배송으로 찾아뵙겠습니다!''';

      case KakaoConfig.templateDelivered:
        return '''안녕하세요, #{고객명}님!
주문하신 상품이 배송 완료되었습니다.

■ 주문번호: #{주문번호}
■ 상품: #{상품명}

2FIT MALL을 이용해 주셔서 감사합니다.
상품이 마음에 드셨다면 리뷰를 남겨주세요!''';

      case KakaoConfig.templateCancelled:
        return '''안녕하세요, #{고객명}님.
주문이 취소되었습니다.

■ 주문번호: #{주문번호}
■ 취소사유: #{취소사유}
■ 환불금액: #{환불금액}원

환불은 3~5 영업일 이내 처리됩니다.''';

      default:
        return '';
    }
  }
}

// ══════════════════════════════════════════════════════════════
// AdminWebNotifier — 브라우저 Web Notification API 기반 관리자 알림
// 채팅 문의 / 신규 주문 발생 시 브라우저 푸시 알림 전송
// ══════════════════════════════════════════════════════════════
class AdminWebNotifier {
  static bool _permissionGranted = false;
  static bool _permissionRequested = false;

  // ── 알림 권한 요청 ──────────────────────────────────────────
  static Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
    if (_permissionGranted) return true;
    if (_permissionRequested) return false;

    try {
      _permissionRequested = true;
      final permission = await web_notif.requestNotificationPermission();
      _permissionGranted = permission == 'granted';
      if (kDebugMode) debugPrint('🔔 알림 권한: $permission');
      return _permissionGranted;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 알림 권한 요청 실패: $e');
      return false;
    }
  }

  // ── 현재 알림 권한 상태 확인 ────────────────────────────────
  static bool get isGranted {
    if (!kIsWeb) return false;
    try {
      return web_notif.getNotificationPermission() == 'granted';
    } catch (_) {
      return false;
    }
  }

  static String get permissionStatus {
    if (!kIsWeb) return 'not_supported';
    try {
      return web_notif.getNotificationPermission() ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  // ── 채팅 문의 알림 ──────────────────────────────────────────
  static Future<void> notifyChatInquiry({
    required String userName,
    required String message,
    String? language,
  }) async {
    final lang = language ?? 'KO';
    const title = '💬 새 채팅 문의 — 2FIT MALL';
    final body = '[$lang] $userName: $message';
    await _showBrowserNotification(title: title, body: body, tag: 'chat_${DateTime.now().millisecondsSinceEpoch}');
  }

  // ── 신규 주문 알림 ──────────────────────────────────────────
  static Future<void> notifyNewOrder({
    required String orderId,
    required String userName,
    required double totalAmount,
  }) async {
    final price = totalAmount.toInt().toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    const title = '🛍️ 새 주문 접수 — 2FIT MALL';
    final body = '주문번호: $orderId\n고객: $userName\n금액: $price원';
    await _showBrowserNotification(title: title, body: body, tag: 'order_$orderId');
  }

  // ── 내부: 브라우저 알림 표시 ────────────────────────────────
  static Future<void> _showBrowserNotification({
    required String title,
    required String body,
    String? tag,
  }) async {
    if (!kIsWeb) return;

    try {
      // 권한 확인
      if (!isGranted) {
        final granted = await requestPermission();
        if (!granted) {
          if (kDebugMode) debugPrint('🔔 알림 권한 없음 — 알림 스킵');
          return;
        }
      }

      // 브라우저 알림 생성 (Web API - 기본 방식)
      web_notif.showBrowserNotification(title);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 브라우저 알림 실패: $e');
    }
  }
}

// ══════════════════════════════════════════════════════════════
// AdminNotificationStore — 앱 내 알림 저장소 (미확인 알림 배지)
// ══════════════════════════════════════════════════════════════
class AdminNotification {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final String type; // 'chat' | 'order'
  bool isRead;

  AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

class AdminNotificationStore {
  static final List<AdminNotification> _notifications = [];
  static final StreamController<List<AdminNotification>> _controller =
      StreamController<List<AdminNotification>>.broadcast();

  static Stream<List<AdminNotification>> get stream => _controller.stream;
  static List<AdminNotification> get all => List.unmodifiable(_notifications);
  static int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static void add(AdminNotification notification) {
    _notifications.insert(0, notification);
    // 최대 50개 유지
    if (_notifications.length > 50) _notifications.removeLast();
    _controller.add(List.unmodifiable(_notifications));
  }

  static void addChatNotification({
    required String userName,
    required String message,
    String? language,
  }) {
    final lang = language ?? 'KO';
    add(AdminNotification(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      title: '💬 새 채팅 문의',
      body: '[$lang] $userName: $message',
      time: DateTime.now(),
      type: 'chat',
    ));
    // 브라우저 알림도 함께 전송
    AdminWebNotifier.notifyChatInquiry(
      userName: userName,
      message: message,
      language: lang,
    );
  }

  static void addOrderNotification({
    required String orderId,
    required String userName,
    required double totalAmount,
  }) {
    final price = totalAmount.toInt().toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    add(AdminNotification(
      id: 'order_$orderId',
      title: '🛍️ 새 주문 접수',
      body: '$userName | $price원',
      time: DateTime.now(),
      type: 'order',
    ));
    // 브라우저 알림도 함께 전송
    AdminWebNotifier.notifyNewOrder(
      orderId: orderId,
      userName: userName,
      totalAmount: totalAmount,
    );
  }

  static void markAllRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _controller.add(List.unmodifiable(_notifications));
  }

  static void clear() {
    _notifications.clear();
    _controller.add([]);
  }
}
