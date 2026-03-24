// order_excel_service.dart — 주문 엑셀 내보내기 서비스
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class OrderExcelService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── 전날 오후1시 ~ 당일 오후1시 날짜 계산 ──
  static DateTimeRange getDailyRange({DateTime? baseDate}) {
    final now = baseDate ?? DateTime.now();
    // 기준: 오늘 오후 1시
    final todayAt1pm = DateTime(now.year, now.month, now.day, 13, 0, 0);
    // 현재 시각이 오후 1시 이전이면 어제 오후1시 ~ 오늘 오후1시
    // 현재 시각이 오후 1시 이후이면 오늘 오후1시 ~ 내일 오후1시
    final DateTime start;
    final DateTime end;
    if (now.isBefore(todayAt1pm)) {
      start = todayAt1pm.subtract(const Duration(days: 1));
      end = todayAt1pm;
    } else {
      start = todayAt1pm;
      end = todayAt1pm.add(const Duration(days: 1));
    }
    return DateTimeRange(start: start, end: end);
  }

  // ── 날짜 범위로 주문 조회 ──
  static Future<List<OrderModel>> getOrdersByDateRange(
      DateTime start, DateTime end) async {
    try {
      final snapshot = await _db
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .get();

      final orders = snapshot.docs
          .map((doc) => _parseOrder(doc.data(), doc.id))
          .whereType<OrderModel>()
          .toList();

      orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return orders;
    } catch (e) {
      if (kDebugMode) debugPrint('주문 조회 오류: $e');
      // orderBy 없이 재시도
      try {
        final snapshot = await _db.collection('orders').get();
        final orders = snapshot.docs
            .map((doc) => _parseOrder(doc.data(), doc.id))
            .whereType<OrderModel>()
            .where((o) =>
                !o.createdAt.isBefore(start) && o.createdAt.isBefore(end))
            .toList();
        orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return orders;
      } catch (e2) {
        if (kDebugMode) debugPrint('주문 조회 폴백 오류: $e2');
        return [];
      }
    }
  }

  static OrderModel? _parseOrder(Map<String, dynamic> data, String docId) {
    try {
      final rawItems = data['items'] as List<dynamic>? ?? [];
      final items = rawItems.map((item) {
        final m = item as Map<String, dynamic>;
        return OrderItem(
          productId: m['productId'] as String? ?? '',
          productName: m['productName'] as String? ?? '',
          size: m['size'] as String? ?? '',
          color: m['color'] as String? ?? '',
          quantity: (m['quantity'] as num?)?.toInt() ?? 1,
          price: (m['price'] as num?)?.toDouble() ?? 0,
          customOptions: m['customOptions'] as Map<String, dynamic>?,
        );
      }).toList();

      final statusStr = data['status'] as String? ?? 'pending';
      final status = OrderStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => OrderStatus.pending,
      );

      DateTime createdAt;
      final raw = data['createdAt'];
      if (raw is Timestamp) {
        createdAt = raw.toDate();
      } else if (raw is String) {
        createdAt = DateTime.tryParse(raw) ?? DateTime.now();
      } else {
        createdAt = DateTime.now();
      }

      return OrderModel(
        id: docId,
        userId: data['userId'] as String? ?? '',
        userName: data['userName'] as String? ?? '',
        userEmail: data['userEmail'] as String? ?? '',
        userPhone: data['userPhone'] as String? ?? '',
        userAddress: data['userAddress'] as String? ?? '',
        items: items,
        totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
        shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0,
        paymentMethod: data['paymentMethod'] as String? ?? '',
        status: status,
        orderType: data['orderType'] as String? ?? 'personal',
        customOptions: data['customOptions'] as Map<String, dynamic>?,
        groupName: data['groupName'] as String?,
        groupCount: (data['groupCount'] as num?)?.toInt(),
        createdAt: createdAt,
        memo: data['memo'] as String?,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('주문 파싱 오류: $e');
      return null;
    }
  }

  // ── 엑셀 파일 생성 (Uint8List 반환) ──
  static Uint8List generateExcel(
      List<OrderModel> orders, DateTime start, DateTime end) {
    final excel = Excel.createExcel();

    // ══════════════════════════════════
    // 단체/커스텀 주문만 필터링
    // ══════════════════════════════════
    final groupOrders = orders.where((o) =>
        o.orderType == 'group' ||
        o.orderType == 'additional' ||
        (o.customOptions != null && o.customOptions!.isNotEmpty) ||
        o.items.any((i) => i.customOptions != null && i.customOptions!.isNotEmpty)
    ).toList();

    // ══════════════════════════════════
    // 시트 1: 주문 요약 (단체/커스텀)
    // ══════════════════════════════════
    final summarySheet = excel['주문요약'];
    excel.setDefaultSheet('주문요약');

    // 헤더 스타일
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final subHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2D2D5E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'),
      fontColorHex: ExcelColor.fromHexString('#E65100'),
    );
    final evenRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
    );

    // 타이틀 행
    _setCell(summarySheet, 0, 0,
        '2FIT MALL 단체/커스텀 주문 내역 (${_fmt(start)} ~ ${_fmt(end)})',
        style: headerStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: 0));

    // 통계 행
    final totalOrders = groupOrders.length;
    final pendingCount =
        groupOrders.where((o) => o.status == OrderStatus.pending).length;
    final confirmedCount =
        groupOrders.where((o) => o.status == OrderStatus.confirmed).length;
    final shippingCount =
        groupOrders.where((o) => o.status == OrderStatus.shipped).length;
    final deliveredCount =
        groupOrders.where((o) => o.status == OrderStatus.delivered).length;

    _setCell(summarySheet, 1, 0, '총 주문 수', style: subHeaderStyle);
    _setCell(summarySheet, 1, 1, '$totalOrders건');
    _setCell(summarySheet, 1, 2, '대기', style: subHeaderStyle);
    _setCell(summarySheet, 1, 3, '$pendingCount건');
    _setCell(summarySheet, 1, 4, '확인', style: subHeaderStyle);
    _setCell(summarySheet, 1, 5, '$confirmedCount건');
    _setCell(summarySheet, 1, 6, '배송중', style: subHeaderStyle);
    _setCell(summarySheet, 1, 7, '$shippingCount건');
    _setCell(summarySheet, 1, 8, '배송완료', style: subHeaderStyle);
    _setCell(summarySheet, 1, 9, '$deliveredCount건');

    // 빈 행
    _setCell(summarySheet, 2, 0, '');

    // 컬럼 헤더 (이메일·단가·상품금액·배송비·총결제금액·결제수단·주문유형 제거)
    // No | 주문번호 | 주문일시 | 주문자 | 연락처 | 배송지 | 상품명 | 사이즈 | 컬러 | 수량 | 단체명 | 단체수량 | 주문상태 | 메모
    final headers = [
      'No', '주문번호', '주문일시', '주문자', '연락처',
      '배송지', '상품명', '사이즈', '컬러', '수량',
      '단체명', '단체수량', '주문상태', '메모',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(summarySheet, 3, i, headers[i], style: subHeaderStyle);
    }

    // 데이터 행
    int rowIdx = 4;
    int orderNo = 1;
    for (final order in groupOrders) {
      final isEven = (orderNo % 2 == 0);
      final rowStyle = isEven ? evenRowStyle : null;

      if (order.items.isEmpty) {
        _setCell(summarySheet, rowIdx, 0, '$orderNo', style: rowStyle);
        _setCell(summarySheet, rowIdx, 1, _shortId(order.id), style: rowStyle);
        _setCell(summarySheet, rowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
        _setCell(summarySheet, rowIdx, 3, order.userName, style: rowStyle);
        _setCell(summarySheet, rowIdx, 4, order.userPhone, style: rowStyle);
        _setCell(summarySheet, rowIdx, 5, order.userAddress, style: rowStyle);
        _setCell(summarySheet, rowIdx, 6, '-', style: rowStyle);
        _setCell(summarySheet, rowIdx, 7, '-', style: rowStyle);
        _setCell(summarySheet, rowIdx, 8, '-', style: rowStyle);
        _setCell(summarySheet, rowIdx, 9, 0, style: rowStyle);
        _setCell(summarySheet, rowIdx, 10, order.groupName ?? '', style: rowStyle);
        _setCell(summarySheet, rowIdx, 11, order.groupCount ?? '', style: rowStyle);
        _setCell(summarySheet, rowIdx, 12, _statusLabel(order.status), style: rowStyle);
        _setCell(summarySheet, rowIdx, 13, order.memo ?? '', style: rowStyle);
        rowIdx++;
      } else {
        for (var itemIdx = 0; itemIdx < order.items.length; itemIdx++) {
          final item = order.items[itemIdx];
          final isFirst = itemIdx == 0;

          _setCell(summarySheet, rowIdx, 0, isFirst ? '$orderNo' : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 1, isFirst ? _shortId(order.id) : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 2, isFirst ? _fmtFull(order.createdAt) : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 3, isFirst ? order.userName : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 4, isFirst ? order.userPhone : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 5, isFirst ? order.userAddress : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 6, item.productName, style: rowStyle);
          _setCell(summarySheet, rowIdx, 7, item.size, style: rowStyle);
          _setCell(summarySheet, rowIdx, 8, item.color, style: rowStyle);
          _setCell(summarySheet, rowIdx, 9, item.quantity, style: rowStyle);
          _setCell(summarySheet, rowIdx, 10, isFirst ? (order.groupName ?? '') : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 11, isFirst ? (order.groupCount ?? '') : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 12, isFirst ? _statusLabel(order.status) : '', style: rowStyle);

          // 메모 + 커스텀 옵션 합산
          String memoText = isFirst ? (order.memo ?? '') : '';
          if (item.customOptions != null && item.customOptions!.isNotEmpty) {
            final opts = item.customOptions!.entries
                .map((e) => '${e.key}: ${e.value}')
                .join(' / ');
            memoText = memoText.isEmpty ? '[$opts]' : '$memoText [$opts]';
          }
          _setCell(summarySheet, rowIdx, 13, memoText, style: rowStyle);

          rowIdx++;
        }
      }
      orderNo++;
    }

    // 합계 행
    _setCell(summarySheet, rowIdx, 0, '합계', style: totalStyle);
    _setCell(summarySheet, rowIdx, 9,
        groupOrders.fold<int>(0, (s, o) => s + o.items.fold<int>(0, (si, i) => si + i.quantity)),
        style: totalStyle);

    // 열 너비 설정 (14컬럼)
    final colWidths = [
      6.0,  // No
      20.0, // 주문번호
      18.0, // 주문일시
      10.0, // 주문자
      14.0, // 연락처
      30.0, // 배송지
      22.0, // 상품명
      8.0,  // 사이즈
      10.0, // 컬러
      6.0,  // 수량
      14.0, // 단체명
      8.0,  // 단체수량
      10.0, // 주문상태
      30.0, // 메모
    ];
    for (var i = 0; i < colWidths.length; i++) {
      summarySheet.setColumnWidth(i, colWidths[i]);
    }

    // ══════════════════════════════════
    // 시트 2: 배송 목록 (간략)
    // ══════════════════════════════════
    final deliverySheet = excel['배송목록'];

    final deliveryHeaders = [
      'No', '주문번호', '주문일시', '수령인', '연락처', '배송지',
      '상품명(사이즈/컬러/수량)', '결제금액', '배송비', '주문상태', '메모',
    ];
    for (var i = 0; i < deliveryHeaders.length; i++) {
      _setCell(deliverySheet, 0, i, deliveryHeaders[i], style: subHeaderStyle);
    }

    int dRowIdx = 1;
    int dNo = 1;
    for (final order in groupOrders) {
      final itemsSummary = order.items
          .map((it) => '${it.productName}(${it.size}/${it.color}×${it.quantity})')
          .join('\n');

      final isEven = (dNo % 2 == 0);
      final rowStyle = isEven ? evenRowStyle : null;

      _setCell(deliverySheet, dRowIdx, 0, '$dNo', style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 1, _shortId(order.id), style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 3, order.userName, style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 4, order.userPhone, style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 5, order.userAddress, style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 6, itemsSummary, style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 7, order.totalAmount.toInt(), style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 8, order.shippingFee.toInt(), style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 9, _statusLabel(order.status), style: rowStyle);
      _setCell(deliverySheet, dRowIdx, 10, order.memo ?? '', style: rowStyle);

      dRowIdx++;
      dNo++;
    }

    final deliveryColWidths = [6.0, 20.0, 18.0, 10.0, 14.0, 35.0, 40.0, 14.0, 10.0, 10.0, 25.0];
    for (var i = 0; i < deliveryColWidths.length; i++) {
      deliverySheet.setColumnWidth(i, deliveryColWidths[i]);
    }

    // ══════════════════════════════════
    // 시트 3: 상품별 집계
    // ══════════════════════════════════
    final productSheet = excel['상품별집계'];

    // 상품별 집계 계산 (단체/커스텀만)
    final productMap = <String, Map<String, dynamic>>{};
    for (final order in groupOrders) {
      for (final item in order.items) {
        final key = '${item.productName}__${item.size}__${item.color}';
        if (productMap.containsKey(key)) {
          productMap[key]!['quantity'] =
              (productMap[key]!['quantity'] as int) + item.quantity;
          productMap[key]!['amount'] =
              (productMap[key]!['amount'] as double) + item.price * item.quantity;
        } else {
          productMap[key] = {
            'productName': item.productName,
            'size': item.size,
            'color': item.color,
            'price': item.price,
            'quantity': item.quantity,
            'amount': item.price * item.quantity,
          };
        }
      }
    }

    final productHeaders2 = ['상품명', '사이즈', '컬러', '단가', '총수량', '총금액'];
    for (var i = 0; i < productHeaders2.length; i++) {
      _setCell(productSheet, 0, i, productHeaders2[i], style: subHeaderStyle);
    }

    final productList = productMap.values.toList()
      ..sort((a, b) =>
          (b['amount'] as double).compareTo(a['amount'] as double));

    int pRowIdx = 1;
    for (final p in productList) {
      final isEven = (pRowIdx % 2 == 0);
      final rowStyle = isEven ? evenRowStyle : null;
      _setCell(productSheet, pRowIdx, 0, p['productName'], style: rowStyle);
      _setCell(productSheet, pRowIdx, 1, p['size'], style: rowStyle);
      _setCell(productSheet, pRowIdx, 2, p['color'], style: rowStyle);
      _setCell(productSheet, pRowIdx, 3, (p['price'] as double).toInt(), style: rowStyle);
      _setCell(productSheet, pRowIdx, 4, p['quantity'], style: rowStyle);
      _setCell(productSheet, pRowIdx, 5, (p['amount'] as double).toInt(), style: rowStyle);
      pRowIdx++;
    }

    // 합계
    _setCell(productSheet, pRowIdx, 0, '합계', style: totalStyle);
    _setCell(productSheet, pRowIdx, 4,
        productMap.values.fold<int>(0, (s, p) => s + (p['quantity'] as int)),
        style: totalStyle);
    _setCell(productSheet, pRowIdx, 5,
        productMap.values.fold<double>(0, (s, p) => s + (p['amount'] as double)).toInt(),
        style: totalStyle);

    final productColWidths = [25.0, 10.0, 12.0, 12.0, 10.0, 14.0];
    for (var i = 0; i < productColWidths.length; i++) {
      productSheet.setColumnWidth(i, productColWidths[i]);
    }

    // ══════════════════════════════════
    // 시트 4: 단체주문 팀원 명단 (group/additional만)
    // ══════════════════════════════════
    final groupPersonSheet = excel['팀원명단'];

    final personHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4A148C'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final gpHeaders = ['No', '주문번호', '팀명', '이름', '성별', '상의 사이즈', '하의 사이즈', '메인 색상', '커스텀 옵션'];
    for (var i = 0; i < gpHeaders.length; i++) {
      _setCell(groupPersonSheet, 0, i, gpHeaders[i], style: personHeaderStyle);
    }

    int gpRowIdx = 1;
    int gpNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final persons = (opts['persons'] as List<dynamic>?) ?? [];
      if (persons.isEmpty) continue;

      final teamName = opts['teamName']?.toString() ?? '-';
      final mainColor = opts['mainColor']?.toString() ?? '-';
      final printLabel = opts['printTypeLabel']?.toString() ?? '-';

      for (final pEntry in persons) {
        final p = pEntry as Map<String, dynamic>;
        final isEven2 = gpNo % 2 == 0;
        final rowStyle2 = isEven2 ? evenRowStyle : null;
        _setCell(groupPersonSheet, gpRowIdx, 0, '$gpNo', style: rowStyle2);
        _setCell(groupPersonSheet, gpRowIdx, 1, _shortId(order.id), style: rowStyle2);
        _setCell(groupPersonSheet, gpRowIdx, 2, teamName, style: rowStyle2);
        _setCell(groupPersonSheet, gpRowIdx, 3, p['name']?.toString() ?? '-', style: rowStyle2);
        _setCell(groupPersonSheet, gpRowIdx, 4, p['gender']?.toString() ?? '-', style: rowStyle2);
        _setCell(groupPersonSheet, gpRowIdx, 5, p['topSize']?.toString() ?? '-', style: rowStyle2);
        _setCell(groupPersonSheet, gpRowIdx, 6, p['bottomSize']?.toString() ?? '-', style: rowStyle2);
        _setCell(groupPersonSheet, gpRowIdx, 7, mainColor, style: rowStyle2);
        _setCell(groupPersonSheet, gpRowIdx, 8, printLabel, style: rowStyle2);
        gpRowIdx++;
        gpNo++;
      }
    }

    final gpColWidths = [6.0, 20.0, 14.0, 12.0, 8.0, 14.0, 14.0, 12.0, 22.0];
    for (var i = 0; i < gpColWidths.length; i++) {
      groupPersonSheet.setColumnWidth(i, gpColWidths[i]);
    }

    // 기본 시트 설정
    excel.setDefaultSheet('주문요약');

    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  // ── 헬퍼 함수들 ──

  static void _setCell(Sheet sheet, int row, int col, dynamic value,
      {CellStyle? style}) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else if (value is String) {
      cell.value = TextCellValue(value);
    } else if (value == '') {
      cell.value = TextCellValue('');
    } else {
      cell.value = TextCellValue(value.toString());
    }
    if (style != null) cell.cellStyle = style;
  }

  static String _shortId(String id) =>
      id.length > 12 ? id.substring(0, 12) : id;

  static String _fmt(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:00';

  static String _fmtFull(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _krw(double v) =>
      '₩${v.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  static String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return '주문대기';
      case OrderStatus.confirmed: return '주문확인';
      case OrderStatus.processing: return '제작중';
      case OrderStatus.shipped: return '배송중';
      case OrderStatus.delivered: return '배송완료';
      case OrderStatus.cancelled: return '취소';
      default: return s.name;
    }
  }

  static String _orderTypeLabel(String t) {
    switch (t) {
      case 'personal': return '개인';
      case 'group': return '단체';
      case 'additional': return '추가제작';
      default: return t;
    }
  }

  // ══════════════════════════════════
  // 단체주문 개별 엑셀 생성
  // ══════════════════════════════════
  static Uint8List generateGroupOrderExcel(OrderModel order) {
    final excel = Excel.createExcel();
    final opts = order.customOptions ?? {};
    final persons = (opts['persons'] as List<dynamic>?) ?? [];

    // ── 시트 1: 주문 요약 ──
    final summarySheet = excel['주문정보'];
    excel.setDefaultSheet('주문정보');

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#6A1B9A'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final labelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#F3E5F5'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
    );

    // 타이틀
    _setCell(summarySheet, 0, 0, '2FIT 단체주문 주문서', style: headerStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0));

    // 주문 기본정보
    final infoRows = [
      ['주문번호', order.id],
      ['주문일시', _fmtFull(order.createdAt)],
      ['단체명/팀명', opts['teamName']?.toString() ?? '-'],
      ['담당자', opts['managerName']?.toString() ?? order.userName],
      ['연락처', order.userPhone],
      ['이메일', order.userEmail],
      ['배송지', order.userAddress],
      ['총 인원', '${opts['totalCount'] ?? 0}명'],
      ['남/여', '남 ${opts['maleCount'] ?? 0}명 / 여 ${opts['femaleCount'] ?? 0}명'],
      ['커스텀 옵션', opts['printTypeLabel']?.toString() ?? '-'],
      ['메인 색상', opts['mainColor']?.toString() ?? '-'],
      ['원단 종류', opts['fabricType']?.toString() ?? '-'],
      ['원단 무게', opts['fabricWeight']?.toString() ?? '-'],
      ['허리밴드', opts['waistbandOption']?.toString() ?? '-'],
      ['주문 상태', _statusLabel(order.status)],
      ['결제 금액', '${order.totalAmount.toInt()}원'],
      ['메모', opts['memoText']?.toString() ?? order.memo ?? '-'],
    ];

    for (var i = 0; i < infoRows.length; i++) {
      _setCell(summarySheet, i + 2, 0, infoRows[i][0], style: labelStyle);
      _setCell(summarySheet, i + 2, 1, infoRows[i][1]);
    }

    summarySheet.setColumnWidth(0, 18.0);
    summarySheet.setColumnWidth(1, 40.0);

    // ── 시트 2: 팀원 명단 ──
    final personSheet = excel['팀원명단'];

    final personHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final evenStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'));
    final maleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
      fontColorHex: ExcelColor.fromHexString('#1565C0'),
      bold: true,
    );
    final femaleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FCE4EC'),
      fontColorHex: ExcelColor.fromHexString('#C62828'),
      bold: true,
    );

    // 팀명 표시
    _setCell(personSheet, 0, 0, '팀명: ${opts['teamName'] ?? '-'}  /  총 ${persons.length}명', style: headerStyle);
    personSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0));

    // 컬럼 헤더
    final pHeaders = ['No', '이름', '성별', '상의 사이즈', '하의 사이즈', '비고'];
    for (var i = 0; i < pHeaders.length; i++) {
      _setCell(personSheet, 1, i, pHeaders[i], style: personHeaderStyle);
    }

    // 데이터
    for (var i = 0; i < persons.length; i++) {
      final p = persons[i] as Map<String, dynamic>;
      final rowStyle = i % 2 == 0 ? evenStyle : null;
      final gStyle = p['gender'] == '남' ? maleStyle : (p['gender'] == '여' ? femaleStyle : null);

      _setCell(personSheet, i + 2, 0, '${p['index'] ?? i + 1}', style: rowStyle);
      _setCell(personSheet, i + 2, 1, p['name']?.toString() ?? '-', style: rowStyle);
      _setCell(personSheet, i + 2, 2, p['gender']?.toString() ?? '-', style: gStyle);
      _setCell(personSheet, i + 2, 3, p['topSize']?.toString() ?? '-', style: rowStyle);
      _setCell(personSheet, i + 2, 4, p['bottomSize']?.toString() ?? '-', style: rowStyle);
      // 비고: 커스텀 사이즈 여부
      final useCustom = p['useCustom'] == true;
      if (useCustom) {
        final h = p['customHeight']?.toString() ?? '';
        final w = p['customWeight']?.toString() ?? '';
        _setCell(personSheet, i + 2, 5, '키:${h}cm 몸무게:${w}kg', style: rowStyle);
      } else {
        _setCell(personSheet, i + 2, 5, '', style: rowStyle);
      }
    }

    // 합계 행
    final totalStyle2 = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
    );
    _setCell(personSheet, persons.length + 2, 0, '합계', style: totalStyle2);
    _setCell(personSheet, persons.length + 2, 1, '${persons.length}명', style: totalStyle2);
    _setCell(personSheet, persons.length + 2, 2, '남 ${opts['maleCount'] ?? 0}명 / 여 ${opts['femaleCount'] ?? 0}명', style: totalStyle2);

    personSheet.setColumnWidth(0, 6.0);
    personSheet.setColumnWidth(1, 14.0);
    personSheet.setColumnWidth(2, 8.0);
    personSheet.setColumnWidth(3, 14.0);
    personSheet.setColumnWidth(4, 14.0);
    personSheet.setColumnWidth(5, 22.0);

    excel.setDefaultSheet('주문정보');
    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  const DateTimeRange({required this.start, required this.end});
}
