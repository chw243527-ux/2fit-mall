// notification_web_impl.dart
// ─────────────────────────────────────────────────────────────
// 웹 플랫폼 브라우저 Notification API — dart:js_util 기반 구현
// ─────────────────────────────────────────────────────────────
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

// ── 브라우저 알림 표시 ──────────────────────────────────────
void showBrowserNotification(String title, [String body = '']) {
  try {
    final permission = js_util.getProperty(
        js_util.getProperty(js.context, 'Notification'), 'permission') as String?;
    if (permission != 'granted') return;

    // options 객체 생성
    final options = js_util.newObject();
    if (body.isNotEmpty) {
      js_util.setProperty(options, 'body', body);
    }
    js_util.setProperty(options, 'icon', '/icons/Icon-192.png');
    js_util.setProperty(options, 'badge', '/icons/Icon-192.png');
    js_util.setProperty(options, 'requireInteraction', false);
    js_util.setProperty(options, 'silent', false);

    js_util.callConstructor(
      js_util.getProperty(js.context, 'Notification') as Object,
      [title, options],
    );
  } catch (e) {
    // 알림 실패는 무시 (앱 동작에 영향 없음)
  }
}

// ── 브라우저 알림 권한 요청 ─────────────────────────────────
Future<String> requestNotificationPermission() async {
  try {
    final notifClass = js_util.getProperty(js.context, 'Notification');
    if (notifClass == null) return 'not_supported';

    // Notification.requestPermission() → Promise<string>
    final result = await js_util.promiseToFuture<String>(
      js_util.callMethod(notifClass, 'requestPermission', []) as Object,
    );
    return result;
  } catch (e) {
    return 'denied';
  }
}

// ── 현재 알림 권한 상태 확인 ────────────────────────────────
String? getNotificationPermission() {
  try {
    final notifClass = js_util.getProperty(js.context, 'Notification');
    if (notifClass == null) return 'not_supported';
    return js_util.getProperty(notifClass, 'permission') as String?;
  } catch (e) {
    return null;
  }
}
