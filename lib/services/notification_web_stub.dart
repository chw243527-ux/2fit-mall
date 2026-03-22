// notification_web_stub.dart - 웹이 아닌 플랫폼용 스텁
void showBrowserNotification(String title, [String body = '']) {
  // 웹이 아닌 플랫폼에서는 아무것도 하지 않음
}

Future<String> requestNotificationPermission() async {
  return 'denied';
}

String? getNotificationPermission() {
  return null;
}
