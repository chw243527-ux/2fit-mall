import 'package:cloud_firestore/cloud_firestore.dart';

class GroupOrderPolicy {
  final int minimumQuantity;
  final double discountRate;
  final List<String> allowedCategories;
  final List<String> excludedKeywords;

  const GroupOrderPolicy({
    this.minimumQuantity = 5,
    this.discountRate = 0,
    this.allowedCategories = const ['싱글렛'],
    this.excludedKeywords = const [],
  });

  double get discountMultiplier => (1 - discountRate / 100).clamp(0.0, 1.0);

  bool allowsProduct({required String category, required String name, String subCategory = ''}) {
    final haystack = '$name $subCategory'.toLowerCase();
    final isSinglet = haystack.contains('싱글렛') || haystack.contains('singlet');
    if (!isSinglet) return false;
    // 과거 정책에 저장된 싱글렛 제외값은 무시하고, 다른 별도 제외 키워드만 적용한다.
    final hasOtherExcludedKeyword = excludedKeywords.any((keyword) {
      final normalized = keyword.toLowerCase();
      if (normalized == '싱글렛' || normalized == 'singlet') return false;
      return haystack.contains(normalized);
    });
    return !hasOtherExcludedKeyword;
  }

  factory GroupOrderPolicy.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    final rawCategories = map['allowedCategories'];
    final rawExcluded = map['excludedKeywords'];
    return GroupOrderPolicy(
      minimumQuantity: ((map['minimumQuantity'] as num?)?.toInt() ?? 5).clamp(1, 9999),
      discountRate: ((map['discountRate'] as num?)?.toDouble() ?? 0).clamp(0, 90),
      allowedCategories: rawCategories is List && rawCategories.isNotEmpty
          ? rawCategories.map((e) => e.toString()).toList()
          : const ['싱글렛'],
      excludedKeywords: rawExcluded is List
          ? rawExcluded.map((e) => e.toString()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'minimumQuantity': minimumQuantity,
        'discountRate': discountRate,
        'allowedCategories': allowedCategories,
        'excludedKeywords': excludedKeywords,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class GroupOrderPolicyService {
  static final _doc = FirebaseFirestore.instance
      .collection('app_settings')
      .doc('group_order_policy');

  static Future<GroupOrderPolicy> getPolicy() async {
    try {
      final snapshot = await _doc.get();
      return GroupOrderPolicy.fromMap(snapshot.data());
    } catch (_) {
      return const GroupOrderPolicy();
    }
  }

  static Future<void> savePolicy(GroupOrderPolicy policy) async {
    await _doc.set(policy.toMap(), SetOptions(merge: true));
  }
}
