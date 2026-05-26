// video_banner_stub.dart
// Android / iOS 네이티브: video_player 패키지로 실제 동영상 재생
// 재생 완료 후 유튜브 광고 스타일 CTA 버튼 표시
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBannerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VoidCallback? onProductTap; // 영상 종료 후 CTA 버튼 콜백

  // 로컬 asset 경로 (pubspec.yaml에 등록된 경로)
  static const String localAssetVideo = 'assets/images/banner_video.mp4';

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
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isEnded = false;          // 재생 종료 여부
  bool _isMuted = true;

  // CTA 버튼 애니메이션
  late AnimationController _ctaAnimCtrl;
  late Animation<double> _ctaFadeAnim;
  late Animation<Offset> _ctaSlideAnim;

  @override
  void initState() {
    super.initState();

    // CTA 애니메이션 컨트롤러
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
    ).animate(CurvedAnimation(
      parent: _ctaAnimCtrl,
      curve: Curves.easeOutCubic,
    ));

    _initVideo();
  }

  Future<void> _initVideo() async {
    // 로컬 asset 우선 시도
    final ctrl = VideoPlayerController.asset(
      VideoBannerWidget.localAssetVideo,
    );

    try {
      await ctrl.initialize();
      ctrl.setVolume(0.0); // 음소거 시작
      ctrl.setLooping(false); // loop OFF → onEnded 감지

      // 재생 위치 리스너 → 영상 종료 감지
      ctrl.addListener(_onVideoListener);

      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _controller = ctrl;
        _isInitialized = true;
      });

      ctrl.play();
    } catch (e) {
      // 로컬 asset 실패 → 네트워크 URL 폴백 (thumbnailUrl 사용)
      ctrl.dispose();
      debugPrint('VideoBanner stub: 로컬 실패 → 폴백: $e');
    }
  }

  void _onVideoListener() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;

    // 종료 감지: 재생 위치가 전체 길이에 도달 & 재생 중지됨
    if (!_isEnded &&
        dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 200 &&
        !ctrl.value.isPlaying) {
      if (!mounted) return;
      setState(() => _isEnded = true);
      _ctaAnimCtrl.forward();
    }
  }

  /// 다시보기: 처음부터 재생
  void _replay() {
    final ctrl = _controller;
    if (ctrl == null) return;
    setState(() => _isEnded = false);
    _ctaAnimCtrl.reset();
    ctrl.seekTo(Duration.zero);
    ctrl.play();
  }

  void _toggleMute() {
    final ctrl = _controller;
    if (ctrl == null) return;
    setState(() {
      _isMuted = !_isMuted;
      ctrl.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoListener);
    _controller?.dispose();
    _ctaAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 동영상 플레이어 (또는 초기화 전 검은 배경) ──
        if (_isInitialized && _controller != null)
          GestureDetector(
            onTap: _isEnded ? null : widget.onTap,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // 모바일 화면 꽉 채우기
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          )
        else
          // 초기화 전: 썸네일 or 검은 배경
          _buildFallback(),

        // ── 재생 종료 후 어두운 오버레이 ──
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
                      Colors.black.withValues(alpha: 0.20),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── CTA 버튼 (재생 종료 후 표시) ──
        if (_isEnded)
          Positioned(
            left: 0,
            right: 0,
            bottom: screenH * 0.08, // 화면 높이 기준 하단 위치
            child: SlideTransition(
              position: _ctaSlideAnim,
              child: FadeTransition(
                opacity: _ctaFadeAnim,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenW * 0.06, // 양 옆 여백 6%
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── 메인 CTA 버튼 ──
                      GestureDetector(
                        onTap: () {
                          if (widget.onProductTap != null) {
                            widget.onProductTap!();
                          } else {
                            widget.onTap?.call();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 아이콘 원형 버튼
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF111111),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // 텍스트
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '2FIT 제품 보러가기',
                                      style: TextStyle(
                                        color: Color(0xFF111111),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '단체주문 · 맞춤 제작 · 고품질 스포츠웨어',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Color(0xFF555555),
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── 다시보기 버튼 ──
                      GestureDetector(
                        onTap: _replay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.40),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.replay_rounded,
                                color: Colors.white.withValues(alpha: 0.90),
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '다시보기',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.90),
                                  fontSize: 13,
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
          ),

        // ── 음소거 토글 (재생 중일 때만) ──
        if (!_isEnded && _isInitialized)
          Positioned(
            right: 16,
            bottom: 24,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                width: 38,
                height: 38,
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

        // ── 초기 로딩 중 인디케이터 ──
        if (!_isInitialized)
          const Positioned(
            right: 16,
            bottom: 24,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  // 초기화 전 또는 실패 시 표시할 위젯
  Widget _buildFallback() {
    final thumb = widget.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return Image.network(
        thumb,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF111111)),
      );
    }
    return Container(color: const Color(0xFF111111));
  }
}
