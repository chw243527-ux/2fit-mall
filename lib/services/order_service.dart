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
      await _db.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
      paymentMethod: data['paymentMethod'] as String? ?? '',
      orderType: rawOrderType,
      customOptions: customOptions.isEmpty ? null : customOptions,
      groupName: data['groupName'] as String?,
      groupCount: (data['groupCount'] as num?)?.toInt(),
      memo: data['memo'] as String?,
      createdAt: createdAt,
      additionalOrderCount: (data['additionalOrderCount'] as num?)?.toInt() ?? 0,
      colorEditCount: (data['colorEditCount'] as num?)?.toInt() ?? 0,
      items: (data['items'] as List? ?? []).map((i) {
        final item = Map<String, dynamic>.from(i as Map);
        Map<String, dynamic>? itemOpts;
        final rawItemOpts = item['customOptions'];
        if (rawItemOpts is Map) {
          itemOpts = Map<String, dynamic>.from(rawItemOpts);
        }
        return OrderItem(
          productId: item['productId'] as String? ?? '',
          productName: item['productName'] as String? ?? '',
          size: item['size'] as String? ?? '',
          color: item['color'] as String? ?? '',
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          price: (item['price'] as num?)?.toDouble() ?? 0,
          customOptions: itemOpts,
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
