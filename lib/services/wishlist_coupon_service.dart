// wishlist_coupon_service.dart - 찜목록 서비스
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
