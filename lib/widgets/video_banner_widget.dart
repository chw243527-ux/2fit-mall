// video_banner_widget.dart
// 플랫폼에 따라 Web impl / Stub을 자동 선택하는 진입점
export 'video_banner_stub.dart'
    if (dart.library.html) 'video_banner_web_impl.dart';
