// banner_service.dart — Firestore /banners 컬렉션 CRUD
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class BannerService {
  static final _col = FirebaseFirestore.instance.collection('banners');

  // ── 실시간 스트림 (active만, order 정렬) ──────────────────
  static Stream<List<BannerModel>> watchActiveBanners() {
    return _col
        .where('active', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BannerModel.fromFirestore(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ── 전체 스트림 (관리자용) ────────────────────────────────
  static Stream<List<BannerModel>> watchAllBanners() {
    return _col
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BannerModel.fromFirestore(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ── 단건 조회 ────────────────────────────────────────────
  static Future<BannerModel?> getBanner(String id) async {
    try {
      final doc = await _col.doc(id).get();
      if (!doc.exists) return null;
      return BannerModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      if (kDebugMode) debugPrint('BannerService.getBanner error: $e');
      return null;
    }
  }

  // ── 추가 ─────────────────────────────────────────────────
  static Future<String?> addBanner(BannerModel banner) async {
    try {
      final ref = await _col.add(banner.toFirestore());
      return ref.id;
    } catch (e) {
      if (kDebugMode) debugPrint('BannerService.addBanner error: $e');
      return null;
    }
  }

  // ── 수정 (부분 업데이트) ──────────────────────────────────
  static Future<bool> updateBanner(String id, Map<String, dynamic> fields) async {
    try {
      await _col.doc(id).update(fields);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('BannerService.updateBanner error: $e');
      return false;
    }
  }

  // ── 전체 교체 ─────────────────────────────────────────────
  static Future<bool> setBanner(BannerModel banner) async {
    try {
      await _col.doc(banner.id).set(banner.toFirestore());
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('BannerService.setBanner error: $e');
      return false;
    }
  }

  // ── 삭제 ─────────────────────────────────────────────────
  static Future<bool> deleteBanner(String id) async {
    try {
      await _col.doc(id).delete();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('BannerService.deleteBanner error: $e');
      return false;
    }
  }

  // ── 순서 일괄 업데이트 ────────────────────────────────────
  static Future<void> reorderBanners(List<BannerModel> banners) async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < banners.length; i++) {
      batch.update(_col.doc(banners[i].id), {'order': i});
    }
    await batch.commit();
  }

  // ── 초기 데이터 시드 (DB 비어있을 때 1회 실행) ───────────
  static Future<void> seedDefaultBanners() async {
    try {
      final snap = await _col.limit(1).get();
      if (snap.docs.isNotEmpty) return; // 이미 데이터 있음

      final defaults = [
        BannerModel(
          id: 'banner_1',
          order: 0,
          title: '2025 S/S 신상품',
          tag: 'NEW ARRIVALS',
          titleKo: '새로운 시즌이\n시작됩니다',
          titleEn: 'NEW SEASON\nSTARTS',
          ctaKo: '신상품 보러가기',
          ctaEn: 'VIEW NEW ARRIVALS',
          imageUrl: 'https://www.genspark.ai/api/files/s/0A333RJO?cache_control=3600',
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
          accentColor: 0xFFE53935,
          btnAction: 0,
        ),
        BannerModel(
          id: 'banner_2',
          order: 1,
          title: '베스트셀러',
          tag: 'BEST SELLER',
          titleKo: '가장 많이\n선택받은 2FIT',
          titleEn: 'MOST\nLOVED 2FIT',
          ctaKo: '베스트 상품 보기',
          ctaEn: 'SHOP BEST',
          imageUrl: 'https://www.genspark.ai/api/files/s/wc91nP9e?cache_control=3600',
          accentColor: 0xFFFF6B35,
          btnAction: 1,
        ),
        BannerModel(
          id: 'banner_3',
          order: 2,
          title: '단체주문 전문',
          tag: 'GROUP ORDER',
          titleKo: '팀 유니폼\n맞춤 제작 전문',
          titleEn: 'CUSTOM\nTEAM UNIFORM',
          ctaKo: '단체주문 알아보기',
          ctaEn: 'GROUP ORDER',
          imageUrl: 'https://www.genspark.ai/api/files/s/8ed64BLu?cache_control=3600',
          accentColor: 0xFF1565C0,
          btnAction: 2,
        ),
      ];

      final batch = FirebaseFirestore.instance.batch();
      for (final b in defaults) {
        batch.set(_col.doc(b.id), b.toFirestore());
      }
      await batch.commit();
      if (kDebugMode) debugPrint('BannerService: 기본 배너 3개 시드 완료');
    } catch (e) {
      if (kDebugMode) debugPrint('BannerService.seedDefaultBanners error: $e');
    }
  }
}
