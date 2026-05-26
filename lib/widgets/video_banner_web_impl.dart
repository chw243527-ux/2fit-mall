// video_banner_web_impl.dart
// 웹 전용: HTML <video autoplay muted playsinline> 직접 삽입
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 등록된 viewType 캐시 (중복 등록 방지)
final Set<String> _registeredVideoViews = {};

// HTML video 엘리먼트 레퍼런스
final Map<String, html.VideoElement> _videoElements = {};

/// Web용 비디오 배너 위젯
/// - 로컬 asset 경로 고정 재생 (Firestore videoUrl 무시 — 항상 로컬 우선)
/// - loop = false → 영상 끝(육상경기장 씬)에서 멈춤
/// - autoplay + muted → 브라우저 autoplay 정책 통과
class VideoBannerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VoidCallback? onProductTap;

  // Flutter 웹 빌드 후 실제 서빙 경로 (build/web/assets/assets/images/...)
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
  Timer? _playRetryTimer;

  // 항상 로컬 asset 고정 — Firestore URL 무시
  static const String _src = VideoBannerWidget.localAssetVideo;

  @override
  void initState() {
    super.initState();
    // viewType을 타임스탬프로 유일하게 생성 → 캐시 재사용 방지
    _viewType = 'video-banner-${DateTime.now().microsecondsSinceEpoch}';
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
    _videoElements.remove(_viewType);
    super.dispose();
  }

  void _registerVideoView() {
    if (_registeredVideoViews.contains(_viewType)) return;
    _registeredVideoViews.add(_viewType);

    // ignore: avoid_web_libraries_in_flutter
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final video = html.VideoElement()
        ..src = _src                  // ← 로컬 asset 고정 (Firestore URL 무시)
        ..autoplay = true
        ..muted = true
        ..loop = false               // ← loop OFF: 영상 끝에서 멈춤
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

      // onError: 로컬 asset 실패 시만 로그 (외부 URL 폴백 없음)
      video.onError.listen((_) {
        if (kDebugMode) debugPrint('VideoBanner: 로컬 asset 로드 실패 ($_src)');
      });

      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
