import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 전역 이미지 헬퍼 — CachedNetworkImage 기반
/// • 메모리 + 디스크 캐시로 재로딩 없음
/// • 로딩 중: 회색 shimmer placeholder
/// • 에러: 회색 아이콘
///
/// 사용법:
///   NetImage('https://...', fit: BoxFit.cover, width: 120, height: 120)
///   NetImage.square('https://...', size: 60, fit: BoxFit.cover)
class NetImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? backgroundColor;

  const NetImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.backgroundColor,
  });

  factory NetImage.square(
    String url, {
    Key? key,
    required double size,
    BoxFit fit = BoxFit.cover,
    Color? backgroundColor,
  }) {
    return NetImage(
      url,
      key: key,
      width: size,
      height: size,
      fit: fit,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      // 로딩 중 - 밝은 회색 플레이스홀더
      placeholder: (_, __) => _placeholder(),
      // 에러 - 아이콘
      errorWidget: (_, __, ___) => _errorWidget(),
      // 성능 옵션
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: _memWidth(),
      memCacheHeight: _memHeight(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? const Color(0xFFF5F5F5),
    );
  }

  Widget _errorWidget() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? const Color(0xFFF0F0F0),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Color(0xFFCCCCCC), size: 28),
      ),
    );
  }

  // 메모리 캐시 해상도 제한 (디코딩 비용 절감)
  int? _memWidth() {
    if (width == null || width! <= 0) return null;
    // 3배 픽셀 밀도까지 고려, 최대 1200px
    return (width! * 3).clamp(1, 1200).toInt();
  }

  int? _memHeight() {
    if (height == null || height! <= 0) return null;
    return (height! * 3).clamp(1, 1200).toInt();
  }
}
