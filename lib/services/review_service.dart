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
          isBest: data['isBest'] as bool? ?? false,
          adminReply: data['adminReply'] as String? ?? '',
          adminReplyAt: (data['adminReplyAt'] as Timestamp?)?.toDate(),
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
          isBest: data['isBest'] as bool? ?? false,
          adminReply: data['adminReply'] as String? ?? '',
          adminReplyAt: (data['adminReplyAt'] as Timestamp?)?.toDate(),
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
          isBest: data['isBest'] as bool? ?? false,
          adminReply: data['adminReply'] as String? ?? '',
          adminReplyAt: (data['adminReplyAt'] as Timestamp?)?.toDate(),
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
          isBest: data['isBest'] as bool? ?? false,
          adminReply: data['adminReply'] as String? ?? '',
          adminReplyAt: (data['adminReplyAt'] as Timestamp?)?.toDate(),
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

  static Future<bool> addReview(ReviewModel review) async {
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
        'isBest': false,
        'adminReply': '',
      });
      await _updateProductRating(review.productId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('addReview error: $e');
      return false;
    }
  }

  static Future<bool> updateReview(ReviewModel review) async {
    try {
      await _db.collection('reviews').doc(review.id).update({
        'rating': review.rating,
        'content': review.content,
        'images': review.images,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _updateProductRating(review.productId);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('updateReview error: $e');
      return false;
    }
  }

  /// 상품별 베스트 리뷰를 지정합니다. 지정 시 기존 베스트는 자동 해제됩니다.
  static Future<bool> setBestReview({
    required String reviewId,
    required String productId,
    required bool isBest,
  }) async {
    try {
      final batch = _db.batch();
      if (isBest) {
        final snap = await _db
            .collection('reviews')
            .where('productId', isEqualTo: productId)
            .get();
        for (final doc in snap.docs) {
          if (doc.id != reviewId && doc.data()['isBest'] == true) {
            batch.update(doc.reference, {'isBest': false});
          }
        }
      }
      batch.update(_db.collection('reviews').doc(reviewId), {'isBest': isBest});
      await batch.commit();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('setBestReview error: $e');
      return false;
    }
  }

  /// 관리자 답변을 저장하거나 비웁니다.
  static Future<bool> saveAdminReply({
    required String reviewId,
    required String reply,
  }) async {
    try {
      await _db.collection('reviews').doc(reviewId).update({
        'adminReply': reply.trim(),
        'adminReplyAt': reply.trim().isEmpty
            ? FieldValue.delete()
            : FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('saveAdminReply error: $e');
      return false;
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
          isBest: data['isBest'] as bool? ?? false,
          adminReply: data['adminReply'] as String? ?? '',
          adminReplyAt: (data['adminReplyAt'] as Timestamp?)?.toDate(),
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
