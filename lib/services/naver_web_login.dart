// naver_web_login.dart
// 웹(dart.library.html) 빌드용 — JS interop으로 팝업 OAuth 호출
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_util' as js_util;
import 'package:js/js.dart';

@JS('naverOAuthLogin')
external dynamic _naverOAuthLogin();

/// index.html에 등록된 window.naverOAuthLogin() 팝업을 호출하고
/// access_token 문자열을 반환합니다.
Future<String?> callNaverOAuth() async {
  try {
    final promise = _naverOAuthLogin();
    if (promise == null) return null;
    final result = await js_util.promiseToFuture<dynamic>(promise);
    return result?.toString();
  } catch (e) {
    return null;
  }
}
