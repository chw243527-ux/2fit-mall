import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twofit_mall/widgets/design_revision_countdown.dart';

void main() {
  testWidgets('활성 디자인 수정 기간은 잔여 시간을 표시한다', (tester) async {
    final deadline = DateTime.now().add(const Duration(hours: 2, minutes: 3));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesignRevisionCountdown(
            deadline: deadline,
            revisionCount: 0,
          ),
        ),
      ),
    );

    expect(find.text('1차 디자인 수정 기간'), findsOneWidget);
    expect(find.textContaining('잔여 '), findsOneWidget);
    expect(find.textContaining('마감 '), findsOneWidget);
  });

  testWidgets('만료된 디자인 수정 기간은 종료 상태를 표시한다', (tester) async {
    final deadline = DateTime.now().subtract(const Duration(seconds: 1));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesignRevisionCountdown(
            deadline: deadline,
            revisionCount: 1,
          ),
        ),
      ),
    );

    expect(find.text('2차 디자인 수정 기간 종료'), findsOneWidget);
    expect(find.text('디자인 수정 기간이 종료되어 자동 확정 처리됩니다.'), findsOneWidget);
  });
}
