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

  /// 배너 동영상 업로드 (1번 슬라이드 전용)
  /// [bannerId] - 배너 문서 ID
  /// [videoBytes] - 동영상 바이트 데이터
  /// [fileName] - 원본 파일명 (확장자 추출에 사용)
  static Future<String?> uploadBannerVideo({
    required String bannerId,
    required Uint8List videoBytes,
    required String fileName,
  }) async {
    try {
      // 확장자 추출 (mp4, mov, webm 등)
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'mp4';
      final contentType = ext == 'webm'
          ? 'video/webm'
          : ext == 'mov'
              ? 'video/quicktime'
              : 'video/mp4';

      final ref = _storage
          .ref()
          .child('banners/videos/$bannerId.$ext');
      final task = await ref.putData(
        videoBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {'banner': bannerId, 'uploadedAt': DateTime.now().toIso8601String()},
        ),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('uploadBannerVideo error: $e');
      return null;
    }
  }

  /// 업로드 진행률 스트림 (동영상 등 대용량 파일 전용)
  static Stream<double> uploadBannerVideoWithProgress({
    required String bannerId,
    required Uint8List videoBytes,
    required String fileName,
    required void Function(String url) onComplete,
    required void Function(String error) onError,
  }) async* {
    try {
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : 'mp4';
      final contentType = ext == 'webm'
          ? 'video/webm'
          : ext == 'mov'
              ? 'video/quicktime'
              : 'video/mp4';

      final ref = _storage
          .ref()
          .child('banners/videos/$bannerId.$ext');
      final task = ref.putData(
        videoBytes,
        SettableMetadata(contentType: contentType),
      );

      await for (final snapshot in task.snapshotEvents) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        yield progress;
        if (snapshot.state == TaskState.success) {
          final url = await snapshot.ref.getDownloadURL();
          onComplete(url);
          return;
        }
        if (snapshot.state == TaskState.error) {
          onError('업로드 중 오류가 발생했습니다');
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('uploadBannerVideoWithProgress error: $e');
      onError(e.toString());
    }
  }
}
