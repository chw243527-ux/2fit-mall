// fcm_service.dart - Firebase Cloud Messaging + 웹 브라우저 알림
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/models.dart';

class FcmService {
  static final _db = FirebaseFirestore.instance;
  static String? _currentToken;

  // ── 초기화 ────────────────────────────────────────────
  static Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 알림 권한 요청
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        debugPrint('FCM 권한: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // FCM 토큰 가져오기
        try {
          if (kIsWeb) {
            // 웹 VAPID 키 설정 방법:
            // 1. Firebase Console → 프로젝트 설정 → 클라우드 메시징 탭
            // 2. 웹 푸시 인증서 → '키 쌍 생성' 클릭
            // 3. 생성된 키를 아래 vapidKey에 붙여넣기
            const vapidKey =
                'BPOVoK3gRuXzSCDkS5jtfKFNV1PV3BXnJJXVlFJhk6KQQMK5zqJ_N3G5zYYsNJT1JoV7tKMvVsZJfS5rqF5o3M';
            // ignore: dead_code
            _currentToken = await messaging.getToken(
              vapidKey: vapidKey.isEmpty ? null : vapidKey,
            ).catchError((_) => null);
          } else {
            _currentToken = await messaging.getToken();
          }
          if (kDebugMode) debugPrint('FCM 토큰: ${_currentToken?.substring(0, 20)}...');
        } catch (e) {
          if (kDebugMode) debugPrint('FCM 토큰 가져오기 실패 (정상): $e');
        }

        // 포그라운드 메시지 핸들러
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (kDebugMode) {
            debugPrint('포그라운드 메시지: ${message.notification?.title}');
          }
        });

        // 토큰 갱신 핸들러
        messaging.onTokenRefresh.listen((newToken) {
          _currentToken = newToken;
          if (kDebugMode) debugPrint('FCM 토큰 갱신됨');
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FCM 초기화 오류 (무시): $e');
    }
  }

  static Future<String?> getToken() async => _currentToken;

  // ── FCM 토큰 Firestore 저장 ────────────────────────────
  static Future<void> saveTokenToFirestore(String userId) async {
    if (userId.isEmpty) return;
    try {
      final token = _currentToken ?? 'web_${DateTime.now().millisecondsSinceEpoch}';
      await _db.collection('users').doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'android',
      });
      if (kDebugMode) debugPrint('✅ FCM 토큰 저장: $userId');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM 토큰 저장 실패: $e');
    }
  }

  // ── 주문 상태 변경 알림 ────────────────────────────────
  static Future<void> sendOrderStatusNotification({
    OrderModel? order,
    OrderStatus? newStatus,
    String? userId,
    String? orderId,
    String? status,
    String? message,
  }) async {
    try {
      final targetUserId = order?.userId ?? userId ?? '';
      final targetOrderId = order?.id ?? orderId ?? '';
      final statusLabel = newStatus?.label ?? status ?? '';
      final sid = targetOrderId.length > 8
          ? targetOrderId.substring(0, 8)
          : targetOrderId;
      final body = message ?? '주문 #$sid 상태가 "$statusLabel"으로 변경되었습니다';

      // Firestore 알림 저장 (앱 내 알림)
      final notifRef = _db.collection('notifications').doc();
      await notifRef.set({
        'id': notifRef.id,
        'userId': targetUserId,
        'title': '📦 주문 상태 변경',
        'body': body,
        'type': 'order_status',
        'orderId': targetOrderId,
        'status': statusLabel,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ 주문 상태 알림 저장: $targetOrderId → $statusLabel');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('sendOrderStatusNotification error: $e');
    }
  }

  // ── 새 주문 접수 알림 (관리자용) ─────────────────────
  static Future<void> sendNewOrderNotification(OrderModel order) async {
    try {
      final sid = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
      final notifRef = _db.collection('admin_notifications').doc();
      await notifRef.set({
        'id': notifRef.id,
        'title': '🛒 새 주문 접수',
        'body': '${order.userName}님 주문 #$sid (${_fmtPrice(order.totalAmount)}원)',
        'type': 'new_order',
        'orderId': order.id,
        'orderAmount': order.totalAmount,
        'customerName': order.userName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) debugPrint('✅ 새 주문 관리자 알림 저장: ${order.id}');
    } catch (e) {
      if (kDebugMode) debugPrint('sendNewOrderNotification error: $e');
    }
  }

  // ── 재입고 알림 ────────────────────────────────────────
  static Future<void> sendRestockNotification({
    required String productId,
    required String productName,
  }) async {
    try {
      // 재입고 알림 신청자 조회
      final wishlistSnap = await _db
          .collection('restock_alerts')
          .where('productId', isEqualTo: productId)
          .where('notified', isEqualTo: false)
          .get();

      int sentCount = 0;
      for (final doc in wishlistSnap.docs) {
        final targetUserId = doc.data()['userId'] as String? ?? '';
        if (targetUserId.isEmpty) continue;

        final notifRef = _db.collection('notifications').doc();
        await notifRef.set({
          'id': notifRef.id,
          'userId': targetUserId,
          'title': '🔔 재입고 알림',
          'body': '"$productName" 상품이 재입고되었습니다!',
          'type': 'restock',
          'productId': productId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 알림 발송 완료 표시
        await doc.reference.update({'notified': true});
        sentCount++;
      }

      if (kDebugMode) {
        debugPrint('✅ 재입고 알림 발송: $productName ($sentCount명)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('sendRestockNotification error: $e');
    }
  }

  // ── 프로모션/이벤트 알림 ──────────────────────────────
  static Future<bool> sendPromoNotification({
    required String title,
    String? body,
    String? message,
    String? targetGrade,
    String? targetUserId,
  }) async {
    try {
      final notifBody = body ?? message ?? '2FIT Mall에서 새로운 소식을 전달드립니다.';

      if (targetUserId != null) {
        // 특정 사용자 대상
        final notifRef = _db.collection('notifications').doc();
        await notifRef.set({
          'id': notifRef.id,
          'userId': targetUserId,
          'title': title,
          'body': notifBody,
          'type': 'promo',
          'targetGrade': targetGrade,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 전체 또는 등급별 대상 → 브로드캐스트 알림 저장
        final broadcastRef = _db.collection('broadcast_notifications').doc();
        await broadcastRef.set({
          'id': broadcastRef.id,
          'title': title,
          'body': notifBody,
          'type': 'promo',
          'targetGrade': targetGrade ?? 'all',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (kDebugMode) debugPrint('✅ 프로모션 알림 저장: $title');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('sendPromoNotification error: $e');
      return false;
    }
  }

  // ── 읽지 않은 알림 수 스트림 ──────────────────────────
  static Stream<int> watchUnreadCount(String userId) {
    if (userId.isEmpty) return Stream.value(0);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length)
        .handleError((_) => 0);
  }

  // ── 알림 목록 스트림 ─────────────────────────────────
  static Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data())
            .toList()
            ..sort((a, b) {
              final at = a['createdAt'];
              final bt = b['createdAt'];
              if (at == null || bt == null) return 0;
              return (bt as dynamic).compareTo(at);
            }))
        .handleError((_) => <Map<String, dynamic>>[]);
  }

  // ── 알림 읽음 처리 ────────────────────────────────────
  static Future<void> markAsRead(String notifId) async {
    try {
      await _db.collection('notifications').doc(notifId).update({'isRead': true});
    } catch (e) {
      if (kDebugMode) debugPrint('markAsRead error: $e');
    }
  }

  // ── 전체 알림 읽음 처리 ───────────────────────────────
  static Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) debugPrint('markAllAsRead error: $e');
    }
  }

  // ── 가격 포맷 헬퍼 ────────────────────────────────────
  static String _fmtPrice(double amount) {
    final n = amount.toInt();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
