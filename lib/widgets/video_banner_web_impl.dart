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
/// - videoUrl이 'assets/images/banner_video.mp4' 이면 → 로컬 asset 재생
/// - videoUrl이 http(s):// URL 이면 → 네트워크 스트리밍
/// - loop = true → 영상 끝나면 처음부터 반복 재생
/// - autoplay + muted → 브라우저 autoplay 정책 통과
class VideoBannerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VoidCallback? onProductTap;

  // Flutter 웹 빌드 후 로컬 asset 실제 서빙 경로
  static const String localAssetVideo = 'assets/assets/images/banner_video.mp4';

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

class _VideoBannerWidgetState extends State<VideoBannerWidget>
    with SingleTickerProviderStateMixin {
  late String _viewType;
  Timer? _playRetryTimer;

  // 영상 준비 여부 → true가 되면 opacity 1로 페이드인
  bool _videoReady = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

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

    // 페이드인 컨트롤러 (0→1, 400ms)
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _viewType = 'video-banner-${DateTime.now().microsecondsSinceEpoch}';
    _registerVideoView();

    // DOM 삽입 후 재생 시도
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryPlay());
  }

  /// canplay/loadeddata 이벤트가 오면 videoReady = true → 페이드인
  void _onVideoReady() {
    if (!mounted) return;
    if (!_videoReady) {
      setState(() => _videoReady = true);
      _fadeCtrl.forward();
    }
  }

  void _tryPlay() {
    final video = _videoElements[_viewType];
    if (video == null) {
      // DOM 아직 삽입 전 → 짧은 주기로 재시도
      _playRetryTimer = Timer(const Duration(milliseconds: 100), _tryPlay);
      return;
    }
    // 이미 재생 중이면 ready 처리
    if (!video.paused) {
      _onVideoReady();
      return;
    }
    // readyState >= HAVE_FUTURE_DATA(3) 이면 즉시 재생 가능
    if (video.readyState >= 3) {
      video.play().then((_) => _onVideoReady()).catchError((_) {
        video.muted = true;
        video.play().then((_) => _onVideoReady()).catchError((_) {});
      });
    } else {
      // 아직 버퍼 없음 → canplay 이벤트로 처리하고 50ms 후 재확인
      _playRetryTimer = Timer(const Duration(milliseconds: 50), _tryPlay);
    }
  }

  @override
  void dispose() {
    _playRetryTimer?.cancel();
    _fadeCtrl.dispose();
    _videoElements.remove(_viewType);
    super.dispose();
  }

  void _registerVideoView() {
    if (_registeredVideoViews.contains(_viewType)) return;
    _registeredVideoViews.add(_viewType);

    final src = _resolvedSrc;

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
        ..style.backgroundColor = 'transparent'   // 검은 배경 제거
        ..style.display = 'block'
        ..style.pointerEvents = 'none';

      // 썸네일 poster 설정 → 첫 프레임 검은화면 방지
      final thumb = widget.thumbnailUrl;
      if (thumb != null && thumb.isNotEmpty) {
        video.poster = thumb;
      }

      _videoElements[_viewType] = video;

      // 버퍼 준비 되면 재생 + 페이드인
      video.onCanPlay.listen((_) {
        if (video.paused) {
          video.play().catchError((_) {
            video.muted = true;
            video.play().catchError((_) {});
          });
        }
        _onVideoReady();
      });

      // 데이터 로드 완료 → 재생 보장
      video.onLoadedData.listen((_) {
        if (video.paused) video.play().catchError((_) {});
        _onVideoReady();
      });

      // 재생 시작됨 → 확실한 ready 처리
      video.onPlay.listen((_) => _onVideoReady());

      // loop=true 유지 + ended 이중 보장
      video.onEnded.listen((_) {
        video.currentTime = 0;
        video.play().catchError((_) {});
      });

      video.onError.listen((_) {
        if (kDebugMode) debugPrint('VideoBanner: 영상 로드 실패 ($src)');
      });

      // DOM 부착 직전 load() 호출 → 즉시 버퍼링 시작
      video.load();

      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 썸네일 placeholder: 영상 준비 전 검은화면 방지 ──
            if (!_videoReady && widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
              Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A1A)),
              )
            else if (!_videoReady)
              const ColoredBox(color: Color(0xFF1A1A1A)),

            // ── 비디오 레이어: 준비되면 페이드인 ──
            FadeTransition(
              opacity: _fadeAnim,
              child: HtmlElementView(viewType: _viewType),
            ),
          ],
        ),
      ),
    );
  }
}
