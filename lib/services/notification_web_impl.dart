// notification_web_impl.dart
// ─────────────────────────────────────────────────────────────
// 웹 플랫폼 브라우저 Notification API — dart:js_util 기반 구현
// ─────────────────────────────────────────────────────────────
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

// FCM getToken() 호출 전에 현재 origin의 Service Worker가 활성화될 때까지 대기합니다.
// Firebase Messaging은 활성 Service Worker가 없으면 웹 토큰을 발급하지 않습니다.
Future<void> ensureServiceWorkerReady() async {
  try {
    final navigator = js_util.getProperty(js.context, 'navigator');
    if (navigator == null) return;
    final serviceWorker = js_util.getProperty(navigator, 'serviceWorker');
    if (serviceWorker == null) return;
    final ready = js_util.getProperty(serviceWorker, 'ready');
    if (ready != null) {
      await js_util.promiseToFuture<Object>(ready as Object);
    }
  } catch (_) {
    // Service Worker가 없는 환경에서는 getToken()이 구체적인 오류를 반환하도록 둡니다.
  }
}

// ── 브라우저 알림 표시 ──────────────────────────────────────
Future<void> showBrowserNotification(String title, [String body = '']) async {
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

    // Android Chrome에서는 페이지의 new Notification()보다
    // 활성 Service Worker의 showNotification()이 안정적으로 표시됩니다.
    final navigator = js_util.getProperty(js.context, 'navigator');
    final serviceWorker = js_util.getProperty(navigator, 'serviceWorker');
    final ready = js_util.getProperty(serviceWorker, 'ready');
    final registration = await js_util.promiseToFuture<Object>(ready as Object);
    js_util.callMethod(registration, 'showNotification', [title, options]);
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
