// category_service.dart — Firestore 기반 카테고리 관리 서비스
// app_settings/categories 문서에 메인·하위 카테고리를 저장/로드

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CategoryService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static DocumentReference get _doc =>
      _db.collection('app_settings').doc('categories');

  // ── 기본(내장) 카테고리 ─────────────────────────────────────
  static const List<String> defaultMainCategories = [
    '상의', '하의', '세트', '아우터', '스킨슈트', '악세사리', '이벤트', '단체주문',
  ];

  static const Map<String, List<String>> defaultSubCatMap = {
    '상의': [
      'NEW 심리스 싱글렛 A',
      'NEW 심리스 싱글렛 B',
      'NEW 여성 크롭 싱글렛 A',
      'NEW 여성 크롭 싱글렛 B',
      'Standard 심리스 싱글렛 A',
      'Standard 심리스 싱글렛 B',
      'Standard 여성 크롭 싱글렛 A',
      'Standard 여성 크롭 싱글렛 B',
      '크롭탑', '라운드티', '카라티', '롱 슬리브', '맨투맨', '후드집업', '트레이닝 집업',
    ],
    '하의': [
      '타이즈', '남성 5부', '여성 2.5부', '숏츠', '트레이닝바지',
    ],
    '세트': ['싱글렛세트A타입', '트레이닝복세트'],
    '아우터': ['바람막이', '다운패딩', '다운조끼패딩', '롱패딩'],
    '스킨슈트': ['스킨슈트'],
    '악세사리': ['모자', '백팩'],
    '이벤트': ['이벤트'],
    '단체주문': ['싱글렛세트A타입', '싱글렛 B타입', '스킨슈트', '트레이닝복세트', '기타'],
  };

  // ── 인메모리 캐시 ───────────────────────────────────────────
  static List<String>? _cachedMainCats;
  static Map<String, List<String>>? _cachedSubCatMap;

  // ── Firestore에서 로드 ──────────────────────────────────────
  static Future<void> load() async {
    try {
      final snap = await _doc.get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        // Firestore에 저장된 값 우선 사용
        final rawMain = data['mainCategories'];
        final rawSubs = data['subCatMap'];
        if (rawMain != null) {
          _cachedMainCats = List<String>.from(rawMain as List);
        }
        if (rawSubs != null) {
          final subMap = rawSubs as Map<String, dynamic>;
          _cachedSubCatMap = subMap.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          );
        }
        // 기본 카테고리 중 Firestore에 없는 항목은 추가하지 않음 (관리자가 삭제한 것 존중)
      } else {
        // 문서 없으면 기본값으로 초기화 후 저장 (최초 1회)
        final cats = List<String>.from(defaultMainCategories);
        final subs = Map<String, List<String>>.from(defaultSubCatMap.map(
          (k, v) => MapEntry(k, List<String>.from(v)),
        ));
        await _saveToFirestore(cats, subs);
        _cachedMainCats = cats;
        _cachedSubCatMap = subs;
      }
    } catch (e) {
      debugPrint('⚠️ CategoryService.load 실패: $e');
      _cachedMainCats ??= List<String>.from(defaultMainCategories);
      _cachedSubCatMap ??= Map<String, List<String>>.from(defaultSubCatMap.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ));
    }
  }

  // ── 기본값으로 강제 초기화 (카테고리 리셋) ─────────────────
  static Future<void> resetToDefaults() async {
    final cats = List<String>.from(defaultMainCategories);
    final subs = Map<String, List<String>>.from(defaultSubCatMap.map(
      (k, v) => MapEntry(k, List<String>.from(v)),
    ));
    await _saveToFirestore(cats, subs);
    _cachedMainCats = cats;
    _cachedSubCatMap = subs;
  }

  // ── getter (캐시 우선, 없으면 기본값) ───────────────────────
  static List<String> get mainCategories =>
      _cachedMainCats ?? List<String>.from(defaultMainCategories);

  static Map<String, List<String>> get subCatMap =>
      _cachedSubCatMap ?? Map<String, List<String>>.from(defaultSubCatMap.map(
        (k, v) => MapEntry(k, List<String>.from(v)),
      ));

  static List<String> subCatsFor(String mainCat) =>
      subCatMap[mainCat] ?? [];

  // ── 메인 카테고리 추가 ─────────────────────────────────────
  static Future<void> addMainCategory(String name) async {
    final prevCats = _cachedMainCats;
    final prevSubs = _cachedSubCatMap;
    final cats = List<String>.from(mainCategories);
    if (cats.contains(name)) return;
    cats.add(name);
    final subs = Map<String, List<String>>.from(subCatMap);
    subs[name] = [name]; // 기본 하위카테고리: 메인과 동일한 이름
    // 캐시 선반영 후 저장 시도 (실패 시 롤백)
    _cachedMainCats = cats;
    _cachedSubCatMap = subs;
    try {
      await _saveToFirestore(cats, subs);
    } catch (e) {
      // Firestore 저장 실패 → 캐시 롤백
      _cachedMainCats = prevCats;
      _cachedSubCatMap = prevSubs;
      debugPrint('❌ CategoryService.addMainCategory 실패: $e');
      rethrow;
    }
  }

  // ── 메인 카테고리 삭제 ─────────────────────────────────────
  static Future<void> removeMainCategory(String name) async {
    final prevCats = _cachedMainCats;
    final prevSubs = _cachedSubCatMap;
    final cats = List<String>.from(mainCategories)..remove(name);
    final subs = Map<String, List<String>>.from(subCatMap)..remove(name);
    _cachedMainCats = cats;
    _cachedSubCatMap = subs;
    try {
      await _saveToFirestore(cats, subs);
    } catch (e) {
      _cachedMainCats = prevCats;
      _cachedSubCatMap = prevSubs;
      debugPrint('❌ CategoryService.removeMainCategory 실패: $e');
      rethrow;
    }
  }

  // ── 하위 카테고리 추가 ─────────────────────────────────────
  static Future<void> addSubCategory(String mainCat, String subName) async {
    final prevSubs = _cachedSubCatMap;
    final subs = Map<String, List<String>>.from(subCatMap);
    final list = List<String>.from(subs[mainCat] ?? []);
    if (list.contains(subName)) return;
    list.add(subName);
    subs[mainCat] = list;
    _cachedSubCatMap = subs;
    try {
      await _saveToFirestore(List<String>.from(mainCategories), subs);
    } catch (e) {
      _cachedSubCatMap = prevSubs;
      debugPrint('❌ CategoryService.addSubCategory 실패: $e');
      rethrow;
    }
  }

  // ── 하위 카테고리 삭제 ─────────────────────────────────────
  static Future<void> removeSubCategory(String mainCat, String subName) async {
    final prevSubs = _cachedSubCatMap;
    final subs = Map<String, List<String>>.from(subCatMap);
    final list = List<String>.from(subs[mainCat] ?? [])..remove(subName);
    subs[mainCat] = list;
    _cachedSubCatMap = subs;
    try {
      await _saveToFirestore(List<String>.from(mainCategories), subs);
    } catch (e) {
      _cachedSubCatMap = prevSubs;
      debugPrint('❌ CategoryService.removeSubCategory 실패: $e');
      rethrow;
    }
  }

  // ── 하위 카테고리 순서 변경 ────────────────────────────────
  static Future<void> reorderSubCategories(String mainCat, List<String> newOrder) async {
    final prevSubs = _cachedSubCatMap;
    final subs = Map<String, List<String>>.from(subCatMap);
    subs[mainCat] = newOrder;
    _cachedSubCatMap = subs;
    try {
      await _saveToFirestore(List<String>.from(mainCategories), subs);
    } catch (e) {
      _cachedSubCatMap = prevSubs;
      debugPrint('❌ CategoryService.reorderSubCategories 실패: $e');
      rethrow;
    }
  }

  // ── 메인 카테고리 순서 변경 ────────────────────────────────
  static Future<void> reorderMainCategories(List<String> newOrder) async {
    final prevCats = _cachedMainCats;
    _cachedMainCats = newOrder;
    try {
      await _saveToFirestore(newOrder, Map<String, List<String>>.from(subCatMap));
    } catch (e) {
      _cachedMainCats = prevCats;
      debugPrint('❌ CategoryService.reorderMainCategories 실패: $e');
      rethrow;
    }
  }

  // ── Firestore 저장 (내부) ──────────────────────────────────
  static Future<void> _saveToFirestore(
    List<String> cats,
    Map<String, List<String>> subs,
  ) async {
    await _doc.set({
      'mainCategories': cats,
      'subCatMap': subs,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── 캐시 초기화 (강제 리로드용) ───────────────────────────
  static void clearCache() {
    _cachedMainCats = null;
    _cachedSubCatMap = null;
  }
}
