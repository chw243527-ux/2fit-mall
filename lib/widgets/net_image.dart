import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 전역 이미지 헬퍼
/// • 웹: Image.network + cacheWidth/cacheHeight + shimmer placeholder
///   (Flutter Web은 flutter_cache_manager 파일 캐시 미지원)
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

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    if (kIsWeb) {
      return _WebImage(
        url: url,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        backgroundColor: backgroundColor,
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
      width: width,
      height: height,
      backgroundColor: backgroundColor,
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

  int? _memWidth() {
    if (width == null || width! <= 0) return null;
    return (width! * 3).clamp(1, 1200).toInt();
  }

  int? _memHeight() {
    if (height == null || height! <= 0) return null;
    return (height! * 3).clamp(1, 1200).toInt();
  }
}

/// 웹 전용 이미지 위젯
/// Image.network의 cacheWidth/cacheHeight로 Flutter 엔진 메모리 캐시 활용
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
    if (oldWidget.url != widget.url) {
      _loaded = false;
      _error = false;
      _loadImage();
    }
  }

  void _loadImage() {
    // double.infinity 방어: infinite 값은 null로 처리 (ResizeImage 크래시 방지)
    final rawW = widget.width;
    final rawH = widget.height;
    final w = (rawW != null && rawW.isFinite && rawW > 0) ? (rawW * 3).clamp(1, 1200).toInt() : null;
    final h = (rawH != null && rawH.isFinite && rawH > 0) ? (rawH * 3).clamp(1, 1200).toInt() : null;

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
          child: Icon(Icons.broken_image_outlined, color: Color(0xFFCCCCCC), size: 28),
        ),
      );
    }

    // clipBehavior: Clip.antiAlias — 부모 ClipRRect(borderRadius)와 함께
    // 이미지가 모서리 밖으로 삐져나오지 않도록 Stack 자체도 클리핑
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
            // FittedBox: 외부 fit 파라미터 사용 (cover=채움/fill=비율고정)
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
