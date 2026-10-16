// category_service.dart — Firestore 기반 3단계 카테고리 관리 서비스
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CategoryService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static DocumentReference get _doc =>
      _db.collection('app_settings').doc('categories');

  static const defaultMainCategories = [
    '상의',
    '하의',
    '세트',
    '아우터',
    '스킨슈트',
    '악세사리',
    '이벤트',
    '단체주문',
  ];
  static const defaultMiddleCategories = ['일반', '기성품', '단체주문'];
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
      '크롭탑',
      '라운드티',
      '카라티',
      '롱 슬리브',
      '맨투맨',
      '후드집업',
      '트레이닝 집업'
    ],
    '하의': ['타이즈', '남성 5부', '여성 2.5부', '숏츠', '트레이닝바지'],
    '세트': ['싱글렛세트A타입', '트레이닝복세트'],
    '아우터': ['바람막이', '다운패딩', '다운조끼패딩', '롱패딩'],
    '스킨슈트': ['스킨슈트'],
    '악세사리': ['모자', '백팩'],
    '이벤트': ['이벤트'],
    '단체주문': ['싱글렛세트A타입', '싱글렛 B타입', '스킨슈트', '트레이닝복세트', '기타'],
  };

  static List<String>? _cachedMainCats;
  static Map<String, List<String>>? _cachedMiddleCatMap;
  static Map<String, List<String>>? _cachedSubCatMap;
  static String _key(String main, String middle) => '$main::$middle';
  static Map<String, List<String>> _copy(Map<String, List<String>> source) => {
        for (final e in source.entries) e.key: List<String>.from(e.value),
      };
  static Map<String, List<String>> _defaultMiddles() => {
        for (final main in defaultMainCategories)
          main: List<String>.from(defaultMiddleCategories),
      };
  static Map<String, List<String>> _defaultSubs() => {
        // 기본 하위 카테고리는 일반 중위 카테고리에만 둡니다.
        // 기성품·단체주문은 관리자가 필요에 따라 별도로 등록합니다.
        for (final main in defaultMainCategories)
          _key(main, '일반'):
              List<String>.from(defaultSubCatMap[main] ?? const []),
      };

  static Future<void> load() async {
    try {
      final snap = await _doc.get();
      if (!snap.exists) {
        final mains = List<String>.from(defaultMainCategories);
        final middles = _defaultMiddles();
        final subs = _defaultSubs();
        await _save(mains, middles, subs);
        _cachedMainCats = mains;
        _cachedMiddleCatMap = middles;
        _cachedSubCatMap = subs;
        return;
      }
      final data = snap.data() as Map<String, dynamic>;
      final rawMain = data['mainCategories'];
      _cachedMainCats = rawMain is List
          ? rawMain.map((e) => e.toString()).toList()
          : List<String>.from(defaultMainCategories);
      final middles = <String, List<String>>{};
      final rawMiddles = data['middleCatMap'];
      if (rawMiddles is Map) {
        rawMiddles.forEach((k, v) {
          if (v is List) {
            middles[k.toString()] = v.map((e) => e.toString()).toList();
          }
        });
      }
      final subs = <String, List<String>>{};
      final rawSubs = data['subCatMap'];
      if (rawSubs is Map) {
        rawSubs.forEach((k, v) {
          if (v is List) {
            subs[k.toString()] = v.map((e) => e.toString()).toList();
          }
        });
      }
      for (final main in _cachedMainCats!) {
        middles.putIfAbsent(main, () => ['일반']);
        if (middles[main]!.isEmpty) middles[main]!.add('일반');
        // 기존 main -> sub 구조를 main::일반 구조로 자동 변환
        final legacy = subs.remove(main);
        if (legacy != null) subs[_key(main, '일반')] = legacy;
        for (final middle in middles[main]!) {
          subs.putIfAbsent(_key(main, middle), () => <String>[]);
        }
      }
      _cachedMiddleCatMap = middles;
      _cachedSubCatMap = subs;
    } catch (_) {
      debugPrint('client_operation_failed');
      _cachedMainCats ??= List<String>.from(defaultMainCategories);
      _cachedMiddleCatMap ??= _defaultMiddles();
      _cachedSubCatMap ??= _defaultSubs();
    }
  }

  static List<String> get mainCategories =>
      _cachedMainCats ?? List<String>.from(defaultMainCategories);
  static Map<String, List<String>> get middleCatMap =>
      _cachedMiddleCatMap ?? _defaultMiddles();
  static List<String> middleCatsFor(String main) =>
      List<String>.from(middleCatMap[main] ?? const ['일반']);
  static Map<String, List<String>> get subCatMap => {
        for (final main in mainCategories) main: subCatsFor(main),
      };
  static List<String> subCatsFor(String main, [String middle = '일반']) =>
      List<String>.from(_cachedSubCatMap?[_key(main, middle)] ??
          _cachedSubCatMap?[main] ??
          const []);

  static Future<void> addMainCategory(String name) async {
    if (mainCategories.contains(name)) return;
    final mains = List<String>.from(mainCategories)..add(name);
    final middles = _copy(middleCatMap)..[name] = ['일반'];
    final subs = _copy(_cachedSubCatMap ?? _defaultSubs())
      ..[_key(name, '일반')] = <String>[];
    await _saveAndCache(mains, middles, subs);
  }

  static Future<void> renameMainCategory(String oldName, String newName) async {
    final value = newName.trim();
    if (value.isEmpty || oldName == value || mainCategories.contains(value)) {
      return;
    }
    final mains = List<String>.from(mainCategories);
    final i = mains.indexOf(oldName);
    if (i < 0) return;
    mains[i] = value;
    final middles = _copy(middleCatMap);
    middles[value] = middles.remove(oldName) ?? ['일반'];
    final subs = <String, List<String>>{};
    for (final e in (_cachedSubCatMap ?? {}).entries) {
      final prefix = '$oldName::';
      final key = e.key.startsWith(prefix)
          ? '$value::${e.key.substring(prefix.length)}'
          : e.key == oldName
              ? value
              : e.key;
      subs[key] = List<String>.from(e.value);
    }
    await _saveAndCache(mains, middles, subs);
  }

  static Future<void> removeMainCategory(String name) async {
    final mains = List<String>.from(mainCategories)..remove(name);
    final middles = _copy(middleCatMap)..remove(name);
    final subs = _copy(_cachedSubCatMap ?? {})
      ..removeWhere((key, _) => key.startsWith('$name::'))
      ..remove(name);
    await _saveAndCache(mains, middles, subs);
  }

  static Future<void> addMiddleCategory(String main, String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    final middles = _copy(middleCatMap);
    final list = List<String>.from(middles[main] ?? ['일반']);
    if (list.contains(value)) return;
    list.add(value);
    middles[main] = list;
    final subs = _copy(_cachedSubCatMap ?? {})..[_key(main, value)] = [];
    await _saveAndCache(List<String>.from(mainCategories), middles, subs);
  }

  static Future<void> renameMiddleCategory(
      String main, String oldName, String newName) async {
    final value = newName.trim();
    final list = middleCatsFor(main);
    if (value.isEmpty || oldName == value || list.contains(value)) return;
    final i = list.indexOf(oldName);
    if (i < 0) return;
    list[i] = value;
    final middles = _copy(middleCatMap)..[main] = list;
    final subs = _copy(_cachedSubCatMap ?? {})
      ..[_key(main, value)] = (_cachedSubCatMap?[_key(main, oldName)] ?? [])
      ..remove(_key(main, oldName));
    await _saveAndCache(List<String>.from(mainCategories), middles, subs);
  }

  static Future<void> removeMiddleCategory(String main, String name) async {
    final list = middleCatsFor(main);
    if (list.length <= 1) return;
    list.remove(name);
    final middles = _copy(middleCatMap)..[main] = list;
    final subs = _copy(_cachedSubCatMap ?? {})..remove(_key(main, name));
    await _saveAndCache(List<String>.from(mainCategories), middles, subs);
  }

  static Future<void> addSubCategory(String main, String name,
      [String middle = '일반']) async {
    final key = _key(main, middle);
    final subs = _copy(_cachedSubCatMap ?? {})
      ..[key] = List<String>.from(_cachedSubCatMap?[key] ?? []);
    if (subs[key]!.contains(name)) return;
    subs[key]!.add(name);
    await _saveAndCache(
        List<String>.from(mainCategories), _copy(middleCatMap), subs);
  }

  static Future<void> removeSubCategory(String main, String name,
      [String middle = '일반']) async {
    final key = _key(main, middle);
    final list = List<String>.from(_cachedSubCatMap?[key] ?? [])..remove(name);
    final subs = _copy(_cachedSubCatMap ?? {})..[key] = list;
    await _saveAndCache(
        List<String>.from(mainCategories), _copy(middleCatMap), subs);
  }

  static Future<void> renameSubCategory(
      String main, String oldName, String newName,
      [String middle = '일반']) async {
    final value = newName.trim();
    final key = _key(main, middle);
    final list = List<String>.from(_cachedSubCatMap?[key] ?? []);
    final i = list.indexOf(oldName);
    if (value.isEmpty || i < 0 || (value != oldName && list.contains(value))) {
      return;
    }
    list[i] = value;
    final subs = _copy(_cachedSubCatMap ?? {})..[key] = list;
    await _saveAndCache(
        List<String>.from(mainCategories), _copy(middleCatMap), subs);
  }

  static Future<void> reorderSubCategories(String main, List<String> order,
      [String middle = '일반']) async {
    final subs = _copy(_cachedSubCatMap ?? {})
      ..[_key(main, middle)] = List<String>.from(order);
    await _saveAndCache(
        List<String>.from(mainCategories), _copy(middleCatMap), subs);
  }

  static Future<void> reorderMainCategories(List<String> order) async =>
      _saveAndCache(List<String>.from(order), _copy(middleCatMap),
          _copy(_cachedSubCatMap ?? {}));

  static Future<void> resetToDefaults() async {
    final mains = List<String>.from(defaultMainCategories);
    final middles = _defaultMiddles();
    final subs = _defaultSubs();
    await _saveAndCache(mains, middles, subs);
  }

  static Future<void> _saveAndCache(List<String> mains,
      Map<String, List<String>> middles, Map<String, List<String>> subs) async {
    await _save(mains, middles, subs);
    _cachedMainCats = mains;
    _cachedMiddleCatMap = middles;
    _cachedSubCatMap = subs;
  }

  static Future<void> _save(List<String> mains,
      Map<String, List<String>> middles, Map<String, List<String>> subs) async {
    await _doc.set({
      'mainCategories': mains,
      'middleCatMap': middles,
      'subCatMap': subs,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  static void clearCache() {
    _cachedMainCats = null;
    _cachedMiddleCatMap = null;
    _cachedSubCatMap = null;
  }
}
