import 'package:flutter/material.dart';
import '../main.dart' show navigatorKey;
import '../screens/main_screen.dart';

/// 뒤로가기 공통 처리 함수
/// - Navigator 스택에 이전 화면이 있으면 → pop
/// - 없으면 (앱 최초 진입이거나 딥링크 진입 등) → MainScreen 홈탭으로 이동
void goBackOrHome(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  } else {
    // 스택이 없을 때: MainScreen 홈탭으로 이동
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
      (route) => false,
    );
  }
}

/// AppBar leading 뒤로가기 버튼 위젯 (공통)
Widget buildBackButton(BuildContext context, {Color color = Colors.white}) {
  return IconButton(
    icon: Icon(Icons.arrow_back_ios_rounded, color: color, size: 20),
    onPressed: () => goBackOrHome(context),
  );
}
