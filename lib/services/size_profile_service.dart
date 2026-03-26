import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// Firestore 컬렉션: size_profiles/{userId}/profiles/{docId}
class SizeProfileService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('size_profiles').doc(userId).collection('profiles');

  // ── 프로필 목록 조회 ────────────────────────────────────
  static Future<List<SizeProfile>> getProfiles(String userId) async {
    final snap = await _col(userId).get();
    final list = snap.docs
        .map((d) => SizeProfile.fromJson(d.id, d.data()))
        .toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  // ── 실시간 스트림 ────────────────────────────────────────
  static Stream<List<SizeProfile>> watchProfiles(String userId) {
    return _col(userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => SizeProfile.fromJson(d.id, d.data()))
              .toList();
          // 메모리 정렬 (index 불필요)
          list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return list;
        });
  }

  // ── 저장 (신규 or 업데이트) ──────────────────────────────
  static Future<SizeProfile> saveProfile(
      String userId, SizeProfile profile) async {
    final data = profile.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (profile.id.isEmpty) {
      // 신규 생성
      final ref = await _col(userId).add(data);
      return SizeProfile.fromJson(ref.id, profile.toJson()
        ..['updatedAt'] = DateTime.now().toIso8601String());
    } else {
      // 업데이트
      await _col(userId).doc(profile.id).set(data, SetOptions(merge: true));
      return profile;
    }
  }

  // ── 삭제 ────────────────────────────────────────────────
  static Future<void> deleteProfile(String userId, String profileId) async {
    await _col(userId).doc(profileId).delete();
  }

  // ── 최대 저장 개수 제한 (10개) ──────────────────────────
  static const int maxProfiles = 10;
}
