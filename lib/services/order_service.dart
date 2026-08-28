// order_service.dart — Firestore 기반 주문 서비스 (Hive 로컬 백업 병행)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/models.dart';
import '../utils/constants.dart';
import 'fcm_service.dart';
import 'email_service.dart';

class OrderService {
  static const _boxName = 'orders';
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return await Hive.openBox(_boxName);
  }

  // ────────────────────────────────────────────
  // 주문 저장
  // ────────────────────────────────────────────
  static Future<void> saveOrder(OrderModel order) async {
    final orderMap = _orderToMap(order);

    // 1) Hive 로컬 저장 (오프라인 백업)
    try {
      final box = await _getBox();
      await box.put(order.id, orderMap);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Hive 주문 저장 실패: $e');
    }

    // 2) Firestore 저장
    try {
      await _db.collection('orders').doc(order.id).set({
        ...orderMap,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) debugPrint('✅ Firestore 주문 저장 완료: ${order.id}');
      // ℹ️ 이메일 발송은 OrderProvider.addOrder()에서 처리 (중복 방지)
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 주문 저장 실패 (로컬만 저장됨): $e');
    }
  }

  // ────────────────────────────────────────────
  // 특정 유저 주문 조회
  // ────────────────────────────────────────────
  static Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      // Firestore에서 조회 (복잡한 쿼리 없이 단순 where)
      final snapshot = await _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      final orders = snapshot.docs
          .map((doc) => _orderFromFirestore(doc.data(), docId: doc.id))
          .toList();

      // 메모리에서 정렬
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 주문 조회 실패, Hive 폴백: $e');
      return _getUserOrdersFromHive(userId);
    }
  }

  /// 주문번호로 단일 주문을 조회합니다.
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _db.collection('orders').doc(orderId).get();
      if (!doc.exists || doc.data() == null) return null;
      return _orderFromFirestore(doc.data()!, docId: doc.id);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 주문 단건 조회 실패: $e');
      return null;
    }
  }

  // ────────────────────────────────────────────
  // 전체 주문 조회 (관리자용)
  // ────────────────────────────────────────────
  static Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _db.collection('orders').get();
      final orders = snapshot.docs
          .map((doc) => _orderFromFirestore(doc.data()))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 전체 주문 조회 실패, Hive 폴백: $e');
      return _getAllOrdersFromHive();
    }
  }

  // ────────────────────────────────────────────
  // 실시간 주문 스트림 (관리자용)
  // ────────────────────────────────────────────
  static Stream<List<OrderModel>> watchAllOrders() {
    return _db
        .collection('orders')
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => _orderFromFirestore(doc.data(), docId: doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // 특정 유저 주문 실시간 스트림
  static Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => _orderFromFirestore(doc.data(), docId: doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // ────────────────────────────────────────────
  // 주문 삭제 (관리자용)
  // ────────────────────────────────────────────
  static Future<void> deleteOrder(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).delete();
      if (kDebugMode) debugPrint('🗑️ 주문 삭제: $orderId');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 주문 삭제 실패: $e');
    }
    // Hive에서도 삭제
    try {
      final box = await _getBox();
      await box.delete(orderId);
    } catch (_) {}
  }

  // 주문 상태 업데이트 (배송 추적번호 포함)
  static Future<void> updateOrderStatusWithTracking({
    required String orderId,
    required OrderStatus status,
    String? trackingNumber,
    String? shippingCompany,
    String? adminMemo,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (trackingNumber != null) updates['trackingNumber'] = trackingNumber;
    if (shippingCompany != null) updates['shippingCompany'] = shippingCompany;
    if (adminMemo != null) updates['adminMemo'] = adminMemo;

    try {
      await _db.collection('orders').doc(orderId).update(updates);
      // Hive 업데이트
      final box = await _getBox();
      final data = box.get(orderId);
      if (data != null) {
        final updated = Map<String, dynamic>.from(data as Map);
        updated['status'] = status.name;
        if (trackingNumber != null) updated['trackingNumber'] = trackingNumber;
        if (shippingCompany != null) updated['shippingCompany'] = shippingCompany;
        await box.put(orderId, updated);
      }

      // ── 상태 변경 알림 + 이메일 발송 ──────────────────────
      try {
        // Firestore에서 주문 정보 조회
        final orderDoc = await _db.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
          final orderData = orderDoc.data()!;
          final order = _orderFromFirestore(orderData, docId: orderDoc.id);
          // FCM 알림
          await FcmService.sendOrderStatusNotification(
            order: order,
            newStatus: status,
            message: trackingNumber != null
                ? '배송 시작! 운송장: $trackingNumber (${shippingCompany ?? ''})'
                : null,
          );
          // 이메일 발송
          EmailService.sendOrderStatusEmail(
            order: order,
            newStatus: status,
            trackingNumber: trackingNumber,
            courierName: shippingCompany,
          ).catchError((e) {
            if (kDebugMode) debugPrint('이메일 발송 실패 (무시): $e');
            return false;
          });
        }
      } catch (e) {
        if (kDebugMode) debugPrint('알림/이메일 발송 실패 (무시): $e');
      }

      if (kDebugMode) debugPrint('✅ 주문 상태+배송정보 업데이트: $orderId');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 주문 업데이트 실패: $e');
    }
  }

  // ────────────────────────────────────────────
  // 주문 상태 업데이트
  // ────────────────────────────────────────────
  static Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    // 1) Hive 업데이트
    try {
      final box = await _getBox();
      final data = box.get(orderId);
      if (data != null) {
        final updated = Map<String, dynamic>.from(data as Map);
        updated['status'] = status.name;
        await box.put(orderId, updated);
      }
    } catch (_) {}

    // 2) Firestore 업데이트
    try {
      final Map<String, dynamic> updateData = {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // 배송완료 시 deliveredAt 기록 (자동 구매확정 기준)
      if (status == OrderStatus.delivered) {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }
      // 주문확인(confirmed) 시 디자인수정요청 마감일 = 3일 후로 설정
      if (status == OrderStatus.confirmed) {
        updateData['designRevisionDeadline'] =
            DateTime.now().add(const Duration(days: 3)).toIso8601String();
      }
      await _db.collection('orders').doc(orderId).update(updateData);
      if (kDebugMode) debugPrint('✅ Firestore 주문 상태 업데이트: $orderId → ${status.name}');

      // 3) FCM 알림 + 이메일 발송
      try {
        final orderDoc = await _db.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
          final order = _orderFromFirestore(orderDoc.data()!, docId: orderDoc.id);
          await FcmService.sendOrderStatusNotification(order: order, newStatus: status);
          EmailService.sendOrderStatusEmail(order: order, newStatus: status)
              .catchError((e) => false);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('알림 발송 실패 (무시): $e');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 상태 업데이트 실패: $e');
    }
  }

  // ────────────────────────────────────────────
  // 주문번호 생성
  // ────────────────────────────────────────────
  static String generateOrderId() {
    final now = DateTime.now();
    final ts = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final seq = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'ORD-$ts-$seq';
  }

  // ────────────────────────────────────────────
  // 색상/단체명 수정 요청 저장 (마이페이지 → Firestore)
  // ────────────────────────────────────────────
  static Future<bool> submitColorNameChangeRequest({
    required String orderId,
    String? newColorName,
    String? newTeamName,
    String? memo,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'colorEditRequested': true,
        'colorEditRequestedAt': FieldValue.serverTimestamp(),
      };
      if (newColorName != null) updates['requestedColorName'] = newColorName;
      if (newTeamName != null && newTeamName.isNotEmpty) {
        updates['requestedTeamName'] = newTeamName;
      }
      if (memo != null && memo.isNotEmpty) updates['colorEditMemo'] = memo;

      // colorEditCount 증가
      await _db.collection('orders').doc(orderId).update({
        ...updates,
        'colorEditCount': FieldValue.increment(1),
      });

      // Hive 동기화
      try {
        final box = await _getBox();
        final data = box.get(orderId);
        if (data != null) {
          final updated = Map<String, dynamic>.from(data as Map);
          updated['colorEditCount'] = ((updated['colorEditCount'] as int?) ?? 0) + 1;
          if (newColorName != null) updated['requestedColorName'] = newColorName;
          await box.put(orderId, updated);
        }
      } catch (_) {}

      // ── 관리자 알림 전송 (디자인 수정 요청) ──
      try {
        final notifRef = FirebaseFirestore.instance.collection('admin_notifications').doc();
        final sid = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
        final changeSummary = [
          if (newColorName != null) '색상: $newColorName',
          if (newTeamName != null && newTeamName.isNotEmpty) '단체명: $newTeamName',
          if (memo != null && memo.isNotEmpty) '메모: $memo',
        ].join(' / ');
        await notifRef.set({
          'id': notifRef.id,
          'title': '🎨 디자인 수정 요청',
          'body': '주문 #$sid — $changeSummary',
          'type': 'design_modify',
          'orderId': orderId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('관리자 알림 저장 실패: $e');
      }

      if (kDebugMode) debugPrint('✅ 색상/단체명 변경 요청 저장: $orderId → $newColorName');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 색상 변경 요청 저장 실패: $e');
      return false;
    }
  }

  // ────────────────────────────────────────────
  // 단체 주문 유틸리티
  // ────────────────────────────────────────────
  static bool canModifyOrder(OrderModel order) {
    if (order.orderType != 'group') return false;
    final deadline = order.createdAt.add(const Duration(days: AppConstants.customOrderModifyDays));
    return DateTime.now().isBefore(deadline);
  }

  static int getModifyDaysLeft(OrderModel order) {
    final deadline = order.createdAt.add(const Duration(days: AppConstants.customOrderModifyDays));
    final diff = deadline.difference(DateTime.now());
    return diff.inDays.clamp(0, AppConstants.customOrderModifyDays);
  }

  static bool shouldAutoConfirm(OrderModel order) {
    if (order.status != OrderStatus.confirmed &&
        order.status != OrderStatus.shipped &&
        order.status != OrderStatus.delivered) {
      final autoDate = order.createdAt.add(const Duration(days: AppConstants.customOrderAutoConfirmDays));
      return DateTime.now().isAfter(autoDate);
    }
    return false;
  }

  static Future<int> processAutoConfirm() async {
    final orders = await getAllOrders();
    int count = 0;
    for (final order in orders) {
      if (order.orderType == 'group' && shouldAutoConfirm(order)) {
        await updateOrderStatus(order.id, OrderStatus.confirmed);
        count++;
      }
    }
    return count;
  }

  // ────────────────────────────────────────────
  // 배송완료 자동 처리 (tracker.delivery API 조회)
  // shipped 상태의 주문 중 운송장이 등록된 것만 조회
  // lastEvent.status.code == 'DELIVERED' 이면 delivered 로 자동 전환
  // ────────────────────────────────────────────
  static String _carrierIdFromName(String name) {
    final n = name.trim().toLowerCase();
    if (n.contains('cj') || n.contains('대한통운')) return 'kr.cjlogistics';
    if (n.contains('한진')) return 'kr.hanjin';
    if (n.contains('롯데') || n.contains('lotte')) return 'kr.lotte';
    if (n.contains('우체국') || n.contains('epost')) return 'kr.epost';
    if (n.contains('로젠') || n.contains('logen')) return 'kr.logen';
    if (n.contains('경동')) return 'kr.kdexp';
    if (n.contains('대신')) return 'kr.daesin';
    if (n.contains('gtx') || n.contains('로지스')) return 'kr.cjlogistics';
    return 'kr.hanjin'; // 기본값 한진
  }

  static Future<int> autoCheckDelivered() async {
    int updated = 0;
    try {
      // shipped 상태 + trackingNumber 있는 주문만 조회
      final snap = await _db
          .collection('orders')
          .where('status', isEqualTo: OrderStatus.shipped.name)
          .get();

      const endpoint = 'https://apis.tracker.delivery/graphql';
      const query = r'''
query Track($carrierId: ID!, $trackingNumber: String!) {
  track(carrierId: $carrierId, trackingNumber: $trackingNumber) {
    lastEvent { status { code } }
  }
}''';

      for (final doc in snap.docs) {
        final data = doc.data();
        final trackingNumber = (data['trackingNumber'] as String? ?? '').trim();
        final shippingCompany = (data['shippingCompany'] as String? ?? '').trim();
        if (trackingNumber.isEmpty) continue;

        try {
          final carrierId = _carrierIdFromName(shippingCompany);
          final resp = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query,
              'variables': {'carrierId': carrierId, 'trackingNumber': trackingNumber},
            }),
          ).timeout(const Duration(seconds: 8));

          if (resp.statusCode != 200) continue;
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          if (body.containsKey('errors')) continue;

          final code = body['data']?['track']?['lastEvent']?['status']?['code'] as String?;
          if (code == null) continue;

          if (code.toUpperCase() == 'DELIVERED') {
            // Firestore 상태 delivered 로 전환 + deliveredAt 기록
            await _db.collection('orders').doc(doc.id).update({
              'status': OrderStatus.delivered.name,
              'deliveredAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            // Hive 동기화
            try {
              final box = await _getBox();
              final cached = box.get(doc.id);
              if (cached != null) {
                final m = Map<String, dynamic>.from(cached as Map);
                m['status'] = OrderStatus.delivered.name;
                await box.put(doc.id, m);
              }
            } catch (_) {}
            // FCM 푸시 알림
            try {
              final order = _orderFromFirestore(data, docId: doc.id);
              await FcmService.sendOrderStatusNotification(
                order: order,
                newStatus: OrderStatus.delivered,
                message: '배송이 완료되었습니다! 구매를 확정해 주세요.',
              );
            } catch (_) {}
            updated++;
            if (kDebugMode) debugPrint('✅ 자동 배송완료: ${doc.id} ($trackingNumber)');
          }
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ 배송조회 실패 (${doc.id}): $e');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ autoCheckDelivered 실패: $e');
    }
    return updated;
  }

  // ────────────────────────────────────────────
  // 베스트 상품 집계 (실제 구매 기준)
  // ────────────────────────────────────────────

  /// 취소/환불을 제외한 모든 실구매 주문에서
  /// productId별 실제 판매 수량(quantity 합산)을 집계해 반환.
  /// (pending 포함 — 결제 완료 시점부터 베스트 반영)
  /// 반환값: { productId: totalQuantity }
  static Future<Map<String, int>> getSalesCountMap() async {
    try {
      // Firestore whereNotIn은 최대 10개 값 지원
      final snapshot = await _db
          .collection('orders')
          .where('status', whereNotIn: [
            OrderStatus.cancelled.name,
            OrderStatus.refunded.name,
          ])
          .get();

      final Map<String, int> countMap = {};
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final rawItems = data['items'] as List<dynamic>? ?? [];
          for (final rawItem in rawItems) {
            final item = rawItem as Map<String, dynamic>;
            final productId = item['productId'] as String? ?? '';
            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
            if (productId.isNotEmpty) {
              countMap[productId] = (countMap[productId] ?? 0) + qty;
            }
          }
        } catch (_) {}
      }
      return countMap;
    } catch (_) {
      return {};
    }
  }

  // ────────────────────────────────────────────
  // 내부 유틸리티
  // ────────────────────────────────────────────
  static Future<List<OrderModel>> _getUserOrdersFromHive(String userId) async {
    final box = await _getBox();
    final orders = <OrderModel>[];
    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null && data['userId'] == userId) {
        try {
          orders.add(_orderFromMap(Map<String, dynamic>.from(data as Map)));
        } catch (_) {}
      }
    }
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  static Future<List<OrderModel>> _getAllOrdersFromHive() async {
    final box = await _getBox();
    final orders = <OrderModel>[];
    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        try {
          orders.add(_orderFromMap(Map<String, dynamic>.from(data as Map)));
        } catch (_) {}
      }
    }
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  static Map<String, dynamic> _orderToMap(OrderModel order) {
    final map = <String, dynamic>{
      'id': order.id,
      'userId': order.userId,
      'userName': order.userName,
      'userEmail': order.userEmail,
      'userPhone': order.userPhone,
      'userAddress': order.userAddress,
      'status': order.status.name,
      'totalAmount': order.totalAmount,
      'shippingFee': order.shippingFee,
      'couponId': order.couponId,
      'couponDiscount': order.couponDiscount,
      'usedPoints': order.usedPoints,
      'pointDiscount': order.pointDiscount,
      'paymentMethod': order.paymentMethod,
      'orderType': order.orderType,
      'groupName': order.groupName,
      'groupCount': order.groupCount,
      'memo': order.memo,
      'createdAt': order.createdAt.toIso8601String(),
      'items': order.items.map((i) => i.toJson()).toList(),
    };
    // 단체주문인 경우 customOptions (persons, teamName 등) 저장
    if (order.customOptions != null && order.customOptions!.isNotEmpty) {
      map['customOptions'] = order.customOptions;
    }
    // 단체주문 편의 필드: persons, teamName을 최상위에도 저장 (검색 용이)
    if (order.orderType == 'group' || order.orderType == 'additional') {
      final opts = order.customOptions ?? {};
      final persons = opts['persons'];
      if (persons != null) map['persons'] = persons;
      final teamName = opts['teamName'] ?? order.groupName;
      if (teamName != null) map['teamName'] = teamName;
    }
    // 결제키 / 현금영수증 번호
    if (order.paymentKey != null) map['paymentKey'] = order.paymentKey;
    if (order.cashReceiptNum != null) map['cashReceiptNum'] = order.cashReceiptNum;
    return map;
  }

  /// gender 영문 → 한글 변환 헬퍼
  static String _normalizeGender(dynamic g) {
    if (g == null) return '-';
    final s = g.toString().toLowerCase();
    if (s == 'male' || s == 'm' || s == '남성') return '남';
    if (s == 'female' || s == 'f' || s == '여성') return '여';
    return g.toString();
  }

  /// persons 리스트 정규화 (gender 영문→한글)
  static List<dynamic> _normalizePersons(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((p) {
      if (p is Map) {
        final m = Map<String, dynamic>.from(p);
        m['gender'] = _normalizeGender(m['gender']);
        return m;
      }
      return p;
    }).toList();
  }

  /// public wrapper — mypage_screen 등 외부에서 Firestore doc 파싱에 직접 사용
  static OrderModel parseOrderFromFirestore(Map<String, dynamic> data, {String? docId}) {
    return _orderFromFirestore(data, docId: docId);
  }

  static OrderModel _orderFromFirestore(Map<String, dynamic> data, {String? docId}) {
    // 문서 ID: 파라미터 우선, 없으면 data['id'] 사용
    final resolvedDocId = (docId?.isNotEmpty == true) ? docId! : (data['id'] as String? ?? '');

    // Firestore Timestamp → DateTime 변환
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final statusStr = data['status'] as String? ?? 'pending';
    final status = OrderStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => OrderStatus.pending,
    );

    // customOptions 파싱: top-level customOptions 맵 + persons 필드 통합
    Map<String, dynamic> customOptions;
    final rawOpts = data['customOptions'];
    if (rawOpts is Map) {
      customOptions = Map<String, dynamic>.from(rawOpts);
    } else {
      customOptions = {};
    }

    // persons 필드: customOptions.persons 없으면 top-level persons 병합 (gender 정규화 포함)
    final optsPersons = customOptions['persons'];
    if (optsPersons == null || (optsPersons as List?)?.isEmpty == true) {
      final topPersons = data['persons'];
      if (topPersons is List && topPersons.isNotEmpty) {
        customOptions['persons'] = _normalizePersons(topPersons);
      }
    } else {
      customOptions['persons'] = _normalizePersons(optsPersons);
    }

    // groupName, teamName 통합
    if (customOptions['teamName'] == null || (customOptions['teamName'] as String?)?.isEmpty == true) {
      final gn = data['groupName'] as String?;
      if (gn != null && gn.isNotEmpty) customOptions['teamName'] = gn;
    }
    // totalCount 통합
    if (customOptions['totalCount'] == null) {
      final gc = data['groupCount'];
      if (gc != null) customOptions['totalCount'] = gc;
    }
    // maleCount/femaleCount 통합 (top-level에서)
    if (customOptions['maleCount'] == null && data['maleCount'] != null) {
      customOptions['maleCount'] = data['maleCount'];
    }
    if (customOptions['femaleCount'] == null && data['femaleCount'] != null) {
      customOptions['femaleCount'] = data['femaleCount'];
    }
    // manager/담당자 이름 통합
    if (customOptions['manager'] == null && customOptions['managerName'] == null) {
      final mgr = data['managerName'] as String?;
      if (mgr != null && mgr.isNotEmpty) customOptions['manager'] = mgr;
    }

    // ── 최상위 designRevisionRequest → customOptions에 병합 ──
    // 디자인수정 요청은 최상위 필드로 저장, customOptions getter는 customOptions 안에서 읽음
    final topDrReq = data['designRevisionRequest'];
    if (topDrReq is Map) {
      final existing = customOptions['designRevisionRequest'];
      if (existing is Map) {
        // 이미 있으면 최상위 값으로 덮어쓰기 (더 최신 데이터 우선)
        final merged = Map<String, dynamic>.from(existing);
        merged.addAll(Map<String, dynamic>.from(topDrReq));
        customOptions['designRevisionRequest'] = merged;
      } else {
        customOptions['designRevisionRequest'] = Map<String, dynamic>.from(topDrReq);
      }
    }

    // ── orderType 자동 보정 ──
    // Firestore에 'personal'로 저장됐더라도 진짜 단체주문이면 보정
    String rawOrderType = data['orderType'] as String? ?? 'personal';
    if (rawOrderType == 'personal') {
      final hasPersons = (customOptions['persons'] as List?)?.isNotEmpty == true;
      final hasTeamName = (customOptions['teamName'] as String?)?.isNotEmpty == true;
      // GRP_/GROUP- 접두사이거나, persons+teamName 모두 있으면 단체주문으로 보정
      final isGrpId = resolvedDocId.startsWith('GRP_') || resolvedDocId.startsWith('GROUP-');
      if (isGrpId || (hasPersons && hasTeamName)) {
        final isAdditional = resolvedDocId.contains('ADD') ||
            customOptions['isAdditional'] == true ||
            data['isAdditionalOrder'] == true;
        rawOrderType = isAdditional ? 'additional' : 'group';
      }
    }

    // 주소: userAddress 없으면 deliveryAddress 사용
    final userAddress = (data['userAddress'] as String?)?.isNotEmpty == true
        ? data['userAddress'] as String
        : (data['deliveryAddress'] as String? ?? '');

    return OrderModel(
      id: resolvedDocId,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userPhone: data['userPhone'] as String? ?? '',
      userAddress: userAddress,
      status: status,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0,
      couponId: data['couponId'] as String?,
      couponDiscount: (data['couponDiscount'] as num?)?.toDouble() ?? 0,
      usedPoints: (data['usedPoints'] as num?)?.toInt() ?? 0,
      pointDiscount: (data['pointDiscount'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? '',
      orderType: rawOrderType,
      customOptions: customOptions.isEmpty ? null : customOptions,
      groupName: data['groupName'] as String?,
      groupCount: (data['groupCount'] as num?)?.toInt(),
      memo: data['memo'] as String?,
      createdAt: createdAt,
      additionalOrderCount: (data['additionalOrderCount'] as num?)?.toInt() ?? 0,
      colorEditCount: (data['colorEditCount'] as num?)?.toInt() ?? 0,
      designRevisionCount: (data['designRevisionCount'] as num?)?.toInt() ?? 0,
      designRevisionDeadline: data['designRevisionDeadline'] != null
          ? DateTime.tryParse(data['designRevisionDeadline'] as String)
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] is Timestamp
              ? (data['deliveredAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['deliveredAt'].toString()))
          : null,
      paymentKey: data['paymentKey'] as String?,
      cashReceiptNum: data['cashReceiptNum'] as String?,
      items: _parseItems(data),
    );
  }

  /// items 파싱 — Firestore data에서 items 추출.
  /// items 필드가 없거나 비어 있으면 customOptions/top-level 필드로 폴백 아이템 1개 생성.
  static List<OrderItem> _parseItems(Map<String, dynamic> data) {
    final rawList = data['items'] as List?;
    if (rawList != null && rawList.isNotEmpty) {
      return rawList.map((i) {
        final item = Map<String, dynamic>.from(i as Map);
        Map<String, dynamic>? itemOpts;
        final rawItemOpts = item['customOptions'];
        if (rawItemOpts is Map) itemOpts = Map<String, dynamic>.from(rawItemOpts);
        return OrderItem(
          productId: item['productId'] as String? ?? '',
          productName: item['productName'] as String? ?? '',
          size: item['size'] as String? ?? '',
          color: item['color'] as String? ?? '',
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          price: (item['price'] as num?)?.toDouble() ?? 0,
          customOptions: itemOpts,
          imageUrl: item['imageUrl'] as String?,
        );
      }).toList();
    }

    // ── 폴백: items 없을 때 customOptions / top-level 필드에서 구성
    final opts = data['customOptions'];
    final optsMap = opts is Map ? Map<String, dynamic>.from(opts) : <String, dynamic>{};

    // 상품명 후보: customOptions.productName > customOptions.teamName+'단체복' > groupName+'단체복' > '주문 상품'
    final productName = (optsMap['productName'] as String?)?.isNotEmpty == true
        ? optsMap['productName'] as String
        : (data['productName'] as String?)?.isNotEmpty == true
            ? data['productName'] as String
            : ((optsMap['teamName'] ?? data['groupName']) as String?)?.isNotEmpty == true
                ? '${optsMap['teamName'] ?? data['groupName']} 단체복'
                : '주문 상품';

    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
    final shippingFee = (data['shippingFee'] as num?)?.toDouble() ?? 0;
    final qty = (data['groupCount'] as num?)?.toInt()
        ?? (optsMap['totalCount'] as num?)?.toInt()
        ?? 1;
    final price = qty > 0 ? (totalAmount - shippingFee) / qty : (totalAmount - shippingFee);

    final imageUrl = (optsMap['productImageUrl'] as String?)?.isNotEmpty == true
        ? optsMap['productImageUrl'] as String?
        : (optsMap['designFileUrl'] as String?)?.isNotEmpty == true
            ? optsMap['designFileUrl'] as String?
            : null;

    return [
      OrderItem(
        productId: optsMap['productId'] as String? ?? '',
        productName: productName,
        size: '단체',
        color: optsMap['mainColor'] as String? ?? '',
        quantity: qty,
        price: price,
        imageUrl: imageUrl,
      ),
    ];
  }

  static OrderModel _orderFromMap(Map<String, dynamic> data) {
    final statusStr = data['status'] as String? ?? 'pending';
    final status = OrderStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => OrderStatus.pending,
    );
    return OrderModel(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userPhone: data['userPhone'] as String? ?? '',
      userAddress: data['userAddress'] as String? ?? '',
      status: status,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0,
      couponId: data['couponId'] as String?,
      couponDiscount: (data['couponDiscount'] as num?)?.toDouble() ?? 0,
      usedPoints: (data['usedPoints'] as num?)?.toInt() ?? 0,
      pointDiscount: (data['pointDiscount'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? '',
      orderType: data['orderType'] as String? ?? 'personal',
      groupName: data['groupName'] as String?,
      groupCount: data['groupCount'] as int?,
      memo: data['memo'] as String?,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
      customOptions: data['customOptions'] as Map<String, dynamic>?,
      additionalOrderCount: (data['additionalOrderCount'] as num?)?.toInt() ?? 0,
      colorEditCount: (data['colorEditCount'] as num?)?.toInt() ?? 0,
      designRevisionCount: (data['designRevisionCount'] as num?)?.toInt() ?? 0,
      designRevisionDeadline: data['designRevisionDeadline'] != null
          ? DateTime.tryParse(data['designRevisionDeadline'] as String)
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] is Timestamp
              ? (data['deliveredAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['deliveredAt'].toString()))
          : null,
      paymentKey: data['paymentKey'] as String?,
      cashReceiptNum: data['cashReceiptNum'] as String?,
      items: (data['items'] as List? ?? []).map((i) {
        final item = Map<String, dynamic>.from(i as Map);
        return OrderItem(
          productId: item['productId'] as String? ?? '',
          productName: item['productName'] as String? ?? '',
          size: item['size'] as String? ?? '',
          color: item['color'] as String? ?? '',
          quantity: item['quantity'] as int? ?? 1,
          price: (item['price'] as num?)?.toDouble() ?? 0,
          customOptions: item['customOptions'] != null
              ? Map<String, dynamic>.from(item['customOptions'] as Map)
              : null,
          imageUrl: item['imageUrl'] as String?,
        );
      }).toList(),
    );
  }
}
