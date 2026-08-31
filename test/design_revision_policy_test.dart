import 'package:flutter_test/flutter_test.dart';

import 'package:twofit_mall/models/models.dart';

void main() {
  group('단체주문 디자인 수정 단계별 7일 정책', () {
    test('1차 수정은 주문 후 7일 이내에만 가능하다', () {
      final order = _order(createdAt: DateTime.now().subtract(const Duration(days: 6)));
      expect(order.canRequestDesignRevision, isTrue);
      expect(order.isDesignConfirmed, isFalse);

      final expired = _order(
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(expired.canRequestDesignRevision, isFalse);
      expect(expired.isDesignConfirmed, isTrue);
    });

    test('1차 수정 요청 후 관리자 확인 전에는 2차 수정이 열리지 않는다', () {
      final order = _order(
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        designRevisionCount: 1,
      );
      expect(order.secondDesignRevisionDeadline, isNull);
      expect(order.canRequestDesignRevision, isFalse);
      expect(order.isDesignConfirmed, isFalse);
    });

    test('1차 수정본 확인 후 7일 이내에만 2차 수정이 가능하다', () {
      final open = _order(
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        designRevisionCount: 1,
        respondedAt: DateTime.now().subtract(const Duration(days: 6)),
      );
      expect(open.canRequestDesignRevision, isTrue);
      expect(open.isDesignConfirmed, isFalse);

      final expired = _order(
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        designRevisionCount: 1,
        respondedAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(expired.canRequestDesignRevision, isFalse);
      expect(expired.isDesignConfirmed, isTrue);
    });

    test('수정 2회 완료 후에는 추가 수정이 불가능하고 확정된다', () {
      final order = _order(
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        designRevisionCount: 2,
        respondedAt: DateTime.now(),
      );
      expect(order.canRequestDesignRevision, isFalse);
      expect(order.isDesignConfirmed, isTrue);
    });
  });
}

OrderModel _order({
  required DateTime createdAt,
  int designRevisionCount = 0,
  DateTime? respondedAt,
}) {
  return OrderModel(
    id: 'GRP_POLICY_TEST',
    userId: 'policy-test-user',
    userName: '정책 테스트 사용자',
    userEmail: 'policy@example.com',
    userPhone: '010-0000-0000',
    userAddress: '서울시',
    items: const [],
    totalAmount: 0,
    paymentMethod: '무통장입금',
    status: OrderStatus.confirmed,
    orderType: 'group',
    groupName: '정책 테스트팀',
    groupCount: 1,
    createdAt: createdAt,
    designRevisionCount: designRevisionCount,
    customOptions: respondedAt == null
        ? null
        : {
            'designRevisionRequest': {
              'status': 'responded',
              'respondedAt': respondedAt.toIso8601String(),
            },
          },
  );
}
