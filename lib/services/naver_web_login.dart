// naver_web_login.dart
// 웹(dart.library.html) 빌드용 — JS interop으로 팝업 OAuth 호출
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_util' as js_util;
import 'package:js/js.dart';

@JS('naverOAuthLogin')
external dynamic _naverOAuthLogin();

/// index.html에 등록된 window.naverOAuthLogin() 팝업을 호출하고
/// {token, naverId, email, name, photoUrl} Map을 반환합니다.
Future<Map<String, String>?> callNaverOAuth() async {
  try {
    final promise = _naverOAuthLogin();
    if (promise == null) return null;
    final result = await js_util.promiseToFuture<dynamic>(promise);
    if (result == null) return null;

    return {
      'token'   : js_util.getProperty<String>(result, 'token')    ?? '',
      'naverId' : js_util.getProperty<String>(result, 'naverId')  ?? '',
      'email'   : js_util.getProperty<String>(result, 'email')    ?? '',
      'name'    : js_util.getProperty<String>(result, 'name')     ?? '',
      'photoUrl': js_util.getProperty<String>(result, 'photoUrl') ?? '',
    };
  } catch (e) {
    return null;
  }
}
