// point_service.dart — 포인트 적립/차감/조회 서비스
// Firestore 컬렉션: users/{uid}/point_history (sub-collection)
// 적립률: 결제금액의 1% (단체주문 제외, 개인 일반주문만)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ── 포인트 액션 타입 ────────────────────────────────────────
enum PointActionType { earn, use, expire, admin }

extension PointActionTypeExt on PointActionType {
  String get label {
    switch (this) {
      case PointActionType.earn:   return '적립';
      case PointActionType.use:    return '사용';
      case PointActionType.expire: return '소멸';
      case PointActionType.admin:  return '관리자 조정';
    }
  }
  String get key {
    switch (this) {
      case PointActionType.earn:   return 'earn';
      case PointActionType.use:    return 'use';
      case PointActionType.expire: return 'expire';
      case PointActionType.admin:  return 'admin';
    }
  }
  static PointActionType fromKey(String k) {
    switch (k) {
      case 'use':    return PointActionType.use;
      case 'expire': return PointActionType.expire;
      case 'admin':  return PointActionType.admin;
      default:       return PointActionType.earn;
    }
  }
}

// ── 포인트 내역 모델 ────────────────────────────────────────
class PointHistory {
  final String id;
  final PointActionType action;
  final int amount;       // 양수 = 적립, 음수 = 차감
  final String desc;      // 예: '주문 ORD-20260815-00001 1% 적립'
  final String? orderId;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const PointHistory({
    required this.id,
    required this.action,
    required this.amount,
    required this.desc,
    this.orderId,
    required this.createdAt,
    this.expiresAt,
  });

  factory PointHistory.fromDoc(String id, Map<String, dynamic> d) {
    final createdAt = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final action = PointActionTypeExt.fromKey(d['action'] as String? ?? 'earn');
    return PointHistory(
      id: id,
      action: action,
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      desc: d['desc'] as String? ?? '',
      orderId: d['orderId'] as String?,
      createdAt: createdAt,
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ??
          (action == PointActionType.earn || action == PointActionType.admin
              ? DateTime(createdAt.year + 1, createdAt.month, createdAt.day,
                  createdAt.hour, createdAt.minute, createdAt.second)
              : null),
    );
  }

  Map<String, dynamic> toDoc() => {
    'action': action.key,
    'amount': amount,
    'desc': desc,
    if (orderId != null) 'orderId': orderId,
    'createdAt': Timestamp.fromDate(createdAt),
    if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
  };
}

// ── 포인트 서비스 ────────────────────────────────────────────
class PointService {
  static final _db = FirebaseFirestore.instance;

  static const double _earnRate = 0.01; // 1%

  // ── 현재 포인트 잔액 조회 ──────────────────────────────
  static Future<int> getBalance(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return 0;
      return (doc.data()?['points'] as num?)?.toInt() ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('getBalance error: $e');
      return 0;
    }
  }

  // ── 포인트 내역 스트림 (최신순 50건) ─────────────────
  static Stream<List<PointHistory>> watchHistory(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('point_history')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PointHistory.fromDoc(d.id, d.data()))
            .toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('watchHistory error: $e');
      return <PointHistory>[];
    });
  }

  // ── 주문 완료 시 1% 자동 적립 ─────────────────────────
  // orderType == 'personal' 인 경우만 적립
  static Future<void> earnFromOrder({
    required String userId,
    required String orderId,
    required double totalAmount,
    required String orderType,
  }) async {
    // 단체주문(group, additional)은 포인트 적립 제외
    if (orderType != 'personal') return;
    // 적립 포인트 계산 (소수점 버림)
    final earned = (totalAmount * _earnRate).floor();
    if (earned <= 0) return;

    try {
      final userRef = _db.collection('users').doc(userId);
      final histRef = userRef.collection('point_history').doc();

      await _db.runTransaction((txn) async {
        final snap = await txn.get(userRef);
        final prev = (snap.data()?['points'] as num?)?.toInt() ?? 0;
        txn.update(userRef, {'points': prev + earned});
        txn.set(histRef, PointHistory(
          id: histRef.id,
          action: PointActionType.earn,
          amount: earned,
          desc: '주문 $orderId 구매 적립 (1%)',
          orderId: orderId,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 365)),
        ).toDoc());
      });

      if (kDebugMode) {
        debugPrint('✅ 포인트 적립: $earned P (주문 $orderId, 유저 $userId)');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ earnFromOrder error: $e');
      // 포인트 적립 실패는 조용히 처리 (주문 자체에는 영향 없음)
    }
  }

  // ── 포인트 사용 (결제 시 차감) ─────────────────────────
  // minUse: 10,000P 이상부터 사용 가능
  static const int minUsePoints = 10000;

  /// 관리자가 고객에게 포인트를 직접 적립합니다.
  /// 잔액과 이력 기록을 하나의 트랜잭션으로 처리해 누락을 방지합니다.
  static Future<bool> adminCreditPoints({
    required String userId,
    required int amount,
    required String reason,
  }) async {
    if (amount <= 0 || reason.trim().isEmpty) return false;
    try {
      final userRef = _db.collection('users').doc(userId);
      final histRef = userRef.collection('point_history').doc();
      await _db.runTransaction((txn) async {
        final snap = await txn.get(userRef);
        if (!snap.exists) throw Exception('회원 정보를 찾을 수 없습니다.');
        final prev = (snap.data()?['points'] as num?)?.toInt() ?? 0;
        txn.update(userRef, {'points': prev + amount});
        txn.set(histRef, PointHistory(
          id: histRef.id,
          action: PointActionType.admin,
          amount: amount,
          desc: '관리자 적립: ${reason.trim()}',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 365)),
        ).toDoc());
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ adminCreditPoints error: $e');
      return false;
    }
  }

  static Future<bool> usePoints({
    required String userId,
    required String orderId,
    required int amount, // 차감할 포인트 (양수)
  }) async {
    if (amount <= 0) return true;
    if (amount < minUsePoints) {
      if (kDebugMode) debugPrint('⚠️ 포인트 최소 사용금액 미달: $amount < $minUsePoints');
      return false;
    }
    try {
      final userRef = _db.collection('users').doc(userId);
      final histRef = userRef.collection('point_history').doc();
      bool success = false;

      await _db.runTransaction((txn) async {
        final snap = await txn.get(userRef);
        final prev = (snap.data()?['points'] as num?)?.toInt() ?? 0;
        if (prev < amount) {
          // 잔액 부족 → 롤백
          throw Exception('포인트 잔액 부족: $prev < $amount');
        }
        txn.update(userRef, {'points': prev - amount});
        txn.set(histRef, PointHistory(
          id: histRef.id,
          action: PointActionType.use,
          amount: -amount,
          desc: '주문 $orderId 포인트 사용',
          orderId: orderId,
          createdAt: DateTime.now(),
        ).toDoc());
        success = true;
      });
      return success;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ usePoints error: $e');
      return false;
    }
  }

  /// 결제 실패·취소 시 선차감된 포인트를 1회 환급합니다.
  static Future<bool> refundPoints({
    required String userId,
    required String orderId,
    required int amount,
  }) async {
    if (amount <= 0) return true;
    try {
      final userRef = _db.collection('users').doc(userId);
      final refundRef = userRef.collection('point_history').doc('refund_$orderId');
      await _db.runTransaction((txn) async {
        final refundSnap = await txn.get(refundRef);
        if (refundSnap.exists) return;
        final userSnap = await txn.get(userRef);
        final prev = (userSnap.data()?['points'] as num?)?.toInt() ?? 0;
        txn.update(userRef, {'points': prev + amount});
        txn.set(refundRef, PointHistory(
          id: refundRef.id,
          action: PointActionType.admin,
          amount: amount,
          desc: '결제 실패 주문 $orderId 포인트 환급',
          orderId: orderId,
          createdAt: DateTime.now(),
        ).toDoc());
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ refundPoints error: $e');
      return false;
    }
  }

  /// 만료된 적립 포인트를 자동 소멸합니다.
  /// expire_{원본이력ID} 문서를 멱등 키로 사용해 반복 실행되어도 중복 차감하지 않습니다.
  static Future<int> expirePoints(String userId) async {
    final now = DateTime.now();
    try {
      final historySnap = await _db
          .collection('users').doc(userId).collection('point_history')
          .where('expiresAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .limit(100)
          .get();
      var expiredTotal = 0;
      for (final doc in historySnap.docs) {
        final source = PointHistory.fromDoc(doc.id, doc.data());
        if (source.amount <= 0 ||
            (source.action != PointActionType.earn &&
                source.action != PointActionType.admin)) continue;
        final expireRef = _db.collection('users').doc(userId)
            .collection('point_history').doc('expire_${doc.id}');
        await _db.runTransaction((txn) async {
          if ((await txn.get(expireRef)).exists) return;
          final userRef = _db.collection('users').doc(userId);
          final userSnap = await txn.get(userRef);
          final balance = (userSnap.data()?['points'] as num?)?.toInt() ?? 0;
          final amount = balance.clamp(0, source.amount).toInt();
          if (amount <= 0) return;
          txn.update(userRef, {'points': balance - amount});
          txn.set(expireRef, PointHistory(
            id: expireRef.id,
            action: PointActionType.expire,
            amount: -amount,
            desc: '${source.expiresAt!.year}.${source.expiresAt!.month}.${source.expiresAt!.day} 적립 포인트 기간 만료 소멸',
            orderId: source.orderId,
            createdAt: now,
          ).toDoc());
          expiredTotal += amount;
        });
      }
      return expiredTotal;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ expirePoints error: $e');
      return 0;
    }
  }

  // ── 포인트 잔액 실시간 스트림 ─────────────────────────
  static Stream<int> watchBalance(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snap) => (snap.data()?['points'] as num?)?.toInt() ?? 0)
        .handleError((e) {
      if (kDebugMode) debugPrint('watchBalance error: $e');
      return 0;
    });
  }
}
