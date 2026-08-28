// notification_service.dart
// ══════════════════════════════════════════════════════════════
// 알림 서비스 — 카카오 알림톡 + 관리자 이메일 알림 + 브라우저 알림
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'supabase_service.dart';
import 'notification_web_stub.dart'
    if (dart.library.html) 'notification_web_impl.dart' as web_notif;

// ─── 서버 알림 설정 ─────────────────────────────────────────────
// SOLAPI 자격증명과 발신번호는 Firebase Functions 서버에만 존재합니다.
// 클라이언트는 Firebase ID Token으로 서버 함수를 호출합니다.

// ─── 관리자 설정 ────────────────────────────────────────────
class AdminConfig {
  // 주문 알림을 받을 관리자 이메일
  static const adminEmail = 'chw243527@gmail.com';

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
      _sendOrderNotification(order: order, kind: 'order_confirmed'),
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
    await _sendOrderNotification(
      order: order,
      kind: 'shipped',
      params: {'trackingNumber': trackingNumber, 'courierName': courierName},
    );
  }

  // ─── 배송 완료 알림 ──────────────────────────────────────────
  static Future<void> sendDelivered(OrderModel order) async {
    await _sendOrderNotification(order: order, kind: 'delivered');
  }

  // ─── 주문 취소 알림 ──────────────────────────────────────────
  static Future<void> sendCancelled({
    required OrderModel order,
    required String reason,
  }) async {
    await _sendOrderNotification(
      order: order,
      kind: 'cancelled',
      params: {'reason': reason},
    );
  }

  // ─── 관리자 채팅 알림 (SMS + 알림톡) ──────────────────────────
  // 일반 사용자가 채팅 입력 시 관리자 핸드폰으로 즉시 알림
  static Future<void> sendChatAlertToAdmin({
    required String userName,
    required String message,
    String language = 'KO',
  }) async {
    await _postServerNotification(
      endpoint: 'sendSolapiChatAlimtalk',
      body: {
        'userName': userName,
        'message': message,
        'language': language,
      },
    );
  }

  // ── Firebase Functions 서버 알림 호출 ─────────────────────────
  static const _functionsBaseUrl =
      'https://us-central1-fit-mall.cloudfunctions.net';

  static Future<void> _postServerNotification({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) debugPrint('알림 스킵: Firebase 로그인이 필요합니다.');
        return;
      }
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) return;
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 400 && kDebugMode) {
        debugPrint('서버 알림 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 알림 실패가 주문·결제 흐름을 막지 않도록 처리합니다.
      if (kDebugMode) debugPrint('서버 알림 호출 실패: $e');
    }
  }

  static Future<void> _sendOrderNotification({
    required OrderModel order,
    required String kind,
    Map<String, String> params = const {},
  }) async {
    await _postServerNotification(
      endpoint: 'sendSolapiOrderNotification',
      body: {
        'orderId': order.id,
        'kind': kind,
        'params': params,
      },
    );
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

    // 브라우저의 현재 실제 상태를 먼저 확인
    final currentStatus = web_notif.getNotificationPermission();

    // 이미 허용돼 있으면 바로 true
    if (currentStatus == 'granted') {
      _permissionGranted = true;
      return true;
    }

    // 브라우저가 명시적으로 거부한 상태 — 재요청 불가 (브라우저 정책)
    if (currentStatus == 'denied') {
      _permissionGranted = false;
      return false;
    }

    // 'default' 상태: 실제 브라우저 권한 팝업 요청
    // (_permissionRequested 플래그로 막지 않음 — 사용자가 수동으로 재시도 가능)
    try {
      _permissionRequested = true;
      final permission = await web_notif.requestNotificationPermission();
      _permissionGranted = permission == 'granted';
      if (kDebugMode) debugPrint('🔔 알림 권한 결과: $permission');
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

      // 브라우저 알림 생성 (title + body 함께 전달)
      web_notif.showBrowserNotification(title, body);
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
