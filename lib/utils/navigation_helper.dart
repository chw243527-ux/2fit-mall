import 'package:flutter/material.dart';
import '../main.dart' show navigatorKey;
import '../screens/main_screen.dart';

/// 뒤로가기 공통 처리 함수 (AppBar ← 버튼 전용)
/// - Navigator 스택에 이전 화면이 있으면 → pop (정상 뒤로가기)
/// - 없으면 → MainScreen 홈탭으로 이동 (앱 종료 없음)
void goBackOrHome(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  } else {
    // 스택 바닥 → 홈으로 이동
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
