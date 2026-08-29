// wishlist_coupon_service.dart - 찜목록 & 쿠폰 서비스
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'secure_checkout_service.dart';

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

// ── 쿠폰 서비스 ─────────────────────────────────────────
class CouponService {
  static final _db = FirebaseFirestore.instance;

  // ─── 관리자용 ───────────────────────────────────────

  /// admin_coupons 컬렉션 실시간 스트림 (관리자 대시보드용)
  static Stream<List<CouponModel>> watchAdminCoupons() {
    return _db
        .collection('admin_coupons')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _parse(d.id, d.data())).toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('watchAdminCoupons error: $e');
      return <CouponModel>[];
    });
  }

  /// 쿠폰 생성
  static Future<String> createCoupon({
    required String code,
    required String name,
    required CouponType type,
    required double value,
    double minOrderAmount = 0,
    double? maxDiscountAmount,
    DateTime? startsAt,
    required DateTime expiresAt,
    bool isDownloadable = true,
    int? downloadLimit,
  }) async {
    try {
      // 코드 중복 체크
      final dup = await _db
          .collection('admin_coupons')
          .where('code', isEqualTo: code.toUpperCase().trim())
          .get();
      if (dup.docs.isNotEmpty) return '이미 존재하는 쿠폰 코드입니다.';

      final ref = _db.collection('admin_coupons').doc();
      await ref.set({
        'id': ref.id,
        'code': code.toUpperCase().trim(),
        'name': name.trim(),
        'type': type == CouponType.fixed ? 'fixed' : 'percent',
        'value': value,
        'minOrderAmount': minOrderAmount,
        if (maxDiscountAmount != null) 'maxDiscountAmount': maxDiscountAmount,
        if (startsAt != null) 'startsAt': Timestamp.fromDate(startsAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isUsed': false,
        'isDownloadable': isDownloadable,
        if (downloadLimit != null) 'downloadLimit': downloadLimit,
        'downloadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return '';
    } catch (e) {
      if (kDebugMode) debugPrint('createCoupon error: $e');
      return '쿠폰 생성 중 오류가 발생했습니다.';
    }
  }

  /// 쿠폰 수정
  static Future<String> updateCoupon({
    required String couponId,
    required String name,
    required CouponType type,
    required double value,
    double minOrderAmount = 0,
    double? maxDiscountAmount,
    DateTime? startsAt,
    required DateTime expiresAt,
    bool isDownloadable = false,
    int? downloadLimit,
  }) async {
    try {
      await _db.collection('admin_coupons').doc(couponId).update({
        'name': name.trim(),
        'type': type == CouponType.fixed ? 'fixed' : 'percent',
        'value': value,
        'minOrderAmount': minOrderAmount,
        // null이면 FieldValue.delete()로 필드 완전 제거 (null 값 저장 방지)
        'maxDiscountAmount': maxDiscountAmount ?? FieldValue.delete(),
        'startsAt': startsAt != null
            ? Timestamp.fromDate(startsAt)
            : FieldValue.delete(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isDownloadable': isDownloadable,
        'downloadLimit': downloadLimit ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return '';
    } catch (e) {
      if (kDebugMode) debugPrint('updateCoupon error: $e');
      return '쿠폰 수정 중 오류가 발생했습니다: $e';
    }
  }

  /// 쿠폰 삭제
  static Future<String> deleteCoupon(String couponId) async {
    try {
      await _db.collection('admin_coupons').doc(couponId).delete();
      return '';
    } catch (e) {
      if (kDebugMode) debugPrint('deleteCoupon error: $e');
      return '쿠폰 삭제 중 오류가 발생했습니다.';
    }
  }

  // ─── 사용자용 ───────────────────────────────────────

  /// 코드로 쿠폰 검증 (checkout에서 직접 코드 입력 시)
  static Future<CouponModel?> validateCode(String code) async {
    try {
      final snap = await _db
          .collection('admin_coupons')
          .where('code', isEqualTo: code.toUpperCase().trim())
          .get();
      if (snap.docs.isEmpty) return null;
      final coupon = _parse(snap.docs.first.id, snap.docs.first.data());
      return coupon.isValid ? coupon : null;
    } catch (e) {
      if (kDebugMode) debugPrint('validateCode error: $e');
      return null;
    }
  }

  /// 전체 유효 쿠폰 실시간 스트림 (checkout에서 보유 쿠폰 목록 표시)
  static Stream<List<CouponModel>> watchValidCoupons() {
    return _db.collection('admin_coupons').snapshots().map((snap) => snap.docs
        .map((d) => _parse(d.id, d.data()))
        .where((c) => c.isValid)
        .toList());
  }

  /// 다운로드 가능한 공개 쿠폰 스트림 (홈 팝업용)
  static Stream<List<CouponModel>> watchDownloadableCoupons() {
    return _db
        .collection('admin_coupons')
        .where('isDownloadable', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _parse(d.id, d.data()))
            .where((c) => c.canDownload)
            .toList())
        .handleError((e) {
      if (kDebugMode) debugPrint('watchDownloadableCoupons error: $e');
      return <CouponModel>[];
    });
  }

  /// 사용자가 이미 다운로드한 쿠폰 ID 목록
  static Future<Set<String>> getDownloadedCouponIds(String userId) async {
    try {
      final snap = await _db
          .collection('user_coupons')
          .doc(userId)
          .collection('coupons')
          .get();
      return snap.docs.map((d) => d.id).toSet();
    } catch (e) {
      if (kDebugMode) debugPrint('getDownloadedCouponIds error: $e');
      return {};
    }
  }

  /// 사용자가 직접 다운로드해 보유한 쿠폰 스트림 (마이페이지·결제용)
  static Stream<List<CouponModel>> watchUserCoupons(String userId) {
    return _db
        .collection('user_coupons')
        .doc(userId)
        .collection('coupons')
        .snapshots()
        .map((snap) {
      final coupons = snap.docs
          .map((doc) => _parse(doc.id, doc.data()))
          .where((coupon) => coupon.isValid && !coupon.isUsed)
          .toList();
      coupons.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
      return coupons;
    }).handleError((e) {
      if (kDebugMode) debugPrint('watchUserCoupons error: $e');
      return <CouponModel>[];
    });
  }

  /// 사용자 쿠폰 다운로드는 서버가 공개 여부·다운로드 수·중복을 검증해 발급합니다.
  static Future<String> downloadCoupon({
    required String userId,
    required CouponModel coupon,
  }) async {
    final result = await SecureCheckoutService.downloadCoupon(coupon.id);
    if (result.isEmpty ||
        result == 'already_downloaded' ||
        result == 'limit_exceeded' ||
        result == 'not_downloadable' ||
        result == 'expired') {
      return result;
    }
    if (kDebugMode) debugPrint('downloadCoupon secure request failed: $result');
    return '다운로드 중 오류가 발생했습니다.';
  }

  /// 결제 성공 후 고객 보유 쿠폰을 사용 처리합니다.
  /// 이미 사용 처리된 쿠폰은 중복 결제에서도 멱등적으로 성공 처리합니다.
  static Future<bool> markUserCouponUsed({
    required String userId,
    required String couponId,
    required String orderId,
  }) async {
    try {
      final ref = _db
          .collection('user_coupons')
          .doc(userId)
          .collection('coupons')
          .doc(couponId);
      final result = await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data() ?? <String, dynamic>{};
        if (data['isUsed'] == true) return true;
        tx.update(ref, {
          'isUsed': true,
          'usedOrderId': orderId,
          'usedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('markUserCouponUsed error: $e');
      return false;
    }
  }

  // ─── 파싱 ───────────────────────────────────────────
  static CouponModel _parse(String id, Map<String, dynamic> data) {
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
      startsAt: (data['startsAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      isUsed: data['isUsed'] as bool? ?? false,
      isDownloadable: data['isDownloadable'] as bool? ?? false,
      downloadLimit: data['downloadLimit'] as int?,
      downloadCount: (data['downloadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
