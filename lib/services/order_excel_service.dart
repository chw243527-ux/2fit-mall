// order_excel_service.dart — 주문 엑셀 내보내기 서비스 (전면 개선판)
// 포함 항목: 디자인이미지URL, 주문날짜, 키/몸무게/허리/허벅지, 이름, 인쇄옵션,
//            하의길이, 색상, 수량, 성별, 허리밴드
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class OrderExcelService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── 단체주문 여부 공통 판별 함수 ──
  // GRP_/GROUP- ID이거나, orderType이 group/additional이거나,
  // persons 배열 + teamName 둘 다 있으면 단체주문
  static bool _isGroupOrder(OrderModel o) {
    if (o.orderType == 'group' || o.orderType == 'additional') return true;
    final isGrpId = o.id.startsWith('GRP_') || o.id.startsWith('GROUP-');
    if (isGrpId) return true;
    final hasTeamName = (o.customOptions?['teamName'] as String?)?.isNotEmpty == true;
    final hasPersons = (o.customOptions?['persons'] as List?)?.isNotEmpty == true;
    return hasTeamName && hasPersons;
  }

  // ── 전날 오후1시 ~ 당일 오후1시 날짜 계산 ──
  // 항상 "오늘 13:00 기준의 직전 24시간 회차"를 반환한다.
  //   start = 어제 13:00:00
  //   end   = 오늘 13:00:00
  // (오전에 다운받든 오후에 다운받든 동일한 구간)
  static DateTimeRange getDailyRange({DateTime? baseDate}) {
    final now = baseDate ?? DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 13, 0, 0);
    final start = end.subtract(const Duration(days: 1));
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

  /// gender 영문 → 한글 변환
  static String _normalizeGender(dynamic g) {
    if (g == null) return '-';
    final s = g.toString().toLowerCase();
    if (s == 'male' || s == 'm' || s == '남성') return '남';
    if (s == 'female' || s == 'f' || s == '여성') return '여';
    return g.toString();
  }

  /// persons 리스트 gender 정규화
  static List<dynamic> _normalizePersons(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((p) {
      if (p is Map) {
        final m = Map<String, dynamic>.from(p);
        m['gender'] = _normalizeGender(m['gender']);
        return m;
      }
      return p;
    }).toList();
  }

  static OrderModel? _parseOrder(Map<String, dynamic> data, String docId) {
    try {
      final rawItems = data['items'] as List<dynamic>? ?? [];
      final items = rawItems.map((item) {
        final m = item as Map<String, dynamic>;
        Map<String, dynamic>? itemOpts;
        final rawItemOpts = m['customOptions'];
        if (rawItemOpts is Map) {
          itemOpts = Map<String, dynamic>.from(rawItemOpts);
        }
        return OrderItem(
          productId: m['productId'] as String? ?? '',
          productName: m['productName'] as String? ?? '',
          size: m['size'] as String? ?? '',
          color: m['color'] as String? ?? '',
          quantity: (m['quantity'] as num?)?.toInt() ?? 1,
          price: (m['price'] as num?)?.toDouble() ?? 0,
          customOptions: itemOpts,
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

      Map<String, dynamic> customOptions;
      final rawOpts = data['customOptions'];
      if (rawOpts is Map) {
        customOptions = Map<String, dynamic>.from(rawOpts);
      } else {
        customOptions = {};
      }

      // persons: customOptions.persons 없으면 top-level persons 사용 (gender 정규화)
      final optsPersons = customOptions['persons'];
      if (optsPersons == null || (optsPersons as List?)?.isEmpty == true) {
        final topPersons = data['persons'];
        if (topPersons is List && topPersons.isNotEmpty) {
          customOptions['persons'] = _normalizePersons(topPersons);
        }
      } else {
        customOptions['persons'] = _normalizePersons(optsPersons);
      }

      // teamName: customOptions.teamName 없으면 groupName 사용
      if (customOptions['teamName'] == null ||
          (customOptions['teamName'] as String?)?.isEmpty == true) {
        final gn = data['groupName'] as String?;
        if (gn != null && gn.isNotEmpty) customOptions['teamName'] = gn;
      }
      // totalCount: groupCount 폴백
      if (customOptions['totalCount'] == null) {
        final gc = data['groupCount'];
        if (gc != null) customOptions['totalCount'] = gc;
      }
      // maleCount/femaleCount 폴백
      if (customOptions['maleCount'] == null && data['maleCount'] != null) {
        customOptions['maleCount'] = data['maleCount'];
      }
      if (customOptions['femaleCount'] == null && data['femaleCount'] != null) {
        customOptions['femaleCount'] = data['femaleCount'];
      }
      // manager 폴백
      if (customOptions['manager'] == null && customOptions['managerName'] == null) {
        final mgr = data['managerName'] as String?;
        if (mgr != null && mgr.isNotEmpty) customOptions['manager'] = mgr;
      }
      // item.customOptions에서 색상/인쇄옵션 폴백 (최상위 customOptions에 없는 경우)
      if (items.isNotEmpty && items.first.customOptions != null) {
        final itemOpts = items.first.customOptions!;
        if (customOptions['mainColor'] == null && itemOpts['mainColor'] != null) {
          customOptions['mainColor'] = itemOpts['mainColor'];
        }
        if (customOptions['printType'] == null && itemOpts['printType'] != null) {
          customOptions['printType'] = itemOpts['printType'];
        }
        if (customOptions['waistband'] == null && itemOpts['waistband'] != null) {
          customOptions['waistbandOption'] = itemOpts['waistband'];
        }
        if (customOptions['fabric'] == null && itemOpts['fabric'] != null) {
          customOptions['fabric'] = itemOpts['fabric'];
        }
        if (customOptions['designFileUrl'] == null && itemOpts['designFileUrl'] != null) {
          customOptions['designFileUrl'] = itemOpts['designFileUrl'];
        }
      }

      // ── orderType 보정: 실제 단체주문 특성으로 자동 판별 ──
      String resolvedOrderType = data['orderType'] as String? ?? 'personal';
      if (resolvedOrderType == 'personal') {
        final hasPersons = (customOptions['persons'] as List?)?.isNotEmpty == true;
        final hasTeamName = (customOptions['teamName'] as String?)?.isNotEmpty == true;
        // GRP_/GROUP- 접두사 또는 persons+teamName 모두 있으면 단체주문
        final isGrpId = docId.startsWith('GRP_') || docId.startsWith('GROUP-');
        if (isGrpId || (hasPersons && hasTeamName)) {
          final isAdditional = docId.contains('ADD') ||
              customOptions['isAdditional'] == true ||
              data['isAdditionalOrder'] == true;
          resolvedOrderType = isAdditional ? 'additional' : 'group';
        }
      }

      // 주소: userAddress 없으면 deliveryAddress 사용
      final userAddress = (data['userAddress'] as String?)?.isNotEmpty == true
          ? data['userAddress'] as String
          : (data['deliveryAddress'] as String? ?? '');

      return OrderModel(
        id: docId,
        userId: data['userId'] as String? ?? '',
        userName: data['userName'] as String? ?? '',
        userEmail: data['userEmail'] as String? ?? '',
        userPhone: data['userPhone'] as String? ?? '',
        userAddress: userAddress,
        items: items,
        totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
        shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0,
        paymentMethod: data['paymentMethod'] as String? ?? '',
        status: status,
        orderType: resolvedOrderType,
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
      bold: true, fontSize: 14,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true, fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#2D2D5E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final maleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#DBEAFE'),
      fontColorHex: ExcelColor.fromHexString('#1565C0'),
      bold: true, fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
    );
    final femaleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FCE4EC'),
      fontColorHex: ExcelColor.fromHexString('#AD1457'),
      bold: true, fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
    );
    final evenRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F0F4FF'),
      fontSize: 10,
    );
    final oddRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontSize: 10,
    );
    final totalStyle = CellStyle(
      bold: true, fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#D4EDDA'),
      fontColorHex: ExcelColor.fromHexString('#155724'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final labelStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'),
      fontColorHex: ExcelColor.fromHexString('#E65100'),
    );
    final separatorStyle = CellStyle(
      bold: true, fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#CFD8DC'),
      fontColorHex: ExcelColor.fromHexString('#263238'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final detailStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
      fontColorHex: ExcelColor.fromHexString('#4527A0'),
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
    );
    final subTotalStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#FFF9C4'),
      fontColorHex: ExcelColor.fromHexString('#F57F17'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // 단체/커스텀 주문과 개인 주문 분리
    final groupOrders = orders.where(_isGroupOrder).toList();
    final personalOrders = orders.where((o) => !_isGroupOrder(o)).toList();

    // ══════════════════════════════════════════════════════════
    // 시트 1: 전체 주문 요약
    // ══════════════════════════════════════════════════════════
    final summarySheet = excel['주문요약'];
    excel.setDefaultSheet('주문요약');

    _setCell(summarySheet, 0, 0,
        '2FIT MALL 선택 주문 내역 (${orders.length}건) — 출력: ${_fmtFull(exportedAt)}',
        style: titleStyle, border: false);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0));
    summarySheet.setRowHeight(0, 30);

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
    summarySheet.setRowHeight(3, 22);

    int rowIdx = 4;
    int orderNo = 1;
    for (final order in orders) {
      final opts = order.customOptions ?? {};
      final isGroup = order.orderType == 'group' || order.orderType == 'additional';
      final isEven = orderNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : oddRowStyle;

      final imageUrl = _extractDesignImageUrl(order);
      final colorInfo = _extractColorInfo(order);
      final colorHex  = _extractColorHex(order);
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
      _setColorCell(summarySheet, rowIdx, 8, colorInfo, baseStyle: rowStyle, overrideHex: colorHex);
      _setCell(summarySheet, rowIdx, 9,
          opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-',
          style: rowStyle);
      _setCell(summarySheet, rowIdx, 10,
          opts['defaultLength']?.toString() ?? '-', style: rowStyle);
      _setWaistbandCell(summarySheet, rowIdx, 11, opts, baseStyle: rowStyle);
      _setCell(summarySheet, rowIdx, 12, totalQty, style: rowStyle);
      _setCell(summarySheet, rowIdx, 13,
          maleCount > 0 ? maleCount : '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 14,
          femaleCount > 0 ? femaleCount : '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 15, imageUrl.isNotEmpty ? imageUrl : '-', style: rowStyle);
      _setCell(summarySheet, rowIdx, 16, _statusLabel(order.status), style: rowStyle);
      summarySheet.setRowHeight(rowIdx, 18);

      rowIdx++;
      orderNo++;
    }

    // 합계 행
    for (var i = 0; i < summaryHeaders.length; i++) {
      _setCell(summarySheet, rowIdx, i, i == 0 ? '합 계' : '', style: totalStyle);
    }
    _setCell(summarySheet, rowIdx, 12,
        orders.fold<int>(0, (s, o) => s + o.items.fold<int>(0, (si, i) => si + i.quantity)),
        style: totalStyle);
    _setCell(summarySheet, rowIdx, 13,
        orders.fold<int>(0, (s, o) => s + _countGender(o, '남')),
        style: totalStyle);
    _setCell(summarySheet, rowIdx, 14,
        orders.fold<int>(0, (s, o) => s + _countGender(o, '여')),
        style: totalStyle);
    summarySheet.setRowHeight(rowIdx, 20);

    final summaryColWidths = [
      4.0, 22.0, 17.0, 10.0, 16.0,
      12.0, 14.0, 18.0, 14.0, 14.0,
      10.0, 12.0, 8.0, 7.0, 7.0,
      46.0, 10.0,
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
    sizeSheet.setRowHeight(0, 22);

    int sRowIdx = 1;
    int sNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final persons = (opts['persons'] as List<dynamic>?) ?? [];
      if (persons.isEmpty) {
        final rowStyle = sNo.isOdd ? oddRowStyle : evenRowStyle;
        _setCell(sizeSheet, sRowIdx, 0, '$sNo', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 1, _shortId(order.id), style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 3, opts['teamName']?.toString() ?? order.groupName ?? '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 4, '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 5, order.userName, style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 6, '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 7, order.items.isNotEmpty ? order.items.first.size : '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 8, '-', style: rowStyle);
        _setCell(sizeSheet, sRowIdx, 9, opts['defaultLength']?.toString() ?? '-', style: rowStyle);
        _setColorCell(sizeSheet, sRowIdx, 10, _extractColorInfo(order), overrideHex: _extractColorHex(order));
        for (var c = 11; c < sizeHeaders.length; c++) {
          _setCell(sizeSheet, sRowIdx, c, '-', style: rowStyle);
        }
        sizeSheet.setRowHeight(sRowIdx, 17);
        sRowIdx++;
        sNo++;
        continue;
      }

      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
      final mainColor = opts['mainColor']?.toString() ?? '-';
      final defaultLength = opts['defaultLength']?.toString() ?? '';
      final printType = opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-';

      // ── 팀 헤더 행 ──
      _setCell(sizeSheet, sRowIdx, 0,
          '▶ $teamName  |  ${_fmtFull(order.createdAt)}  |  총 ${persons.length}명',
          style: separatorStyle, border: false);
      sizeSheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sRowIdx),
          CellIndex.indexByColumnRow(columnIndex: sizeHeaders.length - 1, rowIndex: sRowIdx));
      sizeSheet.setRowHeight(sRowIdx, 20);
      sRowIdx++;

      int teamMale = 0, teamFemale = 0;

      for (var i = 0; i < persons.length; i++) {
        final p = persons[i] as Map<String, dynamic>;
        final gender = p['gender']?.toString() ?? '';
        final gStyle = gender == '남' ? maleStyle : (gender == '여' ? femaleStyle : (sNo.isOdd ? oddRowStyle : evenRowStyle));
        if (gender == '남') teamMale++;
        if (gender == '여') teamFemale++;

        final height = p['height']?.toString() ?? '';
        final weight = p['weight']?.toString() ?? '';
        final waist = p['waist']?.toString() ?? '';
        final thigh = p['thigh']?.toString() ?? '';
        final hasDetail = height.isNotEmpty || weight.isNotEmpty || waist.isNotEmpty || thigh.isNotEmpty;
        final personalLength = p['bottomLength']?.toString() ?? '';
        final personColor = p['color']?.toString() ?? '';

        _setCell(sizeSheet, sRowIdx, 0, '$sNo', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 1, _shortId(order.id), style: gStyle);
        _setCell(sizeSheet, sRowIdx, 2, _fmtFull(order.createdAt), style: gStyle);
        _setCell(sizeSheet, sRowIdx, 3, teamName, style: gStyle);
        _setCell(sizeSheet, sRowIdx, 4, '${(p['index'] ?? i + 1)}번', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 5,
            p['name']?.toString().isNotEmpty == true ? p['name']!.toString() : '-', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 6, gender.isNotEmpty ? gender : '-', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 7,
            p['topSize']?.toString().isNotEmpty == true ? p['topSize']!.toString() : '-', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 8,
            p['bottomSize']?.toString().isNotEmpty == true ? p['bottomSize']!.toString() : '-', style: gStyle);
        _setCell(sizeSheet, sRowIdx, 9,
            personalLength.isNotEmpty ? personalLength : (defaultLength.isNotEmpty ? defaultLength : '개별'), style: gStyle);
        _setColorCell(sizeSheet, sRowIdx, 10,
            personColor.isNotEmpty ? personColor : mainColor);
        _setCell(sizeSheet, sRowIdx, 11, hasDetail && height.isNotEmpty ? height : '', style: hasDetail ? detailStyle : gStyle);
        _setCell(sizeSheet, sRowIdx, 12, hasDetail && weight.isNotEmpty ? weight : '', style: hasDetail ? detailStyle : gStyle);
        _setCell(sizeSheet, sRowIdx, 13, hasDetail && waist.isNotEmpty ? waist : '', style: hasDetail ? detailStyle : gStyle);
        _setCell(sizeSheet, sRowIdx, 14, hasDetail && thigh.isNotEmpty ? thigh : '', style: hasDetail ? detailStyle : gStyle);
        _setCell(sizeSheet, sRowIdx, 15, printType, style: gStyle);
        _setWaistbandCell(sizeSheet, sRowIdx, 16, opts);
        _setCell(sizeSheet, sRowIdx, 17, hasDetail ? '상세치수' : '', style: gStyle);
        sizeSheet.setRowHeight(sRowIdx, 17);

        sRowIdx++;
        sNo++;
      }

      // ── 팀 소계 행 ──
      _setCell(sizeSheet, sRowIdx, 0, '소계', style: subTotalStyle);
      _setCell(sizeSheet, sRowIdx, 1, teamName, style: subTotalStyle);
      _setCell(sizeSheet, sRowIdx, 2, '총 ${persons.length}명', style: subTotalStyle);
      _setCell(sizeSheet, sRowIdx, 3, '남 $teamMale명', style: subTotalStyle);
      _setCell(sizeSheet, sRowIdx, 4, '여 $teamFemale명', style: subTotalStyle);
      for (var c = 5; c < sizeHeaders.length; c++) {
        _setCell(sizeSheet, sRowIdx, c, '', style: subTotalStyle);
      }
      sizeSheet.setRowHeight(sRowIdx, 18);
      sRowIdx++;
    }

    // 개인 주문도 포함
    for (final order in personalOrders) {
      final rowStyle = sNo.isOdd ? oddRowStyle : evenRowStyle;
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
        _setColorCell(sizeSheet, sRowIdx, 10, item.color, baseStyle: rowStyle);
        for (var c = 11; c < sizeHeaders.length; c++) {
          _setCell(sizeSheet, sRowIdx, c, '-', style: rowStyle);
        }
        sizeSheet.setRowHeight(sRowIdx, 17);
        sRowIdx++;
        sNo++;
      }
    }

    final sizeColWidths = [
      4.0, 18.0, 15.0, 14.0, 8.0, 12.0, 6.0,
      10.0, 10.0, 10.0, 13.0,
      8.0, 10.0, 8.0, 10.0,
      14.0, 12.0, 10.0,
    ];
    for (var i = 0; i < sizeColWidths.length; i++) {
      sizeSheet.setColumnWidth(i, sizeColWidths[i]);
    }

    // ══════════════════════════════════════════════════════════
    // 시트 3: 디자인 이미지 & 주문 상세 (실제 이미지 삽입)
    // ══════════════════════════════════════════════════════════
    final imageSheet = excel['디자인이미지및상세'];

    // 이미지 컬럼: 12=상품이미지, 13=참조이미지
    final imgHeaders = [
      'No', '주문번호', '주문날짜', '단체명', '상품명',
      '인쇄옵션', '색상', '하의길이', '허리밴드', '총수량', '남', '여',
      '상품이미지', '남자참조이미지', '메모',
    ];
    for (var i = 0; i < imgHeaders.length; i++) {
      _setCell(imageSheet, 0, i, imgHeaders[i], style: headerStyle);
    }

    // 이미지 삽입 목록 (나중에 _insertImagesIntoXlsx에 전달)
    final List<_ImageToInsert> selectedImagesToInsert = [];
    // 이미지 시트 인덱스: excel의 시트 목록에서 '디자인이미지및상세' 위치
    // 주문요약(0), 사이즈목록(1), 디자인이미지및상세(2) 순서
    const int imgSheetIdx = 2;
    const int imgRowHeightPx = 120; // 행 높이 120px

    int imgRowIdx = 1;
    int imgNo = 1;
    for (final order in orders) {
      final opts = order.customOptions ?? {};
      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
      final isEven = imgNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : null;

      final maleRefUrl = opts['maleRefImageUrl']?.toString() ?? '';
      final productImgUrl = _extractDesignImageUrl(order);

      final colorInfo = _extractColorInfo(order);
      final colorHex2 = _extractColorHex(order);
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
      _setColorCell(imageSheet, imgRowIdx, 6, colorInfo, baseStyle: rowStyle, overrideHex: colorHex2);
      _setCell(imageSheet, imgRowIdx, 7,
          opts['defaultLength']?.toString() ?? '-', style: rowStyle);
      _setWaistbandCell(imageSheet, imgRowIdx, 8, opts, baseStyle: rowStyle);
      _setCell(imageSheet, imgRowIdx, 9, totalQty, style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 10, maleCount > 0 ? maleCount : '-', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 11, femaleCount > 0 ? femaleCount : '-', style: rowStyle);
      // 이미지 컬럼: 텍스트 비워두고 실제 이미지 삽입 예약
      _setCell(imageSheet, imgRowIdx, 12, '', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 13, '', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 14,
          opts['memoText']?.toString() ?? order.memo ?? '', style: rowStyle);

      // 상품 이미지 삽입 예약
      if (productImgUrl.isNotEmpty) {
        selectedImagesToInsert.add(_ImageToInsert(
          url: productImgUrl,
          sheetIndex: imgSheetIdx,
          row: imgRowIdx + 1, // 1-based
          col: 12,
          widthPx: 160, heightPx: imgRowHeightPx,
          label: '상품이미지_$imgNo',
        ));
      }
      // 참조 이미지 삽입 예약
      if (maleRefUrl.isNotEmpty) {
        selectedImagesToInsert.add(_ImageToInsert(
          url: maleRefUrl,
          sheetIndex: imgSheetIdx,
          row: imgRowIdx + 1, // 1-based
          col: 13,
          widthPx: 160, heightPx: imgRowHeightPx,
          label: '참조이미지_$imgNo',
        ));
      }

      imgRowIdx++;
      imgNo++;
    }

    final imgColWidths = [
      5.0, 22.0, 16.0, 14.0, 20.0,
      16.0, 16.0, 12.0, 14.0, 8.0, 6.0, 6.0,
      22.0, 22.0, 25.0, // 이미지 컬럼 폭 조정 (22 = ~160px)
    ];
    for (var i = 0; i < imgColWidths.length; i++) {
      imageSheet.setColumnWidth(i, imgColWidths[i]);
    }

    excel.setDefaultSheet('주문요약');
    final baseBytes = excel.encode()!;

    // 이미지 없으면 바로 반환
    if (selectedImagesToInsert.isEmpty) return Uint8List.fromList(baseBytes);

    // 이미지 다운로드 (병렬)
    await Future.wait(selectedImagesToInsert.map((img) async {
      try {
        final resp = await http.get(Uri.parse(img.url))
            .timeout(const Duration(seconds: 20));
        if (resp.statusCode == 200) {
          img.bytes = resp.bodyBytes;
          final ct = resp.headers['content-type'] ?? '';
          img.ext = (ct.contains('png') || img.url.toLowerCase().contains('.png')) ? 'png' : 'jpeg';
        }
      } catch (_) {}
    }));

    return _insertImagesIntoXlsx(Uint8List.fromList(baseBytes), selectedImagesToInsert);
  }

  // ════════════════════════════════════════════════════════════════
  // 일일 마감 엑셀 생성 (전날 13시~당일 13시, 단체주문 전용)
  // ════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateDailyGroupOrderExcel(
      List<OrderModel> orders, DateTime start, DateTime end) async {
    final excel = Excel.createExcel();

    final groupOrders = orders.where(_isGroupOrder).toList();

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

    summarySheet.setRowHeight(0, 28);
    summarySheet.setRowHeight(1, 22);

    final headers = [
      'No', '주문번호', '주문날짜', '단체명', '담당자', '연락처',
      '인쇄옵션', '색상', '하의길이', '허리밴드',
      '총인원', '남성', '여성', '커스텀옵션', '디자인이미지URL', '메모',
    ];
    for (var i = 0; i < headers.length; i++) {
      _setCell(summarySheet, 3, i, headers[i], style: headerStyle);
    }
    summarySheet.setRowHeight(3, 22);

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
      _setColorCell(summarySheet, rowIdx, 7, _extractColorInfo(order), baseStyle: rowStyle, overrideHex: _extractColorHex(order));
      _setCell(summarySheet, rowIdx, 8, opts['defaultLength']?.toString() ?? '개별선택', style: rowStyle);
      _setWaistbandCell(summarySheet, rowIdx, 9, opts, baseStyle: rowStyle);
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
    sizeSheet.setRowHeight(0, 22);

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
        _setColorCell(sizeSheet, sRowIdx, 10,
            personColor.isNotEmpty ? personColor : mainColor);
        // 상세 신체 치수
        _setCell(sizeSheet, sRowIdx, 11, hasDetail && height.isNotEmpty ? height : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 12, hasDetail && weight.isNotEmpty ? weight : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 13, hasDetail && waist.isNotEmpty ? waist : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 14, hasDetail && thigh.isNotEmpty ? thigh : '', style: hasDetail ? detailStyle : null);
        _setCell(sizeSheet, sRowIdx, 15, printType);
        _setWaistbandCell(sizeSheet, sRowIdx, 16, opts);

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
    // 시트 3: 디자인 이미지 (실제 이미지 삽입)
    // ══════════════════════════════════
    final imageSheet = excel['디자인이미지'];

    final imgHeaders = [
      'No', '주문번호', '주문날짜', '단체명', '상품명',
      '인쇄옵션', '색상', '하의길이', '허리밴드',
      '상품이미지', '남자참조이미지',
    ];
    for (var i = 0; i < imgHeaders.length; i++) {
      _setCell(imageSheet, 0, i, imgHeaders[i], style: headerStyle);
    }

    // 이미지 삽입 목록 (시트 인덱스: 단체주문요약=0, 사이즈=1, 디자인이미지=2)
    final List<_ImageToInsert> dailyImagesToInsert = [];
    const int dailyImgSheetIdx = 2;

    int imgRowIdx = 1;
    int imgNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final isEven = imgNo % 2 == 0;
      final rowStyle = isEven ? evenRowStyle : null;
      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
      final productImgUrl = _extractDesignImageUrl(order);
      final maleRefUrl = opts['maleRefImageUrl']?.toString() ?? '';

      _setCell(imageSheet, imgRowIdx, 0, '$imgNo', style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 1, order.id, style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 2, _fmtFull(order.createdAt), style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 3, teamName, style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 4, order.items.map((i) => i.productName).toSet().join(' / '), style: rowStyle);
      _setCell(imageSheet, imgRowIdx, 5, opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-', style: rowStyle);
      _setColorCell(imageSheet, imgRowIdx, 6, _extractColorInfo(order), baseStyle: rowStyle, overrideHex: _extractColorHex(order));
      _setCell(imageSheet, imgRowIdx, 7, opts['defaultLength']?.toString() ?? '-', style: rowStyle);
      _setWaistbandCell(imageSheet, imgRowIdx, 8, opts, baseStyle: rowStyle);
      _setCell(imageSheet, imgRowIdx, 9, '', style: rowStyle); // 이미지로 대체
      _setCell(imageSheet, imgRowIdx, 10, '', style: rowStyle); // 이미지로 대체

      if (productImgUrl.isNotEmpty) {
        dailyImagesToInsert.add(_ImageToInsert(
          url: productImgUrl,
          sheetIndex: dailyImgSheetIdx,
          row: imgRowIdx + 1,
          col: 9,
          widthPx: 160, heightPx: 120,
          label: '상품이미지_$imgNo',
        ));
      }
      if (maleRefUrl.isNotEmpty) {
        dailyImagesToInsert.add(_ImageToInsert(
          url: maleRefUrl,
          sheetIndex: dailyImgSheetIdx,
          row: imgRowIdx + 1,
          col: 10,
          widthPx: 160, heightPx: 120,
          label: '참조이미지_$imgNo',
        ));
      }

      imgRowIdx++;
      imgNo++;
    }

    final imgColWidths = [
      5.0, 22.0, 16.0, 16.0, 20.0,
      16.0, 16.0, 12.0, 14.0,
      22.0, 22.0, // 이미지 컬럼
    ];
    for (var i = 0; i < imgColWidths.length; i++) {
      imageSheet.setColumnWidth(i, imgColWidths[i]);
    }

    excel.setDefaultSheet('단체주문요약');
    final dailyBase = excel.encode()!;

    if (dailyImagesToInsert.isEmpty) return Uint8List.fromList(dailyBase);

    await Future.wait(dailyImagesToInsert.map((img) async {
      try {
        final resp = await http.get(Uri.parse(img.url))
            .timeout(const Duration(seconds: 20));
        if (resp.statusCode == 200) {
          img.bytes = resp.bodyBytes;
          final ct = resp.headers['content-type'] ?? '';
          img.ext = (ct.contains('png') || img.url.toLowerCase().contains('.png')) ? 'png' : 'jpeg';
        }
      } catch (_) {}
    }));

    return _insertImagesIntoXlsx(Uint8List.fromList(dailyBase), dailyImagesToInsert);
  }

  // ── 기존 generateExcel (개인+단체 통합) 유지 ──
  static Future<Uint8List> generateExcel(
      List<OrderModel> orders, DateTime start, DateTime end) async {
    final excel = Excel.createExcel();

    final groupOrders = orders.where(_isGroupOrder).toList();

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
          _setColorCell(summarySheet, rowIdx, 8, item.color, baseStyle: rowStyle);
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

    // ── 디자인 이미지 시트 추가 (실제 이미지 삽입) ──
    final headerStyle2 = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#2C3E50'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final evenRowStyle2 = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
    );
    final imgSheet = excel['디자인이미지'];
    final baseImgHeaders = [
      'No', '주문번호', '주문날짜', '단체명', '상품명',
      '인쇄옵션', '색상', '하의길이', '허리밴드',
      '상품이미지', '남자참조이미지',
    ];
    for (var i = 0; i < baseImgHeaders.length; i++) {
      _setCell(imgSheet, 0, i, baseImgHeaders[i], style: headerStyle2);
    }
    final List<_ImageToInsert> baseImagesToInsert = [];
    const int baseImgSheetIdx = 1; // 주문요약=0, 디자인이미지=1
    int bImgRowIdx = 1;
    int bImgNo = 1;
    for (final order in groupOrders) {
      final opts = order.customOptions ?? {};
      final isEven = bImgNo % 2 == 0;
      final rowStyle2 = isEven ? evenRowStyle2 : null;
      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
      final productImgUrl = _extractDesignImageUrl(order);
      final maleRefUrl = opts['maleRefImageUrl']?.toString() ?? '';

      _setCell(imgSheet, bImgRowIdx, 0, '$bImgNo', style: rowStyle2);
      _setCell(imgSheet, bImgRowIdx, 1, order.id, style: rowStyle2);
      _setCell(imgSheet, bImgRowIdx, 2, _fmtFull(order.createdAt), style: rowStyle2);
      _setCell(imgSheet, bImgRowIdx, 3, teamName, style: rowStyle2);
      _setCell(imgSheet, bImgRowIdx, 4,
          order.items.map((i) => i.productName).toSet().join(' / '), style: rowStyle2);
      _setCell(imgSheet, bImgRowIdx, 5,
          opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '-', style: rowStyle2);
      _setColorCell(imgSheet, bImgRowIdx, 6, _extractColorInfo(order), baseStyle: rowStyle2, overrideHex: _extractColorHex(order));
      _setCell(imgSheet, bImgRowIdx, 7, opts['defaultLength']?.toString() ?? '-', style: rowStyle2);
      _setWaistbandCell(imgSheet, bImgRowIdx, 8, opts, baseStyle: rowStyle2);
      _setCell(imgSheet, bImgRowIdx, 9, '', style: rowStyle2);
      _setCell(imgSheet, bImgRowIdx, 10, '', style: rowStyle2);

      if (productImgUrl.isNotEmpty) {
        baseImagesToInsert.add(_ImageToInsert(
          url: productImgUrl,
          sheetIndex: baseImgSheetIdx,
          row: bImgRowIdx + 1,
          col: 9,
          widthPx: 160, heightPx: 120,
          label: '상품이미지_$bImgNo',
        ));
      }
      if (maleRefUrl.isNotEmpty) {
        baseImagesToInsert.add(_ImageToInsert(
          url: maleRefUrl,
          sheetIndex: baseImgSheetIdx,
          row: bImgRowIdx + 1,
          col: 10,
          widthPx: 160, heightPx: 120,
          label: '참조이미지_$bImgNo',
        ));
      }
      bImgRowIdx++;
      bImgNo++;
    }
    final baseImgColWidths = [
      5.0, 22.0, 16.0, 16.0, 20.0,
      16.0, 16.0, 12.0, 14.0,
      22.0, 22.0,
    ];
    for (var i = 0; i < baseImgColWidths.length; i++) {
      imgSheet.setColumnWidth(i, baseImgColWidths[i]);
    }

    excel.setDefaultSheet('주문요약');
    final baseBytes2 = excel.encode()!;

    if (baseImagesToInsert.isEmpty) return Uint8List.fromList(baseBytes2);

    await Future.wait(baseImagesToInsert.map((img) async {
      try {
        final resp = await http.get(Uri.parse(img.url))
            .timeout(const Duration(seconds: 20));
        if (resp.statusCode == 200) {
          img.bytes = resp.bodyBytes;
          final ct = resp.headers['content-type'] ?? '';
          img.ext = (ct.contains('png') || img.url.toLowerCase().contains('.png')) ? 'png' : 'jpeg';
        }
      } catch (_) {}
    }));

    return _insertImagesIntoXlsx(Uint8List.fromList(baseBytes2), baseImagesToInsert);
  }

  // ── 단체주문 개별 엑셀 생성 (개선판) ── async 버전 (이미지 실제 삽입)
  static Future<Uint8List> generateGroupOrderExcelAsync(OrderModel order) async {
    final opts = order.customOptions ?? {};
    // customOptions 우선, 없으면 item.imageUrl 사용
    final productImageUrl = opts['productImageUrl']?.toString() ??
        opts['designImageUrl']?.toString() ??
        opts['imageUrl']?.toString() ??
        order.items.firstWhere(
          (i) => i.imageUrl != null && i.imageUrl!.isNotEmpty,
          orElse: () => order.items.isNotEmpty ? order.items.first : OrderItem(
            productId: '', productName: '', size: '', color: '',
            quantity: 0, price: 0,
          ),
        ).imageUrl ?? '';
    final designFileUrl = opts['designFileUrl']?.toString() ??
        opts['maleRefImageUrl']?.toString() ?? '';

    // 1) 기본 xlsx 바이트 생성 (sync)
    final baseBytes = generateGroupOrderExcel(order);

    // 2) 다운로드할 이미지 목록
    // generateGroupOrderExcel에서 row 1부터 이미지 행을 생성하므로 동일 위치에 삽입
    // A열(0)=레이블, B열(1)~D열(3)=이미지 영역(merge됨)
    final List<_ImageToInsert> imagesToInsert = [];
    int imgRow = 1; // 1-based Excel row (row 0 = 제목행)
    if (productImageUrl.isNotEmpty) {
      imagesToInsert.add(_ImageToInsert(
        url: productImageUrl,
        sheetIndex: 0,  // '주문정보' 시트
        row: imgRow,    // 1-based
        col: 1,         // B열 (A열은 레이블)
        widthPx: 260,
        heightPx: 195,
        label: '디자인이미지',
      ));
      imgRow++;
    }
    if (designFileUrl.isNotEmpty) {
      imagesToInsert.add(_ImageToInsert(
        url: designFileUrl,
        sheetIndex: 0,
        row: imgRow,
        col: 1,         // B열
        widthPx: 260,
        heightPx: 195,
        label: '참조이미지',
      ));
    }

    if (imagesToInsert.isEmpty) return baseBytes;

    // 3) 이미지 다운로드
    for (final img in imagesToInsert) {
      try {
        final resp = await http.get(Uri.parse(img.url))
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) {
          img.bytes = resp.bodyBytes;
          // 확장자 판별
          final ct = resp.headers['content-type'] ?? '';
          if (ct.contains('png') || img.url.toLowerCase().contains('.png')) {
            img.ext = 'png';
          } else {
            img.ext = 'jpeg';
          }
        }
      } catch (_) {
        // 다운로드 실패 → 해당 이미지는 삽입 건너뜀
      }
    }

    // 4) xlsx ZIP에 이미지 삽입
    return _insertImagesIntoXlsx(baseBytes, imagesToInsert);
  }

  // ─────────────────────────────────────────────────────────────
  // xlsx ZIP에 이미지를 직접 삽입하는 유틸 함수
  // ─────────────────────────────────────────────────────────────
  static Uint8List _insertImagesIntoXlsx(
      Uint8List xlsxBytes, List<_ImageToInsert> images) {
    try {
      final archive = ZipDecoder().decodeBytes(xlsxBytes);

      // 시트별로 그룹화
      final Map<int, List<_ImageToInsert>> bySheet = {};
      for (final img in images) {
        if (img.bytes == null) continue;
        bySheet.putIfAbsent(img.sheetIndex, () => []).add(img);
      }
      if (bySheet.isEmpty) return xlsxBytes;

      // workbook.xml에서 시트 rId 목록 추출
      final wbFile = archive.findFile('xl/workbook.xml');
      if (wbFile == null) return xlsxBytes;
      final wbXml = utf8.decode(wbFile.content as List<int>);

      // workbook.xml.rels에서 sheetIndex→파일명 매핑
      final wbRelsFile = archive.findFile('xl/_rels/workbook.xml.rels');
      final Map<String, String> rIdToSheet = {}; // rId → xl/worksheets/sheetN.xml
      if (wbRelsFile != null) {
        final relsXml = utf8.decode(wbRelsFile.content as List<int>);
        final relRe = RegExp(
            r'<Relationship[^>]*Id="([^"]+)"[^>]*Target="([^"]+)"',
            multiLine: true);
        for (final m in relRe.allMatches(relsXml)) {
          final target = m.group(2)!;
          if (target.contains('sheet')) {
            rIdToSheet[m.group(1)!] =
                target.startsWith('worksheets') ? 'xl/$target' : target;
          }
        }
      }

      // workbook.xml의 sheet 순서로 rId 리스트 추출
      final sheetRe =
          RegExp(r'<sheet\b[^>]*r:id="([^"]+)"', multiLine: true);
      final sheetRIds = sheetRe
          .allMatches(wbXml)
          .map((m) => m.group(1)!)
          .toList();

      final List<ArchiveFile> newFiles = [];

      for (final entry in bySheet.entries) {
        final sheetIdx = entry.key;
        final imgs = entry.value;
        if (sheetIdx >= sheetRIds.length) continue;

        final sheetRId = sheetRIds[sheetIdx];
        final sheetPath = rIdToSheet[sheetRId];
        if (sheetPath == null) continue;

        // sheetN.xml 경로에서 N 추출
        final sheetNumMatch =
            RegExp(r'sheet(\d+)\.xml').firstMatch(sheetPath);
        if (sheetNumMatch == null) continue;
        final sheetNum = sheetNumMatch.group(1)!;

        // 기존 drawing 관계가 있는지 확인
        final sheetRelsPath =
            'xl/worksheets/_rels/sheet$sheetNum.xml.rels';
        final existingRelsFile = archive.findFile(sheetRelsPath);
        String existingRelsXml = existingRelsFile != null
            ? utf8.decode(existingRelsFile.content as List<int>)
            : '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n</Relationships>';

        // 이미 drawing 관계가 있으면 drawingN 번호 추출, 없으면 새로 추가
        final drawingRe =
            RegExp(r'drawing(\d+)\.xml', caseSensitive: false);
        final existingDrawingMatch =
            drawingRe.firstMatch(existingRelsXml);
        final drawingNum = existingDrawingMatch != null
            ? existingDrawingMatch.group(1)!
            : sheetNum;
        final drawingPath = 'xl/drawings/drawing$drawingNum.xml';
        final drawingRelsPath =
            'xl/drawings/_rels/drawing$drawingNum.xml.rels';

        // 이미지 파일 추가 + drawing XML 빌드
        final drawingRelsEntries = <String>[];
        final drawingAnchors = <String>[];
        int imgIdCounter = 1;

        // 기존 drawing.xml.rels가 있으면 기존 rId 번호 이어받기
        final existingDrawingRelsFile =
            archive.findFile(drawingRelsPath);
        int nextRId = 1;
        if (existingDrawingRelsFile != null) {
          final existingDRXml = utf8.decode(
              existingDrawingRelsFile.content as List<int>);
          final ridNums = RegExp(r'Id="rId(\d+)"')
              .allMatches(existingDRXml)
              .map((m) => int.tryParse(m.group(1)!) ?? 0)
              .toList();
          if (ridNums.isNotEmpty) {
            nextRId = ridNums.reduce((a, b) => a > b ? a : b) + 1;
          }
          drawingRelsEntries
              .add(existingDRXml.replaceAll('</Relationships>', ''));
        } else {
          drawingRelsEntries.add(
              '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
              '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
        }

        // 기존 drawing.xml이 있으면 앵커 이어받기
        final existingDrawingFile = archive.findFile(drawingPath);
        String existingDrawingContent = '';
        if (existingDrawingFile != null) {
          existingDrawingContent =
              utf8.decode(existingDrawingFile.content as List<int>);
          // 닫는 태그 제거
          existingDrawingContent = existingDrawingContent
              .replaceAll('</xdr:wsDr>', '')
              .replaceAll('</wsDr>', '');
        }

        for (final img in imgs) {
          if (img.bytes == null) continue;
          final mediaName = 'image_${sheetNum}_$imgIdCounter.${img.ext}';
          final mediaPath = 'xl/media/$mediaName';
          final rId = 'rId$nextRId';

          // 이미지 파일 추가
          newFiles.add(ArchiveFile(
              mediaPath, img.bytes!.length, img.bytes!));

          // drawing.xml.rels 항목
          final mimeType =
              img.ext == 'png' ? 'image/png' : 'image/jpeg';
          drawingRelsEntries.add(
              '  <Relationship Id="$rId" '
              'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
              'Target="../media/$mediaName"/>');

          // EMU 변환 (1px ≈ 9525 EMU at 96dpi)
          final wEmu = img.widthPx * 9525;
          final hEmu = img.heightPx * 9525;

          // oneCellAnchor: from 셀에서 시작, EMU 크기로 고정 표시
          // row/col은 0-based
          final anchorRow = img.row - 1; // 0-based
          final anchorCol = img.col;     // 열 index

          drawingAnchors.add('''
  <xdr:oneCellAnchor>
    <xdr:from>
      <xdr:col>$anchorCol</xdr:col><xdr:colOff>91440</xdr:colOff>
      <xdr:row>$anchorRow</xdr:row><xdr:rowOff>91440</xdr:rowOff>
    </xdr:from>
    <xdr:ext cx="$wEmu" cy="$hEmu"/>
    <xdr:pic>
      <xdr:nvPicPr>
        <xdr:cNvPr id="${100 + imgIdCounter}" name="${img.label}$imgIdCounter"/>
        <xdr:cNvPicPr><a:picLocks noChangeAspect="1"/></xdr:cNvPicPr>
      </xdr:nvPicPr>
      <xdr:blipFill>
        <a:blip r:embed="$rId" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
        <a:stretch><a:fillRect/></a:stretch>
      </xdr:blipFill>
      <xdr:spPr>
        <a:xfrm><a:off x="0" y="0"/><a:ext cx="$wEmu" cy="$hEmu"/></a:xfrm>
        <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
      </xdr:spPr>
    </xdr:pic>
    <xdr:clientData/>
  </xdr:oneCellAnchor>''');

          nextRId++;
          imgIdCounter++;
        }

        // drawing.xml 생성/갱신
        final drawingXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" '
            'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            '${existingDrawingContent.contains('<xdr:wsDr') ? '' : ''}'
            '${drawingAnchors.join('\n')}\n</xdr:wsDr>';
        final drawingBytes = utf8.encode(drawingXml);
        newFiles.add(
            ArchiveFile(drawingPath, drawingBytes.length, drawingBytes));

        // drawing.xml.rels 생성/갱신
        final drawingRelsXml =
            '${drawingRelsEntries.join('\n')}\n</Relationships>';
        final drawingRelsBytes = utf8.encode(drawingRelsXml);
        newFiles.add(ArchiveFile(
            drawingRelsPath, drawingRelsBytes.length, drawingRelsBytes));

        // sheet.xml에 <drawing r:id="rId_drawing"/> 추가 (아직 없을 때만)
        final sheetFile = archive.findFile(sheetPath);
        if (sheetFile != null) {
          var sheetXml =
              utf8.decode(sheetFile.content as List<int>);
          final drawingRIdInSheet = 'rIdD$sheetNum';
          if (!sheetXml.contains('<drawing ') &&
              !sheetXml.contains('<drawing\t')) {
            // </sheetData> 뒤 또는 </worksheet> 바로 앞에 삽입
            final insertTag =
                '<drawing r:id="$drawingRIdInSheet"/>';
            if (sheetXml.contains('</sheetData>')) {
              sheetXml = sheetXml.replaceFirst(
                  '</sheetData>',
                  '</sheetData>$insertTag');
            } else {
              sheetXml = sheetXml.replaceFirst(
                  '</worksheet>', '$insertTag</worksheet>');
            }
            // xmlns:r 이미 있는지 확인
            if (!sheetXml.contains('xmlns:r=')) {
              sheetXml = sheetXml.replaceFirst(
                  '<worksheet ',
                  '<worksheet xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ');
            }
            final sheetBytes = utf8.encode(sheetXml);
            newFiles.add(ArchiveFile(
                sheetPath, sheetBytes.length, sheetBytes));
          }

          // sheet.xml.rels에 drawing 관계 추가
          if (existingRelsFile != null) {
            if (!existingRelsXml.contains(drawingRIdInSheet)) {
              final drawingRelEntry =
                  '  <Relationship Id="$drawingRIdInSheet" '
                  'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" '
                  'Target="../drawings/drawing$drawingNum.xml"/>';
              existingRelsXml = existingRelsXml.replaceFirst(
                  '</Relationships>',
                  '$drawingRelEntry\n</Relationships>');
              final updatedRelsBytes = utf8.encode(existingRelsXml);
              newFiles.add(ArchiveFile(sheetRelsPath,
                  updatedRelsBytes.length, updatedRelsBytes));
            }
          } else {
            // rels 파일 자체가 없으면 새로 생성
            final newRelsXml =
                '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
                '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
                '  <Relationship Id="$drawingRIdInSheet" '
                'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" '
                'Target="../drawings/drawing$drawingNum.xml"/>\n'
                '</Relationships>';
            final newRelsBytes = utf8.encode(newRelsXml);
            newFiles.add(ArchiveFile(sheetRelsPath,
                newRelsBytes.length, newRelsBytes));
          }
        }
      }

      // [Content_Types].xml에 drawing 및 media 타입 추가
      final ctFile = archive.findFile('[Content_Types].xml');
      if (ctFile != null) {
        var ctXml = utf8.decode(ctFile.content as List<int>);

        // drawing ContentType
        const drawingCT =
            '<Override PartName="/xl/drawings/drawing1.xml" '
            'ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>';
        if (!ctXml.contains('drawing+xml')) {
          ctXml = ctXml.replaceFirst(
              '</Types>', '$drawingCT\n</Types>');
        }
        // PNG
        const pngCT =
            '<Default Extension="png" ContentType="image/png"/>';
        if (!ctXml.contains('image/png')) {
          ctXml =
              ctXml.replaceFirst('</Types>', '$pngCT\n</Types>');
        }
        // JPEG
        const jpgCT =
            '<Default Extension="jpeg" ContentType="image/jpeg"/>';
        if (!ctXml.contains('image/jpeg')) {
          ctXml =
              ctXml.replaceFirst('</Types>', '$jpgCT\n</Types>');
        }
        // jpg
        const jpgCT2 =
            '<Default Extension="jpg" ContentType="image/jpeg"/>';
        if (!ctXml.contains('"jpg"')) {
          ctXml =
              ctXml.replaceFirst('</Types>', '$jpgCT2\n</Types>');
        }

        final ctBytes = utf8.encode(ctXml);
        newFiles.add(
            ArchiveFile('[Content_Types].xml', ctBytes.length, ctBytes));
      }

      // 새 archive 구성 (기존 파일은 유지, 새/수정 파일로 덮어씀)
      final newArchive = Archive();
      final newFilePaths = newFiles.map((f) => f.name).toSet();
      for (final f in archive.files) {
        if (!newFilePaths.contains(f.name)) {
          newArchive.addFile(f);
        }
      }
      for (final f in newFiles) {
        newArchive.addFile(f);
      }

      final encoded = ZipEncoder().encode(newArchive);
      if (encoded == null) return xlsxBytes;
      return Uint8List.fromList(encoded);
    } catch (e) {
      if (kDebugMode) debugPrint('이미지 삽입 오류: $e');
      return xlsxBytes; // 실패 시 원본 반환
    }
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

    // 이미지 URL: customOptions → item.imageUrl 순으로 폴백
    final productImageUrl = opts['productImageUrl']?.toString().isNotEmpty == true
        ? opts['productImageUrl']!.toString()
        : opts['designImageUrl']?.toString().isNotEmpty == true
            ? opts['designImageUrl']!.toString()
            : order.items.firstWhere(
                (i) => i.imageUrl != null && i.imageUrl!.isNotEmpty,
                orElse: () => order.items.isNotEmpty ? order.items.first : OrderItem(
                  productId: '', productName: '', size: '', color: '', quantity: 0, price: 0,
                ),
              ).imageUrl ?? '';
    final designFileUrl = opts['designFileUrl']?.toString() ?? opts['maleRefImageUrl']?.toString() ?? '';
    final bottomColorName = opts['bottomColorName']?.toString() ?? '';

    // 이미지 URL 하이퍼링크 스타일
    final linkStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#1565C0'),
      underline: Underline.Single,
      bold: false,
      fontSize: 10,
    );
    final imgLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 10,
    );
    final imgNoteStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#757575'),
      fontSize: 9,
      italic: true,
    );

    // 이미지 행: URL 텍스트 없이 셀만 넓게 확보 → async 버전에서 실제 이미지 삽입
    int imgRow = 1;
    if (productImageUrl.isNotEmpty) {
      // A열: 이미지 레이블, B열: 이미지 실제 삽입 공간 (비워둠)
      _setCell(summarySheet, imgRow, 0, '디자인이미지', style: imgLabelStyle);
      summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: imgRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: imgRow),
      );
      _setCell(summarySheet, imgRow, 1, '', style: imgNoteStyle);
      summarySheet.setRowHeight(imgRow, 200.0); // 행 높이 200pt = 이미지 표시 충분
      imgRow++;
    }
    if (designFileUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '참조이미지', style: imgLabelStyle);
      summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: imgRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: imgRow),
      );
      _setCell(summarySheet, imgRow, 1, '', style: imgNoteStyle);
      summarySheet.setRowHeight(imgRow, 200.0);
      imgRow++;
    }

    final teamName = opts['teamName']?.toString() ?? order.groupName ?? '-';
    final mainColor = opts['mainColor']?.toString() ?? '-';
    final colorInfo = bottomColorName.isNotEmpty
        ? '상의: $mainColor / 하의: $bottomColorName'
        : mainColor;
    // adjustedColorHex: 실제 사용된 hex (조정값 우선, 없으면 팔레트 검색)
    final adjustedHex = opts['adjustedColorHex']?.toString() ?? '';
    final mainColorHex = adjustedHex.isNotEmpty && adjustedHex.startsWith('#')
        ? adjustedHex
        : _getColorHex(mainColor);

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
      ['허리밴드', _extractWaistbandInfo(opts)],
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
      final key = infoRows[i][0].toString();
      // 색상 항목: 배경색 + hex 코드 함께 표시
      if (key == '색상') {
        _setColorCell(summarySheet, startRow + i, 1, infoRows[i][1].toString(),
            overrideHex: mainColorHex);
      // 허리밴드 항목: 색상변경이면 배경색 적용
      } else if (key == '허리밴드') {
        final wHex = _extractWaistbandHex(opts);
        if (wHex != null) {
          _setColorCell(summarySheet, startRow + i, 1,
              infoRows[i][1].toString(), overrideHex: wHex);
        } else {
          _setCell(summarySheet, startRow + i, 1, infoRows[i][1]);
        }
      } else {
        _setCell(summarySheet, startRow + i, 1, infoRows[i][1]);
      }
    }

    // ── 추가제작 주문인 경우: 기존 주문 정보 별도 섹션 추가 ──
    if (order.orderType == 'additional') {
      final origOrderId    = opts['originalOrderId']?.toString() ?? '';
      final origOrderDate  = opts['originalOrderDate']?.toString() ?? '';
      final origTeamName   = opts['originalTeamName']?.toString() ?? '';
      final origTotalCount = opts['originalTotalCount']?.toString() ?? '';
      final origStatus     = opts['originalStatus']?.toString() ?? '';

      final origHeaderStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#4A148C'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        fontSize: 11,
      );
      final origLabelStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
        fontColorHex: ExcelColor.fromHexString('#4A148C'),
      );

      final origStartRow = startRow + infoRows.length + 2;

      _setCell(summarySheet, origStartRow - 1, 0, '▶ 기존 주문 정보 (원주문)', style: origHeaderStyle);
      summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: origStartRow - 1),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: origStartRow - 1),
      );

      final origRows = [
        ['기존 주문번호', origOrderId.isNotEmpty ? origOrderId : '(미연결)'],
        ['기존 주문일자', origOrderDate.isNotEmpty ? origOrderDate.substring(0, 10) : '-'],
        ['기존 팀명', origTeamName.isNotEmpty ? origTeamName : '-'],
        ['기존 총 인원', origTotalCount.isNotEmpty ? '$origTotalCount명' : '-'],
        ['기존 주문 상태', origStatus.isNotEmpty ? origStatus : '-'],
      ];
      for (var i = 0; i < origRows.length; i++) {
        _setCell(summarySheet, origStartRow + i, 0, origRows[i][0], style: origLabelStyle);
        _setCell(summarySheet, origStartRow + i, 1, origRows[i][1]);
      }
    }

    summarySheet.setColumnWidth(0, 26.0);
    summarySheet.setColumnWidth(1, 70.0);
    summarySheet.setColumnWidth(2, 38.0);
    summarySheet.setColumnWidth(3, 6.0);   // 이미지 삽입 여백
    summarySheet.setColumnWidth(4, 48.0);  // 이미지 표시 열 (E열)
    summarySheet.setColumnWidth(5, 48.0);  // 이미지 표시 열 (F열)
    summarySheet.setColumnWidth(6, 48.0);  // 이미지 표시 열 (G열)

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
      'No', '이름', '성별', '사이즈구분', '상의 사이즈', '하의 사이즈', '하의 길이', '색상',
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

      final sizeType = p['sizeType']?.toString() ?? '성인';
      final juniorStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#E0F2F1'),
        fontColorHex: ExcelColor.fromHexString('#00695C'),
        bold: true,
      );
      final sizeStyle = sizeType == '주니어' ? juniorStyle : rowStyle;

      _setCell(personSheet, i + 2, 0, '${p['index'] ?? i + 1}', style: rowStyle);
      _setCell(personSheet, i + 2, 1, p['name']?.toString().isNotEmpty == true ? p['name']!.toString() : '-', style: gStyle);
      _setCell(personSheet, i + 2, 2, gender.isNotEmpty ? gender : '-', style: gStyle);
      _setCell(personSheet, i + 2, 3, sizeType, style: sizeStyle);
      _setCell(personSheet, i + 2, 4, p['topSize']?.toString().isNotEmpty == true ? p['topSize']!.toString() : '-', style: sizeStyle);
      _setCell(personSheet, i + 2, 5, p['bottomSize']?.toString().isNotEmpty == true ? p['bottomSize']!.toString() : '-', style: sizeStyle);
      _setCell(personSheet, i + 2, 6,
          personalLength.isNotEmpty ? personalLength : (defaultLength.isNotEmpty ? defaultLength : '개별선택'),
          style: rowStyle);
      final usedColor = personColor.isNotEmpty ? personColor : mainColor;
      final personHex = _getColorHex(usedColor) ?? mainColorHex;
      _setColorCell(personSheet, i + 2, 7, usedColor, baseStyle: rowStyle,
          overrideHex: personHex);
      // 상세 신체 치수
      _setCell(personSheet, i + 2, 8, hasDetail && height.isNotEmpty ? height : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 9, hasDetail && weight.isNotEmpty ? weight : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 10, hasDetail && waist.isNotEmpty ? waist : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 11, hasDetail && thigh.isNotEmpty ? thigh : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 12, hasDetail ? '상세치수입력' : '', style: rowStyle);
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
    // 우선순위: customOptions → item.imageUrl → item.customOptions
    final url = opts['productImageUrl']?.toString() ??
        opts['designImageUrl']?.toString() ??
        opts['designFileUrl']?.toString() ??
        opts['imageUrl']?.toString() ??
        '';
    if (url.isNotEmpty) return url;
    // 아이템의 imageUrl 필드 확인 (주문 시 저장된 상품 이미지)
    for (final item in order.items) {
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        return item.imageUrl!;
      }
    }
    // 아이템의 customOptions 이미지 확인
    for (final item in order.items) {
      final itemUrl = item.customOptions?['productImageUrl']?.toString() ??
          item.customOptions?['designFileUrl']?.toString() ??
          item.customOptions?['designImageUrl']?.toString() ??
          item.customOptions?['imageUrl']?.toString() ?? '';
      if (itemUrl.isNotEmpty) return itemUrl;
    }
    return '';
  }

  /// 주문에서 색상 정보 추출
  static String _extractColorInfo(OrderModel order) {
    final opts = order.customOptions ?? {};
    String mainColor = opts['mainColor']?.toString() ?? '';
    // item.customOptions 폴백
    if (mainColor.isEmpty && order.items.isNotEmpty) {
      mainColor = order.items.first.customOptions?['mainColor']?.toString() ?? '';
    }
    final bottomColor = opts['bottomColorName']?.toString() ??
        opts['bottomColor']?.toString() ?? '';
    if (mainColor.isNotEmpty && bottomColor.isNotEmpty) {
      return '상의:$mainColor / 하의:$bottomColor';
    }
    if (mainColor.isNotEmpty) return mainColor;
    // 아이템의 color 필드
    if (order.items.isNotEmpty && order.items.first.color.isNotEmpty) {
      return order.items.first.color;
    }
    return '-';
  }

  /// 허리밴드 옵션 표시 문자열 (색상변경이면 hex 포함)
  static String _extractWaistbandInfo(Map<String, dynamic> opts) {
    final option = opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '-';
    final hex = opts['waistbandColorHex']?.toString() ?? '';
    if (hex.isNotEmpty && hex.startsWith('#') && hex.length == 7) {
      return '$option ($hex)';
    }
    return option;
  }

  /// 허리밴드 색상 hex 추출 (색상변경 선택 시)
  static String? _extractWaistbandHex(Map<String, dynamic> opts) {
    final hex = opts['waistbandColorHex']?.toString() ?? '';
    if (hex.isNotEmpty && hex.startsWith('#') && hex.length == 7) return hex;
    return null;
  }

  /// 허리밴드 셀 설정 (색상변경이면 배경색 적용)
  static void _setWaistbandCell(Sheet sheet, int row, int col,
      Map<String, dynamic> opts, {CellStyle? baseStyle}) {
    final text = _extractWaistbandInfo(opts);
    final hex  = _extractWaistbandHex(opts);
    if (hex != null) {
      _setColorCell(sheet, row, col, text, overrideHex: hex, baseStyle: baseStyle);
    } else {
      _setCell(sheet, row, col, text, style: baseStyle);
    }
  }

  /// 주문에서 adjustedColorHex(실제 조정된 hex) 추출
  /// 없으면 mainColor 이름으로 팔레트에서 hex 반환
  static String? _extractColorHex(OrderModel order) {
    final opts = order.customOptions ?? {};
    // 1순위: 저장된 adjustedColorHex
    final adjusted = opts['adjustedColorHex']?.toString() ?? '';
    if (adjusted.isNotEmpty && adjusted.startsWith('#')) return adjusted;
    // 2순위: mainColor 이름으로 팔레트 검색
    final mainColor = opts['mainColor']?.toString() ?? '';
    if (mainColor.isNotEmpty) return _getColorHex(mainColor);
    return null;
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

  // ── 색상 이름 → Hex 변환 맵 ──
  static const Map<String, String> _colorNameToHex = {
    '블랙':       '#1A1A1A',
    '화이트':     '#F5F5F5',
    '챠콜':       '#3C3C3C',
    '라이트그레이': '#BDBDBD',
    '네이비':     '#0D1B4F',
    '로얄블루':   '#1245A8',
    '스카이블루':  '#3FA9F5',
    '민트':       '#26C9A0',
    '다크그린':   '#1B4332',
    '그린':       '#43A047',
    '레드':       '#CC0000',
    '버건디':     '#6D0E19',
    '핑크':       '#EE82A2',
    '라이트핑크': '#F8BBD0',
    '퍼플':       '#7B1FA2',
    '오렌지':     '#FF6B35',
    '옐로우':     '#FFD600',
    '골드':       '#D4AF37',
    '카키':       '#7D7C48',
    '브라운':     '#795548',
    '베이지':     '#F5E6C8',
    '아이보리':   '#FFFBEA',
    '실버':       '#C0C0C0',
    '형광그린':   '#39FF14',
    '형광핑크':   '#FF1493',
    '형광옐로우': '#FFFF00',
    '네온오렌지': '#FF5F00',
    '코발트':     '#0047AB',
    '라벤더':     '#E6CCFF',
    '피치':       '#FFCBA4',
  };

  /// 색상 이름에서 hex 코드 추출 (상의:XXX / 하의:XXX 형태 지원)
  static String? _getColorHex(String colorName) {
    // 상의/하의 복합 색상에서 첫 번째(상의) 색상 추출
    final name = colorName.contains('/')
        ? colorName.split('/').first.replaceAll('상의:', '').trim()
        : colorName.trim();
    return _colorNameToHex[name];
  }

  /// 색상 이름으로 셀 배경색 적용 + 이름(#HEX) 텍스트 표시
  /// 복합 색상 "상의:블랙 / 하의:네이비" 지원: 첫 번째 색상으로 배경색 결정
  static void _setColorCell(Sheet sheet, int row, int col, String colorText,
      {CellStyle? baseStyle, String? overrideHex}) {
    // 표시할 hex 결정: overrideHex 우선, 없으면 색상 이름에서 추출
    String? hex = overrideHex ?? _getColorHex(colorText);
    // 텍스트에 hex 코드 추가 (이미 포함되어 있지 않은 경우)
    String displayText = colorText;
    if (hex != null && !colorText.contains('#')) {
      displayText = '$colorText ($hex)';
    }
    CellStyle style;
    if (hex != null) {
      final isLight = _isLightColor(hex);
      style = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(hex),
        fontColorHex: ExcelColor.fromHexString(isLight ? '#1A1A1A' : '#FFFFFF'),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        fontSize: 10,
      );
    } else {
      style = baseStyle ?? CellStyle(horizontalAlign: HorizontalAlign.Center);
    }
    _setCell(sheet, row, col, displayText, style: style);
  }

  /// 색상이 밝은지 판단 (YIQ 알고리즘)
  static bool _isLightColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      final r = int.parse(clean.substring(0, 2), radix: 16);
      final g = int.parse(clean.substring(2, 4), radix: 16);
      final b = int.parse(clean.substring(4, 6), radix: 16);
      final yiq = (r * 299 + g * 587 + b * 114) / 1000;
      return yiq >= 128;
    } catch (_) {
      return true;
    }
  }

  // ── 공통 테두리 ──
  static final Border _thinBorder = Border(
    borderColorHex: '#BBBBBB'.excelColor,
    borderStyle: BorderStyle.Thin,
  );
  static final Border _medBorder = Border(
    borderColorHex: '#888888'.excelColor,
    borderStyle: BorderStyle.Medium,
  );

  /// 스타일에 Thin 테두리를 추가해 반환 (배경/폰트 유지)
  static CellStyle _withBorder(CellStyle? base, {bool thick = false}) {
    final b = thick ? _medBorder : _thinBorder;
    if (base == null) {
      return CellStyle(
        leftBorder: b, rightBorder: b, topBorder: b, bottomBorder: b,
        fontSize: 10,
      );
    }
    return CellStyle(
      bold: base.isBold,
      italic: base.isItalic,
      fontSize: base.fontSize ?? 10,
      fontFamily: base.fontFamily,
      fontColorHex: base.fontColor,
      backgroundColorHex: base.backgroundColor,
      horizontalAlign: base.horizontalAlignment,
      verticalAlign: base.verticalAlignment,
      leftBorder: b, rightBorder: b, topBorder: b, bottomBorder: b,
    );
  }

  // ── 헬퍼 함수들 ──
  static void _setCell(Sheet sheet, int row, int col, dynamic value,
      {CellStyle? style, bool border = true}) {
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
    cell.cellStyle = border ? _withBorder(style) : (style ?? CellStyle());
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
        if (c == 6) {
          // 색상 컬럼: 실제 색상 배경 적용
          _setColorCell(sz, r + 3, c, row[c]);
        } else {
          _setCell(sz, r + 3, c, row[c], style: c == 2 ? genderStyle : (r.isEven ? evenRowStyle : null));
        }
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

/// 이미지 삽입 정보를 담는 내부 헬퍼 클래스
class _ImageToInsert {
  final String url;
  final int sheetIndex; // 0-based
  final int row;        // 1-based Excel row
  final int col;        // 0-based column index
  final int widthPx;
  final int heightPx;
  final String label;
  Uint8List? bytes;
  String ext; // 'png' or 'jpeg'

  _ImageToInsert({
    required this.url,
    required this.sheetIndex,
    required this.row,
    required this.col,
    required this.widthPx,
    required this.heightPx,
    required this.label,
  }) : ext = 'jpeg';
}
