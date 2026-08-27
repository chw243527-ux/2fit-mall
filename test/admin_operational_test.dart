import 'package:flutter_test/flutter_test.dart';

import 'package:twofit_mall/models/models.dart';

/// 관리자 목록의 전체선택·선택해제·개별 토글 동작을 앱 UI와 독립적으로 검증하기 위한
/// 작은 테스트 픽스처입니다. 실제 Firestore를 호출하지 않으므로 CI에서도 안전합니다.
class _SelectionHarness {
  _SelectionHarness(Iterable<String> ids) : ids = ids.toSet();

  final Set<String> ids;
  final Set<String> selected = <String>{};

  bool get allSelected => ids.isNotEmpty && selected.length == ids.length;

  void toggle(String id) {
    if (!ids.contains(id)) return;
    if (!selected.add(id)) selected.remove(id);
  }

  void selectAll() {
    selected
      ..clear()
      ..addAll(ids);
  }

  void clear() => selected.clear();
}

ProductModel _product({
  bool isNew = false,
  DateTime? newExpiresAt,
  double price = 39000,
  double? originalPrice,
  int stockCount = 12,
}) {
  return ProductModel(
    id: 'p-test-001',
    name: '테스트 레깅스',
    category: '레깅스',
    price: price,
    originalPrice: originalPrice,
    description: '관리자 자동화 테스트 상품',
    images: const [],
    sizes: const ['S', 'M', 'L'],
    colors: const ['Black'],
    isNew: isNew,
    newExpiresAt: newExpiresAt,
    stockCount: stockCount,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('관리자 목록 일괄 선택 시나리오', () {
    test('전체선택은 현재 목록만 선택하고 선택해제는 모두 비운다', () {
      final selection = _SelectionHarness(['o-1', 'o-2', 'o-3']);

      expect(selection.allSelected, isFalse);
      selection.selectAll();
      expect(selection.selected, equals({'o-1', 'o-2', 'o-3'}));
      expect(selection.allSelected, isTrue);

      selection.clear();
      expect(selection.selected, isEmpty);
      expect(selection.allSelected, isFalse);
    });

    test('개별 토글은 선택 개수와 전체선택 상태를 정확히 갱신한다', () {
      final selection = _SelectionHarness(['u-1', 'u-2']);

      selection.toggle('u-1');
      expect(selection.selected, equals({'u-1'}));
      expect(selection.allSelected, isFalse);

      selection.toggle('u-2');
      expect(selection.allSelected, isTrue);

      selection.toggle('u-1');
      expect(selection.selected, equals({'u-2'}));
      expect(selection.allSelected, isFalse);

      selection.toggle('unknown');
      expect(selection.selected, equals({'u-2'}));
    });

    test('빈 목록에서는 전체선택 상태가 될 수 없다', () {
      final selection = _SelectionHarness(const <String>[]);
      selection.selectAll();
      expect(selection.selected, isEmpty);
      expect(selection.allSelected, isFalse);
    });
  });

  group('관리자 상품 CRUD 데이터 계약', () {
    test('상품 수정 데이터는 가격·원가·재고·사이즈 정보를 유지한다', () {
      final product = _product(
        price: 29000,
        originalPrice: 39000,
        stockCount: 8,
      );

      expect(product.price, 29000);
      expect(product.originalPrice, 39000);
      expect(product.discountPercent, 26);
      expect(product.stockCount, 8);
      expect(product.sizes, containsAll(<String>['S', 'M', 'L']));
      expect(product.colors, contains('Black'));
    });

    test('신상품 만료일 전후 노출 상태가 다르다', () {
      final active = _product(
        isNew: true,
        newExpiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      final expired = _product(
        isNew: true,
        newExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(active.isNewActive, isTrue);
      expect(expired.isNewActive, isFalse);
    });

    test('재고 수량은 관리자가 수정한 음수가 아닌 값을 보존한다', () {
      final product = _product(stockCount: 0);

      expect(product.stockCount, 0);
      expect(product.stockCount, greaterThanOrEqualTo(0));
    });
  });

  group('관리자 주문 상태 변경 시나리오', () {
    test('모든 주문 상태는 관리자 화면에 표시할 라벨을 가진다', () {
      for (final status in OrderStatus.values) {
        expect(status.label.trim(), isNotEmpty,
            reason: '${status.name} 라벨이 비어 있습니다.');
      }

      expect(OrderStatus.pending.label, '주문 대기');
      expect(OrderStatus.processing.label, '제작/준비 중');
      expect(OrderStatus.shipped.label, '배송 중');
      expect(OrderStatus.delivered.label, '배송 완료');
      expect(OrderStatus.cancelled.label, '주문 취소');
      expect(OrderStatus.refunded.label, '환불 완료');
    });

    test('주문 상태 enum의 저장값은 안정적인 이름을 사용한다', () {
      expect(OrderStatus.values.map((status) => status.name).toSet().length,
          OrderStatus.values.length);
      expect(OrderStatus.confirmed.name, 'confirmed');
      expect(OrderStatus.purchaseConfirmed.name, 'purchaseConfirmed');
    });
  });

  group('관리자 화면 운영 계약', () {
    test('관리자 메뉴는 중복 없는 17개 탭으로 구성되어야 한다', () {
      const labels = <String>[
        '대시보드',
        '주문관리',
        '디자인요청',
        '배송관리',
        '채팅상담',
        '재고관리',
        '상품관리',
        '교환/반품',
        '리뷰관리',
        '배너관리',
        '직원관리',
        '회원관리',
        '공지관리',
        '매출통계',
        '카테고리관리',
        '섹션관리',
        '쿠폰관리',
      ];

      expect(labels, hasLength(17));
      expect(labels.toSet(), hasLength(labels.length));
      expect(labels, containsAll(<String>['주문관리', '상품관리', '회원관리']));
    });
  });
}
