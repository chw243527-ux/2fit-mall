// privacy_service.dart — 개인정보 보호 서비스
// 개인정보 마스킹, 데이터 보호, 접근 제어 기능 제공

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyService {
  static final _db = FirebaseFirestore.instance;

  // ────────────────────────────────────────────────
  // 개인정보 마스킹 유틸리티
  // ────────────────────────────────────────────────

  /// 전화번호 마스킹: 010-1234-5678 → 010-****-5678
  static String maskPhone(String phone) {
    if (phone.isEmpty) return phone;
    final clean = phone.replaceAll('-', '').replaceAll(' ', '');
    if (clean.length < 8) return phone;
    // 국내 번호 형식 처리
    if (phone.contains('-')) {
      final parts = phone.split('-');
      if (parts.length == 3) {
        return '${parts[0]}-****-${parts[2]}';
      }
    }
    // 숫자만 있는 경우
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}-****-${clean.substring(7)}';
    }
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }

  /// 이메일 마스킹: test@example.com → te***@example.com
  static String maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;
    final parts = email.split('@');
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) {
      return '${local[0]}***@$domain';
    }
    return '${local.substring(0, 2)}***@$domain';
  }

  /// 이름 마스킹: 홍길동 → 홍*동, Hong GilDong → H***g
  static String maskName(String name) {
    if (name.isEmpty) return name;
    if (name.length <= 1) return '*';
    if (name.length == 2) return '${name[0]}*';
    if (name.length == 3) return '${name[0]}*${name[2]}';
    // 영문 이름
    if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}';
    }
    // 한글 이름 (4자 이상)
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}';
  }

  /// 주소 마스킹: 서울시 강남구 역삼동 123-45 → 서울시 강남구 **** ***-**
  static String maskAddress(String address) {
    if (address.isEmpty) return address;
    // 구/군 단위까지만 표시
    final parts = address.split(' ');
    if (parts.length > 3) {
      return '${parts.take(3).join(' ')} ****';
    }
    if (parts.length > 2) {
      return '${parts.take(2).join(' ')} ****';
    }
    return '${address.substring(0, address.length ~/ 2)}****';
  }

  /// 카드번호 마스킹: 1234-5678-9012-3456 → 1234-****-****-3456
  static String maskCardNumber(String card) {
    if (card.isEmpty) return card;
    final clean = card.replaceAll('-', '').replaceAll(' ', '');
    if (clean.length < 8) return card;
    return '${clean.substring(0, 4)}-****-****-${clean.substring(clean.length - 4)}';
  }

  // ────────────────────────────────────────────────
  // 관리자 화면용 마스킹 (일부 표시)
  // ────────────────────────────────────────────────

  /// 관리자용 전화번호: 010-1234-5678 (마스킹 없음)
  static String adminPhone(String phone) => phone;

  /// 관리자용 이메일 (마스킹 없음)
  static String adminEmail(String email) => email;

  // ────────────────────────────────────────────────
  // 데이터 보존 기간 관리
  // ────────────────────────────────────────────────

  /// 개인정보 보존 기간 초과 데이터 정리 (3년)
  static Future<int> cleanupExpiredPersonalData() async {
    const retentionDays = 3 * 365; // 3년
    final cutoff = DateTime.now().subtract(const Duration(days: retentionDays));

    int cleaned = 0;
    try {
      // 취소된 주문 중 보존기간 초과 데이터 익명화
      final oldOrders = await _db
          .collection('orders')
          .where('status', isEqualTo: 'cancelled')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      final batch = _db.batch();
      for (final doc in oldOrders.docs) {
        batch.update(doc.reference, {
          'userPhone': '***-****-****',
          'userEmail': '***@***.***',
          'userAddress': '(삭제됨)',
          'personalDataDeleted': true,
          'personalDataDeletedAt': FieldValue.serverTimestamp(),
        });
        cleaned++;
      }
      if (cleaned > 0) await batch.commit();

      if (kDebugMode) debugPrint('✅ 개인정보 정리: ${cleaned}건');
    } catch (e) {
      if (kDebugMode) debugPrint('개인정보 정리 오류: $e');
    }
    return cleaned;
  }

  // ────────────────────────────────────────────────
  // 개인정보 열람/삭제 요청 처리
  // ────────────────────────────────────────────────

  /// 사용자 개인정보 열람 요청 기록
  static Future<void> logDataAccessRequest({
    required String userId,
    required String requestType, // 'view', 'delete', 'export'
    String? reason,
  }) async {
    try {
      await _db.collection('privacy_requests').add({
        'userId': userId,
        'requestType': requestType,
        'reason': reason ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('개인정보 요청 기록 실패: $e');
    }
  }

  /// 사용자 데이터 완전 삭제 (탈퇴 처리)
  static Future<bool> deleteUserData(String userId) async {
    try {
      // 사용자 정보 익명화
      await _db.collection('users').doc(userId).update({
        'name': '탈퇴회원',
        'email': 'deleted_$userId@deleted.com',
        'phone': '',
        'address': '',
        'profileImage': '',
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // 해당 사용자의 주문에서 개인정보 익명화
      final orders = await _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      if (orders.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in orders.docs) {
          batch.update(doc.reference, {
            'userName': '탈퇴회원',
            'userEmail': 'deleted@deleted.com',
            'userPhone': '***-****-****',
            'userAddress': '(탈퇴)',
          });
        }
        await batch.commit();
      }

      // 리뷰 익명화
      final reviews = await _db
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();
      if (reviews.docs.isNotEmpty) {
        final rBatch = _db.batch();
        for (final doc in reviews.docs) {
          rBatch.update(doc.reference, {'userName': '탈퇴회원', 'userEmail': ''});
        }
        await rBatch.commit();
      }

      if (kDebugMode) debugPrint('✅ 사용자 데이터 삭제: $userId');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('사용자 데이터 삭제 오류: $e');
      return false;
    }
  }

  // ────────────────────────────────────────────────
  // 접근 로그 기록
  // ────────────────────────────────────────────────

  /// 민감 데이터 접근 로그
  static Future<void> logSensitiveAccess({
    required String adminId,
    required String action,
    required String targetType, // 'order', 'user', 'review'
    String? targetId,
  }) async {
    try {
      await _db.collection('access_logs').add({
        'adminId': adminId,
        'action': action,
        'targetType': targetType,
        'targetId': targetId ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'ipInfo': 'web',
      });
    } catch (_) {} // 로그 실패는 무시
  }

  // ────────────────────────────────────────────────
  // GDPR/개인정보보호법 준수 체크
  // ────────────────────────────────────────────────

  /// 개인정보 수집 동의 여부 확인
  static Future<bool> checkConsent(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['privacyConsent'] == true;
    } catch (e) {
      return false;
    }
  }

  /// 개인정보 수집 동의 기록
  static Future<void> recordConsent({
    required String userId,
    required bool agreed,
    required String version, // 약관 버전
  }) async {
    try {
      await _db.collection('users').doc(userId).update({
        'privacyConsent': agreed,
        'privacyConsentVersion': version,
        'privacyConsentAt': FieldValue.serverTimestamp(),
      });
      // 동의 이력 기록
      await _db.collection('consent_history').add({
        'userId': userId,
        'agreed': agreed,
        'version': version,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('동의 기록 실패: $e');
    }
  }
}
