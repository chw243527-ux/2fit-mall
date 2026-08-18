import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 전역 이미지 헬퍼
/// • 웹: Image.network + ResizeImage(cacheWidth/cacheHeight) + shimmer
///   - width/height가 null/infinity인 경우 LayoutBuilder로 실제 크기 측정 후 캐시
/// • 네이티브: CachedNetworkImage (메모리+디스크 캐시)
/// • 로딩 중: shimmer 애니메이션
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
  static bool _needsMeasure(double? v) =>
      v == null || !v.isFinite || v <= 0;

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
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
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
      color: backgroundColor ?? const Color(0xFFF0F0F0),
      child: const Center(
        child: Icon(Icons.broken_image_outlined,
            color: Color(0xFFCCCCCC), size: 28),
      ),
    );
  }

  int? _memWidth() {
    if (_needsMeasure(width)) return null;
    return (width! * 3).clamp(1, 2400).toInt();
  }

  int? _memHeight() {
    if (_needsMeasure(height)) return null;
    return (height! * 3).clamp(1, 2400).toInt();
  }
}

/// 웹 전용 이미지 위젯
/// Image.network의 ResizeImage(cacheWidth/cacheHeight)로 Flutter 엔진 메모리 캐시 활용
/// width/height는 항상 유한한 값 또는 null로 전달되어야 함 (infinity 금지)
class _WebImage extends StatefulWidget {
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
  State<_WebImage> createState() => _WebImageState();
}

class _WebImageState extends State<_WebImage> {
  late ImageProvider _provider;
  bool _loaded = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_WebImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _loaded = false;
      _error = false;
      _loadImage();
    }
  }

  void _loadImage() {
    final rawW = widget.width;
    final rawH = widget.height;

    // PC 고해상도 대응: 픽셀 비율 2× 최대 2400px 상한
    final devicePixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final dpr = devicePixelRatio.clamp(1.0, 3.0);

    final w = (rawW != null && rawW.isFinite && rawW > 0)
        ? ((rawW * dpr).clamp(1, 2400)).toInt()
        : null;
    final h = (rawH != null && rawH.isFinite && rawH > 0)
        ? ((rawH * dpr).clamp(1, 2400)).toInt()
        : null;

    _provider = ResizeImage.resizeIfNeeded(
      w,
      h,
      NetworkImage(widget.url),
    );

    final stream = _provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (_, __) {
        if (mounted) setState(() => _loaded = true);
      },
      onError: (_, __) {
        if (mounted) setState(() => _error = true);
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor ?? const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: Color(0xFFCCCCCC), size: 28),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.antiAlias,
      children: [
        // shimmer - 로딩 중에만 표시
        if (!_loaded)
          SizedBox.expand(
            child: _ShimmerBox(
              width: widget.width,
              height: widget.height,
              backgroundColor: widget.backgroundColor,
            ),
          ),
        // 실제 이미지 - 로드 완료 후 페이드인
        AnimatedOpacity(
          opacity: _loaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: SizedBox.expand(
            child: FittedBox(
              fit: widget.fit,
              clipBehavior: Clip.hardEdge,
              child: Image(
                image: _provider,
                fit: widget.fit,
                alignment: widget.alignment,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ],
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
    return Shimmer.fromColors(
      baseColor: backgroundColor ?? const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF8F8F8),
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }
}
