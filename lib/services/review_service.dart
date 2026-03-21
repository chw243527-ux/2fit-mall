// review_service.dart - Firestore 기반 리뷰 서비스
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class ReviewService {
  static final _db = FirebaseFirestore.instance;

  static Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      final snap = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();
      final list = snap.docs.map((d) {
        final data = d.data();
        return ReviewModel(
          id: d.id,
          userId: data['userId'] as String? ?? '',
          userName: data['userName'] as String? ?? '회원',
          productId: data['productId'] as String? ?? productId,
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          content: data['content'] as String? ?? '',
          images: List<String>.from(data['images'] ?? []),
          size: data['size'] as String? ?? '',
          color: data['color'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('getProductReviews error: $e');
      return [];
    }
  }

  static Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final snap = await _db
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();
      final list = snap.docs.map((d) {
        final data = d.data();
        return ReviewModel(
          id: d.id,
          userId: data['userId'] as String? ?? userId,
          userName: data['userName'] as String? ?? '회원',
          productId: data['productId'] as String? ?? '',
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          content: data['content'] as String? ?? '',
          images: List<String>.from(data['images'] ?? []),
          size: data['size'] as String? ?? '',
          color: data['color'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('getUserReviews error: $e');
      return [];
    }
  }

  static Stream<List<ReviewModel>> watchProductReviews(String productId) {
    return _db
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) {
            final data = d.data();
            return ReviewModel(
              id: d.id,
              userId: data['userId'] as String? ?? '',
              userName: data['userName'] as String? ?? '회원',
              productId: data['productId'] as String? ?? productId,
              rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
              content: data['content'] as String? ?? '',
              images: List<String>.from(data['images'] ?? []),
              size: data['size'] as String? ?? '',
              color: data['color'] as String? ?? '',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((e) {
          if (kDebugMode) debugPrint('watchProductReviews error: $e');
          return <ReviewModel>[];
        });
  }

  static Stream<List<ReviewModel>> watchUserReviews(String userId) {
    return _db
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) {
            final data = d.data();
            return ReviewModel(
              id: d.id,
              userId: data['userId'] as String? ?? userId,
              userName: data['userName'] as String? ?? '회원',
              productId: data['productId'] as String? ?? '',
              rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
              content: data['content'] as String? ?? '',
              images: List<String>.from(data['images'] ?? []),
              size: data['size'] as String? ?? '',
              color: data['color'] as String? ?? '',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((e) {
          if (kDebugMode) debugPrint('watchUserReviews error: $e');
          return <ReviewModel>[];
        });
  }

  static Future<void> addReview(ReviewModel review) async {
    try {
      await _db.collection('reviews').doc(review.id).set({
        'id': review.id,
        'userId': review.userId,
        'userName': review.userName,
        'productId': review.productId,
        'rating': review.rating,
        'content': review.content,
        'images': review.images,
        'size': review.size,
        'color': review.color,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _updateProductRating(review.productId);
    } catch (e) {
      if (kDebugMode) debugPrint('addReview error: $e');
    }
  }

  static Future<void> updateReview(ReviewModel review) async {
    try {
      await _db.collection('reviews').doc(review.id).update({
        'rating': review.rating,
        'content': review.content,
        'images': review.images,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _updateProductRating(review.productId);
    } catch (e) {
      if (kDebugMode) debugPrint('updateReview error: $e');
    }
  }

  static Future<bool> submitReview({
    required ReviewWriteRequest request,
    required String userId,
    required String userName,
  }) async {
    try {
      final ref = _db.collection('reviews').doc();
      await ref.set({
        'id': ref.id,
        'userId': userId,
        'userName': userName,
        'productId': request.productId,
        'orderId': request.orderId,
        'rating': request.rating,
        'content': request.content,
        'images': request.images,
        'size': request.size,
        'color': request.color,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // 상품 평점 업데이트
      await _updateProductRating(request.productId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('submitReview error: $e');
      return false;
    }
  }

  static Future<bool> deleteReview(String reviewId, String productId) async {
    try {
      await _db.collection('reviews').doc(reviewId).delete();
      await _updateProductRating(productId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('deleteReview error: $e');
      return false;
    }
  }

  static Future<void> _updateProductRating(String productId) async {
    try {
      final snap = await _db
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();
      if (snap.docs.isEmpty) return;
      final ratings = snap.docs
          .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0.0)
          .toList();
      final avg = ratings.reduce((a, b) => a + b) / ratings.length;
      await _db.collection('products').doc(productId).update({
        'rating': double.parse(avg.toStringAsFixed(1)),
        'reviewCount': ratings.length,
      });
    } catch (_) {}
  }

  static Future<List<ReviewModel>> getAllReviews() async {
    try {
      final snap = await _db.collection('reviews').get();
      final list = snap.docs.map((d) {
        final data = d.data();
        return ReviewModel(
          id: d.id,
          userId: data['userId'] as String? ?? '',
          userName: data['userName'] as String? ?? '회원',
          productId: data['productId'] as String? ?? '',
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          content: data['content'] as String? ?? '',
          images: List<String>.from(data['images'] ?? []),
          size: data['size'] as String? ?? '',
          color: data['color'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('getAllReviews error: $e');
      return [];
    }
  }
}
