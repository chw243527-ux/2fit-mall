import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// 전역 이미지 헬퍼
/// • 웹: Image.network + ResizeImage(cacheWidth/cacheHeight) + 정적 placeholder
///   - width/height가 null/infinity인 경우 LayoutBuilder로 실제 크기 측정 후 캐시
/// • 네이티브: CachedNetworkImage (메모리+디스크 캐시)
/// • 로딩 중: 정적 placeholder로 스크롤 중 애니메이션 비용 최소화
/// • 에러: 회색 아이콘
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

  // double.infinity 또는 null → LayoutBuilder 측정 필요 여부
  static bool _needsMeasure(double? v) => v == null || !v.isFinite || v <= 0;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    if (kIsWeb) {
      // width/height 모두 확정값이면 바로 렌더
      if (!_needsMeasure(width) && !_needsMeasure(height)) {
        return _WebImage(
          url: url,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          backgroundColor: backgroundColor,
        );
      }

      // 하나라도 infinity/null이면 LayoutBuilder로 실제 크기 측정
      return LayoutBuilder(
        builder: (context, constraints) {
          final measuredW = _needsMeasure(width)
              ? (constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : null)
              : width;
          final measuredH = _needsMeasure(height)
              ? (constraints.maxHeight.isFinite && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : null)
              : height;

          return _WebImage(
            url: url,
            width: measuredW,
            height: measuredH,
            fit: fit,
            alignment: alignment,
            backgroundColor: backgroundColor,
          );
        },
      );
    }

    // 네이티브: CachedNetworkImage → FittedBox로 감싸 항상 영역 꽉 채움
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: fit,
        clipBehavior: Clip.hardEdge,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          alignment: alignment,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _errorWidget(),
          fadeInDuration: const Duration(milliseconds: 120),
          fadeOutDuration: Duration.zero,
          memCacheWidth: _memWidth(),
          memCacheHeight: _memHeight(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return _ShimmerBox(
      width: _needsMeasure(width) ? null : width,
      height: _needsMeasure(height) ? null : height,
      backgroundColor: backgroundColor,
    );
  }

  Widget _errorWidget() {
    return Container(
      width: _needsMeasure(width) ? null : width,
      height: _needsMeasure(height) ? null : height,
      color: backgroundColor ?? AppColors.surfaceGray,
      child: const Center(
        child: Icon(Icons.broken_image_outlined,
            color: AppColors.border, size: 28),
      ),
    );
  }

  int? _memWidth() {
    if (_needsMeasure(width)) return null;
    return (width! * 2).clamp(1, 1600).toInt();
  }

  int? _memHeight() {
    if (_needsMeasure(height)) return null;
    return (height! * 2).clamp(1, 1600).toInt();
  }
}

/// 웹 전용 이미지 위젯
/// Image.network의 ResizeImage(cacheWidth/cacheHeight)로 Flutter 엔진 메모리 캐시 활용
/// width/height는 항상 유한한 값 또는 null로 전달되어야 함 (infinity 금지)
class _WebImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? backgroundColor;

  const _WebImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Safari에서는 ResizeImage + cross-origin Firebase Storage URL 조합이
    // 이미지 디코딩에 실패할 수 있습니다. 원본 URL을 Image.network에 직접
    // 전달하면 iOS Safari와 Chromium이 동일한 경로로 이미지를 로드합니다.
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _ShimmerBox(
          width: width,
          height: height,
          backgroundColor: backgroundColor,
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: backgroundColor ?? AppColors.surfaceGray,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: AppColors.border, size: 28),
        ),
      ),
    );
  }
}

/// shimmer 플레이스홀더
class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const _ShimmerBox({this.width, this.height, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    // 스크롤 중 각 카드마다 shimmer 애니메이션을 만들지 않는 정적 placeholder
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.surfaceGray,
    );
  }
}
