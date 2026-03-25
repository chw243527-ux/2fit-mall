// order_excel_service.dart — 주문 엑셀 내보내기 서비스 (개선판)
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class OrderExcelService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── 전날 오후1시 ~ 당일 오후1시 날짜 계산 ──
  static DateTimeRange getDailyRange({DateTime? baseDate}) {
    final now = baseDate ?? DateTime.now();
    final todayAt1pm = DateTime(now.year, now.month, now.day, 13, 0, 0);
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

  // ── 이미지 URL → Base64 변환 (웹 환경용) ──
  static Future<String?> _fetchImageBase64(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      // Base64 데이터 URL인 경우
      if (url.startsWith('data:image')) {
        final base64Part = url.split(',').last;
        return base64Part;
      }
      // HTTP URL인 경우 다운로드
      if (url.startsWith('http')) {
        final response = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          return base64Encode(response.bodyBytes);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('이미지 로드 실패: $e');
    }
    return null;
  }

  // ── 일일 마감 엑셀 생성 (전날 13시~당일 13시, 단체주문 전용) ──
  // 이미지 삽입을 위해 async로 변경
  static Future<Uint8List> generateDailyGroupOrderExcel(
      List<OrderModel> orders, DateTime start, DateTime end) async {
    final excel = Excel.createExcel();

    // 단체/커스텀 주문만 필터링
    final groupOrders = orders.where((o) =>
        o.orderType == 'group' ||
        o.orderType == 'additional' ||
        (o.customOptions != null && o.customOptions!.isNotEmpty)).toList();

    // ── 스타일 정의 ──
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final subHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4A148C'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final labelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#F3E5F5'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
    );
    final evenRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FAFAFA'),
    );
    final totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1B5E20'),
    );
    final warningStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFF8E1'),
      fontColorHex: ExcelColor.fromHexString('#E65100'),
    );

    // ══════════════════════════════════
    // 시트 1: 단체주문 요약
    // ══════════════════════════════════
    final summarySheet = excel['단체주문요약'];
    excel.setDefaultSheet('단체주문요약');

    // 타이틀
    _setCell(summarySheet, 0, 0,
        '2FIT MALL 단체주문 일일마감 (${_fmt(start)} ~ ${_fmt(end)})',
        style: headerStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: 0));

    // 통계
    _setCell(summarySheet, 1, 0, '단체주문 총 ${groupOrders.length}건', style: subHeaderStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: 1));

    // 컬럼 헤더 (가격 제외, 단체주문 필요 정보)
    final headers = [
      'No', '주문번호', '주문날짜', '단체명', '담당자', '연락처',
      '구매옵션', '인원수', '남성', '여성',
      '메인색상', '하의길이', '원단종류', '커스텀옵션', '메모',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(summarySheet, 3, i, headers[i], style: subHeaderStyle);
    }

    int rowIdx = 4;
    int orderNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final isEven = orderNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : null;

      _setCell(summarySheet, rowIdx, 0, '$orderNo', style: rowStyle);
      _setCell(summarySheet, rowIdx, 1, _shortId(order.id), style: rowStyle);
      _setCell(summarySheet, rowIdx, 2, _fmtDate(order.createdAt), style: rowStyle);
      _setCell(summarySheet, rowIdx, 3, opts['teamName']?.toString() ?? order.groupName ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 4, opts['managerName']?.toString() ?? order.userName, style: rowStyle);
      _setCell(summarySheet, rowIdx, 5, _maskPhone(order.userPhone), style: rowStyle);
      _setCell(summarySheet, rowIdx, 6, opts['printTypeLabel']?.toString() ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 7, opts['totalCount'] ?? order.groupCount ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 8, opts['maleCount'] ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 9, opts['femaleCount'] ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 10, opts['mainColor']?.toString() ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 11, opts['defaultLength']?.toString() ?? '개별선택', style: rowStyle);
      _setCell(summarySheet, rowIdx, 12, opts['fabricType']?.toString() ?? '-', style: rowStyle);
      // 커스텀 옵션 요약
      final customSummary = _buildCustomSummary(opts);
      _setCell(summarySheet, rowIdx, 13, customSummary, style: rowStyle);
      _setCell(summarySheet, rowIdx, 14, opts['memoText']?.toString() ?? order.memo ?? '', style: rowStyle);

      rowIdx++;
      orderNo++;
    }

    // 합계
    _setCell(summarySheet, rowIdx, 0, '합계', style: totalStyle);
    final totalPersons = groupOrders.fold<int>(0, (s, o) {
      final cnt = o.customOptions?['totalCount'];
      return s + ((cnt as num?)?.toInt() ?? o.groupCount ?? 0);
    });
    _setCell(summarySheet, rowIdx, 7, totalPersons, style: totalStyle);

    final summaryColWidths = [
      6.0, 22.0, 16.0, 16.0, 12.0, 16.0,
      20.0, 8.0, 8.0, 8.0,
      14.0, 12.0, 14.0, 30.0, 25.0,
    ];
    for (var i = 0; i < summaryColWidths.length; i++) {
      summarySheet.setColumnWidth(i, summaryColWidths[i]);
    }

    // ══════════════════════════════════
    // 시트 2: 인원별 사이즈 내역
    // ══════════════════════════════════
    final sizeSheet = excel['인원별사이즈'];

    final sizeHeaders = [
      'No', '주문번호', '단체명', '인원번호', '이름', '성별',
      '상의사이즈', '하의사이즈', '하의길이', '메인색상', '비고',
    ];
    for (var i = 0; i < sizeHeaders.length; i++) {
      _setCell(sizeSheet, 0, i, sizeHeaders[i], style: subHeaderStyle);
    }

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

    int sRowIdx = 1;
    int sNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final persons = (opts['persons'] as List<dynamic>?) ?? [];
      if (persons.isEmpty) continue;

      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
      final mainColor = opts['mainColor']?.toString() ?? '-';
      final defaultLength = opts['defaultLength']?.toString() ?? '';

      for (var i = 0; i < persons.length; i++) {
        final p = persons[i] as Map<String, dynamic>;
        final gender = p['gender']?.toString() ?? '';
        final gStyle = gender == '남' ? maleStyle : (gender == '여' ? femaleStyle : null);

        _setCell(sizeSheet, sRowIdx, 0, '$sNo');
        _setCell(sizeSheet, sRowIdx, 1, _shortId(order.id));
        _setCell(sizeSheet, sRowIdx, 2, teamName);
        _setCell(sizeSheet, sRowIdx, 3, '${(p['index'] ?? i + 1)}번');
        _setCell(sizeSheet, sRowIdx, 4, p['name']?.toString() ?? '-', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 5, gender, style: gStyle);
        _setCell(sizeSheet, sRowIdx, 6, p['topSize']?.toString() ?? '-');
        _setCell(sizeSheet, sRowIdx, 7, p['bottomSize']?.toString() ?? '-');
        // 하의 길이: 개인 설정 or 기본값
        final personalLength = p['bottomLength']?.toString() ?? '';
        _setCell(sizeSheet, sRowIdx, 8, personalLength.isNotEmpty ? personalLength : defaultLength);
        _setCell(sizeSheet, sRowIdx, 9, mainColor);
        // 비고: 커스텀 사이즈 여부
        final note = p['useCustom'] == true
            ? '키:${p['customHeight'] ?? '-'}cm 몸무게:${p['customWeight'] ?? '-'}kg'
            : '';
        _setCell(sizeSheet, sRowIdx, 10, note);

        sRowIdx++;
        sNo++;
      }

      // 팀 구분선
      _setCell(sizeSheet, sRowIdx, 0, '── $teamName 팀 끝 ──', style: warningStyle);
      sizeSheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sRowIdx),
          CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: sRowIdx));
      sRowIdx++;
    }

    final sizeColWidths = [6.0, 22.0, 16.0, 10.0, 12.0, 8.0, 14.0, 14.0, 12.0, 14.0, 24.0];
    for (var i = 0; i < sizeColWidths.length; i++) {
      sizeSheet.setColumnWidth(i, sizeColWidths[i]);
    }

    // ══════════════════════════════════
    // 시트 3: 상품 이미지 & 주문 정보
    // 이미지 URL을 텍스트로 기록 (실제 삽입은 웹 제약으로 URL 기록)
    // ══════════════════════════════════
    final imageSheet = excel['디자인이미지'];

    final imgHeaders = ['No', '주문번호', '단체명', '상품명', '디자인이미지URL', '상품이미지URL', '커스텀옵션'];
    for (var i = 0; i < imgHeaders.length; i++) {
      _setCell(imageSheet, 0, i, imgHeaders[i], style: subHeaderStyle);
    }

    int imgRowIdx = 1;
    int imgNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';

      // 디자인 수정 요청 파일 URL (PDF 등)
      final designFileUrl = opts['designFileUrl']?.toString() ?? '';
      // 참조 이미지 URL (남/여)
      final maleRefUrl = opts['maleRefImageUrl']?.toString() ?? '';
      final femaleRefUrl = opts['femaleRefImageUrl']?.toString() ?? '';

      for (final item in order.items) {
        _setCell(imageSheet, imgRowIdx, 0, '$imgNo');
        _setCell(imageSheet, imgRowIdx, 1, _shortId(order.id));
        _setCell(imageSheet, imgRowIdx, 2, teamName);
        _setCell(imageSheet, imgRowIdx, 3, item.productName);
        // 디자인 이미지 URL (클릭 가능한 링크)
        final imgUrl = item.customOptions?['productImageUrl']?.toString() ??
            opts['productImageUrl']?.toString() ?? '-';
        _setCell(imageSheet, imgRowIdx, 4, designFileUrl.isNotEmpty ? designFileUrl : '-');
        _setCell(imageSheet, imgRowIdx, 5, imgUrl);
        _setCell(imageSheet, imgRowIdx, 6, opts['printTypeLabel']?.toString() ?? '-');

        imgRowIdx++;
        imgNo++;
      }

      // 남여 참조 이미지
      if (maleRefUrl.isNotEmpty || femaleRefUrl.isNotEmpty) {
        _setCell(imageSheet, imgRowIdx, 0, '(참조)');
        _setCell(imageSheet, imgRowIdx, 1, _shortId(order.id));
        _setCell(imageSheet, imgRowIdx, 2, teamName);
        _setCell(imageSheet, imgRowIdx, 3, '하의 참조이미지');
        _setCell(imageSheet, imgRowIdx, 4, '남자: $maleRefUrl / 여자: $femaleRefUrl');
        _setCell(imageSheet, imgRowIdx, 5, '-');
        _setCell(imageSheet, imgRowIdx, 6, '-');
        imgRowIdx++;
      }
    }

    final imgColWidths = [6.0, 22.0, 16.0, 24.0, 50.0, 50.0, 20.0];
    for (var i = 0; i < imgColWidths.length; i++) {
      imageSheet.setColumnWidth(i, imgColWidths[i]);
    }

    excel.setDefaultSheet('단체주문요약');
    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  // ── 기존 generateExcel (개인+단체 통합) 유지 ──
  static Uint8List generateExcel(
      List<OrderModel> orders, DateTime start, DateTime end) {
    final excel = Excel.createExcel();

    final groupOrders = orders.where((o) =>
        o.orderType == 'group' ||
        o.orderType == 'additional' ||
        (o.customOptions != null && o.customOptions!.isNotEmpty) ||
        o.items.any((i) => i.customOptions != null && i.customOptions!.isNotEmpty)
    ).toList();

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

    // 시트 1: 주문요약
    final summarySheet = excel['주문요약'];
    excel.setDefaultSheet('주문요약');

    _setCell(summarySheet, 0, 0,
        '2FIT MALL 단체/커스텀 주문 내역 (${_fmt(start)} ~ ${_fmt(end)})',
        style: headerStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: 0));

    final headers = [
      'No', '주문번호', '주문일시', '주문자', '연락처',
      '배송지', '상품명', '사이즈', '컬러', '수량',
      '단체명', '단체수량', '주문상태', '메모',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(summarySheet, 3, i, headers[i], style: subHeaderStyle);
    }

    int rowIdx = 4;
    int orderNo = 1;
    for (final order in groupOrders) {
      final isEven = orderNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : null;

      if (order.items.isEmpty) {
        _setCell(summarySheet, rowIdx, 0, '$orderNo', style: rowStyle);
        _setCell(summarySheet, rowIdx, 1, _shortId(order.id), style: rowStyle);
        _setCell(summarySheet, rowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
        _setCell(summarySheet, rowIdx, 3, order.userName, style: rowStyle);
        _setCell(summarySheet, rowIdx, 4, _maskPhone(order.userPhone), style: rowStyle);
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
          _setCell(summarySheet, rowIdx, 4, isFirst ? _maskPhone(order.userPhone) : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 5, isFirst ? order.userAddress : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 6, item.productName, style: rowStyle);
          _setCell(summarySheet, rowIdx, 7, item.size, style: rowStyle);
          _setCell(summarySheet, rowIdx, 8, item.color, style: rowStyle);
          _setCell(summarySheet, rowIdx, 9, item.quantity, style: rowStyle);
          _setCell(summarySheet, rowIdx, 10, isFirst ? (order.groupName ?? '') : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 11, isFirst ? (order.groupCount ?? '') : '', style: rowStyle);
          _setCell(summarySheet, rowIdx, 12, isFirst ? _statusLabel(order.status) : '', style: rowStyle);

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

    _setCell(summarySheet, rowIdx, 0, '합계', style: totalStyle);
    _setCell(summarySheet, rowIdx, 9,
        groupOrders.fold<int>(0, (s, o) => s + o.items.fold<int>(0, (si, i) => si + i.quantity)),
        style: totalStyle);

    final colWidths = [6.0, 20.0, 18.0, 10.0, 14.0, 30.0, 22.0, 8.0, 10.0, 6.0, 14.0, 8.0, 10.0, 30.0];
    for (var i = 0; i < colWidths.length; i++) {
      summarySheet.setColumnWidth(i, colWidths[i]);
    }

    excel.setDefaultSheet('주문요약');
    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  // ── 단체주문 개별 엑셀 생성 (개선판 — 이미지·모든 필드 포함, 가격 제외) ──
  static Future<Uint8List> generateGroupOrderExcelAsync(OrderModel order) async {
    return generateGroupOrderExcel(order);
  }

  static Uint8List generateGroupOrderExcel(OrderModel order) {
    final excel = Excel.createExcel();
    final opts = order.customOptions ?? {};
    final persons = (opts['persons'] as List<dynamic>?) ?? [];

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
    final subHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
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
    final evenStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
    );

    // ── 시트 1: 주문정보 (가격 제외, 모든 필드 포함) ──
    final summarySheet = excel['주문정보'];
    excel.setDefaultSheet('주문정보');

    // 타이틀
    _setCell(summarySheet, 0, 0, '2FIT 단체주문 주문서', style: headerStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0));

    // 이미지 URL 정보
    final productImageUrl = opts['productImageUrl']?.toString() ?? '';
    final designFileUrl = opts['designFileUrl']?.toString() ?? '';
    final maleRefUrl = opts['maleRefImageUrl']?.toString() ?? '';
    final femaleRefUrl = opts['femaleRefImageUrl']?.toString() ?? '';
    final bottomColorName = opts['bottomColorName']?.toString() ?? '';

    int imgRow = 1;
    if (productImageUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '[상세페이지 디자인 이미지]', style: labelStyle);
      _setCell(summarySheet, imgRow, 1, productImageUrl);
      _setCell(summarySheet, imgRow, 2, '※ URL을 클릭하거나 복사하여 브라우저에서 확인');
      imgRow++;
    }
    if (designFileUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '[디자인수정 PDF 첨부]', style: labelStyle);
      _setCell(summarySheet, imgRow, 1, designFileUrl);
      _setCell(summarySheet, imgRow, 2, '※ PDF 파일 링크');
      imgRow++;
    }
    if (maleRefUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '[남자 하의 참조이미지]', style: labelStyle);
      _setCell(summarySheet, imgRow, 1, maleRefUrl);
      imgRow++;
    }
    if (femaleRefUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '[여자 하의 참조이미지]', style: labelStyle);
      _setCell(summarySheet, imgRow, 1, femaleRefUrl);
      imgRow++;
    }

    // 주문 기본정보 (가격 제외)
    final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
    final mainColor = opts['mainColor']?.toString() ?? '-';
    final colorInfo = bottomColorName.isNotEmpty
        ? '상의: $mainColor / 하의: $bottomColorName'
        : mainColor;

    final infoRows = [
      ['주문번호', order.id],
      ['주문날짜', _fmtFull(order.createdAt)],
      ['단체명/팀명', teamName],
      ['담당자', opts['managerName']?.toString() ?? order.userName],
      ['연락처', _maskPhone(order.userPhone)],
      ['이메일', _maskEmail(order.userEmail)],
      ['배송지', order.userAddress],
      ['총 인원', '${opts['totalCount'] ?? order.groupCount ?? 0}명'],
      ['남/여 구분', '남 ${opts['maleCount'] ?? 0}명 / 여 ${opts['femaleCount'] ?? 0}명'],
      ['구매옵션(커스텀)', opts['printTypeLabel']?.toString() ?? '-'],
      ['색상', colorInfo],
      ['하의 기본길이', opts['defaultLength']?.toString() ?? '개별선택'],
      ['원단 종류', opts['fabricType']?.toString() ?? '-'],
      ['원단 무게', opts['fabricWeight']?.toString() ?? '-'],
      ['허리밴드', opts['waistbandOption']?.toString() ?? '-'],
      ['독점디자인 여부', opts['exclusiveDesign'] == true ? '예' : '아니오'],
      ['추가제작 여부', order.orderType == 'additional' ? '추가제작주문' : '신규주문'],
      ['주문 상태', _statusLabel(order.status)],
      ['메모', opts['memoText']?.toString() ?? order.memo ?? '-'],
    ];

    final startRow = imgRow + 1;
    for (var i = 0; i < infoRows.length; i++) {
      _setCell(summarySheet, startRow + i, 0, infoRows[i][0], style: labelStyle);
      _setCell(summarySheet, startRow + i, 1, infoRows[i][1]);
    }

    summarySheet.setColumnWidth(0, 22.0);
    summarySheet.setColumnWidth(1, 55.0);
    summarySheet.setColumnWidth(2, 30.0);

    // ── 시트 2: 인원별 사이즈 상세 명단 ──
    final personSheet = excel['팀원별사이즈명단'];

    final teamNameForSheet = opts['teamName']?.toString() ?? order.groupName ?? '-';
    final mainColorForSheet = opts['mainColor']?.toString() ?? '-';
    final bottomColorForSheet = opts['bottomColorName']?.toString() ?? '';
    final colorDisplay = bottomColorForSheet.isNotEmpty
        ? '상의:$mainColorForSheet / 하의:$bottomColorForSheet'
        : mainColorForSheet;

    _setCell(personSheet, 0, 0,
        '팀명: $teamNameForSheet  |  총 ${persons.length}명  |  색상: $colorDisplay  |  하의길이: ${opts['defaultLength'] ?? '개별선택'}',
        style: headerStyle);
    personSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0));

    // 인원별 헤더 (인원번호, 이름, 성별, 상의사이즈, 하의사이즈, 하의길이, 색상, 비고)
    final pHeaders = ['No', '이름', '성별', '상의 사이즈', '하의 사이즈', '하의 길이', '색상', '비고'];
    for (var i = 0; i < pHeaders.length; i++) {
      _setCell(personSheet, 1, i, pHeaders[i], style: subHeaderStyle);
    }

    final defaultLength = opts['defaultLength']?.toString() ?? '';
    for (var i = 0; i < persons.length; i++) {
      final p = persons[i] as Map<String, dynamic>;
      final rowStyle = i % 2 == 0 ? evenStyle : null;
      final gender = p['gender']?.toString() ?? '';
      final gStyle = gender == '남' ? maleStyle : (gender == '여' ? femaleStyle : rowStyle);

      _setCell(personSheet, i + 2, 0, '${p['index'] ?? i + 1}', style: rowStyle);
      _setCell(personSheet, i + 2, 1, p['name']?.toString() ?? '-', style: gStyle);
      _setCell(personSheet, i + 2, 2, gender, style: gStyle);
      _setCell(personSheet, i + 2, 3, p['topSize']?.toString() ?? '-', style: rowStyle);
      _setCell(personSheet, i + 2, 4, p['bottomSize']?.toString() ?? '-', style: rowStyle);
      // 하의 길이: 개인 선택 우선, 없으면 기본값
      final personalLength = p['bottomLength']?.toString() ?? '';
      _setCell(personSheet, i + 2, 5,
          personalLength.isNotEmpty ? personalLength : (defaultLength.isNotEmpty ? defaultLength : '개별선택'),
          style: rowStyle);
      // 색상: 개인 색상 있으면 표시, 없으면 기본 색상
      final personColor = p['color']?.toString() ?? '';
      _setCell(personSheet, i + 2, 6,
          personColor.isNotEmpty ? personColor : mainColorForSheet, style: rowStyle);
      // 비고: 커스텀 사이즈 정보
      final useCustom = p['useCustom'] == true;
      _setCell(personSheet, i + 2, 7,
          useCustom ? '키:${p['customHeight'] ?? '-'}cm / 몸무게:${p['customWeight'] ?? '-'}kg' : '',
          style: rowStyle);
    }

    // 합계
    final totalStyle2 = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
    );
    _setCell(personSheet, persons.length + 2, 0, '합계', style: totalStyle2);
    _setCell(personSheet, persons.length + 2, 1, '${persons.length}명', style: totalStyle2);
    _setCell(personSheet, persons.length + 2, 2,
        '남 ${opts['maleCount'] ?? 0}명 / 여 ${opts['femaleCount'] ?? 0}명',
        style: totalStyle2);

    final pColWidths = [6.0, 14.0, 8.0, 16.0, 16.0, 12.0, 16.0, 28.0];
    for (var i = 0; i < pColWidths.length; i++) {
      personSheet.setColumnWidth(i, pColWidths[i]);
    }

    excel.setDefaultSheet('주문정보');
    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  // ── 커스텀 옵션 요약 문자열 생성 ──
  static String _buildCustomSummary(Map<String, dynamic> opts) {
    final parts = <String>[];
    if ((opts['printTypeLabel'] as String?)?.isNotEmpty == true) {
      parts.add(opts['printTypeLabel']!);
    }
    if ((opts['waistbandOption'] as String?) != null) {
      parts.add('허리밴드:${opts['waistbandOption']}');
    }
    if (opts['exclusiveDesign'] == true) {
      parts.add('독점디자인');
    }
    return parts.join(' / ');
  }

  // ── 개인정보 마스킹 ──
  static String _maskPhone(String phone) {
    if (phone.length < 8) return phone;
    // 010-XXXX-1234 → 010-****-1234
    return phone.replaceRange(
        phone.indexOf('-') + 1,
        phone.lastIndexOf('-'),
        '****');
  }

  static String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final local = parts[0];
    final masked = local.length > 2
        ? '${local.substring(0, 2)}***'
        : '${local[0]}***';
    return '$masked@${parts[1]}';
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
      id.length > 16 ? id.substring(0, 16) : id;

  static String _fmt(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:00';

  static String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _fmtFull(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  const DateTimeRange({required this.start, required this.end});
}
