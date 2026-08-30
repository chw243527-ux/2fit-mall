// notification_web_stub.dart - 웹이 아닌 플랫폼용 스텁
Future<void> ensureServiceWorkerReady() async {
  // 비웹 플랫폼에서는 Service Worker를 사용하지 않습니다.
}

Future<void> showBrowserNotification(String title, [String body = '']) async {
  // 웹이 아닌 플랫폼에서는 아무것도 하지 않음
}

Future<String> requestNotificationPermission() async {
  return 'denied';
}

String? getNotificationPermission() {
  return null;
}
