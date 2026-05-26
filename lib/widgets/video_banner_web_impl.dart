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

class _VideoBannerWidgetState extends State<VideoBannerWidget> {
  late String _viewType;
  Timer? _playRetryTimer;

  /// Firestore videoUrl → 실제 재생할 src 결정
  /// - 로컬 식별자(assets/images/...) → 웹 asset 경로로 변환
  /// - http(s) URL → 그대로 사용
  String get _resolvedSrc {
    final url = widget.videoUrl;
    if (url.isEmpty) return VideoBannerWidget.localAssetVideo;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    // assets/images/banner_video.mp4 → assets/assets/images/banner_video.mp4
    if (url.startsWith('assets/')) return 'assets/$url';
    return VideoBannerWidget.localAssetVideo;
  }

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

    final src = _resolvedSrc;

    // ignore: avoid_web_libraries_in_flutter
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final video = html.VideoElement()
        ..src = src
        ..autoplay = true
        ..muted = true
        ..loop = true                // ← loop ON: 끝나면 처음부터 반복 재생
        ..setAttribute('playsinline', 'true')
        ..setAttribute('preload', 'auto')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'            // 컨테이너 꽉 채움 (비율 유지, 잘림 없음)
        ..style.objectPosition = 'center center'
        ..style.backgroundColor = '#000000'
        ..style.display = 'block'
        ..style.pointerEvents = 'none';

      final thumb = widget.thumbnailUrl;
      if (thumb != null && thumb.isNotEmpty) {
        video.poster = thumb;
      }

      _videoElements[_viewType] = video;

      // 로드 완료 시 재생 보장
      video.onLoadedData.listen((_) {
        if (video.paused) video.play().catchError((_) {});
      });

      // canplay 시 재생 보장 (autoplay 정책 우회)
      video.onCanPlay.listen((_) {
        if (video.paused) video.play().catchError((_) {});
      });

      // ── ended: 영상 끝 → 즉시 처음부터 재생 ──
      // loop=true 는 유지하되, ended 도 직접 처리해 이중 보장
      video.onEnded.listen((_) {
        video.currentTime = 0;
        video.play().catchError((_) {});
      });

      video.onError.listen((_) {
        if (kDebugMode) debugPrint('VideoBanner: 영상 로드 실패 ($src)');
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
