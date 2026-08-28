// 웹(dart.library.html) 빌드용 — 서버 Authorization Code OAuth 팝업 연동
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_util' as js_util;
import 'package:js/js.dart';

@JS('naverOAuthLogin')
external dynamic _naverOAuthLogin();

String _readString(dynamic object, String property) {
  final value = js_util.getProperty<dynamic>(object, property);
  return value is String ? value : '';
}

/// 서버 교환용 {code, state, redirectUri}를 반환합니다.
Future<Map<String, String>?> callNaverOAuth() async {
  try {
    final promise = _naverOAuthLogin();
    if (promise == null) return null;
    final result = await js_util.promiseToFuture<dynamic>(promise);
    if (result == null) return null;

    return {
      'code': _readString(result, 'code'),
      'state': _readString(result, 'state'),
      'redirectUri': _readString(result, 'redirectUri'),
      'error': _readString(result, 'error'),
    };
  } catch (_) {
    return null;
  }
}
