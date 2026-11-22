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
  static List<String> _hiddenMainCats = <String>[];
  static Map<String, List<String>> _hiddenMiddleCats = <String, List<String>>{};
  static Map<String, List<String>> _hiddenSubCats = <String, List<String>>{};
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
        _hiddenMainCats = <String>[];
        _hiddenMiddleCats = <String, List<String>>{};
        _hiddenSubCats = <String, List<String>>{};
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
      _hiddenMainCats = _readList(data['hiddenMainCategories']);
      _hiddenMiddleCats = _readMap(data['hiddenMiddleCategories']);
      _hiddenSubCats = _readMap(data['hiddenSubCategories']);
    } catch (_) {
      debugPrint('client_operation_failed');
      _cachedMainCats ??= List<String>.from(defaultMainCategories);
      _cachedMiddleCatMap ??= _defaultMiddles();
      _cachedSubCatMap ??= _defaultSubs();
      _hiddenMainCats = <String>[];
      _hiddenMiddleCats = <String, List<String>>{};
      _hiddenSubCats = <String, List<String>>{};
    }
  }

  static List<String> get mainCategories =>
      _cachedMainCats ?? List<String>.from(defaultMainCategories);
  static List<String> get visibleMainCategories =>
      mainCategories.where((name) => !isMainCategoryHidden(name)).toList();
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
  static List<String> visibleMiddleCatsFor(String main) => middleCatsFor(main)
      .where((name) => !isMiddleCategoryHidden(main, name))
      .toList();
  static List<String> visibleSubCatsFor(String main, [String middle = '일반']) =>
      subCatsFor(main, middle)
          .where((name) => !isSubCategoryHidden(main, middle, name))
          .toList();

  static bool isMainCategoryHidden(String name) =>
      _hiddenMainCats.contains(name);
  static bool isMiddleCategoryHidden(String main, String middle) =>
      (_hiddenMiddleCats[main] ?? const <String>[]).contains(middle);
  static bool isSubCategoryHidden(String main, String middle, String sub) =>
      (_hiddenSubCats[_key(main, middle)] ?? const <String>[]).contains(sub);

  /// 상품의 분류 경로가 고객에게 공개되어 있는지 판정합니다.
  /// 중분류가 비어 있는 기존 상품은 '일반'으로 간주하고,
  /// 소분류가 비어 있으면 소분류 숨김 규칙을 적용하지 않습니다.
  static bool isCategoryPathVisible(String main, String middle, String sub) {
    final normalizedMain = main.trim();
    final normalizedMiddle = middle.trim().isEmpty ? '일반' : middle.trim();
    final normalizedSub = sub.trim();
    if (normalizedMain.isEmpty || isMainCategoryHidden(normalizedMain)) {
      return false;
    }
    if (isMiddleCategoryHidden(normalizedMain, normalizedMiddle)) {
      return false;
    }
    return normalizedSub.isEmpty ||
        !isSubCategoryHidden(normalizedMain, normalizedMiddle, normalizedSub);
  }

  static Future<void> toggleMainCategoryVisibility(String name) async {
    final hidden = List<String>.from(_hiddenMainCats);
    hidden.contains(name) ? hidden.remove(name) : hidden.add(name);
    await _saveAndCache(
        mainCategories, middleCatMap, _cachedSubCatMap ?? _defaultSubs(),
        hiddenMain: hidden);
  }

  static Future<void> toggleMiddleCategoryVisibility(
      String main, String middle) async {
    final hidden = _copy(_hiddenMiddleCats);
    final list = List<String>.from(hidden[main] ?? const <String>[]);
    list.contains(middle) ? list.remove(middle) : list.add(middle);
    hidden[main] = list;
    await _saveAndCache(
        mainCategories, middleCatMap, _cachedSubCatMap ?? _defaultSubs(),
        hiddenMiddle: hidden);
  }

  static Future<void> toggleSubCategoryVisibility(
      String main, String middle, String sub) async {
    final hidden = _copy(_hiddenSubCats);
    final key = _key(main, middle);
    final list = List<String>.from(hidden[key] ?? const <String>[]);
    list.contains(sub) ? list.remove(sub) : list.add(sub);
    hidden[key] = list;
    await _saveAndCache(
        mainCategories, middleCatMap, _cachedSubCatMap ?? _defaultSubs(),
        hiddenSub: hidden);
  }

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
    final hiddenMain =
        _hiddenMainCats.map((name) => name == oldName ? value : name).toList();
    final hiddenMiddle = <String, List<String>>{};
    for (final e in _hiddenMiddleCats.entries) {
      hiddenMiddle[e.key == oldName ? value : e.key] =
          List<String>.from(e.value);
    }
    final hiddenSub = <String, List<String>>{};
    for (final e in _hiddenSubCats.entries) {
      final prefix = '$oldName::';
      final key = e.key.startsWith(prefix)
          ? '$value::${e.key.substring(prefix.length)}'
          : e.key;
      hiddenSub[key] = List<String>.from(e.value);
    }
    await _saveAndCache(mains, middles, subs,
        hiddenMain: hiddenMain,
        hiddenMiddle: hiddenMiddle,
        hiddenSub: hiddenSub);
  }

  static Future<void> copyMainCategory(
      String sourceName, String newName) async {
    final value = newName.trim();
    if (value.isEmpty || mainCategories.contains(value)) return;
    final mains = List<String>.from(mainCategories)..add(value);
    final middles = _copy(middleCatMap)
      ..[value] = List<String>.from(middleCatMap[sourceName] ?? ['일반']);
    final subs = _copy(_cachedSubCatMap ?? {});
    for (final middle in middles[value]!) {
      subs[_key(value, middle)] = List<String>.from(
        _cachedSubCatMap?[_key(sourceName, middle)] ??
            _cachedSubCatMap?[sourceName] ??
            const <String>[],
      );
    }
    await _saveAndCache(mains, middles, subs);
  }

  static Future<void> removeMainCategory(String name) async {
    final mains = List<String>.from(mainCategories)..remove(name);
    final middles = _copy(middleCatMap)..remove(name);
    final subs = _copy(_cachedSubCatMap ?? {})
      ..removeWhere((key, _) => key.startsWith('$name::'))
      ..remove(name);
    final hiddenMain = List<String>.from(_hiddenMainCats)..remove(name);
    final hiddenMiddle = _copy(_hiddenMiddleCats)..remove(name);
    final hiddenSub = _copy(_hiddenSubCats)
      ..removeWhere((key, _) => key.startsWith('$name::') || key == name);
    await _saveAndCache(mains, middles, subs,
        hiddenMain: hiddenMain,
        hiddenMiddle: hiddenMiddle,
        hiddenSub: hiddenSub);
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
    final hiddenMiddle = _copy(_hiddenMiddleCats);
    final hiddenList =
        List<String>.from(hiddenMiddle[main] ?? const <String>[]);
    if (hiddenList.remove(oldName)) hiddenList.add(value);
    hiddenMiddle[main] = hiddenList;
    final hiddenSub = _copy(_hiddenSubCats);
    final oldKey = _key(main, oldName);
    final newKey = _key(main, value);
    if (hiddenSub.containsKey(oldKey)) {
      hiddenSub[newKey] = hiddenSub.remove(oldKey)!;
    }
    await _saveAndCache(List<String>.from(mainCategories), middles, subs,
        hiddenMiddle: hiddenMiddle, hiddenSub: hiddenSub);
  }

  static Future<void> removeMiddleCategory(String main, String name) async {
    final list = middleCatsFor(main);
    if (list.length <= 1) return;
    list.remove(name);
    final middles = _copy(middleCatMap)..[main] = list;
    final subs = _copy(_cachedSubCatMap ?? {})..remove(_key(main, name));
    final hiddenMiddle = _copy(_hiddenMiddleCats);
    hiddenMiddle[main] =
        List<String>.from(hiddenMiddle[main] ?? const <String>[])..remove(name);
    final hiddenSub = _copy(_hiddenSubCats)..remove(_key(main, name));
    await _saveAndCache(List<String>.from(mainCategories), middles, subs,
        hiddenMiddle: hiddenMiddle, hiddenSub: hiddenSub);
  }

  static Future<void> copyMiddleCategory(
      String main, String sourceName, String newName) async {
    final value = newName.trim();
    final list = middleCatsFor(main);
    if (value.isEmpty || list.contains(value) || !list.contains(sourceName)) {
      return;
    }
    list.add(value);
    final middles = _copy(middleCatMap)..[main] = list;
    final subs = _copy(_cachedSubCatMap ?? {})
      ..[_key(main, value)] = List<String>.from(
        _cachedSubCatMap?[_key(main, sourceName)] ?? const <String>[],
      );
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

  static Future<void> copySubCategory(
      String main, String middle, String sourceName, String newName) async {
    final value = newName.trim();
    final key = _key(main, middle);
    final list = List<String>.from(_cachedSubCatMap?[key] ?? []);
    if (value.isEmpty || list.contains(value) || !list.contains(sourceName)) {
      return;
    }
    list.add(value);
    final subs = _copy(_cachedSubCatMap ?? {})..[key] = list;
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
    await _saveAndCache(mains, middles, subs,
        hiddenMain: <String>[],
        hiddenMiddle: <String, List<String>>{},
        hiddenSub: <String, List<String>>{});
  }

  static Future<void> _saveAndCache(List<String> mains,
      Map<String, List<String>> middles, Map<String, List<String>> subs,
      {List<String>? hiddenMain,
      Map<String, List<String>>? hiddenMiddle,
      Map<String, List<String>>? hiddenSub}) async {
    await _save(mains, middles, subs,
        hiddenMain: hiddenMain,
        hiddenMiddle: hiddenMiddle,
        hiddenSub: hiddenSub);
    _cachedMainCats = mains;
    _cachedMiddleCatMap = middles;
    _cachedSubCatMap = subs;
    if (hiddenMain != null) _hiddenMainCats = hiddenMain;
    if (hiddenMiddle != null) _hiddenMiddleCats = hiddenMiddle;
    if (hiddenSub != null) _hiddenSubCats = hiddenSub;
  }

  static Future<void> _save(List<String> mains,
      Map<String, List<String>> middles, Map<String, List<String>> subs,
      {List<String>? hiddenMain,
      Map<String, List<String>>? hiddenMiddle,
      Map<String, List<String>>? hiddenSub}) async {
    await _doc.set({
      'mainCategories': mains,
      'middleCatMap': middles,
      'subCatMap': subs,
      'hiddenMainCategories': hiddenMain ?? _hiddenMainCats,
      'hiddenMiddleCategories': hiddenMiddle ?? _hiddenMiddleCats,
      'hiddenSubCategories': hiddenSub ?? _hiddenSubCats,
      'updatedAt': FieldValue.serverTimestamp()
    });
  }

  static void clearCache() {
    _cachedMainCats = null;
    _cachedMiddleCatMap = null;
    _cachedSubCatMap = null;
  }

  static List<String> _readList(dynamic raw) =>
      raw is List ? raw.map((e) => e.toString()).toList() : <String>[];

  static Map<String, List<String>> _readMap(dynamic raw) {
    final result = <String, List<String>>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is List) result[key.toString()] = _readList(value);
      });
    }
    return result;
  }
}
