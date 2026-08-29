// kakao_address_web_stub.dart - 모바일/비웹 플랫폼용 스텁
import 'package:flutter/material.dart';

/// 웹이 아닌 플랫폼에서는 호출되지 않지만 컴파일 오류 방지용 스텁
Widget buildKakaoWebView(BuildContext context) => const SizedBox.shrink();
Widget buildKakaoIframeView() => const SizedBox.shrink();
void registerKakaoIframeListener(void Function(Map<String, dynamic>) onResult) {}
void cancelKakaoIframeListener() {}
Future<Map<String, String>?> showKakaoAddressPopup() async => null;
