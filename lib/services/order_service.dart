// order_service.dart — Firestore 기반 주문 서비스 (Hive 로컬 백업 병행)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

      // 3) 주문 확인 이메일 발송 (비동기, 실패 무시)
      EmailService.sendOrderConfirmEmail(order).catchError((e) {
        if (kDebugMode) debugPrint('주문 확인 이메일 실패 (무시): $e');
        return false;
      });

      // 4) 무통장입금 주문인 경우 관리자에게 별도 알림
      if (order.paymentMethod == '무통장입금') {
        EmailService.sendBankTransferAdminAlert(order).catchError((e) {
          if (kDebugMode) debugPrint('무통장입금 관리자 알림 실패 (무시): $e');
          return false;
        });
      }
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
          .map((doc) => _orderFromFirestore(doc.data()))
          .toList();

      // 메모리에서 정렬
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Firestore 주문 조회 실패, Hive 폴백: $e');
      return _getUserOrdersFromHive(userId);
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
          .map((doc) => _orderFromFirestore(doc.data()))
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
          .map((doc) => _orderFromFirestore(doc.data()))
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
          final order = _orderFromFirestore(orderData);
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
      await _db.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) debugPrint('✅ Firestore 주문 상태 업데이트: $orderId → ${status.name}');

      // 3) FCM 알림 + 이메일 발송
      try {
        final orderDoc = await _db.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
          final order = _orderFromFirestore(orderDoc.data()!);
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
    return {
      'id': order.id,
      'userId': order.userId,
      'userName': order.userName,
      'userEmail': order.userEmail,
      'userPhone': order.userPhone,
      'userAddress': order.userAddress,
      'status': order.status.name,
      'totalAmount': order.totalAmount,
      'shippingFee': order.shippingFee,
      'paymentMethod': order.paymentMethod,
      'orderType': order.orderType,
      'groupName': order.groupName,
      'groupCount': order.groupCount,
      'memo': order.memo,
      'createdAt': order.createdAt.toIso8601String(),
      'items': order.items.map((i) => i.toJson()).toList(),
    };
  }

  static OrderModel _orderFromFirestore(Map<String, dynamic> data) {
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
      paymentMethod: data['paymentMethod'] as String? ?? '',
      orderType: data['orderType'] as String? ?? 'personal',
      groupName: data['groupName'] as String?,
      groupCount: data['groupCount'] as int?,
      memo: data['memo'] as String?,
      createdAt: createdAt,
      items: (data['items'] as List? ?? []).map((i) {
        final item = Map<String, dynamic>.from(i as Map);
        return OrderItem(
          productId: item['productId'] as String? ?? '',
          productName: item['productName'] as String? ?? '',
          size: item['size'] as String? ?? '',
          color: item['color'] as String? ?? '',
          quantity: item['quantity'] as int? ?? 1,
          price: (item['price'] as num?)?.toDouble() ?? 0,
          customOptions: item['customOptions'] as Map<String, dynamic>?,
        );
      }).toList(),
    );
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
      paymentMethod: data['paymentMethod'] as String? ?? '',
      orderType: data['orderType'] as String? ?? 'personal',
      groupName: data['groupName'] as String?,
      groupCount: data['groupCount'] as int?,
      memo: data['memo'] as String?,
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
      items: (data['items'] as List? ?? []).map((i) {
        final item = Map<String, dynamic>.from(i as Map);
        return OrderItem(
          productId: item['productId'] as String? ?? '',
          productName: item['productName'] as String? ?? '',
          size: item['size'] as String? ?? '',
          color: item['color'] as String? ?? '',
          quantity: item['quantity'] as int? ?? 1,
          price: (item['price'] as num?)?.toDouble() ?? 0,
          customOptions: item['customOptions'] as Map<String, dynamic>?,
        );
      }).toList(),
    );
  }
}
