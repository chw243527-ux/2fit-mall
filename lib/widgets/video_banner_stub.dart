// video_banner_stub.dart
// Android / 비-웹 플랫폼용 fallback: 썸네일 이미지만 표시
import 'package:flutter/material.dart';

class VideoBannerWidget extends StatelessWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;

  const VideoBannerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 모바일에서는 썸네일 이미지로 표시
    final thumb = thumbnailUrl;
    if (thumb == null || thumb.isEmpty) {
      return GestureDetector(
        onTap: onTap,
        child: Container(color: const Color(0xFF1A1A1A)),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Image.network(
        thumb,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
      ),
    );
  }
}
