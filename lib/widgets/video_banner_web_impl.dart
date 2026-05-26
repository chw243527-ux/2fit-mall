// video_banner_web_impl.dart
// 웹 전용: HTML <video autoplay muted loop playsinline> 직접 삽입
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 등록된 viewType 캐시 (중복 등록 방지)
final Set<String> _registeredVideoViews = {};

// HTML video 엘리먼트 레퍼런스 (음소거 토글 + 강제 재생용)
final Map<String, html.VideoElement> _videoElements = {};

/// Web용 비디오 배너 위젯
/// - 로컬 asset 경로 우선 사용 → 즉시 재생
/// - loop = true → 동영상 끝나면 자동으로 처음부터 재생 (무한반복)
/// - autoplay + muted → 브라우저 autoplay 정책 통과
class VideoBannerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VoidCallback? onProductTap;

  // 로컬 asset 경로 (Flutter 웹 빌드 후 실제 서빙 경로)
  static const String localAssetVideo = 'assets/assets/images/banner_video.mp4';

  const VideoBannerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.onTap,
    this.onProductTap,
  });

  @override
  State<VideoBannerWidget> createState() => _VideoBannerWidgetState();
}

class _VideoBannerWidgetState extends State<VideoBannerWidget> {
  late String _viewType;
  bool _isMuted = true;
  Timer? _playRetryTimer;

  String get _effectiveVideoUrl => VideoBannerWidget.localAssetVideo;

  @override
  void initState() {
    super.initState();
    _viewType = 'video-banner-local-${_effectiveVideoUrl.hashCode}';
    _registerVideoView();
    WidgetsBinding.instance.addPostFrameCallback((_) => _forcePlay());
  }

  void _forcePlay() {
    final video = _videoElements[_viewType];
    if (video == null) {
      _playRetryTimer = Timer(const Duration(milliseconds: 200), _forcePlay);
      return;
    }
    if (video.paused) {
      video.play().catchError((e) {
        video.muted = true;
        video.play().catchError((_) {
          if (kDebugMode) debugPrint('VideoBanner: play() 거부됨 - $_viewType');
        });
      });
    }
  }

  @override
  void dispose() {
    _playRetryTimer?.cancel();
    super.dispose();
  }

  void _registerVideoView() {
    if (_registeredVideoViews.contains(_viewType)) return;
    _registeredVideoViews.add(_viewType);

    // ignore: avoid_web_libraries_in_flutter
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final video = html.VideoElement()
        ..src = _effectiveVideoUrl
        ..autoplay = true
        ..muted = true
        ..loop = true               // ← loop ON: 끝나면 자동으로 처음부터 재생
        ..setAttribute('playsinline', 'true')
        ..setAttribute('preload', 'auto')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.objectPosition = 'center center'
        ..style.backgroundColor = '#000000'
        ..style.display = 'block'
        ..style.pointerEvents = 'none';

      final thumb = widget.thumbnailUrl;
      if (thumb != null && thumb.isNotEmpty) {
        video.poster = thumb;
      }

      _videoElements[_viewType] = video;

      video.onLoadedData.listen((_) {
        if (video.paused) video.play().catchError((_) {});
      });

      video.onCanPlay.listen((_) {
        if (video.paused) video.play().catchError((_) {});
      });

      // 로컬 asset 실패 → Firebase URL 폴백
      video.onError.listen((_) {
        if (kDebugMode) debugPrint('VideoBanner: 로컬 실패, Firebase URL 폴백');
        if (video.src != widget.videoUrl && widget.videoUrl.isNotEmpty) {
          video.src = widget.videoUrl;
          video.load();
          video.play().catchError((_) {});
        }
      });

      return video;
    });
  }

  void toggleMute() {
    final video = _videoElements[_viewType];
    if (video == null) return;
    setState(() {
      _isMuted = !_isMuted;
      video.muted = _isMuted;
      video.volume = _isMuted ? 0.0 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 600;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── HTML video 엘리먼트 ──
        GestureDetector(
          onTap: widget.onTap,
          child: HtmlElementView(viewType: _viewType),
        ),

        // ── 음소거 토글 버튼 (우하단) ──
        Positioned(
          right: isMobile ? 16 : 20,
          bottom: isMobile ? 24 : 28,
          child: GestureDetector(
            onTap: toggleMute,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Icon(
                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
