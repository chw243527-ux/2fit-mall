// video_banner_stub.dart
// Android / iOS 네이티브: video_player 패키지로 실제 동영상 재생
// loop = true → 동영상 끝나면 자동으로 처음부터 재생 (무한반복)
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBannerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VoidCallback? onProductTap;

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

class _VideoBannerWidgetState extends State<VideoBannerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.asset(
      VideoBannerWidget.localAssetVideo,
    );

    try {
      await ctrl.initialize();
      ctrl.setVolume(0.0);      // 음소거 시작
      ctrl.setLooping(true);    // loop ON → 끝나면 처음부터 자동 재생

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
      ctrl.dispose();
      debugPrint('VideoBanner stub: 로컬 실패 → 폴백: $e');
    }
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
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 600;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 동영상 플레이어 (또는 초기화 전 배경) ──
        if (_isInitialized && _controller != null)
          GestureDetector(
            onTap: widget.onTap,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          )
        else
          _buildFallback(),

        // ── 음소거 토글 버튼 (우하단) ──
        if (_isInitialized)
          Positioned(
            right: isMobile ? 16 : 20,
            bottom: isMobile ? 24 : 28,
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
