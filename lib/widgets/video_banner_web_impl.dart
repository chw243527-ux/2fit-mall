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
/// - 로컬 asset 경로 우선 사용 → 즉시 재생 (네트워크 의존 없음)
/// - poster(썸네일) 즉시 표시 → 검은 화면 방지
/// - autoplay + muted → 브라우저 autoplay 정책 통과
class VideoBannerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;

  // 로컬 asset 경로 (Flutter 웹 빌드 후 실제 서빙 경로)
  // Flutter 웹: assets/ → build/web/assets/assets/ 로 번들됨
  static const String localAssetVideo = 'assets/assets/images/banner_video.mp4';

  const VideoBannerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.onTap,
  });

  @override
  State<VideoBannerWidget> createState() => _VideoBannerWidgetState();
}

class _VideoBannerWidgetState extends State<VideoBannerWidget> {
  late String _viewType;
  bool _isMuted = true;
  bool _isLoaded = false;
  Timer? _playRetryTimer;

  /// 실제 사용할 영상 URL 결정:
  /// 1순위: 로컬 asset (Flutter 웹 빌드에 번들된 파일) → 즉시 재생
  /// 2순위: Firestore에서 받은 videoUrl (네트워크) → 폴백
  String get _effectiveVideoUrl => VideoBannerWidget.localAssetVideo;

  @override
  void initState() {
    super.initState();
    _viewType = 'video-banner-local-${_effectiveVideoUrl.hashCode}';
    _registerVideoView();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forcePlay();
    });
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
        ..loop = true
        ..setAttribute('playsinline', 'true')
        ..setAttribute('preload', 'metadata') // 빠른 초기 로드 후 자동 재생
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'           // 배너 영역 꽉 채우기
        ..style.objectPosition = 'center center'
        ..style.backgroundColor = '#000000'
        ..style.display = 'block'
        ..style.pointerEvents = 'none';

      // poster(썸네일) 설정 → 영상 로드 전 즉시 표시 (검은 화면 방지)
      final thumb = widget.thumbnailUrl;
      if (thumb != null && thumb.isNotEmpty) {
        video.poster = thumb;
      }

      _videoElements[_viewType] = video;

      // 첫 프레임 로드 시 loaded 상태로 전환
      video.onLoadedData.listen((_) {
        if (mounted) setState(() => _isLoaded = true);
        if (video.paused) video.play().catchError((_) {});
      });

      video.onCanPlay.listen((_) {
        if (video.paused) video.play().catchError((_) {});
      });

      // 로컬 asset 실패 시 → Firebase URL로 폴백
      video.onError.listen((_) {
        if (kDebugMode) debugPrint('VideoBanner: 로컬 실패, Firebase URL로 폴백');
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // HTML video 엘리먼트
        GestureDetector(
          onTap: widget.onTap,
          child: HtmlElementView(viewType: _viewType),
        ),

        // 음소거 토글 버튼 (우하단)
        Positioned(
          right: 52,
          bottom: 32,
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
