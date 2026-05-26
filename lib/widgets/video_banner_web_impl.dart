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
/// - dart:html VideoElement를 직접 삽입 → autoplay + muted → 브라우저 정책 통과
/// - 마운트 직후 video.play() 명시 호출 → 즉시 재생 보장
class VideoBannerWidget extends StatefulWidget {
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
  State<VideoBannerWidget> createState() => _VideoBannerWidgetState();
}

class _VideoBannerWidgetState extends State<VideoBannerWidget> {
  late String _viewType;
  bool _isMuted = true;
  Timer? _playRetryTimer;

  @override
  void initState() {
    super.initState();
    _viewType = 'video-banner-${widget.videoUrl.hashCode}';
    _registerVideoView();

    // HtmlElementView가 DOM에 삽입된 직후 play() 호출
    // addPostFrameCallback: 첫 프레임 렌더 완료 후 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forcePlay();
    });
  }

  /// video 엘리먼트에 play()를 명시적으로 호출.
  /// 브라우저는 muted 상태라면 autoplay 정책 통과 가능.
  /// 혹시 재생이 안 됐을 경우 300ms 뒤 한 번 더 시도.
  void _forcePlay() {
    final video = _videoElements[_viewType];
    if (video == null) {
      // DOM 삽입 전일 경우 잠시 후 재시도
      _playRetryTimer = Timer(const Duration(milliseconds: 300), _forcePlay);
      return;
    }
    // paused 상태일 때만 play() 호출
    if (video.paused) {
      video.play().catchError((e) {
        // Autoplay 정책으로 거부됐을 때 — muted 재확인 후 재시도
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
        ..src = widget.videoUrl
        ..autoplay = true
        ..muted = true        // ← 브라우저 autoplay 정책: muted 필수
        ..loop = true
        ..setAttribute('playsinline', 'true')  // iOS Safari 전체화면 방지
        ..setAttribute('preload', 'auto')      // 즉시 로드 시작
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.objectPosition = 'center center'
        ..style.backgroundColor = '#000000'
        ..style.pointerEvents = 'none'; // Flutter GestureDetector가 탭 받도록

      _videoElements[_viewType] = video;

      // canplay 이벤트: 버퍼 준비되면 즉시 play()
      video.onCanPlay.listen((_) {
        if (video.paused) {
          video.play().catchError((_) {});
        }
      });

      // loadeddata 이벤트: 첫 프레임 로드 완료 시 play()
      video.onLoadedData.listen((_) {
        if (video.paused) {
          video.play().catchError((_) {});
        }
      });

      video.onError.listen((_) {
        if (kDebugMode) {
          debugPrint('VideoBanner: 로드 실패 - ${widget.videoUrl}');
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
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
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
