import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:twofit_mall/models/models.dart';
import 'package:twofit_mall/services/order_excel_service.dart';

void main() {
  final exportedAt = DateTime(2026, 9, 1, 13);

  group('관리자 엑셀 주문 유형 분류', () {
    test('명시적 orderType으로 추가제작을 분류한다', () async {
      final bytes = await OrderExcelService.generateSelectedOrdersExcel(
        [
          _order(
            id: 'GRP_1756700000000',
            orderType: 'group',
            customOptions: {
              'orderType': 'additional',
              'originalOrderId': 'GRP_1756600000000',
              'teamName': '테스트팀',
            },
          ),
        ],
        exportedAt,
      );

      final sheet = _summarySheet(bytes);
      expect(_summaryCell(sheet, 0, 1), contains('단체/커스텀: 1건'));
      expect(_summaryCell(sheet, 3, 4), contains('추가제작'));
    });

    test('구버전 추가제작 메타데이터를 추가제작으로 분류한다', () async {
      final bytes = await OrderExcelService.generateSelectedOrdersExcel(
        [
          _order(
            id: 'GRP_1756700000001',
            orderType: 'personal',
            customOptions: {
              'originalOrderId': 'GRP_1756600000001',
              'teamName': '레거시팀',
              'persons': <Map<String, dynamic>>[
                {'name': '홍길동', 'gender': '남'},
              ],
            },
          ),
        ],
        exportedAt,
      );

      final sheet = _summarySheet(bytes);
      expect(_summaryCell(sheet, 3, 4), contains('추가제작'));
    });

    test('일반 GRP 주문과 ADD가 포함된 일반 ID를 추가제작으로 오인하지 않는다', () async {
      final bytes = await OrderExcelService.generateSelectedOrdersExcel(
        [
          _order(
            id: 'GRP_1756700000002',
            orderType: 'group',
            customOptions: {
              'orderType': 'group',
              'teamName': '신규단체팀',
              'persons': <Map<String, dynamic>>[
                {'name': '김철수', 'gender': '남'},
              ],
            },
          ),
          _order(
            id: 'GRP_ADDON_1756700000003',
            orderType: 'group',
            customOptions: {
              'orderType': 'group',
              'teamName': 'ADDON팀',
            },
          ),
        ],
        exportedAt,
      );

      final sheet = _summarySheet(bytes);
      expect(_summaryCell(sheet, 3, 4), contains('단체주문'));
      expect(_summaryCell(sheet, 3, 5), contains('단체주문'));
    });

    test('일반 기성품은 개인주문으로 분류한다', () async {
      final bytes = await OrderExcelService.generateSelectedOrdersExcel(
        [
          _order(
            id: 'ORD_1756700000004',
            orderType: 'personal',
            customOptions: {'productCategory': 'ready-made'},
          ),
        ],
        exportedAt,
      );

      final sheet = _summarySheet(bytes);
      expect(_summaryCell(sheet, 3, 4), contains('개인주문'));
    });
  });
}

OrderModel _order({
  required String id,
  required String orderType,
  Map<String, dynamic>? customOptions,
}) {
  return OrderModel(
    id: id,
    userId: 'test-user',
    userName: '테스트 사용자',
    userEmail: 'test@example.com',
    userPhone: '010-0000-0000',
    userAddress: '서울시',
    items: [
      OrderItem(
        productId: 'product-1',
        productName: '테스트 상품',
        size: '단체',
        color: '블랙',
        quantity: 1,
        price: 10000,
        customOptions: customOptions,
      ),
    ],
    totalAmount: 10000,
    paymentMethod: '무통장입금',
    orderType: orderType,
    groupName: customOptions?['teamName']?.toString(),
    groupCount: customOptions?['persons'] is List
        ? (customOptions!['persons'] as List).length
        : null,
    createdAt: DateTime(2026, 9, 1, 10),
    customOptions: customOptions,
  );
}

Sheet _summarySheet(Uint8List bytes) {
  final workbook = Excel.decodeBytes(bytes);
  return workbook['주문요약'];
}

String _summaryCell(Sheet sheet, int column, int row) =>
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        .value
        .toString();

