import '../utils/theme.dart';
// video_banner_stub.dart
// Android / iOS 네이티브: video_player 패키지로 실제 동영상 재생
// loop = true → 영상 끝나면 처음부터 반복 재생
import 'package:flutter/material.dart';
import 'net_image.dart';
import 'package:video_player/video_player.dart';

/// 네이티브 stub: 웹 전용 함수이므로 no-op
void restartAllVideoBanners() {}

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
      ctrl.setVolume(0.0); // 음소거 시작
      ctrl.setLooping(true); // loop ON: 끝나면 처음부터 반복 재생

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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 동영상 플레이어 (또는 초기화 전 배경) ──
        if (_isInitialized && _controller != null)
          GestureDetector(
            onTap: widget.onTap,
            child: Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          )
        else
          _buildFallback(),

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
      return NetImage(
        thumb,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(color: AppColors.textPrimary);
  }
}
