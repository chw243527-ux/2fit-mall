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

/// 현재 마운트된 모든 비디오 배너를 처음부터 재시작
/// 홈화면 pull-to-refresh 콜백에서 호출
void restartAllVideoBanners() {
  for (final video in _videoElements.values) {
    try {
      video.currentTime = 0;
      video.play().catchError((_) {});
    } catch (_) {}
  }
}

/// Web용 비디오 배너 위젯
/// - videoUrl이 'assets/images/banner_video.mp4' 이면 → 로컬 asset 재생
/// - videoUrl이 http(s):// URL 이면 → 네트워크 스트리밍
/// - loop = true → 영상 끝나면 처음부터 반복 재생
/// - autoplay + muted → 브라우저 autoplay 정책 통과
class VideoBannerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VoidCallback? onProductTap;

  // Flutter 웹 빌드 후 로컬 asset 실제 서빙 경로 (캐시 버스팅 버전 쿼리 포함)
  static const String localAssetVideo = 'assets/assets/images/banner_video.mp4?v=20260529b';

  // Firestore에 저장되는 로컬 식별자
  static const String localAssetId = 'assets/images/banner_video.mp4';

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

  /// Firestore videoUrl → 실제 재생할 src 결정
  String get _resolvedSrc {
    final url = widget.videoUrl;
    if (url.isEmpty) return VideoBannerWidget.localAssetVideo;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('assets/')) return 'assets/$url';
    return VideoBannerWidget.localAssetVideo;
  }

  @override
  void initState() {
    super.initState();

    _viewType = 'video-banner-${DateTime.now().microsecondsSinceEpoch}';

    // ① 뷰 팩토리 즉시 등록 (video 엘리먼트 생성 + 버퍼링 즉시 시작)
    _registerVideoView();

    // ② postFrameCallback: DOM 삽입 직후 play() 강제 호출
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryPlay());
  }

  /// DOM 삽입 대기 → 즉시 play() 강제 호출
  /// 폴링 간격 16ms (≈ 1 프레임) 로 최소화
  void _tryPlay() {
    if (!mounted) return;
    final video = _videoElements[_viewType];
    if (video == null) {
      // DOM 아직 미삽입 → 16ms 후 재시도 (1프레임 단위)
      _playRetryTimer = Timer(const Duration(milliseconds: 16), _tryPlay);
      return;
    }

    // 이미 재생 중이면 종료
    if (!video.paused) return;

    // readyState 무관하게 즉시 play() 시도
    // 브라우저가 준비되는 즉시 재생 시작 (버퍼 없어도 시작 요청)
    video.play().catchError((_) {
      // 자동재생 차단 시 muted 보장 후 재시도
      video.muted = true;
      video.play().catchError((_) {
        // 최후 수단: 250ms 후 한 번 더
        _playRetryTimer = Timer(const Duration(milliseconds: 250), () {
          if (mounted) {
            _videoElements[_viewType]?.play().catchError((_) {});
          }
        });
      });
    });
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

    final src = _resolvedSrc;
    final thumb = widget.thumbnailUrl;

    // ignore: avoid_web_libraries_in_flutter
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final video = html.VideoElement()
        ..src = src
        ..autoplay = true
        ..muted = true
        ..loop = true
        ..setAttribute('playsinline', 'true')
        ..setAttribute('preload', 'auto')
        ..setAttribute('webkit-playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.objectPosition = 'center center'
        ..style.backgroundColor = '#000000'
        ..style.display = 'block'
        ..style.pointerEvents = 'none';

      // poster → 첫 프레임 썸네일 (검은화면 완전 방지)
      if (thumb != null && thumb.isNotEmpty) {
        video.poster = thumb;
      }

      _videoElements[_viewType] = video;

      // canplay → 버퍼 준비 즉시 재생
      video.onCanPlay.listen((_) {
        if (video.paused) {
          video.play().catchError((_) {
            video.muted = true;
            video.play().catchError((_) {});
          });
        }
      });

      // loadeddata → 재생 보장
      video.onLoadedData.listen((_) {
        if (video.paused) video.play().catchError((_) {});
      });

      // loop=true 유지 + ended 이중 보장
      video.onEnded.listen((_) {
        video.currentTime = 0;
        video.play().catchError((_) {});
      });

      video.onError.listen((_) {
        if (kDebugMode) debugPrint('VideoBanner: 영상 로드 실패 ($src)');
      });

      // ★ DOM 부착 전 load() → 네트워크 요청 즉시 시작
      video.load();

      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    // FadeTransition 완전 제거 → HtmlElementView 즉시 opacity 1 표시
    // poster(썸네일)가 첫 프레임 역할 → 검은화면 없음
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox.expand(
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
