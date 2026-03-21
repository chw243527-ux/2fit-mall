// storage_service.dart - Firebase Storage 서비스
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// 상품 이미지 업로드
  static Future<String> uploadProductImage({
    required String productId,
    Uint8List? imageBytes,
    Uint8List? bytes,           // admin_screen 호환 (bytes 파라미터)
    required String fileName,
  }) async {
    final data = imageBytes ?? bytes;
    if (data == null) return '';
    try {
      final ref = _storage
          .ref()
          .child('products/$productId/$fileName');
      final task = await ref.putData(
        data,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('uploadProductImage error: $e');
      return '';
    }
  }

  /// 리뷰 이미지 업로드
  static Future<String?> uploadReviewImage({
    required String reviewId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('reviews/$reviewId/$fileName');
      final task = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('uploadReviewImage error: $e');
      return null;
    }
  }

  /// 여러 이미지 일괄 업로드
  static Future<List<String>> uploadMultipleImages({
    required String folder,
    required String docId,
    required List<Uint8List> imageBytesList,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < imageBytesList.length; i++) {
      final url = await uploadProductImage(
        productId: '$folder/$docId',
        imageBytes: imageBytesList[i],
        fileName: '${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );
      urls.add(url);
    }
    return urls;
  }

  /// 파일 삭제
  static Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('deleteFile error: $e');
    }
  }

  /// 섹션별 이미지 업로드 - sectionKey/bytes 파라미터 방식 (admin_screen 호환)
  static Future<String> uploadSectionImage({
    required String productId,
    required String sectionKey,
    required Uint8List bytes,
    required String fileName,
    String? section,
  }) async {
    try {
      final sectionPath = section ?? sectionKey;
      final ref = _storage
          .ref()
          .child('products/$productId/sections/$sectionPath/$fileName');
      final task = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('uploadSectionImage error: $e');
      return '';
    }
  }



  /// 배너 이미지 업로드
  static Future<String?> uploadBannerImage({
    required String bannerId,
    required Uint8List imageBytes,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('banners/$bannerId.jpg');
      final task = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('uploadBannerImage error: $e');
      return null;
    }
  }
}
