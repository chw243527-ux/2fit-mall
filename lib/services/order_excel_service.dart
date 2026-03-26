// order_excel_service.dart — 주문 엑셀 내보내기 서비스 (전면 개선판)
// 포함 항목: 디자인이미지URL, 주문날짜, 키/몸무게/허리/허벅지, 이름, 인쇄옵션,
//            하의길이, 색상, 수량, 성별, 허리밴드
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

      Map<String, dynamic>? customOptions;
      final rawOpts = data['customOptions'];
      if (rawOpts is Map) {
        customOptions = Map<String, dynamic>.from(rawOpts);
      } else {
        customOptions = {};
      }
      if ((customOptions['persons'] == null ||
          (customOptions['persons'] as List?)?.isEmpty == true)) {
        final topPersons = data['persons'];
        if (topPersons is List && topPersons.isNotEmpty) {
          customOptions['persons'] = topPersons;
        }
      }
      if (customOptions['teamName'] == null ||
          (customOptions['teamName'] as String?)?.isEmpty == true) {
        final gn = data['groupName'] as String?;
        if (gn != null && gn.isNotEmpty) customOptions['teamName'] = gn;
      }
      if (customOptions['totalCount'] == null) {
        final gc = data['groupCount'];
        if (gc != null) customOptions['totalCount'] = gc;
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
        customOptions: customOptions.isEmpty ? null : customOptions,
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
      if (url.startsWith('data:image')) {
        final base64Part = url.split(',').last;
        return base64Part;
      }
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

  // ════════════════════════════════════════════════════════════════
  // 선택 주문 엑셀 생성 (관리자가 체크박스로 선택한 주문들)
  // ════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateSelectedOrdersExcel(
      List<OrderModel> orders, DateTime exportedAt) async {
    final excel = Excel.createExcel();

    // ── 스타일 정의 ──
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 13,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2D2D5E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 11,
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
    final evenRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
    );
    final totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1B5E20'),
    );
    final labelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'),
      fontColorHex: ExcelColor.fromHexString('#E65100'),
    );
    final separatorStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#EEEEEE'),
      fontColorHex: ExcelColor.fromHexString('#555555'),
    );
    final detailStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E8EAF6'),
      fontColorHex: ExcelColor.fromHexString('#283593'),
    );

    // 단체/커스텀 주문과 개인 주문 분리
    final groupOrders = orders.where((o) =>
        o.orderType == 'group' ||
        o.orderType == 'additional' ||
        (o.customOptions != null && o.customOptions!.isNotEmpty)).toList();

    final personalOrders = orders.where((o) =>
        o.orderType == 'regular' || o.orderType == 'personal' ||
        (o.customOptions == null || o.customOptions!.isEmpty)).toList();

    // ══════════════════════════════════════════════════════════
    // 시트 1: 전체 주문 요약
    // ══════════════════════════════════════════════════════════
    final summarySheet = excel['주문요약'];
    excel.setDefaultSheet('주문요약');

    _setCell(summarySheet, 0, 0,
        '2FIT MALL 선택 주문 내역 (${orders.length}건) — 출력: ${_fmtFull(exportedAt)}',
        style: titleStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0));
    summarySheet.setRowHeight(0, 24);

    // 통계 행
    _setCell(summarySheet, 1, 0, '단체/커스텀: ${groupOrders.length}건', style: labelStyle);
    _setCell(summarySheet, 1, 2, '개인주문: ${personalOrders.length}건', style: labelStyle);
    _setCell(summarySheet, 1, 4, '총 수량: ${orders.fold<int>(0, (s, o) => s + o.items.fold<int>(0, (si, i) => si + i.quantity))}개', style: totalStyle);

    // 헤더 (17컬럼)
    final summaryHeaders = [
      'No', '주문번호', '주문날짜', '주문유형', '단체명/팀명',
      '주문자', '연락처', '상품명', '색상', '인쇄옵션',
      '하의길이', '허리밴드', '총수량', '남성', '여성',
      '디자인이미지URL', '상태',
    ];
    for (var i = 0; i < summaryHeaders.length; i++) {
      _setCell(summarySheet, 3, i, summaryHeaders[i], style: headerStyle);
    }

    int rowIdx = 4;
    int orderNo = 1;
    for (final order in orders) {
      final opts = order.customOptions ?? {};
      final isGroup = order.orderType == 'group' || order.orderType == 'additional';
      final isEven = orderNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : null;

      // 디자인 이미지 URL 추출
      final imageUrl = _extractDesignImageUrl(order);
      // 색상 추출
      final colorInfo = _extractColorInfo(order);
      // 남/여 인원 계산
      final maleCount = _countGender(order, '남');
      final femaleCount = _countGender(order, '여');
      final totalQty = order.items.fold<int>(0, (s, i) => s + i.quantity);

      _setCell(summarySheet, rowIdx, 0, '$orderNo', style: rowStyle);
      _setCell(summarySheet, rowIdx, 1, order.id, style: rowStyle);
      _setCell(summarySheet, rowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
      _setCell(summarySheet, rowIdx, 3,
          order.orderType == 'additional' ? '추가제작' : (isGroup ? '단체주문' : '개인주문'),
          style: rowStyle);
      _setCell(summarySheet, rowIdx, 4,
          opts['teamName']?.toString() ?? order.groupName ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 5, order.userName, style: rowStyle);
      _setCell(summarySheet, rowIdx, 6, _maskPhone(order.userPhone), style: rowStyle);
      _setCell(summarySheet, rowIdx, 7,
          order.items.map((i) => i.productName).toSet().join(' / '), style: rowStyle);
      _setCell(summarySheet, rowIdx, 8, colorInfo, style: rowStyle);
      _setCell(summarySheet, rowIdx, 9,
          opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-',
          style: rowStyle);
      _setCell(summarySheet, rowIdx, 10,
          opts['defaultLength']?.toString() ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 11,
          opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '-',
          style: rowStyle);
      _setCell(summarySheet, rowIdx, 12, totalQty, style: rowStyle);
      _setCell(summarySheet, rowIdx, 13,
          maleCount > 0 ? maleCount : '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 14,
          femaleCount > 0 ? femaleCount : '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 15, imageUrl.isNotEmpty ? imageUrl : '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 16, _statusLabel(order.status), style: rowStyle);

      rowIdx++;
      orderNo++;
    }

    // 합계 행
    _setCell(summarySheet, rowIdx, 0, '합계', style: totalStyle);
    _setCell(summarySheet, rowIdx, 12,
        orders.fold<int>(0, (s, o) => s + o.items.fold<int>(0, (si, i) => si + i.quantity)),
        style: totalStyle);

    final summaryColWidths = [
      5.0, 22.0, 18.0, 10.0, 16.0,
      12.0, 14.0, 20.0, 16.0, 16.0,
      12.0, 14.0, 8.0, 7.0, 7.0,
      50.0, 10.0,
    ];
    for (var i = 0; i < summaryColWidths.length; i++) {
      summarySheet.setColumnWidth(i, summaryColWidths[i]);
    }

    // ══════════════════════════════════════════════════════════
    // 시트 2: 인원별 상세 사이즈 명단 (키·몸무게·허리·허벅지 포함)
    // ══════════════════════════════════════════════════════════
    final sizeSheet = excel['인원별사이즈명단'];

    final sizeHeaders = [
      'No', '주문번호', '주문날짜', '단체명', '인원번호', '이름', '성별',
      '상의사이즈', '하의사이즈', '하의길이', '색상',
      '키(cm)', '몸무게(kg)', '허리(cm)', '허벅지(cm)',
      '인쇄옵션', '허리밴드', '비고',
    ];
    for (var i = 0; i < sizeHeaders.length; i++) {
      _setCell(sizeSheet, 0, i, sizeHeaders[i], style: headerStyle);
    }

    int sRowIdx = 1;
    int sNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final persons = (opts['persons'] as List<dynamic>?) ?? [];
      if (persons.isEmpty) {
        // 인원 정보 없는 경우 주문 정보만 기록
        _setCell(sizeSheet, sRowIdx, 0, '$sNo');
        _setCell(sizeSheet, sRowIdx, 1, order.id);
        _setCell(sizeSheet, sRowIdx, 2, _fmtFull(order.createdAt));
        _setCell(sizeSheet, sRowIdx, 3, opts['teamName']?.toString() ?? order.groupName ?? '-');
        _setCell(sizeSheet, sRowIdx, 4, '-');
        _setCell(sizeSheet, sRowIdx, 5, order.userName);
        _setCell(sizeSheet, sRowIdx, 6, '-');
        _setCell(sizeSheet, sRowIdx, 7, order.items.isNotEmpty ? order.items.first.size : '-');
        _setCell(sizeSheet, sRowIdx, 8, '-');
        _setCell(sizeSheet, sRowIdx, 9, opts['defaultLength']?.toString() ?? '-');
        _setCell(sizeSheet, sRowIdx, 10, _extractColorInfo(order));
        sRowIdx++;
        sNo++;
        continue;
      }

      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
      final mainColor = opts['mainColor']?.toString() ?? '-';
      final defaultLength = opts['defaultLength']?.toString() ?? '';
      final printType = opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-';
      final waistband = opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '-';

      for (var i = 0; i < persons.length; i++) {
        final p = persons[i] as Map<String, dynamic>;
        final gender = p['gender']?.toString() ?? '';
        final gStyle = gender == '남' ? maleStyle : (gender == '여' ? femaleStyle : null);

        // 상세 신체 치수 (입력된 경우만)
        final height = p['height']?.toString() ?? '';
        final weight = p['weight']?.toString() ?? '';
        final waist = p['waist']?.toString() ?? '';
        final thigh = p['thigh']?.toString() ?? '';
        final hasDetail = height.isNotEmpty || weight.isNotEmpty || waist.isNotEmpty || thigh.isNotEmpty;

        final personalLength = p['bottomLength']?.toString() ?? '';
        final personColor = p['color']?.toString() ?? '';

        _setCell(sizeSheet, sRowIdx, 0, '$sNo');
        _setCell(sizeSheet, sRowIdx, 1, _shortId(order.id));
        _setCell(sizeSheet, sRowIdx, 2, _fmtFull(order.createdAt));
        _setCell(sizeSheet, sRowIdx, 3, teamName);
        _setCell(sizeSheet, sRowIdx, 4, '${(p['index'] ?? i + 1)}번');
        _setCell(sizeSheet, sRowIdx, 5, p['name']?.toString().isNotEmpty == true ? p['name']!.toString() : '-', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 6, gender.isNotEmpty ? gender : '-', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 7, p['topSize']?.toString().isNotEmpty == true ? p['topSize']!.toString() : '-');
        _setCell(sizeSheet, sRowIdx, 8, p['bottomSize']?.toString().isNotEmpty == true ? p['bottomSize']!.toString() : '-');
        _setCell(sizeSheet, sRowIdx, 9,
            personalLength.isNotEmpty ? personalLength : (defaultLength.isNotEmpty ? defaultLength : '개별'));
        _setCell(sizeSheet, sRowIdx, 10,
            personColor.isNotEmpty ? personColor : mainColor);
        // 상세 신체 치수 — 입력된 경우만 표시
        _setCell(sizeSheet, sRowIdx, 11, hasDetail && height.isNotEmpty ? height : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 12, hasDetail && weight.isNotEmpty ? weight : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 13, hasDetail && waist.isNotEmpty ? waist : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 14, hasDetail && thigh.isNotEmpty ? thigh : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 15, printType);
        _setCell(sizeSheet, sRowIdx, 16, waistband);
        _setCell(sizeSheet, sRowIdx, 17, hasDetail ? '상세치수입력' : '');

        sRowIdx++;
        sNo++;
      }

      // 팀 구분선
      _setCell(sizeSheet, sRowIdx, 0, '── $teamName 완료 (${persons.length}명) ──', style: separatorStyle);
      sizeSheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sRowIdx),
          CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: sRowIdx));
      sRowIdx++;
    }

    // 개인 주문도 포함
    for (final order in personalOrders) {
      final isEven = sNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : null;
      for (final item in order.items) {
        _setCell(sizeSheet, sRowIdx, 0, '$sNo', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 1, _shortId(order.id), style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 3, '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 4, '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 5, order.userName, style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 6, '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 7, item.size, style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 8, '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 9, '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 10, item.color, style: rowStyle);
        sRowIdx++;
        sNo++;
      }
    }

    final sizeColWidths = [
      5.0, 20.0, 16.0, 14.0, 9.0, 12.0, 7.0,
      12.0, 12.0, 12.0, 14.0,
      9.0, 11.0, 9.0, 11.0,
      16.0, 14.0, 12.0,
    ];
    for (var i = 0; i < sizeColWidths.length; i++) {
      sizeSheet.setColumnWidth(i, sizeColWidths[i]);
    }

    // ══════════════════════════════════════════════════════════
    // 시트 3: 디자인 이미지 & 주문 상세
    // ══════════════════════════════════════════════════════════
    final imageSheet = excel['디자인이미지및상세'];

    final imgHeaders = [
      'No', '주문번호', '주문날짜', '단체명', '상품명',
      '인쇄옵션', '색상', '하의길이', '허리밴드', '총수량', '남', '여',
      '상품이미지URL', '남자참조이미지URL', '여자참조이미지URL', '메모',
    ];
    for (var i = 0; i < imgHeaders.length; i++) {
      _setCell(imageSheet, 0, i, imgHeaders[i], style: headerStyle);
    }

    int imgRowIdx = 1;
    int imgNo = 1;
    for (final order in orders) {
      final opts = order.customOptions ?? {};
      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
      final isEven = imgNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : null;

      // 이미지 URL들
      final maleRefUrl = opts['maleRefImageUrl']?.toString() ?? '';
      final femaleRefUrl = opts['femaleRefImageUrl']?.toString() ?? '';
      final productImgUrl = _extractDesignImageUrl(order);

      // 색상 정보
      final colorInfo = _extractColorInfo(order);
      // 남/여 인원
      final maleCount = _countGender(order, '남');
      final femaleCount = _countGender(order, '여');
      final totalQty = order.items.fold<int>(0, (s, i) => s + i.quantity);

      _setCell(imageSheet, imgRowIdx, 0, '$imgNo', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 1, order.id, style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 3, teamName, style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 4,
          order.items.map((i) => i.productName).toSet().join(' / '), style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 5,
          opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-',
          style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 6, colorInfo, style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 7,
          opts['defaultLength']?.toString() ?? '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 8,
          opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '-',
          style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 9, totalQty, style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 10, maleCount > 0 ? maleCount : '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 11, femaleCount > 0 ? femaleCount : '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 12, productImgUrl.isNotEmpty ? productImgUrl : '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 13, maleRefUrl.isNotEmpty ? maleRefUrl : '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 14, femaleRefUrl.isNotEmpty ? femaleRefUrl : '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 15,
          opts['memoText']?.toString() ?? order.memo ?? '', style: rowStyle);

      imgRowIdx++;
      imgNo++;
    }

    final imgColWidths = [
      5.0, 22.0, 16.0, 14.0, 20.0,
      16.0, 16.0, 12.0, 14.0, 8.0, 6.0, 6.0,
      50.0, 50.0, 50.0, 25.0,
    ];
    for (var i = 0; i < imgColWidths.length; i++) {
      imageSheet.setColumnWidth(i, imgColWidths[i]);
    }

    excel.setDefaultSheet('주문요약');
    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  // ════════════════════════════════════════════════════════════════
  // 일일 마감 엑셀 생성 (전날 13시~당일 13시, 단체주문 전용)
  // ════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateDailyGroupOrderExcel(
      List<OrderModel> orders, DateTime start, DateTime end) async {
    final excel = Excel.createExcel();

    final groupOrders = orders.where((o) =>
        o.orderType == 'group' ||
        o.orderType == 'additional' ||
        (o.customOptions != null && o.customOptions!.isNotEmpty)).toList();

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4A148C'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 10,
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
    final detailStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E8EAF6'),
      fontColorHex: ExcelColor.fromHexString('#283593'),
    );

    // ══════════════════════════════════
    // 시트 1: 단체주문 요약
    // ══════════════════════════════════
    final summarySheet = excel['단체주문요약'];
    excel.setDefaultSheet('단체주문요약');

    _setCell(summarySheet, 0, 0,
        '2FIT MALL 단체주문 일일마감 (${_fmt(start)} ~ ${_fmt(end)})',
        style: titleStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: 0));

    _setCell(summarySheet, 1, 0, '단체주문 총 ${groupOrders.length}건 | 총 ${groupOrders.fold<int>(0, (s, o) => s + (o.groupCount ?? 0))}명', style: headerStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: 1));

    final headers = [
      'No', '주문번호', '주문날짜', '단체명', '담당자', '연락처',
      '인쇄옵션', '색상', '하의길이', '허리밴드',
      '총인원', '남성', '여성', '커스텀옵션', '디자인이미지URL', '메모',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(summarySheet, 3, i, headers[i], style: headerStyle);
    }

    int rowIdx = 4;
    int orderNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final isEven = orderNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : null;
      final maleCount = _countGender(order, '남');
      final femaleCount = _countGender(order, '여');
      final imageUrl = _extractDesignImageUrl(order);

      _setCell(summarySheet, rowIdx, 0, '$orderNo', style: rowStyle);
      _setCell(summarySheet, rowIdx, 1, _shortId(order.id), style: rowStyle);
      _setCell(summarySheet, rowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
      _setCell(summarySheet, rowIdx, 3, opts['teamName']?.toString() ?? order.groupName ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 4, opts['manager']?.toString() ?? opts['managerName']?.toString() ?? order.userName, style: rowStyle);
      _setCell(summarySheet, rowIdx, 5, _maskPhone(order.userPhone), style: rowStyle);
      _setCell(summarySheet, rowIdx, 6, opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 7, _extractColorInfo(order), style: rowStyle);
      _setCell(summarySheet, rowIdx, 8, opts['defaultLength']?.toString() ?? '개별선택', style: rowStyle);
      _setCell(summarySheet, rowIdx, 9, opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 10, opts['totalCount'] ?? order.groupCount ?? '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 11, maleCount > 0 ? maleCount : '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 12, femaleCount > 0 ? femaleCount : '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 13, _buildCustomSummary(opts), style: rowStyle);
      _setCell(summarySheet, rowIdx, 14, imageUrl.isNotEmpty ? imageUrl : '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 15, opts['memoText']?.toString() ?? order.memo ?? '', style: rowStyle);

      rowIdx++;
      orderNo++;
    }

    _setCell(summarySheet, rowIdx, 0, '합계', style: totalStyle);
    final totalPersons = groupOrders.fold<int>(0, (s, o) {
      final cnt = o.customOptions?['totalCount'];
      return s + ((cnt as num?)?.toInt() ?? o.groupCount ?? 0);
    });
    _setCell(summarySheet, rowIdx, 10, totalPersons, style: totalStyle);

    final summaryColWidths = [
      5.0, 20.0, 16.0, 16.0, 12.0, 14.0,
      18.0, 16.0, 12.0, 14.0,
      8.0, 7.0, 7.0, 28.0, 50.0, 22.0,
    ];
    for (var i = 0; i < summaryColWidths.length; i++) {
      summarySheet.setColumnWidth(i, summaryColWidths[i]);
    }

    // ══════════════════════════════════
    // 시트 2: 인원별 사이즈 상세 (키·몸무게·허리·허벅지 포함)
    // ══════════════════════════════════
    final sizeSheet = excel['인원별사이즈'];

    final sizeHeaders = [
      'No', '주문번호', '주문날짜', '단체명', '인원번호', '이름', '성별',
      '상의사이즈', '하의사이즈', '하의길이', '색상',
      '키(cm)', '몸무게(kg)', '허리(cm)', '허벅지(cm)',
      '인쇄옵션', '허리밴드',
    ];
    for (var i = 0; i < sizeHeaders.length; i++) {
      _setCell(sizeSheet, 0, i, sizeHeaders[i], style: headerStyle);
    }

    int sRowIdx = 1;
    int sNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final persons = (opts['persons'] as List<dynamic>?) ?? [];
      if (persons.isEmpty) continue;

      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
      final mainColor = opts['mainColor']?.toString() ?? '-';
      final defaultLength = opts['defaultLength']?.toString() ?? '';
      final printType = opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-';
      final waistband = opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '-';

      for (var i = 0; i < persons.length; i++) {
        final p = persons[i] as Map<String, dynamic>;
        final gender = p['gender']?.toString() ?? '';
        final gStyle = gender == '남' ? maleStyle : (gender == '여' ? femaleStyle : null);

        // 상세 치수
        final height = p['height']?.toString() ?? '';
        final weight = p['weight']?.toString() ?? '';
        final waist = p['waist']?.toString() ?? '';
        final thigh = p['thigh']?.toString() ?? '';
        final hasDetail = height.isNotEmpty || weight.isNotEmpty || waist.isNotEmpty || thigh.isNotEmpty;

        final personalLength = p['bottomLength']?.toString() ?? '';
        final personColor = p['color']?.toString() ?? '';

        _setCell(sizeSheet, sRowIdx, 0, '$sNo');
        _setCell(sizeSheet, sRowIdx, 1, _shortId(order.id));
        _setCell(sizeSheet, sRowIdx, 2, _fmtFull(order.createdAt));
        _setCell(sizeSheet, sRowIdx, 3, teamName);
        _setCell(sizeSheet, sRowIdx, 4, '${(p['index'] ?? i + 1)}번');
        _setCell(sizeSheet, sRowIdx, 5, p['name']?.toString().isNotEmpty == true ? p['name']!.toString() : '-', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 6, gender.isNotEmpty ? gender : '-', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 7, p['topSize']?.toString().isNotEmpty == true ? p['topSize']!.toString() : '-');
        _setCell(sizeSheet, sRowIdx, 8, p['bottomSize']?.toString().isNotEmpty == true ? p['bottomSize']!.toString() : '-');
        _setCell(sizeSheet, sRowIdx, 9,
            personalLength.isNotEmpty ? personalLength : (defaultLength.isNotEmpty ? defaultLength : '개별'));
        _setCell(sizeSheet, sRowIdx, 10,
            personColor.isNotEmpty ? personColor : mainColor);
        // 상세 신체 치수
        _setCell(sizeSheet, sRowIdx, 11, hasDetail && height.isNotEmpty ? height : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 12, hasDetail && weight.isNotEmpty ? weight : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 13, hasDetail && waist.isNotEmpty ? waist : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 14, hasDetail && thigh.isNotEmpty ? thigh : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 15, printType);
        _setCell(sizeSheet, sRowIdx, 16, waistband);

        sRowIdx++;
        sNo++;
      }

      // 팀 구분선
      _setCell(sizeSheet, sRowIdx, 0, '── $teamName 완료 (${persons.length}명) ──', style: warningStyle);
      sizeSheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sRowIdx),
          CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: sRowIdx));
      sRowIdx++;
    }

    final sizeColWidths = [
      5.0, 20.0, 16.0, 14.0, 9.0, 12.0, 7.0,
      12.0, 12.0, 12.0, 14.0,
      9.0, 11.0, 9.0, 11.0,
      16.0, 14.0,
    ];
    for (var i = 0; i < sizeColWidths.length; i++) {
      sizeSheet.setColumnWidth(i, sizeColWidths[i]);
    }

    // ══════════════════════════════════
    // 시트 3: 디자인 이미지 URL 모음
    // ══════════════════════════════════
    final imageSheet = excel['디자인이미지'];

    final imgHeaders = [
      'No', '주문번호', '주문날짜', '단체명', '상품명',
      '인쇄옵션', '색상', '하의길이', '허리밴드',
      '상품이미지URL', '남자참조이미지URL', '여자참조이미지URL',
    ];
    for (var i = 0; i < imgHeaders.length; i++) {
      _setCell(imageSheet, 0, i, imgHeaders[i], style: headerStyle);
    }

    int imgRowIdx = 1;
    int imgNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final isEven = imgNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : null;
      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
      final productImgUrl = _extractDesignImageUrl(order);
      final maleRefUrl = opts['maleRefImageUrl']?.toString() ?? '';
      final femaleRefUrl = opts['femaleRefImageUrl']?.toString() ?? '';

      _setCell(imageSheet, imgRowIdx, 0, '$imgNo', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 1, order.id, style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 3, teamName, style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 4, order.items.map((i) => i.productName).toSet().join(' / '), style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 5, opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 6, _extractColorInfo(order), style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 7, opts['defaultLength']?.toString() ?? '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 8, opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 9, productImgUrl.isNotEmpty ? productImgUrl : '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 10, maleRefUrl.isNotEmpty ? maleRefUrl : '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 11, femaleRefUrl.isNotEmpty ? femaleRefUrl : '-', style: rowStyle);

      imgRowIdx++;
      imgNo++;
    }

    final imgColWidths = [
      5.0, 22.0, 16.0, 16.0, 20.0,
      16.0, 16.0, 12.0, 14.0,
      50.0, 50.0, 50.0,
    ];
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

  // ── 단체주문 개별 엑셀 생성 (개선판) ──
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
    final detailStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E8EAF6'),
      fontColorHex: ExcelColor.fromHexString('#283593'),
    );

    // ── 시트 1: 주문정보 ──
    final summarySheet = excel['주문정보'];
    excel.setDefaultSheet('주문정보');

    _setCell(summarySheet, 0, 0, '2FIT 단체주문 주문서', style: headerStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0));

    final productImageUrl = opts['productImageUrl']?.toString() ?? '';
    final designFileUrl = opts['designFileUrl']?.toString() ?? '';
    final maleRefUrl = opts['maleRefImageUrl']?.toString() ?? '';
    final femaleRefUrl = opts['femaleRefImageUrl']?.toString() ?? '';
    final bottomColorName = opts['bottomColorName']?.toString() ?? '';

    int imgRow = 1;
    if (productImageUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '[상세페이지 디자인 이미지]', style: labelStyle);
      _setCell(summarySheet, imgRow, 1, productImageUrl);
      _setCell(summarySheet, imgRow, 2, '※ URL을 복사하여 브라우저에서 확인');
      imgRow++;
    }
    if (designFileUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '[디자인수정 파일 첨부]', style: labelStyle);
      _setCell(summarySheet, imgRow, 1, designFileUrl);
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

    final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
    final mainColor = opts['mainColor']?.toString() ?? '-';
    final colorInfo = bottomColorName.isNotEmpty
        ? '상의: $mainColor / 하의: $bottomColorName'
        : mainColor;

    final infoRows = [
      ['주문번호', order.id],
      ['주문날짜', _fmtFull(order.createdAt)],
      ['단체명/팀명', teamName],
      ['담당자', opts['manager']?.toString() ?? opts['managerName']?.toString() ?? order.userName],
      ['연락처', _maskPhone(order.userPhone)],
      ['이메일', _maskEmail(order.userEmail)],
      ['배송지', order.userAddress],
      ['총 인원', '${opts['totalCount'] ?? order.groupCount ?? 0}명'],
      ['남/여 구분', '남 ${_countGender(order, '남')}명 / 여 ${_countGender(order, '여')}명'],
      ['인쇄옵션(구매옵션)', opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-'],
      ['색상', colorInfo],
      ['하의 기본길이', opts['defaultLength']?.toString() ?? '개별선택'],
      ['허리밴드', opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '-'],
      ['원단 종류', opts['fabricType']?.toString() ?? opts['fabric']?.toString() ?? '-'],
      ['원단 무게', opts['fabricWeight']?.toString() ?? opts['weight']?.toString() ?? '-'],
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

    // ── 시트 2: 인원별 사이즈 (키·몸무게·허리·허벅지 포함) ──
    final personSheet = excel['팀원별사이즈명단'];

    final colorDisplay = bottomColorName.isNotEmpty
        ? '상의:$mainColor / 하의:$bottomColorName'
        : mainColor;

    _setCell(personSheet, 0, 0,
        '팀명: $teamName  |  총 ${persons.length}명  |  색상: $colorDisplay  |  하의길이: ${opts['defaultLength'] ?? '개별선택'}',
        style: headerStyle);
    personSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 0));

    // 헤더 (키·몸무게·허리·허벅지 추가)
    final pHeaders = [
      'No', '이름', '성별', '상의 사이즈', '하의 사이즈', '하의 길이', '색상',
      '키(cm)', '몸무게(kg)', '허리(cm)', '허벅지(cm)', '비고',
    ];
    for (var i = 0; i < pHeaders.length; i++) {
      _setCell(personSheet, 1, i, pHeaders[i], style: subHeaderStyle);
    }

    final defaultLength = opts['defaultLength']?.toString() ?? '';
    for (var i = 0; i < persons.length; i++) {
      final p = persons[i] as Map<String, dynamic>;
      final rowStyle = i % 2 == 0 ? evenStyle : null;
      final gender = p['gender']?.toString() ?? '';
      final gStyle = gender == '남' ? maleStyle : (gender == '여' ? femaleStyle : rowStyle);

      final height = p['height']?.toString() ?? '';
      final weight = p['weight']?.toString() ?? '';
      final waist = p['waist']?.toString() ?? '';
      final thigh = p['thigh']?.toString() ?? '';
      final hasDetail = height.isNotEmpty || weight.isNotEmpty || waist.isNotEmpty || thigh.isNotEmpty;

      final personalLength = p['bottomLength']?.toString() ?? '';
      final personColor = p['color']?.toString() ?? '';

      _setCell(personSheet, i + 2, 0, '${p['index'] ?? i + 1}', style: rowStyle);
      _setCell(personSheet, i + 2, 1, p['name']?.toString().isNotEmpty == true ? p['name']!.toString() : '-', style: gStyle);
      _setCell(personSheet, i + 2, 2, gender.isNotEmpty ? gender : '-', style: gStyle);
      _setCell(personSheet, i + 2, 3, p['topSize']?.toString().isNotEmpty == true ? p['topSize']!.toString() : '-', style: rowStyle);
      _setCell(personSheet, i + 2, 4, p['bottomSize']?.toString().isNotEmpty == true ? p['bottomSize']!.toString() : '-', style: rowStyle);
      _setCell(personSheet, i + 2, 5,
          personalLength.isNotEmpty ? personalLength : (defaultLength.isNotEmpty ? defaultLength : '개별선택'),
          style: rowStyle);
      _setCell(personSheet, i + 2, 6,
          personColor.isNotEmpty ? personColor : mainColor, style: rowStyle);
      // 상세 신체 치수
      _setCell(personSheet, i + 2, 7, hasDetail && height.isNotEmpty ? height : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 8, hasDetail && weight.isNotEmpty ? weight : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 9, hasDetail && waist.isNotEmpty ? waist : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 10, hasDetail && thigh.isNotEmpty ? thigh : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 11, hasDetail ? '상세치수입력' : '', style: rowStyle);
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
        '남 ${_countGender(order, '남')}명 / 여 ${_countGender(order, '여')}명',
        style: totalStyle2);

    final pColWidths = [6.0, 14.0, 8.0, 16.0, 16.0, 12.0, 16.0, 9.0, 11.0, 9.0, 11.0, 14.0];
    for (var i = 0; i < pColWidths.length; i++) {
      personSheet.setColumnWidth(i, pColWidths[i]);
    }

    excel.setDefaultSheet('주문정보');
    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  // ── 유틸리티 함수들 ──

  /// 주문에서 디자인/상품 이미지 URL 추출
  static String _extractDesignImageUrl(OrderModel order) {
    final opts = order.customOptions ?? {};
    // 우선순위: productImageUrl → designFileUrl → 아이템 이미지
    final url = opts['productImageUrl']?.toString() ??
        opts['designImageUrl']?.toString() ??
        opts['imageUrl']?.toString() ??
        '';
    if (url.isNotEmpty) return url;
    // 아이템의 이미지 확인
    for (final item in order.items) {
      final itemUrl = item.customOptions?['productImageUrl']?.toString() ??
          item.customOptions?['imageUrl']?.toString() ?? '';
      if (itemUrl.isNotEmpty) return itemUrl;
    }
    return '';
  }

  /// 주문에서 색상 정보 추출
  static String _extractColorInfo(OrderModel order) {
    final opts = order.customOptions ?? {};
    final mainColor = opts['mainColor']?.toString() ?? '';
    final bottomColor = opts['bottomColorName']?.toString() ?? '';
    if (mainColor.isNotEmpty && bottomColor.isNotEmpty) {
      return '상의:$mainColor / 하의:$bottomColor';
    }
    if (mainColor.isNotEmpty) return mainColor;
    // 아이템의 색상
    if (order.items.isNotEmpty) {
      return order.items.first.color;
    }
    return '-';
  }

  /// persons 배열에서 성별 인원 수 계산
  static int _countGender(OrderModel order, String gender) {
    final opts = order.customOptions ?? {};
    // 저장된 maleCount/femaleCount 우선
    if (gender == '남') {
      final saved = opts['maleCount'];
      if (saved != null) return (saved as num).toInt();
    } else {
      final saved = opts['femaleCount'];
      if (saved != null) return (saved as num).toInt();
    }
    // persons 배열에서 직접 계산
    final persons = (opts['persons'] as List<dynamic>?) ?? [];
    return persons.where((p) => (p as Map<String, dynamic>)['gender']?.toString() == gender).length;
  }

  /// 커스텀 옵션 요약 문자열
  static String _buildCustomSummary(Map<String, dynamic> opts) {
    final parts = <String>[];
    final printType = opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '';
    if (printType.isNotEmpty) parts.add('인쇄:$printType');
    final waistband = opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '';
    if (waistband.isNotEmpty && waistband != '-') parts.add('허리밴드:$waistband');
    if (opts['exclusiveDesign'] == true) parts.add('독점디자인');
    final fabric = opts['fabricType']?.toString() ?? opts['fabric']?.toString() ?? '';
    if (fabric.isNotEmpty && fabric != '-') parts.add('원단:$fabric');
    return parts.join(' / ');
  }

  // ── 개인정보 마스킹 ──
  static String _maskPhone(String phone) {
    if (phone.length < 8) return phone;
    final dashIdx = phone.indexOf('-');
    final lastDash = phone.lastIndexOf('-');
    if (dashIdx < 0 || lastDash <= dashIdx) return phone;
    return phone.replaceRange(dashIdx + 1, lastDash, '****');
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
      id.length > 20 ? '${id.substring(0, 20)}...' : id;

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

  // ════════════════════════════════════════════════════════════════
  // 예시(샘플) 엑셀 파일 생성 — 실제 주문 없이 구조 미리보기용
  // ════════════════════════════════════════════════════════════════
  static Uint8List generateSampleExcel() {
    final excel = Excel.createExcel();

    // ── 스타일 ──
    final titleStyle = CellStyle(
      bold: true, fontSize: 13,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2D2D5E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 11,
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
    final evenRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F8F9FA'),
    );
    final sampleNoteStyle = CellStyle(
      bold: true, fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#FFF9C4'),
      fontColorHex: ExcelColor.fromHexString('#F57F17'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // ════ Sheet 1 : 주문요약 ════
    final sum = excel['주문요약'];
    excel.setDefaultSheet('주문요약');

    _setCell(sum, 0, 0, '⚡ 이 파일은 예시(샘플) 파일입니다 — 실제 주문 데이터가 아닙니다', style: sampleNoteStyle);
    sum.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
              CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: 0));

    _setCell(sum, 1, 0, '2FIT MALL 주문 내역 엑셀 예시', style: titleStyle);
    sum.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
              CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: 1));

    final sumHeaders = [
      'No', '주문번호', '주문일시', '구분', '팀명/단체명',
      '구매자', '인쇄옵션', '색상', '하의길이', '허리밴드',
      '남성수량', '여성수량', '총수량', '디자인이미지URL', '상태',
    ];
    for (int c = 0; c < sumHeaders.length; c++) {
      _setCell(sum, 2, c, sumHeaders[c], style: headerStyle);
    }

    final sampleSummary = [
      ['1', 'ORD-2024-0001', '2024-03-25 14:30', '단체주문', '부산 트라이애슬론팀',
       '김철수', '자수', '네이비', '기본', 'O', '15', '5', '20',
       'https://example.com/design1.jpg', '주문확인'],
      ['2', 'ORD-2024-0002', '2024-03-25 16:00', '단체주문', '서울 마라톤클럽',
       '이영희', '실크스크린', '블랙', '-2cm', 'X', '8', '12', '20',
       'https://example.com/design2.jpg', '제작중'],
      ['3', 'ORD-2024-0003', '2024-03-26 09:15', '개인주문', '-',
       '박민준', '없음', '화이트', '기본', 'O', '1', '0', '1',
       'https://example.com/design3.jpg', '배송중'],
    ];

    for (int r = 0; r < sampleSummary.length; r++) {
      final row = sampleSummary[r];
      final rowStyle = r.isEven ? evenRowStyle : null;
      for (int c = 0; c < row.length; c++) {
        _setCell(sum, r + 3, c, row[c], style: rowStyle);
      }
    }

    for (int c = 0; c < sumHeaders.length; c++) {
      sum.setColumnWidth(c, c == 1 ? 20.0 : c == 4 ? 18.0 : c == 13 ? 35.0 : 12.0);
    }

    // ════ Sheet 2 : 사이즈 명단 ════
    final sz = excel['사이즈명단'];
    _setCell(sz, 0, 0, '⚡ 예시 데이터', style: sampleNoteStyle);
    sz.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
             CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 0));

    _setCell(sz, 1, 0, '팀원별 사이즈 목록', style: titleStyle);
    sz.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
             CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 1));

    final szHeaders = [
      'No', '이름', '성별', '상의사이즈', '하의사이즈', '하의길이',
      '색상', '키(cm)', '몸무게(kg)', '허리(cm)', '허벅지(cm)', '인쇄옵션', '허리밴드',
    ];
    for (int c = 0; c < szHeaders.length; c++) {
      _setCell(sz, 2, c, szHeaders[c], style: headerStyle);
    }

    final sampleMembers = [
      ['1', '김철수', '남성', 'XL', '32', '기본', '네이비', '178', '75', '82', '56', '자수', 'O'],
      ['2', '이영수', '남성', 'L',  '30', '기본', '네이비', '172', '68', '78', '54', '자수', 'O'],
      ['3', '박소연', '여성', 'M',  '27', '-2cm', '네이비', '162', '52', '66', '50', '자수', 'X'],
      ['4', '최지은', '여성', 'S',  '25', '-2cm', '네이비', '158', '48', '62', '48', '자수', 'X'],
    ];

    for (int r = 0; r < sampleMembers.length; r++) {
      final row = sampleMembers[r];
      final isM = row[2] == '남성';
      final genderStyle = isM ? maleStyle : femaleStyle;
      for (int c = 0; c < row.length; c++) {
        _setCell(sz, r + 3, c, row[c], style: c == 2 ? genderStyle : (r.isEven ? evenRowStyle : null));
      }
    }

    for (int c = 0; c < szHeaders.length; c++) {
      sz.setColumnWidth(c, c == 1 ? 12.0 : 10.0);
    }

    // ════ Sheet 3 : 디자인 이미지 ════
    final img = excel['디자인이미지'];
    _setCell(img, 0, 0, '⚡ 예시 데이터', style: sampleNoteStyle);
    img.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0));

    _setCell(img, 1, 0, '디자인 이미지 URL 목록', style: titleStyle);
    img.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1));

    final imgHeaders = ['No', '주문번호', '디자인이미지URL', '남성레퍼런스URL', '여성레퍼런스URL', '메모'];
    for (int c = 0; c < imgHeaders.length; c++) {
      _setCell(img, 2, c, imgHeaders[c], style: headerStyle);
    }

    final sampleImages = [
      ['1', 'ORD-2024-0001', 'https://example.com/design1.jpg', 'https://example.com/male_ref1.jpg', 'https://example.com/female_ref1.jpg', '부산 트라이애슬론팀 - 네이비'],
      ['2', 'ORD-2024-0002', 'https://example.com/design2.jpg', 'https://example.com/male_ref2.jpg', 'https://example.com/female_ref2.jpg', '서울 마라톤클럽 - 블랙'],
    ];

    for (int r = 0; r < sampleImages.length; r++) {
      final row = sampleImages[r];
      for (int c = 0; c < row.length; c++) {
        _setCell(img, r + 3, c, row[c], style: r.isEven ? evenRowStyle : null);
      }
    }

    for (int c = 0; c < imgHeaders.length; c++) {
      img.setColumnWidth(c, c >= 2 && c <= 4 ? 40.0 : c == 5 ? 25.0 : 12.0);
    }

    // 기본 Sheet 제거
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    if (encoded == null) throw Exception('샘플 엑셀 생성 실패');
    return Uint8List.fromList(encoded);
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  const DateTimeRange({required this.start, required this.end});
}
