// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

const _routeKey = 'twofit_last_route_state';
const _legacyKey = 'twofit_last_refresh_state';

void saveWebRouteState(String route, Map<String, String> arguments) {
  try {
    html.window.sessionStorage[_routeKey] = jsonEncode({
      'route': route,
      'arguments': arguments,
    });
  } catch (_) {}
}

Map<String, dynamic>? readWebRouteState() {
  try {
    final raw = html.window.sessionStorage[_routeKey];
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['route'] is! String) return null;
    return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return null;
  }
}

void saveWebRefreshState(String state) {
  try {
    html.window.sessionStorage[_legacyKey] = state;
  } catch (_) {}
}

String? readWebRefreshState() {
  try {
    return html.window.sessionStorage[_legacyKey];
  } catch (_) {
    return null;
  }
}

void clearWebRefreshState() {
  try {
    html.window.sessionStorage.remove(_legacyKey);
    html.window.sessionStorage.remove(_routeKey);
  } catch (_) {}
}
