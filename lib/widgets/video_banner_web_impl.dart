// video_banner_web_impl.dart
// 웹 전용: HTML <video autoplay muted loop playsinline> 직접 삽입
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 등록된 viewType 캐시 (중복 등록 방지)
final Set<String> _registeredVideoViews = {};

// HTML video 엘리먼트 레퍼런스 (음소거 토글용)
final Map<String, html.VideoElement> _videoElements = {};

/// Web용 비디오 배너 위젯
class VideoBannerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl; // 로딩 전 표시할 이미지
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

  @override
  void initState() {
    super.initState();
    // viewType은 URL 기반으로 고유하게 설정
    _viewType = 'video-banner-${widget.videoUrl.hashCode}';
    _registerVideoView();
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
        ..setAttribute('preload', 'auto')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.objectPosition = 'center top'
        ..style.pointerEvents = 'none'; // Flutter GestureDetector가 탭 받도록

      _videoElements[_viewType] = video;

      // 로드 실패 시 썸네일 폴백 (video 숨기고 이미지 표시는 Flutter 레이어에서 처리)
      video.onError.listen((_) {
        if (kDebugMode) {
          // ignore: avoid_print
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Icon(
                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
