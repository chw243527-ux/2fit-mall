// notification_service.dart
// ══════════════════════════════════════════════════════════════
// 알림 서비스 — 카카오 알림톡 + 관리자 이메일 알림 + 브라우저 알림
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'supabase_service.dart';
import 'notification_web_stub.dart'
    if (dart.library.html) 'notification_web_impl.dart' as web_notif;

// ─── 🔑 SOLAPI 카카오 알림톡 설정 ───────────────────────────────
// 발송 방식: SOLAPI (console.solapi.com) 경유
// 참고: https://docs.solapi.com/references/messages/send-many-detail
class KakaoConfig {
  // ══ API 키 발급 위치 ═══════════════════════════════════════════
  // console.solapi.com → 개발(</>) → API 키 관리
  // → API Key + API Secret 복사
  // ═════════════════════════════════════════════════════════════

  // 보안: SOLAPI 자격증명은 클라이언트 앱에 저장하지 않습니다.
  // 발송 기능은 Firebase Functions 서버 측 Secret으로 이전해야 합니다.
  static const apiKey = '';
  static const apiSecret = '';

  // ✅ 발신프로필 키 — SOLAPI 채널 연동 완료 (2026-06-17)
  static const senderKey = 'KA01PF2606170642574857w8Hjn9Czz4';

  // ✅ 발신번호 — SOLAPI 등록 완료 (2026-06-17)
  static const senderPhone = '01072276914';

  // ── 알림톡 템플릿 코드 (SOLAPI 검수 완료 — 2026-06-17) ────────
  static const templateOrderConfirm = 'T6E6wLoEmf'; // 주문 확인
  static const templateShipped      = '1o2lfrsB54'; // 배송 시작
  static const templateDelivered    = 'GmR1Ij666P'; // 배송 완료
  static const templateCancelled    = 'EOMxrky4zz'; // 주문 취소
  // ⚠️ 채팅 알림톡 템플릿: SOLAPI에서 검수 후 실제 코드로 교체
  // console.solapi.com → 카카오 알림톡 → 템플릿 관리 → 새 템플릿 등록
  // 템플릿 내용 예시:
  //   [2FIT MALL] 새 채팅 문의가 도착했습니다.
  //   고객명: #{고객명} / #{시간}
  //   내용: #{메시지}
  //   관리자 확인: https://2fit-mall.co.kr/#/admin?tab=chat
  static const templateChatAlert = ''; // 등록 후 코드 입력 (현재 SMS로 대체 발송)

  static bool get isConfigured =>
      apiKey.isNotEmpty && apiSecret.isNotEmpty && senderKey.isNotEmpty;

  // SOLAPI 알림톡 발송 엔드포인트
  static const apiUrl = 'https://api.solapi.com/messages/v4/send';
}

// ─── 관리자 설정 ────────────────────────────────────────────
class AdminConfig {
  // 주문 알림을 받을 관리자 이메일
  static const adminEmail = 'chw243527@gmail.com';

  // ✅ 관리자 핸드폰 번호 (SMS/알림톡 수신)
  static const adminPhone = '01072276914';

  // Supabase Edge Function URL (이메일 발송용) — 사용 시 입력
  static const emailEdgeFunctionUrl = '';

  static bool get hasEmail => adminEmail.isNotEmpty;
  static bool get hasEdgeFunction => emailEdgeFunctionUrl.isNotEmpty;
  static bool get hasPhone => adminPhone.isNotEmpty;
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
        '#{배송조회URL}': 'https://www.hanjin.com/kor/CMS/DeliveryMgr/WaybillSch.do?mCode=MN038&schLang=KR&wblnumText2=$trackingNumber',
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

  // ─── 관리자 채팅 알림 (SMS + 알림톡) ──────────────────────────
  // 일반 사용자가 채팅 입력 시 관리자 핸드폰으로 즉시 알림
  static Future<void> sendChatAlertToAdmin({
    required String userName,
    required String message,
    String language = 'KO',
  }) async {
    if (!AdminConfig.hasPhone) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final shortMsg = message.length > 30 ? '${message.substring(0, 30)}...' : message;

    // 1) 카카오 알림톡 시도 (템플릿 등록된 경우)
    if (KakaoConfig.templateChatAlert.isNotEmpty) {
      await _sendKakaoAlimtalk(
        phone: AdminConfig.adminPhone,
        templateCode: KakaoConfig.templateChatAlert,
        params: {
          '#{고객명}': userName,
          '#{시간}': timeStr,
          '#{메시지}': shortMsg,
        },
      );
    } else {
      // 2) 알림톡 템플릿 미등록 시 → SMS로 대체 발송
      await _sendSms(
        phone: AdminConfig.adminPhone,
        text: '[2FIT MALL] 새 채팅 문의\n'
            '고객: $userName ($timeStr)\n'
            '내용: $shortMsg\n'
            '확인: 2fit-mall.co.kr/#/admin?tab=chat',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 카카오 알림톡 발송 (내부) — SOLAPI 경유
  // 참고: https://docs.solapi.com/references/messages/send-many-detail
  // ══════════════════════════════════════════════════════════════
  static Future<void> _sendKakaoAlimtalk({
    required String phone,
    required String templateCode,
    required Map<String, String> params,
  }) async {
    if (!KakaoConfig.isConfigured) {
      // API 키 미설정 시 시뮬레이션 로그만 출력
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

      // HMAC-SHA256 인증 헤더 생성
      final date = DateTime.now().toUtc().toIso8601String();
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final hmacData = '$date$salt';
      final hmacBytes = _hmacSha256(KakaoConfig.apiSecret, hmacData);
      final signature = hmacBytes;

      // SOLAPI 알림톡 발송 요청
      // variables 키: SOLAPI는 #{변수명} 형식 그대로 사용
      final response = await http.post(
        Uri.parse(KakaoConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization':
              'HMAC-SHA256 apiKey=${KakaoConfig.apiKey}, date=$date, salt=$salt, signature=$signature',
        },
        body: jsonEncode({
          'message': {
            'to': phone.replaceAll('-', ''),
            'from': KakaoConfig.senderPhone,
            'type': 'ATA', // 알림톡
            'kakaoOptions': {
              'pfId': KakaoConfig.senderKey,
              'templateCode': templateCode,
              'variables': params, // ex) {'#{고객명}': '홍길동', ...}
            },
          },
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (kDebugMode) {
        debugPrint('📱 알림톡 발송 결과: ${response.statusCode}');
        debugPrint('   응답: $data');
      }
    } catch (e) {
      // 알림톡 실패는 결제 흐름을 막지 않음
      if (kDebugMode) debugPrint('⚠️ 알림톡 발송 실패: $e');
    }
  }

  // ── HMAC-SHA256 서명 생성 (SOLAPI 인증용) ────────────────────
  static String _hmacSha256(String secret, String data) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  // ── SMS 문자 발송 (SOLAPI) ───────────────────────────────────
  static Future<void> _sendSms({
    required String phone,
    required String text,
  }) async {
    if (!KakaoConfig.isConfigured) {
      if (kDebugMode) debugPrint('📲 [SMS 시뮬레이션] → $phone\n$text');
      return;
    }
    try {
      final date = DateTime.now().toUtc().toIso8601String();
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _hmacSha256(KakaoConfig.apiSecret, '$date$salt');

      final response = await http.post(
        Uri.parse(KakaoConfig.apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization':
              'HMAC-SHA256 apiKey=${KakaoConfig.apiKey}, date=$date, salt=$salt, signature=$signature',
        },
        body: jsonEncode({
          'message': {
            'to': phone.replaceAll('-', ''),
            'from': KakaoConfig.senderPhone,
            'type': text.length > 90 ? 'LMS' : 'SMS',
            'text': text,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('📲 SMS 발송 결과: ${response.statusCode}');
        debugPrint('   응답: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SMS 발송 실패: $e');
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
