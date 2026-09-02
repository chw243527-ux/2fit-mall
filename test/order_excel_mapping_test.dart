import 'package:flutter_test/flutter_test.dart';

import 'package:twofit_mall/models/models.dart';
import 'package:twofit_mall/services/order_excel_service.dart';

void main() {
  group('단체주문 엑셀 업로드 매핑', () {
    test('주문·상품·팀·인원·옵션·수정이력을 누락 없이 매핑한다', () {
      final parsed = OrderExcelService.parseOrderForTesting({
        'userId': 'user-001',
        'userName': '김민준',
        'userEmail': 'minjun@example.com',
        'userPhone': '010-1234-5678',
        'deliveryAddress': '전북 남원시 테스트로 1',
        'totalAmount': 1040000,
        'shippingFee': 3000,
        'paymentMethod': '가상계좌',
        'status': 'paid',
        'groupName': '전북 러닝크루',
        'groupCount': 3,
        'createdAt': '2026-09-03T10:00:00.000Z',
        'memo': '등판 로고 최종 확인',
        'items': [
          {
            'productId': 'shirt-001',
            'productName': '2FIT 긴팔 티셔츠',
            'size': '혼합',
            'color': '네이비',
            'quantity': 20,
            'price': 27000,
            'customOptions': {
              'mainColor': '네이비',
              'printType': '가슴 로고 + 등판 로고',
              'waistband': '밴드형',
              'fabric': '기능성 폴리에스터',
              'designFileUrl': 'https://example.com/design.pdf',
            },
          },
        ],
        'persons': [
          {
            'name': '박서준',
            'gender': 'male',
            'sizeType': '성인',
            'topSize': 'L',
            'bottomSize': 'M',
            'bottomLength': '24cm',
            'height': '178',
            'weight': '72',
            'waist': '80',
            'thigh': '54',
            'note': '기장 1cm 조정',
          },
          {
            'name': '이도현',
            'gender': 'female',
            'topSize': 'M',
            'bottomSize': 'S',
          },
        ],
        'customOptions': {
          'teamName': '전북 러닝크루',
          'mainColor': '네이비',
          'adjustedColorHex': '#1A237E',
          'bottomColorName': '차콜',
          'bottomColorHex': '#333333',
          'printType': '가슴 로고 + 등판 로고',
          'maleLength': '24cm',
          'femaleLength': '22cm',
          'waistbandOption': '밴드형',
          'fabric': '기능성 폴리에스터',
          'fabricWeight': '180g',
          'exclusive': true,
          'designLogoUrl': 'https://example.com/design.pdf',
          'waistbandLogoUrl': 'https://example.com/waistband.pdf',
          'deliveryMemo': '문 앞 배송',
          'persons': null,
        },
        'designRevisionRequest': {
          'status': 'responded',
          'note': '등판 로고 위치 변경 완료',
        },
      }, 'GRP_TEST_001');

      expect(parsed, isNotNull);
      final order = parsed!;
      final options = order.customOptions!;
      final persons = options['persons'] as List<dynamic>;

      expect(order.id, 'GRP_TEST_001');
      expect(order.isGroupOrder, isTrue);
      expect(order.groupName, '전북 러닝크루');
      expect(order.userName, '김민준');
      expect(order.userEmail, 'minjun@example.com');
      expect(order.userPhone, '010-1234-5678');
      expect(order.userAddress, '전북 남원시 테스트로 1');
      expect(order.totalAmount, 1040000);
      expect(order.shippingFee, 3000);
      expect(order.items.single.quantity, 20);
      expect(order.items.single.price, 27000);
      expect(options['teamName'], '전북 러닝크루');
      expect(options['adjustedColorHex'], '#1A237E');
      expect(options['bottomColorHex'], '#333333');
      expect(options['waistbandOption'], '밴드형');
      expect(options['designRevisionRequest']['status'], 'responded');
      expect(persons, hasLength(2));
      expect(persons[0]['gender'], '남');
      expect(persons[1]['gender'], '여');
      expect(persons[0]['note'], '기장 1cm 조정');
    });

    test('customOptions가 없어도 top-level persons와 groupName을 폴백한다', () {
      final parsed = OrderExcelService.parseOrderForTesting({
        'userName': '테스트 담당자',
        'items': <Map<String, dynamic>>[],
        'groupName': '폴백 팀',
        'groupCount': 1,
        'persons': [
          {'name': '홍길동', 'gender': 'M', 'topSize': 'L'},
        ],
      }, 'GROUP-FALLBACK');

      expect(parsed, isNotNull);
      expect(parsed!.isGroupOrder, isTrue);
      expect(parsed.customOptions!['teamName'], '폴백 팀');
      expect(parsed.customOptions!['persons'][0]['gender'], '남');
      expect(parsed.customOptions!['totalCount'], 1);
    });
  });
}
