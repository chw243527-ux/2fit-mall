// wishlist_coupon_service.dart - 찜목록 및 쿠폰 서비스
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class WishlistService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<String>> getWishlist(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return [];
      final data = doc.data()!;
      return List<String>.from(data['wishlist'] ?? []);
    } catch (e) {
      if (kDebugMode) debugPrint('getWishlist error: $e');
      return [];
    }
  }

  static Future<void> toggleWishlist(String userId, String productId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return;
      final wishlist = List<String>.from(doc.data()!['wishlist'] ?? []);
      if (wishlist.contains(productId)) {
        wishlist.remove(productId);
      } else {
        wishlist.add(productId);
      }
      await _db.collection('users').doc(userId).update({'wishlist': wishlist});
    } catch (e) {
      if (kDebugMode) debugPrint('toggleWishlist error: $e');
    }
  }

  static Future<void> syncWishlist(String userId, List<String> wishlist) async {
    try {
      await _db.collection('users').doc(userId).update({'wishlist': wishlist});
    } catch (e) {
      if (kDebugMode) debugPrint('syncWishlist error: $e');
    }
  }
}

class CouponService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<CouponModel>> getUserCoupons(String userId) async {
    try {
      final snap = await _db
          .collection('coupons')
          .where('userId', isEqualTo: userId)
          .get();
      return snap.docs.map((d) => _parseCoupon(d.id, d.data())).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getUserCoupons error: $e');
      return [];
    }
  }

  static Future<CouponModel?> validateCoupon(String code, String userId) async {
    try {
      final snap = await _db
          .collection('coupons')
          .where('code', isEqualTo: code.toUpperCase())
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final coupon = _parseCoupon(doc.id, doc.data());
      if (!coupon.isValid) return null;
      return coupon;
    } catch (e) {
      if (kDebugMode) debugPrint('validateCoupon error: $e');
      return null;
    }
  }

  static Stream<List<CouponModel>> watchMyCoupons(String userId) {
    return _db
        .collection('coupons')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _parseCoupon(d.id, d.data()))
            .toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('watchMyCoupons error: $e');
      return <CouponModel>[];
    });
  }

  static Future<String> registerCoupon(String userId, String code) async {
    try {
      // admin_coupons에서 코드 확인
      final snap = await _db
          .collection('admin_coupons')
          .where('code', isEqualTo: code.toUpperCase())
          .get();
      if (snap.docs.isEmpty) return '유효하지 않은 쿠폰 코드입니다.';
      final couponData = snap.docs.first.data();
      final coupon = _parseCoupon(snap.docs.first.id, couponData);
      if (!coupon.isValid) return '만료된 쿠폰입니다.';
      // 이미 등록했는지 확인
      final existing = await _db
          .collection('coupons')
          .where('userId', isEqualTo: userId)
          .where('code', isEqualTo: code.toUpperCase())
          .get();
      if (existing.docs.isNotEmpty) return '이미 등록된 쿠폰입니다.';
      // 사용자 쿠폰으로 복사
      final ref = _db.collection('coupons').doc();
      await ref.set({...couponData, 'id': ref.id, 'userId': userId, 'isUsed': false});
      return '쿠폰이 등록되었습니다.';
    } catch (e) {
      if (kDebugMode) debugPrint('registerCoupon error: $e');
      return '쿠폰 등록 중 오류가 발생했습니다.';
    }
  }

  static Future<void> useCoupon(String userId, String couponId) async {
    try {
      await _db.collection('coupons').doc(couponId).update({'isUsed': true});
    } catch (e) {
      if (kDebugMode) debugPrint('useCoupon error: $e');
    }
  }


  static Future<List<CouponModel>> getAdminCoupons() async {
    try {
      final snap = await _db.collection('admin_coupons').get();
      return snap.docs.map((d) => _parseCoupon(d.id, d.data())).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getAdminCoupons error: $e');
      return [];
    }
  }

  static Future<void> createCoupon({
    required String code,
    required String name,
    required CouponType type,
    required double value,
    required double minOrderAmount,
    double? maxDiscountAmount,
    required DateTime expiresAt,
  }) async {
    try {
      final ref = _db.collection('admin_coupons').doc();
      await ref.set({
        'id': ref.id,
        'code': code.toUpperCase(),
        'name': name,
        'type': type == CouponType.fixed ? 'fixed' : 'percent',
        'value': value,
        'minOrderAmount': minOrderAmount,
        'maxDiscountAmount': maxDiscountAmount,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isUsed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('createCoupon error: $e');
    }
  }

  static CouponModel _parseCoupon(String id, Map<String, dynamic> data) {
    final typeStr = data['type'] as String? ?? 'fixed';
    return CouponModel(
      id: id,
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: typeStr == 'percent' ? CouponType.percent : CouponType.fixed,
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (data['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: data['maxDiscountAmount'] != null
          ? (data['maxDiscountAmount'] as num).toDouble()
          : null,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      isUsed: data['isUsed'] as bool? ?? false,
    );
  }
}
