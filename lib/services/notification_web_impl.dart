// notification_web_impl.dart - 웹 플랫폼용 브라우저 알림 구현
// dart.library.html 환경에서만 사용됨

void showBrowserNotification(String title, [String body = '']) {
  // 웹 플랫폼에서 브라우저 알림 (JS interop 필요 - 현재는 스텁)
}

Future<String> requestNotificationPermission() async {
  return 'denied';
}

String? getNotificationPermission() {
  return 'default';
}
