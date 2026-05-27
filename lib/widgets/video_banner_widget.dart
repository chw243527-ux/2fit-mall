// video_banner_widget.dart
// kIsWeb 런타임 분기로 웹/네이티브 구현 선택
// - 웹: HtmlElementView + <video> 태그 (dart:html)
// - 네이티브: video_player 패키지

export 'video_banner_stub.dart'
    if (dart.library.html) 'video_banner_web_impl.dart';
