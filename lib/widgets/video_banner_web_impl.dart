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
/// - 재생 종료 시 유튜브 광고 스타일 "제품 보러가기" 버튼 표시
/// - autoplay + muted → 브라우저 autoplay 정책 통과
class VideoBannerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VoidCallback? onProductTap; // 영상 종료 후 CTA 버튼 콜백

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

class _VideoBannerWidgetState extends State<VideoBannerWidget>
    with SingleTickerProviderStateMixin {
  late String _viewType;
  bool _isMuted = true;
  bool _isEnded = false;       // 영상 재생 종료 여부
  bool _isReplaying = false;   // 다시보기 재생 중
  Timer? _playRetryTimer;

  // CTA 버튼 애니메이션 컨트롤러
  late AnimationController _ctaAnimCtrl;
  late Animation<double> _ctaFadeAnim;
  late Animation<Offset> _ctaSlideAnim;

  String get _effectiveVideoUrl => VideoBannerWidget.localAssetVideo;

  @override
  void initState() {
    super.initState();
    _viewType = 'video-banner-local-${_effectiveVideoUrl.hashCode}';

    // CTA 버튼 페이드+슬라이드 인 애니메이션 (0.5초)
    _ctaAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _ctaFadeAnim = CurvedAnimation(
      parent: _ctaAnimCtrl,
      curve: Curves.easeOut,
    );
    _ctaSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctaAnimCtrl, curve: Curves.easeOutCubic));

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
    _ctaAnimCtrl.dispose();
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
        ..loop = false              // ← loop OFF: 재생 끝나면 onEnded 이벤트 발생
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

      // ★ 재생 종료 이벤트 → CTA 버튼 표시
      video.onEnded.listen((_) {
        if (!mounted) return;
        setState(() {
          _isEnded = true;
          _isReplaying = false;
        });
        // 마지막 프레임에 살짝 어두운 오버레이 + CTA 버튼 애니메이션 시작
        _ctaAnimCtrl.forward();
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

  /// 다시보기 버튼 탭 → 영상 처음부터 재생
  void _replay() {
    final video = _videoElements[_viewType];
    if (video == null) return;
    setState(() {
      _isEnded = false;
      _isReplaying = true;
    });
    _ctaAnimCtrl.reset();
    video.currentTime = 0;
    video.play().catchError((_) {});
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
          onTap: _isEnded ? null : widget.onTap,
          child: HtmlElementView(viewType: _viewType),
        ),

        // ── 재생 종료 후 오버레이 (유튜브 광고 스타일) ──
        if (_isEnded)
          Positioned.fill(
            child: FadeTransition(
              opacity: _ctaFadeAnim,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.70),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── CTA 버튼 영역 (재생 종료 후 표시) ──
        if (_isEnded)
          Positioned(
            right: isMobile ? 16 : 48,
            bottom: isMobile ? 72 : 60,
            child: SlideTransition(
              position: _ctaSlideAnim,
              child: FadeTransition(
                opacity: _ctaFadeAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── 메인 CTA 버튼 (제품 보러가기) ──
                    GestureDetector(
                      onTap: () {
                        if (widget.onProductTap != null) {
                          widget.onProductTap!();
                        } else {
                          widget.onTap?.call();
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 18 : 24,
                          vertical: isMobile ? 13 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isMobile ? 28 : 32,
                              height: isMobile ? 28 : 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFF111111),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: isMobile ? 14 : 16,
                              ),
                            ),
                            SizedBox(width: isMobile ? 10 : 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '2FIT 제품 보러가기',
                                  style: TextStyle(
                                    color: const Color(0xFF111111),
                                    fontSize: isMobile ? 14 : 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                Text(
                                  '단체주문 · 맞춤 제작',
                                  style: TextStyle(
                                    color: const Color(0xFF888888),
                                    fontSize: isMobile ? 10 : 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: isMobile ? 10 : 12),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFF555555),
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── 다시보기 버튼 (소형) ──
                    GestureDetector(
                      onTap: _replay,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.50),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.replay_rounded,
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 13),
                            const SizedBox(width: 5),
                            Text(
                              '다시보기',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── 음소거 토글 버튼 (우하단, 항상 표시) ──
        if (!_isEnded)
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
