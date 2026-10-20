// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

const _key = 'twofit_last_refresh_state';

void saveWebRefreshState(String state) {
  try {
    html.window.sessionStorage[_key] = state;
  } catch (_) {}
}

String? readWebRefreshState() {
  try {
    return html.window.sessionStorage[_key];
  } catch (_) {
    return null;
  }
}

void clearWebRefreshState() {
  try {
    html.window.sessionStorage.remove(_key);
  } catch (_) {}
}
