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
    '상의': ['NEW 싱글렛 A타입', 'NEW 싱글렛 B타입', 'Standard 싱글렛 A타입', 'Standard 싱글렛 B타입', '크롭탑', '라운드티', '카라티', '롱 슬리브', '맨투맨', '후드집업', '트레이닝 집업'],
    '하의': ['NEW 싱글렛 A타입', 'NEW 싱글렛 B타입', '타이즈', '트레이닝바지', '반바지'],
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
      if (!snap.exists) {
        // 최초 실행: 기본값 저장
        await _saveToFirestore(
          List<String>.from(defaultMainCategories),
          Map<String, List<String>>.from(defaultSubCatMap.map(
            (k, v) => MapEntry(k, List<String>.from(v)),
          )),
        );
        _cachedMainCats = List<String>.from(defaultMainCategories);
        _cachedSubCatMap = Map<String, List<String>>.from(defaultSubCatMap.map(
          (k, v) => MapEntry(k, List<String>.from(v)),
        ));
        return;
      }
      final data = snap.data() as Map<String, dynamic>;
      _cachedMainCats = List<String>.from(data['mainCategories'] as List? ?? defaultMainCategories);
      final rawSub = data['subCatMap'] as Map<String, dynamic>? ?? {};
      _cachedSubCatMap = {};

      // 기본값 먼저 채우기 (최신 defaultSubCatMap 기준)
      for (final e in defaultSubCatMap.entries) {
        _cachedSubCatMap![e.key] = List<String>.from(e.value);
      }
      // Firestore 값으로 병합: 기본값에 없는 커스텀 항목만 추가 (기본값 순서 우선)
      for (final e in rawSub.entries) {
        final defaultList = defaultSubCatMap[e.key] ?? [];
        final firestoreList = List<String>.from(e.value as List);
        // 기본값에 없는 추가 항목만 뒤에 병합
        final extras = firestoreList.where((s) => !defaultList.contains(s)).toList();
        if (extras.isNotEmpty) {
          _cachedSubCatMap![e.key] = [...defaultList, ...extras];
        }
        // 기본값에 있는 항목만 있으면 기본값 그대로 유지
      }
      // Firestore와 기본값이 다를 경우 Firestore도 갱신
      await _saveToFirestore(
        List<String>.from(_cachedMainCats!),
        Map<String, List<String>>.from(_cachedSubCatMap!),
      );
    } catch (e) {
      debugPrint('⚠️ CategoryService.load 실패: $e');
      _cachedMainCats = List<String>.from(defaultMainCategories);
      _cachedSubCatMap = Map<String, List<String>>.from(defaultSubCatMap.map(
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
    final cats = List<String>.from(mainCategories);
    if (cats.contains(name)) return;
    cats.add(name);
    final subs = Map<String, List<String>>.from(subCatMap);
    subs[name] = [name]; // 기본 하위카테고리: 메인과 동일한 이름
    await _saveToFirestore(cats, subs);
    _cachedMainCats = cats;
    _cachedSubCatMap = subs;
  }

  // ── 메인 카테고리 삭제 ─────────────────────────────────────
  static Future<void> removeMainCategory(String name) async {
    final cats = List<String>.from(mainCategories)..remove(name);
    final subs = Map<String, List<String>>.from(subCatMap)..remove(name);
    await _saveToFirestore(cats, subs);
    _cachedMainCats = cats;
    _cachedSubCatMap = subs;
  }

  // ── 하위 카테고리 추가 ─────────────────────────────────────
  static Future<void> addSubCategory(String mainCat, String subName) async {
    final subs = Map<String, List<String>>.from(subCatMap);
    final list = List<String>.from(subs[mainCat] ?? []);
    if (list.contains(subName)) return;
    list.add(subName);
    subs[mainCat] = list;
    await _saveToFirestore(List<String>.from(mainCategories), subs);
    _cachedSubCatMap = subs;
  }

  // ── 하위 카테고리 삭제 ─────────────────────────────────────
  static Future<void> removeSubCategory(String mainCat, String subName) async {
    final subs = Map<String, List<String>>.from(subCatMap);
    final list = List<String>.from(subs[mainCat] ?? [])..remove(subName);
    subs[mainCat] = list;
    await _saveToFirestore(List<String>.from(mainCategories), subs);
    _cachedSubCatMap = subs;
  }

  // ── 하위 카테고리 순서 변경 ────────────────────────────────
  static Future<void> reorderSubCategories(String mainCat, List<String> newOrder) async {
    final subs = Map<String, List<String>>.from(subCatMap);
    subs[mainCat] = newOrder;
    await _saveToFirestore(List<String>.from(mainCategories), subs);
    _cachedSubCatMap = subs;
  }

  // ── 메인 카테고리 순서 변경 ────────────────────────────────
  static Future<void> reorderMainCategories(List<String> newOrder) async {
    await _saveToFirestore(newOrder, Map<String, List<String>>.from(subCatMap));
    _cachedMainCats = newOrder;
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
