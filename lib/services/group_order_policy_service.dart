import 'package:cloud_firestore/cloud_firestore.dart';

class GroupOrderPolicy {
  final int minimumQuantity;
  final double discountRate;
  final List<String> allowedCategories;
  final List<String> excludedKeywords;

  const GroupOrderPolicy({
    this.minimumQuantity = 5,
    this.discountRate = 0,
    this.allowedCategories = const ['상의', '아우터', '세트'],
    this.excludedKeywords = const ['싱글렛', 'singlet'],
  });

  double get discountMultiplier => (1 - discountRate / 100).clamp(0.0, 1.0);

  bool allowsProduct({required String category, required String name, String subCategory = ''}) {
    final haystack = '$name $subCategory'.toLowerCase();
    if (excludedKeywords.any((keyword) => haystack.contains(keyword.toLowerCase()))) {
      return false;
    }
    return allowedCategories.contains(category);
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
          : const ['상의', '아우터', '세트'],
      excludedKeywords: rawExcluded is List && rawExcluded.isNotEmpty
          ? rawExcluded.map((e) => e.toString()).toList()
          : const ['싱글렛', 'singlet'],
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
