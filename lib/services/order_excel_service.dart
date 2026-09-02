// order_excel_service.dart — 주문 엑셀 내보내기 서비스 (전면 개선판)
// 포함 항목: 디자인이미지URL, 주문날짜, 키/몸무게/허리/허벅지, 이름, 인쇄옵션,
//            하의길이, 색상, 수량, 성별, 허리밴드
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' as root_bundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class OrderExcelService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── 단체주문 여부 공통 판별 함수 ──
  // OrderModel의 중앙 판별 기준을 사용해 화면·엑셀 분류를 일치시킨다.
  static bool _isGroupOrder(OrderModel o) => o.isGroupOrder;

  // ── 전날 오후1시 ~ 당일 오후1시 날짜 계산 ──
  // 항상 "오늘 13:00 기준의 직전 24시간 회차"를 반환한다.
  //   start = 어제 13:00:00
  //   end   = 오늘 13:00:00
  // (오전에 다운받든 오후에 다운받든 동일한 구간)
  static OrderDateRange getDailyRange({DateTime? baseDate}) {
    final now = baseDate ?? DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 13, 0, 0);
    final start = end.subtract(const Duration(days: 1));
    return OrderDateRange(start: start, end: end);
  }

  /// 특정 날짜(하루 00:00~익일 00:00) 범위
  static OrderDateRange getDayRange(DateTime date) {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end   = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return OrderDateRange(start: start, end: end);
  }

  /// 특정 날짜가 포함된 주(월요일~일요일) 범위
  static OrderDateRange getWeekRange(DateTime date) {
    final weekday = date.weekday; // 1=월, 7=일
    final monday  = date.subtract(Duration(days: weekday - 1));
    final start   = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
    final end     = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
    return OrderDateRange(start: start, end: end);
  }

  /// 특정 날짜가 포함된 월(1일~말일) 범위
  static OrderDateRange getMonthRange(DateTime date) {
    final start = DateTime(date.year, date.month, 1, 0, 0, 0);
    final nextMonth = DateTime(date.year, date.month + 1, 1, 0, 0, 0);
    final end = nextMonth.subtract(const Duration(seconds: 1));
    return OrderDateRange(start: start, end: end);
  }

  /// 임의 기간 범위 (시작일 00:00 ~ 종료일 23:59:59)
  static OrderDateRange getCustomRange(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end   = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return OrderDateRange(start: start, end: end);
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

  @visibleForTesting
  static OrderModel? parseOrderForTesting(
    Map<String, dynamic> data,
    String docId,
  ) => _parseOrder(data, docId);

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
          final optionType = (customOptions['orderType'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase()
                  .replaceAll('-', '_');
          final hasOriginalOrder = (customOptions['originalOrderId'] ??
                      customOptions['parentOrderId'] ??
                      customOptions['sourceOrderId'] ??
                      '')
                  .toString()
                  .trim()
                  .isNotEmpty;
          final isAdditional = optionType == 'additional' ||
              customOptions['isAdditional'] == true ||
              customOptions['isAdditionalOrder'] == true ||
              customOptions['additionalOrder'] == true ||
              data['isAdditionalOrder'] == true ||
              hasOriginalOrder ||
              RegExp(r'^(?:ADD|ADDITIONAL)(?:[_-]|$)', caseSensitive: false)
                  .hasMatch(docId);
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
        customOptions: () {
          // designRevisionRequest를 customOptions에 병합 (엑셀 시트 생성 시 사용)
          final revReq = data['designRevisionRequest'];
          if (revReq is Map) {
            customOptions['designRevisionRequest'] = Map<String, dynamic>.from(revReq);
          }
          return customOptions.isEmpty ? null : customOptions;
        }(),
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
  // ignore: unused_element
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

    // ── 스타일 정의 (주문요약 시트용) ──
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
      final isGroup = order.isGroupOrder;
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
          order.isAdditionalOrder ? '추가제작' : (isGroup ? '단체주문' : '개인주문'),
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
          _lengthDisplay(opts), style: rowStyle);
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
    // 시트 2~N: 팀별 상세 시트 — _buildTeamSheet 공통 헬퍼 사용
    // (이미지+주문정보+인원별사이즈 한 시트에 세로 배치)
    // ══════════════════════════════════════════════════════════
    final List<_ImageToInsert> selectedImagesToInsert = [];

    for (var orderIdx = 0; orderIdx < groupOrders.length; orderIdx++) {
      final order = groupOrders[orderIdx];
      final opts  = order.customOptions ?? {};
      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '팀${orderIdx + 1}';
      final rawSheetName = teamName.replaceAll(RegExp(r'[\\/:*?\[\]]'), '');
      final sheetName = rawSheetName.length > 28 ? rawSheetName.substring(0, 28) : rawSheetName;
      final teamSheet = excel[sheetName];

      final slots = _buildTeamSheet(teamSheet, sheetName, order);
      selectedImagesToInsert.addAll(slots);
    }

    // Excel 라이브러리가 자동 생성한 'Sheet1' 기본 시트 제거
    try { excel.delete('Sheet1'); } catch (_) {}
    excel.setDefaultSheet('주문요약');
    final baseBytes = excel.encode()!;

    // 이미지 없으면 바로 반환
    if (selectedImagesToInsert.isEmpty) return Uint8List.fromList(baseBytes);

    // 이미지 다운로드 (병렬, base64 지원)
    await Future.wait(selectedImagesToInsert.map((img) async {
      try {
        if (img.url.startsWith('data:image')) {
          final comma = img.url.indexOf(',');
          if (comma >= 0) {
            final header = img.url.substring(0, comma);
            img.bytes = base64Decode(img.url.substring(comma + 1));
            img.ext = header.contains('png') ? 'png' : 'jpeg';
          }
        } else {
          final resp = await http.get(Uri.parse(img.url))
              .timeout(const Duration(seconds: 20));
          if (resp.statusCode == 200) {
            img.bytes = resp.bodyBytes;
            final ct = resp.headers['content-type'] ?? '';
            img.ext = (ct.contains('png') || img.url.toLowerCase().contains('.png'))
                ? 'png' : 'jpeg';
          }
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

    // ── 공통 스타일 ──
    final titleStyle = CellStyle(
      bold: true, fontSize: 13,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#4A148C'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final labelStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
      verticalAlign: VerticalAlign.Center,
    );
    final sectionHeaderStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final maleHeaderStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final femaleHeaderStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#C62828'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
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
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1B5E20'),
    );
    final detailStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E8EAF6'),
      fontColorHex: ExcelColor.fromHexString('#283593'),
    );
    final noOptionStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#9E9E9E'),
      italic: true,
    );
    final imgPlaceholderStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      fontColorHex: ExcelColor.fromHexString('#BDBDBD'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      italic: true,
    );

    // 이미지 삽입 목록 (전체 시트 통합)
    final List<_ImageToInsert> allImagesToInsert = [];

    // ══════════════════════════════════════════════
    // 시트 1~N: 팀별 상세 시트 — _buildTeamSheet 공통 헬퍼 사용
    // ══════════════════════════════════════════════
    for (var orderIdx = 0; orderIdx < groupOrders.length; orderIdx++) {
      final order = groupOrders[orderIdx];
      final opts  = order.customOptions ?? {};
      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '팀${orderIdx + 1}';
      final rawSheetName = teamName.replaceAll(RegExp(r'[\\/:*?\[\]]'), '');
      final sheetName = rawSheetName.length > 28 ? rawSheetName.substring(0, 28) : rawSheetName;
      final teamSheet = excel[sheetName];

      final slots = _buildTeamSheet(teamSheet, sheetName, order);
      allImagesToInsert.addAll(slots);
    } // end for each order

    // 첫 번째 팀 시트를 기본 시트로 설정
    if (groupOrders.isNotEmpty) {
      final firstTeamName = groupOrders.first.customOptions?['teamName']?.toString()
          ?? groupOrders.first.groupName ?? '팀1';
      final rawFirst = firstTeamName.replaceAll(RegExp(r'[\\/:*?\[\]]'), '');
      final firstSheet = rawFirst.length > 28 ? rawFirst.substring(0, 28) : rawFirst;
      excel.setDefaultSheet(firstSheet);
    }
    // Excel 라이브러리가 자동 생성한 'Sheet1' 기본 시트 제거
    try { excel.delete('Sheet1'); } catch (_) {}
    final dailyBase = excel.encode()!;

    if (allImagesToInsert.isEmpty) return Uint8List.fromList(dailyBase);

    // 이미지 다운로드 (병렬, base64 지원)
    await Future.wait(allImagesToInsert.map((img) async {
      try {
        if (img.url.startsWith('data:image')) {
          // base64 인라인 이미지
          final comma = img.url.indexOf(',');
          if (comma >= 0) {
            final header = img.url.substring(0, comma);
            img.bytes = base64Decode(img.url.substring(comma + 1));
            img.ext = header.contains('png') ? 'png' : 'jpeg';
          }
        } else {
          final resp = await http.get(Uri.parse(img.url))
              .timeout(const Duration(seconds: 20));
          if (resp.statusCode == 200) {
            img.bytes = resp.bodyBytes;
            final ct = resp.headers['content-type'] ?? '';
            img.ext = (ct.contains('png') || img.url.toLowerCase().contains('.png'))
                ? 'png' : 'jpeg';
          }
        }
      } catch (_) {}
    }));

    return _insertImagesIntoXlsx(Uint8List.fromList(dailyBase), allImagesToInsert);
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

    // ══════════════════════════════════════════════════════════
    // 시트 2~N: 팀별 상세 시트 — _buildTeamSheet 공통 헬퍼 사용
    // (이미지+주문정보+인원별사이즈 한 시트에 세로 배치)
    // ══════════════════════════════════════════════════════════
    final List<_ImageToInsert> baseImagesToInsert = [];

    for (var orderIdx = 0; orderIdx < groupOrders.length; orderIdx++) {
      final order = groupOrders[orderIdx];
      final opts  = order.customOptions ?? {};
      final teamName = opts['teamName']?.toString() ?? order.groupName ?? '팀${orderIdx + 1}';
      final rawSheetName = teamName.replaceAll(RegExp(r'[\\/:*?\[\]]'), '');
      final sheetName = rawSheetName.length > 28 ? rawSheetName.substring(0, 28) : rawSheetName;
      final teamSheet = excel[sheetName];

      final slots = _buildTeamSheet(teamSheet, sheetName, order);
      baseImagesToInsert.addAll(slots);
    }

    // Excel 라이브러리가 자동 생성한 'Sheet1' 기본 시트 제거
    try { excel.delete('Sheet1'); } catch (_) {}
    excel.setDefaultSheet('주문요약');
    final baseBytes2 = excel.encode()!;

    if (baseImagesToInsert.isEmpty) return Uint8List.fromList(baseBytes2);

    await Future.wait(baseImagesToInsert.map((img) async {
      try {
        if (img.url.startsWith('data:image')) {
          final comma = img.url.indexOf(',');
          if (comma >= 0) {
            final header = img.url.substring(0, comma);
            img.bytes = base64Decode(img.url.substring(comma + 1));
            img.ext = header.contains('png') ? 'png' : 'jpeg';
          }
        } else {
          final resp = await http.get(Uri.parse(img.url))
              .timeout(const Duration(seconds: 20));
          if (resp.statusCode == 200) {
            img.bytes = resp.bodyBytes;
            final ct = resp.headers['content-type'] ?? '';
            img.ext = (ct.contains('png') || img.url.toLowerCase().contains('.png')) ? 'png' : 'jpeg';
          }
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
    // 참고이미지: 주문 시 업로드한 refImageUrl 우선, 없으면 maleRefImageUrl 폴백
    final refImageUrl = opts['refImageUrl']?.toString() ??
        opts['maleRefImageUrl']?.toString() ?? '';
    final designLogoUrl = opts['designLogoUrl']?.toString() ?? '';
    final waistbandLogoUrl = opts['waistbandLogoUrl']?.toString() ?? '';

    // 1) 기본 xlsx 바이트 생성 (sync)
    final baseBytes = generateGroupOrderExcel(order);

    // 2) 다운로드할 이미지 목록
    // generateGroupOrderExcel에서 row 1부터 이미지 행을 생성하므로 동일 위치에 삽입
    // A열(0)=레이블, B열(1)~J열(9)=이미지 영역(merge됨)
    final List<_ImageToInsert> imagesToInsert = [];
    int imgRow = 1; // 1-based Excel row (row 0 = 제목행)
    if (productImageUrl.isNotEmpty) {
      imagesToInsert.add(_ImageToInsert(
        url: productImageUrl,
        sheetName: '주문정보',
        sheetIndex: 0,
        row: imgRow,    // 1-based
        col: 1,         // B열 (A열은 레이블)
        widthPx: 260,
        heightPx: 195,
        label: '디자인이미지',
      ));
      imgRow++;
    }
    if (refImageUrl.isNotEmpty) {
      imagesToInsert.add(_ImageToInsert(
        url: refImageUrl,
        sheetName: '주문정보',
        sheetIndex: 0,
        row: imgRow,
        col: 1,         // B열
        widthPx: 260,
        heightPx: 195,
        label: '참고이미지',
      ));
      imgRow++;
    }
    if (designLogoUrl.isNotEmpty) {
      imagesToInsert.add(_ImageToInsert(
        url: designLogoUrl,
        sheetName: '주문정보',
        sheetIndex: 0,
        row: imgRow,
        col: 1,
        widthPx: 260,
        heightPx: 195,
        label: '상의디자인로고',
      ));
      imgRow++;
    }
    if (waistbandLogoUrl.isNotEmpty) {
      imagesToInsert.add(_ImageToInsert(
        url: waistbandLogoUrl,
        sheetName: '주문정보',
        sheetIndex: 0,
        row: imgRow,
        col: 1,
        widthPx: 260,
        heightPx: 195,
        label: '허리밴드로고',
      ));
      // imgRow++; // 마지막 항목이므로 증가 불필요
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

      // 시트별로 그룹화 — sheetName 우선, 없으면 sheetIndex 문자열을 키로 사용
      final Map<String, List<_ImageToInsert>> bySheet = {};
      for (final img in images) {
        if (img.bytes == null) continue;
        final key = (img.sheetName != null && img.sheetName!.isNotEmpty)
            ? img.sheetName!
            : '__idx_${img.sheetIndex}';
        bySheet.putIfAbsent(key, () => []).add(img);
      }
      if (bySheet.isEmpty) return xlsxBytes;

      // workbook.xml에서 시트 rId 목록 추출
      final wbFile = archive.findFile('xl/workbook.xml');
      if (wbFile == null) return xlsxBytes;
      final wbXml = utf8.decode(wbFile.content as List<int>);

      // workbook.xml.rels에서 rId→파일명 매핑
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

      // workbook.xml의 sheet 순서로 rId + name 리스트 추출
      final sheetRe = RegExp(
          r'<sheet\b[^>]*name="([^"]*)"[^>]*r:id="([^"]+)"',
          multiLine: true);
      final sheetRIds = <String>[];           // index → rId
      final Map<String, int> nameToIdx = {}; // sheetName → index
      for (final m in sheetRe.allMatches(wbXml)) {
        final name = m.group(1)!;
        final rId  = m.group(2)!;
        nameToIdx[name] = sheetRIds.length;
        sheetRIds.add(rId);
      }
      // 이름 매핑이 없으면 r:id만 있는 기존 패턴도 폴백 처리
      if (sheetRIds.isEmpty) {
        final fallbackRe = RegExp(r'<sheet\b[^>]*r:id="([^"]+)"', multiLine: true);
        for (final m in fallbackRe.allMatches(wbXml)) {
          sheetRIds.add(m.group(1)!);
        }
      }

      final List<ArchiveFile> newFiles = [];

      for (final entry in bySheet.entries) {
        final sheetKey = entry.key;
        final imgs = entry.value;

        // sheetName으로 인덱스 resolve, 없으면 '__idx_N' 키에서 N 파싱
        int resolvedIdx;
        if (sheetKey.startsWith('__idx_')) {
          resolvedIdx = int.tryParse(sheetKey.substring(6)) ?? 0;
        } else {
          resolvedIdx = nameToIdx.containsKey(sheetKey)
              ? nameToIdx[sheetKey]!
              : imgs.first.sheetIndex;
        }

        if (resolvedIdx >= sheetRIds.length) continue;
        final sheetRId = sheetRIds[resolvedIdx];
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

    // ── 공통 스타일 (디자인수정 엑셀과 동일 팔레트) ──
    final titleStyle = CellStyle(           // 최상단 제목: 진보라
      bold: true, fontSize: 13,
      backgroundColorHex: ExcelColor.fromHexString('#6A1B9A'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final sectionStyle = CellStyle(         // 섹션 헤더: 다크 네이비
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    final labelStyle = CellStyle(           // 레이블: 연보라
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#F3E5F5'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
    );
    final valueStyle = CellStyle(fontSize: 10);
    final headerStyle = CellStyle(          // 테이블 헤더: 딥 인디고
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final maleStyle = CellStyle(            // 남성: 연파랑
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
      fontColorHex: ExcelColor.fromHexString('#1565C0'),
    );
    final femaleStyle = CellStyle(          // 여성: 연핑크
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#FCE4EC'),
      fontColorHex: ExcelColor.fromHexString('#C62828'),
    );
    final evenStyle = CellStyle(            // 짝수 행
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
    );
    final detailStyle = CellStyle(          // 상세치수: 연남색
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#E8EAF6'),
      fontColorHex: ExcelColor.fromHexString('#283593'),
    );
    final totalStyle = CellStyle(           // 합계 행
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
    );
    final imgLabelStyle = CellStyle(        // 이미지 레이블: 디자인수정과 동일
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // ── 시트 1: 주문정보 ──
    final summarySheet = excel['주문정보'];
    excel.setDefaultSheet('주문정보');

    // 제목 행 (0행) — merge 0~9열, 높이 28
    _setCell(summarySheet, 0, 0, '2FIT 단체주문 주문서', style: titleStyle);
    summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0));
    summarySheet.setRowHeight(0, 28);

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
    final refImageUrl = opts['refImageUrl']?.toString() ?? opts['maleRefImageUrl']?.toString() ?? '';
    final designLogoUrl = opts['designLogoUrl']?.toString() ?? '';
    final waistbandLogoUrl = opts['waistbandLogoUrl']?.toString() ?? '';
    final bottomColorName = opts['bottomColorName']?.toString() ?? '';

    // 이미지 행: A열=레이블(16pt), B열=이미지 공간(비워둠, async 버전에서 삽입)
    // merge B~J열, 행 높이 200pt
    int imgRow = 1;
    if (productImageUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '디자인이미지', style: imgLabelStyle);
      summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: imgRow),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: imgRow),
      );
      _setCell(summarySheet, imgRow, 1, '');
      summarySheet.setRowHeight(imgRow, 200.0);
      imgRow++;
    }
    if (refImageUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '참고이미지', style: imgLabelStyle);
      summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: imgRow),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: imgRow),
      );
      _setCell(summarySheet, imgRow, 1, '');
      summarySheet.setRowHeight(imgRow, 200.0);
      imgRow++;
    }
    if (designLogoUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '상의디자인로고', style: imgLabelStyle);
      summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: imgRow),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: imgRow),
      );
      _setCell(summarySheet, imgRow, 1, '');
      summarySheet.setRowHeight(imgRow, 200.0);
      imgRow++;
    }
    if (waistbandLogoUrl.isNotEmpty) {
      _setCell(summarySheet, imgRow, 0, '허리밴드로고', style: imgLabelStyle);
      summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: imgRow),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: imgRow),
      );
      _setCell(summarySheet, imgRow, 1, '');
      summarySheet.setRowHeight(imgRow, 200.0);
      imgRow++;
    }

    final teamName = _optText(opts, ['teamName', 'groupName'], order.groupName ?? '-');
    final mainColor = _optText(opts, ['mainColor', 'color', 'colorName'], '-');
    final colorInfo = bottomColorName.isNotEmpty
        ? '상의: $mainColor / 하의: $bottomColorName'
        : mainColor;
    final adjustedHex = opts['adjustedColorHex']?.toString() ?? '';
    final mainColorHex = adjustedHex.isNotEmpty && adjustedHex.startsWith('#')
        ? adjustedHex
        : _getColorHex(mainColor);

    // 기본 정보 섹션 헤더
    int infoStartRow = imgRow + 1;
    _setCell(summarySheet, imgRow, 0, '▶ 주문 정보', style: sectionStyle);
    summarySheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: imgRow),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: imgRow),
    );
    summarySheet.setRowHeight(imgRow, 20);

    // infoRows — B~J열 merge, 행 높이 18
    void _writeInfoRow(Sheet sh, int row, String label, dynamic value,
        {bool isColor = false, bool isWaistband = false}) {
      _setCell(sh, row, 0, label, style: labelStyle);
      sh.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
      );
      sh.setRowHeight(row, 18);
      if (isColor) {
        _setColorCell(sh, row, 1, value.toString(), overrideHex: mainColorHex);
      } else if (isWaistband) {
        final wHex = _extractWaistbandHex(opts);
        if (wHex != null) {
          _setColorCell(sh, row, 1, value.toString(), overrideHex: wHex);
        } else {
          _setCell(sh, row, 1, value, style: valueStyle);
        }
      } else {
        _setCell(sh, row, 1, value, style: valueStyle);
      }
    }

    final infoRows = [
      ['주문번호',        order.id,                                                                false, false],
      ['주문날짜',        _fmtFull(order.createdAt),                                              false, false],
      ['단체명/팀명',     teamName,                                                               false, false],
      ['담당자',          _optText(opts, ['manager', 'managerName'], order.userName),              false, false],
      ['연락처',          _maskPhone(_optText(opts, ['phone', 'contactPhone'], order.userPhone)),  false, false],
      ['이메일',          _maskEmail(_optText(opts, ['email', 'contactEmail'], order.userEmail)), false, false],
      ['배송지',          _optText(opts, ['address', 'deliveryAddress'], order.userAddress),       false, false],
      ['총 인원',         '${opts['totalCount'] ?? order.groupCount ?? 0}명',                    false, false],
      ['남/여 구분',      '남 ${_countGender(order, '남')}명 / 여 ${_countGender(order, '여')}명', false, false],
      ['인쇄옵션',        _optText(opts, ['printType', 'printTypeLabel'], '-'),                    false, false],
      ['색상',            colorInfo,                                                               true,  false],
      ['하의 기본길이',   _lengthDisplay(opts),                                                     false, false],
      ['허리밴드',        _extractWaistbandInfo(opts),                                             false, true ],
      ['원단 종류',       _optText(opts, ['fabricType', 'fabricName', 'fabric'], '-'),             false, false],
      ['원단 무게',       _optText(opts, ['fabricWeight', 'weight'], '-'),                          false, false],
      ['독점디자인',      _isExclusive(opts) ? '예' : '아니오',                                     false, false],
      ['추가제작 여부',   order.isAdditionalOrder ? '추가제작주문' : '신규주문',          false, false],
      ['주문 상태',       _statusLabel(order.status),                                             false, false],
      ['메모',            _optText(opts, ['memoText', 'memo'], order.memo ?? '-'),                 false, false],
    ];

    for (var i = 0; i < infoRows.length; i++) {
      _writeInfoRow(summarySheet, infoStartRow + i,
          infoRows[i][0].toString(), infoRows[i][1],
          isColor: infoRows[i][2] as bool,
          isWaistband: infoRows[i][3] as bool);
    }

    // ── 추가제작 주문인 경우: 기존 주문 정보 별도 섹션 ──
    if (order.isAdditionalOrder) {
      final origOrderId    = opts['originalOrderId']?.toString() ?? '';
      final origOrderDate  = opts['originalOrderDate']?.toString() ?? '';
      final origTeamName   = opts['originalTeamName']?.toString() ?? '';
      final origTotalCount = opts['originalTotalCount']?.toString() ?? '';
      final origStatus     = opts['originalStatus']?.toString() ?? '';

      final origSectionStyle = CellStyle(
        bold: true, fontSize: 10,
        backgroundColorHex: ExcelColor.fromHexString('#4A148C'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
      final origLabelStyle = CellStyle(
        bold: true, fontSize: 10,
        backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
        fontColorHex: ExcelColor.fromHexString('#4A148C'),
      );

      final origSecRow = infoStartRow + infoRows.length + 1;
      _setCell(summarySheet, origSecRow, 0, '▶ 기존 주문 정보 (원주문)', style: origSectionStyle);
      summarySheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: origSecRow),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: origSecRow),
      );
      summarySheet.setRowHeight(origSecRow, 20);

      final origRows = [
        ['기존 주문번호', origOrderId.isNotEmpty ? origOrderId : '(미연결)'],
        ['기존 주문일자', origOrderDate.isNotEmpty ? origOrderDate.substring(0, 10) : '-'],
        ['기존 팀명',     origTeamName.isNotEmpty ? origTeamName : '-'],
        ['기존 총 인원',  origTotalCount.isNotEmpty ? '$origTotalCount명' : '-'],
        ['기존 주문 상태', origStatus.isNotEmpty ? origStatus : '-'],
      ];
      for (var i = 0; i < origRows.length; i++) {
        final r = origSecRow + 1 + i;
        _setCell(summarySheet, r, 0, origRows[i][0], style: origLabelStyle);
        summarySheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r),
          CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: r),
        );
        _setCell(summarySheet, r, 1, origRows[i][1], style: valueStyle);
        summarySheet.setRowHeight(r, 18);
      }
    }

    // 주문정보 시트 열 너비 — A열: 레이블, B열: 값(이미지), C~J: 보조
    summarySheet.setColumnWidth(0, 16.0);   // A: 레이블
    summarySheet.setColumnWidth(1, 28.0);   // B: 값 / 이미지
    summarySheet.setColumnWidth(2, 12.0);
    summarySheet.setColumnWidth(3, 12.0);
    summarySheet.setColumnWidth(4, 12.0);
    summarySheet.setColumnWidth(5, 12.0);
    summarySheet.setColumnWidth(6, 12.0);
    summarySheet.setColumnWidth(7, 12.0);
    summarySheet.setColumnWidth(8, 12.0);
    summarySheet.setColumnWidth(9, 12.0);

    // ── 시트 2: 인원별 사이즈 ──
    final personSheet = excel['팀원별사이즈명단'];

    final colorDisplay = bottomColorName.isNotEmpty
        ? '상의:$mainColor / 하의:$bottomColorName'
        : mainColor;

    // 제목 행
    _setCell(personSheet, 0, 0,
        '팀명: $teamName  |  총 ${persons.length}명  |  색상: $colorDisplay  |  하의길이: ${_lengthDisplay(opts)}',
        style: titleStyle);
    personSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 0));
    personSheet.setRowHeight(0, 28);

    // 컬럼 헤더 (headerStyle: 딥 인디고 #1A237E)
    final pHeaders = [
      'No', '이름', '성별', '사이즈구분', '상의 사이즈', '하의 사이즈', '하의 길이', '색상',
      '키(cm)', '몸무게(kg)', '허리(cm)', '허벅지(cm)', '비고',
    ];
    for (var i = 0; i < pHeaders.length; i++) {
      _setCell(personSheet, 1, i, pHeaders[i], style: headerStyle);
    }
    personSheet.setRowHeight(1, 22);

    final defaultLength = _lengthDisplay(opts);
    for (var i = 0; i < persons.length; i++) {
      final p = persons[i] as Map<String, dynamic>;
      final rowStyle = i % 2 == 0 ? evenStyle : valueStyle;
      final gender = p['gender']?.toString() ?? '';
      final gStyle = gender == '남' ? maleStyle : (gender == '여' ? femaleStyle : rowStyle);

      final height = p['height']?.toString() ?? '';
      final weight = p['weight']?.toString() ?? '';
      final waist  = p['waist']?.toString()  ?? '';
      final thigh  = p['thigh']?.toString()  ?? '';
      final hasDetail = height.isNotEmpty || weight.isNotEmpty || waist.isNotEmpty || thigh.isNotEmpty;

      final personalLength = p['bottomLength']?.toString() ?? '';
      final personColor    = p['color']?.toString() ?? '';
      final sizeType       = p['sizeType']?.toString() ?? '성인';
      final juniorStyle    = CellStyle(
        bold: true, fontSize: 10,
        backgroundColorHex: ExcelColor.fromHexString('#E0F2F1'),
        fontColorHex: ExcelColor.fromHexString('#00695C'),
      );
      final sizeStyle = sizeType == '주니어' ? juniorStyle : rowStyle;

      _setCell(personSheet, i + 2, 0,  '${p['index'] ?? i + 1}', style: rowStyle);
      _setCell(personSheet, i + 2, 1,  p['name']?.toString().isNotEmpty == true ? p['name']!.toString() : '-', style: gStyle);
      _setCell(personSheet, i + 2, 2,  gender.isNotEmpty ? gender : '-', style: gStyle);
      _setCell(personSheet, i + 2, 3,  sizeType, style: sizeStyle);
      _setCell(personSheet, i + 2, 4,  p['topSize']?.toString().isNotEmpty == true ? p['topSize']!.toString() : '-', style: sizeStyle);
      _setCell(personSheet, i + 2, 5,  p['bottomSize']?.toString().isNotEmpty == true ? p['bottomSize']!.toString() : '-', style: sizeStyle);
      _setCell(personSheet, i + 2, 6,
          personalLength.isNotEmpty ? personalLength : (defaultLength.isNotEmpty ? defaultLength : '개별선택'),
          style: rowStyle);
      final usedColor = personColor.isNotEmpty ? personColor : mainColor;
      final personHex = _getColorHex(usedColor) ?? mainColorHex;
      _setColorCell(personSheet, i + 2, 7, usedColor, baseStyle: rowStyle, overrideHex: personHex);
      _setCell(personSheet, i + 2, 8,  hasDetail && height.isNotEmpty ? height : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 9,  hasDetail && weight.isNotEmpty ? weight : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 10, hasDetail && waist.isNotEmpty  ? waist  : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 11, hasDetail && thigh.isNotEmpty  ? thigh  : '', style: hasDetail ? detailStyle : rowStyle);
      _setCell(personSheet, i + 2, 12, hasDetail ? '상세치수입력' : '', style: rowStyle);
      personSheet.setRowHeight(i + 2, 18);
    }

    // 합계 행
    _setCell(personSheet, persons.length + 2, 0, '합계', style: totalStyle);
    _setCell(personSheet, persons.length + 2, 1, '${persons.length}명', style: totalStyle);
    _setCell(personSheet, persons.length + 2, 2,
        '남 ${_countGender(order, '남')}명 / 여 ${_countGender(order, '여')}명', style: totalStyle);
    personSheet.setRowHeight(persons.length + 2, 20);

    // 팀원별사이즈명단 열 너비
    final pColWidths = [6.0, 14.0, 8.0, 16.0, 16.0, 12.0, 16.0, 9.0, 10.0, 10.0, 10.0, 12.0, 14.0];
    for (var i = 0; i < pColWidths.length; i++) {
      personSheet.setColumnWidth(i, pColWidths[i]);
    }

    // ── 시트 3: 디자인 수정 / 추가제작 이력 ──
    _buildRevisionHistorySheet(excel, order, opts, titleStyle, labelStyle, headerStyle);

    // Excel 라이브러리가 자동 생성한 'Sheet1' 기본 시트 제거
    try { excel.delete('Sheet1'); } catch (_) {}
    excel.setDefaultSheet('주문정보');
    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  /// 디자인 수정 / 추가제작 이력 시트 생성 (디자인수정 엑셀과 동일 스타일)
  static void _buildRevisionHistorySheet(
      Excel excel,
      OrderModel order,
      Map<String, dynamic> opts,
      CellStyle titleStyle,   // #6A1B9A 진보라 — 제목
      CellStyle labelStyle,   // #F3E5F5 연보라 — 레이블
      CellStyle headerStyle,  // #1A237E 딥인디고 — 헤더
  ) {
    final histSheet = excel['수정·추가이력'];

    // 섹션별 헤더 색상 (디자인수정 팔레트 기반)
    final secDesign = CellStyle(            // 디자인수정 섹션: 진보라
      bold: true, fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#4A148C'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    final secAdditional = CellStyle(        // 추가제작 섹션: 딥그린
      bold: true, fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#1B5E20'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    final secColor = CellStyle(             // 컬러수정 섹션: 딥인디고
      bold: true, fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    final rowLabelDesign = CellStyle(       // 디자인 행 레이블
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
    );
    final rowLabelAdd = CellStyle(          // 추가제작 행 레이블
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1B5E20'),
    );
    final rowLabelColor = CellStyle(        // 컬러수정 행 레이블
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
      fontColorHex: ExcelColor.fromHexString('#0D47A1'),
    );
    final evenVal = CellStyle(fontSize: 10, backgroundColorHex: ExcelColor.fromHexString('#FAFAFA'));
    final oddVal  = CellStyle(fontSize: 10);

    void writeRow(Sheet sh, int r, String label, String value, CellStyle lStyle, CellStyle vStyle) {
      _setCell(sh, r, 0, label, style: lStyle);
      sh.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r),
      );
      _setCell(sh, r, 1, value, style: vStyle);
      sh.setRowHeight(r, 18);
    }

    int row = 0;

    // ── 제목 행 ──
    _setCell(histSheet, row, 0, '디자인 수정 · 추가제작 이력  (${order.id})', style: titleStyle);
    histSheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
    );
    histSheet.setRowHeight(row, 28);
    row += 2;

    // ── 1. 디자인 수정 이력 ──
    _setCell(histSheet, row, 0, '▶ 디자인 수정 이력', style: secDesign);
    histSheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
    );
    histSheet.setRowHeight(row, 20);
    row++;

    final designRevCount    = order.designRevisionCount;
    final designRevDeadline = order.designRevisionDeadline;
    final revisionRequest   = opts['designRevisionRequest'] as Map<dynamic, dynamic>?;
    final revisionNote      = revisionRequest?['memo']?.toString() ?? '';
    final revisionColor     = revisionRequest?['colorName']?.toString() ?? '';
    final revisionAt        = revisionRequest?['requestedAt']?.toString() ?? '';
    final revisionStatus    = revisionRequest?['status']?.toString() ?? '';

    final revRows = [
      ['디자인 수정 요청 횟수', '$designRevCount회 / 최대 2회'],
      ['남은 수정 가능 횟수',   '${2 - designRevCount}회'],
      ['마지막 요청 마감일', designRevDeadline != null
          ? '${designRevDeadline.year}.${designRevDeadline.month.toString().padLeft(2,'0')}.${designRevDeadline.day.toString().padLeft(2,'0')} (3일 이내 자동확정)'
          : '요청 없음'],
      ['최근 수정 요청 내용', revisionNote.isNotEmpty ? revisionNote : '-'],
      ['최근 요청 색상명',   revisionColor.isNotEmpty ? revisionColor : '-'],
      ['최근 요청 일자',     revisionAt.isNotEmpty ? revisionAt.substring(0, 10) : '-'],
      ['최근 요청 상태',     revisionStatus.isNotEmpty ? _revStatusLabel(revisionStatus) : '-'],
    ];
    for (var i = 0; i < revRows.length; i++) {
      writeRow(histSheet, row, revRows[i][0], revRows[i][1],
          rowLabelDesign, i.isEven ? evenVal : oddVal);
      row++;
    }
    row += 2;

    // ── 2. 추가제작 이력 ──
    _setCell(histSheet, row, 0, '▶ 추가제작 이력', style: secAdditional);
    histSheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
    );
    histSheet.setRowHeight(row, 20);
    row++;

    final addCount    = order.additionalOrderCount;
    final addDeadline = order.additionalOrderDeadline;
    final canAddFree  = order.canOrderAdditionalFree;
    final origOrderId   = opts['originalOrderId']?.toString() ?? '';
    final origTeamName  = opts['originalTeamName']?.toString() ?? '';
    final origTotalCount = opts['originalTotalCount']?.toString() ?? '';

    final addRows = [
      ['추가제작 신청 횟수',    '$addCount회'],
      ['무료 추가제작 마감일',  '${addDeadline.year}.${addDeadline.month.toString().padLeft(2,'0')}.${addDeadline.day.toString().padLeft(2,'0')}'],
      ['추가제작 가능 여부',    canAddFree ? '가능 (마감 전)' : '마감 (새로 주문 필요)'],
      if (order.isAdditionalOrder) ...[
        ['원주문 번호',  origOrderId.isNotEmpty   ? origOrderId   : '-'],
        ['원주문 팀명',  origTeamName.isNotEmpty  ? origTeamName  : '-'],
        ['원주문 인원',  origTotalCount.isNotEmpty ? '${origTotalCount}명' : '-'],
      ],
    ];
    for (var i = 0; i < addRows.length; i++) {
      writeRow(histSheet, row, addRows[i][0], addRows[i][1],
          rowLabelAdd, i.isEven ? evenVal : oddVal);
      row++;
    }
    row += 2;

    // ── 3. 컬러/단체명 수정 이력 ──
    _setCell(histSheet, row, 0, '▶ 컬러/단체명 수정 이력', style: secColor);
    histSheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
    );
    histSheet.setRowHeight(row, 20);
    row++;

    final colorEditCount  = order.colorEditCount;
    final colorRevRows = [
      ['컬러/단체명 수정 횟수', '$colorEditCount회 / 최대 2회'],
      ['남은 수정 가능 횟수',   '${2 - colorEditCount}회'],
      ['현재 색상',             _optText(opts, ['mainColor', 'color', 'colorName'], '-')],
    ];
    for (var i = 0; i < colorRevRows.length; i++) {
      writeRow(histSheet, row, colorRevRows[i][0], colorRevRows[i][1],
          rowLabelColor, i.isEven ? evenVal : oddVal);
      row++;
    }

    // 열 너비
    histSheet.setColumnWidth(0, 22.0);
    histSheet.setColumnWidth(1, 40.0);
    histSheet.setColumnWidth(2, 12.0);
    histSheet.setColumnWidth(3, 12.0);
    histSheet.setColumnWidth(4, 12.0);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 공통 팀별 시트 빌더 — 디자인수정 엑셀과 동일 스타일/레이아웃
  //
  //  레이아웃 (세로 순서):
  //   행 0      : 팀명 제목 (진보라 #6A1B9A, height 28)
  //   행 1      : ▶ 주문 정보 섹션 (다크네이비 #1A1A2E, height 20)
  //   행 2      : [디자인이미지] A열=레이블, B~J merge, height 200 (이미지 있을 때)
  //   행 3~     : infoRows — A열=레이블(#F3E5F5), B~J merge, height 18
  //   빈 행
  //   ▶ 인원별 사이즈 명단 섹션
  //   컬럼 헤더 (#1A237E 딥인디고)
  //   인원 데이터 행 (남=파랑/여=핑크/짝수=연회색)
  //   합계 행
  //
  //  반환: 이미지 슬롯 목록 (_ImageToInsert) — 호출자가 _insertImagesIntoXlsx에 전달
  // ═══════════════════════════════════════════════════════════════════
  static List<_ImageToInsert> _buildTeamSheet(
    Sheet sheet,
    String sheetName,
    OrderModel order,
  ) {
    final opts    = order.customOptions ?? {};
    final persons = (opts['persons'] as List<dynamic>?) ?? [];

    // ── 스타일 (디자인수정 팔레트와 동일) ──
    final titleStyle = CellStyle(
      bold: true, fontSize: 13,
      backgroundColorHex: ExcelColor.fromHexString('#6A1B9A'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final sectionStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    final labelStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#F3E5F5'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
    );
    final valueStyle   = CellStyle(fontSize: 10);
    final headerStyle  = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final maleStyle    = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
      fontColorHex: ExcelColor.fromHexString('#1565C0'),
    );
    final femaleStyle  = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#FCE4EC'),
      fontColorHex: ExcelColor.fromHexString('#C62828'),
    );
    final evenRowStyle = CellStyle(
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
    );
    final oddRowStyle  = CellStyle(fontSize: 10);
    final totalStyle   = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
    );
    final detailStyle  = CellStyle(
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#E8EAF6'),
      fontColorHex: ExcelColor.fromHexString('#283593'),
    );
    final imgLabelStyle = CellStyle(
      bold: true, fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final noOptionStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#9E9E9E'),
      italic: true,
    );

    // ── 데이터 추출 ──
    final teamName      = opts['teamName']?.toString() ?? order.groupName ?? sheetName;
    final mainColor     = _optText(opts, ['mainColor', 'color', 'colorName'], '-');
    final bottomColorName = opts['bottomColorName']?.toString() ?? '';
    final colorInfo     = bottomColorName.isNotEmpty
        ? '상의: $mainColor / 하의: $bottomColorName'
        : mainColor;
    final adjustedHex   = opts['adjustedColorHex']?.toString() ?? '';
    final mainColorHex  = adjustedHex.isNotEmpty && adjustedHex.startsWith('#')
        ? adjustedHex : _getColorHex(mainColor);
    final colorDisplay  = bottomColorName.isNotEmpty
        ? '상의:$mainColor / 하의:$bottomColorName'
        : mainColor;
    final printType     = _optText(opts, ['printType', 'printTypeLabel']);
    final defaultLength = _lengthDisplay(opts);
    final waistbandInfo = _extractWaistbandInfo(opts);
    final maleCount     = _countGender(order, '남');
    final femaleCount   = _countGender(order, '여');
    final totalCount    = (opts['totalCount'] as num?)?.toInt()
        ?? order.groupCount ?? persons.length;
    final designImgUrl  = _extractDesignImageUrl(order);
    final designFileUrl = opts['designFileUrl']?.toString() ?? opts['maleRefImageUrl']?.toString() ?? '';
    final designLogoUrl = opts['designLogoUrl']?.toString() ?? '';
    final waistbandLogoUrl = opts['waistbandLogoUrl']?.toString() ?? '';
    final designLogoName = opts['designLogoFileName']?.toString() ?? '';
    final waistbandLogoName = opts['waistbandLogoFileName']?.toString() ?? '';
    final imageSlots = <_ImageToInsert>[];
    int rowIdx = 0;

    // ── 행 0: 제목 ──
    _setCell(sheet, rowIdx, 0,
        '[$teamName]  총 ${totalCount}명  |  ${_fmtFull(order.createdAt)}',
        style: titleStyle);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
    );
    sheet.setRowHeight(rowIdx, 28);
    rowIdx++;

    // ── 행 1: 주문 정보 섹션 헤더 ──
    _setCell(sheet, rowIdx, 0, '▶ 주문 정보', style: sectionStyle);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
    );
    sheet.setRowHeight(rowIdx, 20);
    rowIdx++;

    // ── 이미지 행 (디자인이미지, 참조이미지) ──
    if (designImgUrl.isNotEmpty) {
      _setCell(sheet, rowIdx, 0, '디자인이미지', style: imgLabelStyle);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
      );
      _setCell(sheet, rowIdx, 1, '');
      sheet.setRowHeight(rowIdx, 200.0);
      imageSlots.add(_ImageToInsert(
        url: designImgUrl, sheetName: sheetName,
        row: rowIdx + 1, col: 1, widthPx: 260, heightPx: 195, label: '디자인이미지',
      ));
      rowIdx++;
    }
    if (designFileUrl.isNotEmpty) {
      _setCell(sheet, rowIdx, 0, '참조이미지', style: imgLabelStyle);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
      );
      _setCell(sheet, rowIdx, 1, '');
      sheet.setRowHeight(rowIdx, 200.0);
      imageSlots.add(_ImageToInsert(
        url: designFileUrl, sheetName: sheetName,
        row: rowIdx + 1, col: 1, widthPx: 260, heightPx: 195, label: '참조이미지',
      ));
      rowIdx++;
    }

    // ── infoRows ──
    void _writePdfLinkRow(String label, String url, String fileName) {
      if (url.isEmpty && fileName.isEmpty) return;
      _setCell(sheet, rowIdx, 0, label, style: labelStyle);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
      );
      sheet.setRowHeight(rowIdx, 18);
      if (url.isNotEmpty) {
        _setPdfLinkCell(sheet, rowIdx, 1, url,
            linkText: fileName.isEmpty ? 'PDF 열기' : 'PDF 열기 · $fileName');
      } else {
        _setCell(sheet, rowIdx, 1,
            fileName.isEmpty ? '파일 없음' : '$fileName (열기 링크 없음)',
            style: valueStyle);
      }
      rowIdx++;
    }
    void _writeRow(String label, dynamic value,
        {bool isColor = false, bool isWaistband = false, bool isNoOption = false}) {
      _setCell(sheet, rowIdx, 0, label, style: labelStyle);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
      );
      sheet.setRowHeight(rowIdx, 18);
      if (isColor) {
        _setColorCell(sheet, rowIdx, 1, value.toString(), overrideHex: mainColorHex);
      } else if (isWaistband) {
        final wHex = _extractWaistbandHex(opts);
        wHex != null
            ? _setColorCell(sheet, rowIdx, 1, value.toString(), overrideHex: wHex)
            : _setCell(sheet, rowIdx, 1, value, style: valueStyle);
      } else if (isNoOption) {
        _setCell(sheet, rowIdx, 1, value, style: noOptionStyle);
      } else {
        _setCell(sheet, rowIdx, 1, value, style: valueStyle);
      }
      rowIdx++;
    }

    _writeRow('주문번호',   order.id);
    _writeRow('주문날짜',   _fmtFull(order.createdAt));
    _writeRow('단체명/팀명', teamName);
    _writeRow('담당자', _optText(opts, ['manager', 'managerName'], order.userName));
    _writeRow('연락처', _maskPhone(_optText(opts, ['phone', 'contactPhone'], order.userPhone)));
    _writeRow('이메일', _maskEmail(_optText(opts, ['email', 'contactEmail'], order.userEmail)));
    _writeRow('배송지', _optText(opts, ['address', 'deliveryAddress'], order.userAddress));
    _writeRow('총 인원', '${totalCount}명  (남 ${maleCount}명 / 여 ${femaleCount}명)');
    _writeRow('인쇄옵션', printType.isNotEmpty ? printType : '인쇄옵션 없음',
        isNoOption: printType.isEmpty);
    _writeRow('색상', colorDisplay, isColor: true);
    _writeRow('하의길이',   defaultLength);
    _writeRow('허리밴드',   waistbandInfo.isNotEmpty ? waistbandInfo : '없음',
        isWaistband: waistbandInfo.isNotEmpty);
    _writeRow('원단 종류',  _optText(opts, ['fabricType', 'fabricName', 'fabric'], '-'));
    _writeRow('원단 무게',  _optText(opts, ['fabricWeight', 'weight'], '-'));
    _writeRow('독점디자인', _isExclusive(opts) ? '예' : '아니오');
    _writeRow('주문 유형',  order.isAdditionalOrder ? '추가제작주문' : '신규주문');
    _writeRow('주문 상태',  _statusLabel(order.status));
    _writeRow('메모', _optText(opts, ['memoText', 'memo'], order.memo ?? '-'));
    _writePdfLinkRow('디자인 로고 파일', designLogoUrl, designLogoName);
    _writePdfLinkRow('허리밴드 로고 파일', waistbandLogoUrl, waistbandLogoName);

    // ── 인원별 사이즈 섹션 ──
    rowIdx++; // 빈 행
    _setCell(sheet, rowIdx, 0,
        '▶ 인원별 사이즈 명단  (총 ${persons.isNotEmpty ? persons.length : totalCount}명  /  색상: $colorInfo)',
        style: sectionStyle);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
    );
    sheet.setRowHeight(rowIdx, 20);
    rowIdx++;

    if (persons.isEmpty) {
      final noPersonStyle = CellStyle(
        italic: true, fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#9E9E9E'),
        horizontalAlign: HorizontalAlign.Center,
      );
      _setCell(sheet, rowIdx, 0, '인원 정보가 없습니다.', style: noPersonStyle);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
      );
      rowIdx++;
    } else {
      // 컬럼 헤더
      final pHeaders = ['No', '이름', '성별', '사이즈구분', '상의', '하의', '하의길이', '색상', '키', '몸무게', '허리', '허벅지', '비고'];
      // 13개 헤더이므로 필요한 열까지 확장 (0~12)
      for (var c = 0; c < pHeaders.length; c++) {
        _setCell(sheet, rowIdx, c, pHeaders[c], style: headerStyle);
      }
      sheet.setRowHeight(rowIdx, 22);
      rowIdx++;

      // 입력 순서 그대로 출력
      final sorted = persons;

      for (var i = 0; i < sorted.length; i++) {
        final p      = sorted[i] as Map<dynamic, dynamic>;
        final gender = p['gender']?.toString() ?? '';
        final isMale   = gender == '남';
        final isFemale = gender == '여';
        final gStyle   = isMale ? maleStyle : (isFemale ? femaleStyle : null);
        final rowStyle = i.isEven ? evenRowStyle : oddRowStyle;
        final usedStyle = gStyle ?? rowStyle;

        final height = p['height']?.toString() ?? '';
        final weight = p['weight']?.toString() ?? '';
        final waist  = p['waist']?.toString()  ?? '';
        final thigh  = p['thigh']?.toString()  ?? '';
        final hasDetail = height.isNotEmpty || weight.isNotEmpty || waist.isNotEmpty || thigh.isNotEmpty;
        final personalLength = p['bottomLength']?.toString() ?? '';
        final personColor    = p['color']?.toString() ?? '';
        final sizeType       = p['sizeType']?.toString() ?? '성인';
        final juniorStyle    = CellStyle(
          bold: true, fontSize: 10,
          backgroundColorHex: ExcelColor.fromHexString('#E0F2F1'),
          fontColorHex: ExcelColor.fromHexString('#00695C'),
        );
        final finalStyle = sizeType == '주니어' ? juniorStyle : usedStyle;
        final usedColor  = personColor.isNotEmpty ? personColor : mainColor;
        final personHex  = _getColorHex(usedColor) ?? mainColorHex;

        _setCell(sheet, rowIdx, 0,  '${p['index'] ?? i + 1}',          style: rowStyle);
        _setCell(sheet, rowIdx, 1,  p['name']?.toString().isNotEmpty == true ? p['name']!.toString() : '-', style: gStyle ?? rowStyle);
        _setCell(sheet, rowIdx, 2,  gender.isNotEmpty ? gender : '-',   style: gStyle ?? rowStyle);
        _setCell(sheet, rowIdx, 3,  sizeType,                            style: finalStyle);
        _setCell(sheet, rowIdx, 4,  p['topSize']?.toString().isNotEmpty == true ? p['topSize']!.toString() : '-', style: finalStyle);
        _setCell(sheet, rowIdx, 5,  p['bottomSize']?.toString().isNotEmpty == true ? p['bottomSize']!.toString() : '-', style: finalStyle);
        _setCell(sheet, rowIdx, 6,  personalLength.isNotEmpty ? personalLength : (defaultLength.isNotEmpty ? defaultLength : '개별선택'), style: rowStyle);
        _setColorCell(sheet, rowIdx, 7, usedColor, baseStyle: rowStyle, overrideHex: personHex);
        _setCell(sheet, rowIdx, 8,  hasDetail && height.isNotEmpty ? height : '-', style: hasDetail ? detailStyle : rowStyle);
        _setCell(sheet, rowIdx, 9,  hasDetail && weight.isNotEmpty ? weight : '-', style: hasDetail ? detailStyle : rowStyle);
        _setCell(sheet, rowIdx, 10, hasDetail && waist.isNotEmpty  ? waist  : '-', style: hasDetail ? detailStyle : rowStyle);
        _setCell(sheet, rowIdx, 11, hasDetail && thigh.isNotEmpty  ? thigh  : '-', style: hasDetail ? detailStyle : rowStyle);
        _setCell(sheet, rowIdx, 12, sizeType == '주니어' ? '주니어' : (hasDetail ? '상세입력' : ''), style: rowStyle);
        sheet.setRowHeight(rowIdx, 18);
        rowIdx++;
      }

      // 합계 행
      _setCell(sheet, rowIdx, 0, '합계', style: totalStyle);
      _setCell(sheet, rowIdx, 1, '${sorted.length}명', style: totalStyle);
      _setCell(sheet, rowIdx, 2, '남 ${maleCount}명 / 여 ${femaleCount}명', style: totalStyle);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIdx),
      );
      sheet.setRowHeight(rowIdx, 20);
    }

    // ── 열 너비 ──
    sheet.setColumnWidth(0,  16.0);  // A: 레이블
    sheet.setColumnWidth(1,  14.0);  // B: 이름/이미지
    sheet.setColumnWidth(2,   8.0);  // C: 성별
    sheet.setColumnWidth(3,  14.0);  // D: 사이즈구분
    sheet.setColumnWidth(4,  13.0);  // E: 상의
    sheet.setColumnWidth(5,  13.0);  // F: 하의
    sheet.setColumnWidth(6,  13.0);  // G: 하의길이
    sheet.setColumnWidth(7,   9.0);  // H: 색상
    sheet.setColumnWidth(8,   9.0);  // I: 키
    sheet.setColumnWidth(9,   9.0);  // J: 몸무게
    sheet.setColumnWidth(10,  9.0);  // K: 허리
    sheet.setColumnWidth(11, 10.0);  // L: 허벅지
    sheet.setColumnWidth(12, 12.0);  // M: 비고

    return imageSlots;
  }

  /// 디자인 수정 상태 라벨
  static String _revStatusLabel(String status) {
    switch (status) {
      case 'pending': return '검토 중';
      case 'confirmed': return '확정 완료';
      case 'rejected': return '거절됨';
      case 'auto_confirmed': return '자동 확정 (3일 경과)';
      default: return status;
    }
  }

  // ── 유틸리티 함수들 ──

  static String _optText(Map<String, dynamic> opts, List<String> keys, [String fallback = '']) {
    for (final key in keys) {
      final value = opts[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return fallback;
  }

    static String _colorWithHex(String colorName, String? explicitHex) {
    final hex = (explicitHex != null && RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(explicitHex))
        ? explicitHex.toUpperCase()
        : _getColorHex(colorName)?.toUpperCase();
    return hex == null || hex.isEmpty ? colorName : '$colorName ($hex)';
  }

  static bool _isExclusive(Map<String, dynamic> opts) {
    return opts['exclusiveDesign'] == true || opts['exclusive'] == true;
  }

  static String _lengthDisplay(Map<String, dynamic> opts) {
    final common = _optText(opts, ['defaultLength', 'bottomLength']);
    if (common.isNotEmpty) return common;
    final male = _optText(opts, ['maleLength']);
    final female = _optText(opts, ['femaleLength']);
    if (male.isNotEmpty || female.isNotEmpty) {
      return '남: ${male.isEmpty ? '-' : male} / 여: ${female.isEmpty ? '-' : female}';
    }
    return '개별선택';
  }

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

  // ignore: unused_element
  static String _printTypeLabel(String value) {
    const labels = {
      '0': '디자인 유지 + 색상 변경',
      '1': '디자인 유지 + 단체명 + 색상 변경',
      '2': '디자인 변경 + 단체명 + 색상 변경',
      '3': '디자인 유지 + 색상변경 + 단체명 + 이름(후면)',
      '4': '디자인 변경 + 색상변경 + 단체명 + 이름(후면)',
    };
    return labels[value] ?? value;
  }

  static String _buildCustomSummary(Map<String, dynamic> opts) {
    final parts = <String>[];
    final printType = opts['printType']?.toString() ?? opts['printTypeLabel']?.toString() ?? '';
    if (printType.isNotEmpty) parts.add('인쇄:$printType');
    final waistband = opts['waistbandOption']?.toString() ?? opts['waistband']?.toString() ?? '';
    if (waistband.isNotEmpty && waistband != '-') parts.add('허리밴드:$waistband');
    if (_isExclusive(opts)) parts.add('독점디자인');
    final fabric = _optText(opts, ['fabricType', 'fabricName', 'fabric']);
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

  static void _setPdfLinkCell(Sheet sheet, int row, int col, String url,
      {String linkText = 'PDF 열기', CellStyle? style}) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    final safeUrl = url.replaceAll('"', '%22');
    final safeText = linkText.replaceAll('"', "'");
    cell.value = FormulaCellValue('HYPERLINK("$safeUrl","$safeText")');
    cell.cellStyle = _withBorder(style ?? CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#1565C0'),
    ));
  }
  static String _shortId(String id) =>
      id.length > 20 ? '${id.substring(0, 20)}...' : id;

  static String _formatWon(double amount) {
    final value = amount.round().toString();
    final withCommas = value.replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (m) => ',');
    return '$withCommas원';
  }

  static String _fmt(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:00';

  // ignore: unused_element
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

  // ── personChange before/after 파싱 ──
  // Firestore 저장 형식 A (신규): currentTopSize, newTopSize 등
  // Firestore 저장 형식 B (레거시): before='상의 XL / 하의 L', after='상의 XXL'
  static String _extractSizeFromText(String text, String prefix) {
    final idx = text.indexOf(prefix);
    if (idx < 0) return '';
    final rest = text.substring(idx + prefix.length).trim();
    final slashIdx = rest.indexOf('/');
    return (slashIdx >= 0 ? rest.substring(0, slashIdx) : rest).trim();
  }

  static Map<String, String> _parsePersonSizes(Map<dynamic, dynamic> person) {
    // ① 신규 키 방식 (currentTopSize 등)
    final curTopNew = (person['currentTopSize']    ?? person['현재상의']    ?? '').toString().trim();
    final newTopNew = (person['newTopSize']        ?? person['변경상의']    ?? '').toString().trim();
    final curBotNew = (person['currentBottomSize'] ?? person['현재하의']    ?? '').toString().trim();
    final newBotNew = (person['newBottomSize']     ?? person['변경하의']    ?? '').toString().trim();
    final topLen    = (person['topLength']         ?? person['상의길이']    ?? '').toString().trim();
    final botLen    = (person['bottomLength']      ?? person['하의길이']    ?? '').toString().trim();

    if (newTopNew.isNotEmpty || newBotNew.isNotEmpty ||
        curTopNew.isNotEmpty || curBotNew.isNotEmpty) {
      return {
        'curTop': curTopNew, 'newTop': newTopNew,
        'curBot': curBotNew, 'newBot': newBotNew,
        'topLen': topLen,    'botLen': botLen,
      };
    }

    // ② 레거시 before/after 방식
    // before 예: '상의 L / 하의 L'   after 예: '상의 M(110)'
    final before = (person['before'] ?? '').toString();
    final after  = (person['after']  ?? '').toString();
    return {
      'curTop': _extractSizeFromText(before, '상의'),
      'newTop': _extractSizeFromText(after,  '상의'),
      'curBot': _extractSizeFromText(before, '하의'),
      'newBot': _extractSizeFromText(after,  '하의'),
      'topLen': '', 'botLen': '',
    };
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

    // ════ Sheet 3 : 디자인 이미지 (주문정보 시트와 동일한 레이아웃 예시) ════
    final img = excel['디자인이미지'];
    _setCell(img, 0, 0, '⚡ 예시 데이터', style: sampleNoteStyle);
    img.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0));

    _setCell(img, 1, 0, '2FIT 단체주문 주문서 (예시)', style: titleStyle);
    img.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1));

    // 이미지 행 레이아웃 — generateGroupOrderExcel 과 동일 구조
    final imgLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 10,
    );
    final imgNoteStyle2 = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      fontColorHex: ExcelColor.fromHexString('#9E9E9E'),
      fontSize: 9,
      italic: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    // 디자인이미지 행
    _setCell(img, 2, 0, '디자인이미지', style: imgLabelStyle);
    img.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2),
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 2));
    _setCell(img, 2, 1, '← 실제 엑셀에서는 디자인 이미지가 여기에 표시됩니다', style: imgNoteStyle2);
    img.setRowHeight(2, 200.0);

    // 참조이미지 행
    _setCell(img, 3, 0, '참조이미지', style: imgLabelStyle);
    img.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3),
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 3));
    _setCell(img, 3, 1, '← 실제 엑셀에서는 참조 이미지가 여기에 표시됩니다', style: imgNoteStyle2);
    img.setRowHeight(3, 200.0);

    // 주문 정보 rows 예시
    final sampleInfoStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#F3E5F5'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
      fontSize: 10,
    );
    final sampleValueStyle = CellStyle(fontSize: 10);
    final sampleInfoRows = [
      ['주문번호', 'ORD-2024-0001'],
      ['주문날짜', '2024-03-25 14:30'],
      ['단체명/팀명', '부산 트라이애슬론팀'],
      ['담당자', '김철수'],
      ['연락처', '010-****-1234'],
      ['색상', '네이비'],
      ['총 인원', '20명'],
      ['주문 상태', '제작중'],
    ];
    for (int r = 0; r < sampleInfoRows.length; r++) {
      _setCell(img, 5 + r, 0, sampleInfoRows[r][0], style: sampleInfoStyle);
      _setCell(img, 5 + r, 1, sampleInfoRows[r][1], style: sampleValueStyle);
      img.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5 + r),
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 5 + r));
      img.setRowHeight(5 + r, 20.0);
    }

    // 열 너비 (generateGroupOrderExcel과 동일 구조)
    img.setColumnWidth(0, 16.0);  // A열: 레이블
    img.setColumnWidth(1, 50.0);  // B열: 이미지/값
    img.setColumnWidth(2, 20.0);
    img.setColumnWidth(3, 20.0);
    img.setColumnWidth(4, 20.0);
    img.setColumnWidth(5, 20.0);

    // 기본 Sheet 제거
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    if (encoded == null) throw Exception('샘플 엑셀 생성 실패');
    return Uint8List.fromList(encoded);
  }

  // ─────────────────────────────────────────────────────────────
  // 디자인 수정 요청 엑셀 (팀별 시트)
  // requests: _designRequests 리스트, 각 항목 = {
  //   orderId, userName, teamName, colorName, adjustedColorHex,
  //   fabricName, printType, personChanges, memo, status, createdAt
  // }
  // ─────────────────────────────────────────────────────────────
  static Uint8List generateDesignRevisionExcel(List<Map<String, dynamic>> requests) {
    return _buildDesignRevisionBase(requests).bytes;
  }

  // ── async 버전: 팀별 시트에 확정 디자인 이미지 실제 삽입 ──
  static Future<Uint8List> generateDesignRevisionExcelAsync(
      List<Map<String, dynamic>> requests) async {
    final result = _buildDesignRevisionBase(requests);
    if (result.imageSlots.isEmpty) return result.bytes;

    // 이미지 다운로드
    for (final slot in result.imageSlots) {
      try {
        final uri = Uri.parse(slot.url);
        final resp = await http.get(uri).timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) {
          slot.bytes = resp.bodyBytes;
          final ct = resp.headers['content-type'] ?? '';
          slot.ext = (ct.contains('png') || slot.url.toLowerCase().contains('.png'))
              ? 'png'
              : 'jpeg';
        }
      } catch (_) {
        // 다운로드 실패 → 해당 이미지 건너뜀
      }
    }

    return _insertImagesIntoXlsx(result.bytes, result.imageSlots);
  }

  static ({Uint8List bytes, List<_ImageToInsert> imageSlots}) _buildDesignRevisionBase(
      List<Map<String, dynamic>> requests) {
    final excel = Excel.createExcel();

    // ── 스타일 ──
    final titleStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#6A1B9A'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 13,
    );
    final sectionStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      fontSize: 10,
    );
    final labelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#F3E5F5'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
      fontSize: 10,
    );
    final valueStyle = CellStyle(fontSize: 10);
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 10,
    );
    final maleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
      fontColorHex: ExcelColor.fromHexString('#1565C0'),
      fontSize: 10,
    );
    final femaleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FCE4EC'),
      fontColorHex: ExcelColor.fromHexString('#C62828'),
      fontSize: 10,
    );
    final evenRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      fontSize: 10,
    );
    final memoStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FFFDE7'),
      fontColorHex: ExcelColor.fromHexString('#795548'),
      fontSize: 10,
    );

    // ── 1. 요약 시트 ──
    final summarySheet = excel['요약'];
    excel.setDefaultSheet('요약');

    _setCell(summarySheet, 0, 0, '2FIT 디자인 수정 요청 목록', style: titleStyle);
    summarySheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0),
    );
    summarySheet.setRowHeight(0, 28);

    final now = DateTime.now();
    _setCell(summarySheet, 1, 0,
        '생성일시: ${now.year}.${now.month.toString().padLeft(2,'0')}.${now.day.toString().padLeft(2,'0')} ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}  총 ${requests.length}건',
        style: CellStyle(fontSize: 9, fontColorHex: ExcelColor.fromHexString('#757575')));
    summarySheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 1),
    );

    final summaryHeaders = ['No', '단체명', '담당자', '색상', '사이즈 변경', '요청일시'];
    for (int c = 0; c < summaryHeaders.length; c++) {
      _setCell(summarySheet, 3, c, summaryHeaders[c], style: headerStyle);
    }
    summarySheet.setRowHeight(3, 22);

    for (int i = 0; i < requests.length; i++) {
      final req = requests[i];
      final row = 4 + i;
      final rowStyle = i.isEven ? evenRowStyle : valueStyle;
      _setCell(summarySheet, row, 0, '${i + 1}', style: rowStyle);
      _setCell(summarySheet, row, 1, req['teamName'] as String? ?? '-', style: rowStyle);
      _setCell(summarySheet, row, 2, req['userName'] as String? ?? '-', style: rowStyle);
      _setCell(summarySheet, row, 3, req['colorName'] as String? ?? '-', style: rowStyle);
      // 사이즈 변경 상세: "이름: 상의 XL→XXL, 하의 L→XL" 형식
      final personChangesForSummary = (req['personChanges'] as List<dynamic>?) ?? [];
      final sizeChangeSummary = personChangesForSummary.map((p) {
        final person = p as Map<dynamic, dynamic>;
        final name = (person['name'] ?? person['이름'] ?? '?').toString();
        final sz = _parsePersonSizes(person);
        final curTop = sz['curTop']!;
        final newTop = sz['newTop']!;
        final curBot = sz['curBot']!;
        final newBot = sz['newBot']!;
        final topLen = sz['topLen']!;
        final botLen = sz['botLen']!;
        final parts = <String>[];
        if (newTop.isNotEmpty && newTop != '-') {
          final from = (curTop.isNotEmpty && curTop != '-') ? '$curTop→' : '';
          final len  = (topLen.isNotEmpty && topLen != '-') ? '($topLen)' : '';
          parts.add('상의 $from$newTop$len');
        }
        if (newBot.isNotEmpty && newBot != '-') {
          final from = (curBot.isNotEmpty && curBot != '-') ? '$curBot→' : '';
          final len  = (botLen.isNotEmpty && botLen != '-') ? '($botLen)' : '';
          parts.add('하의 $from$newBot$len');
        }
        if (parts.isEmpty) return null;
        return '$name: ${parts.join(', ')}';
      }).whereType<String>().toList();
      final sizeChangeText = sizeChangeSummary.isNotEmpty
          ? sizeChangeSummary.join('\n')
          : '-';
      final sizeChangeStyle = CellStyle(
        fontSize: 9,
        backgroundColorHex: i.isEven
            ? ExcelColor.fromHexString('#F5F5F5')
            : ExcelColor.fromHexString('#FFFFFF'),
        textWrapping: TextWrapping.WrapText,
      );
      _setCell(summarySheet, row, 4, sizeChangeText, style: sizeChangeStyle);
      final createdAt = req['createdAt'] as DateTime?;
      _setCell(summarySheet, row, 5,
          createdAt != null
              ? '${createdAt.year}.${createdAt.month.toString().padLeft(2,'0')}.${createdAt.day.toString().padLeft(2,'0')} ${createdAt.hour.toString().padLeft(2,'0')}:${createdAt.minute.toString().padLeft(2,'0')}'
              : '-',
          style: rowStyle);
      summarySheet.setRowHeight(row, sizeChangeSummary.length > 1 ? (18.0 * sizeChangeSummary.length).clamp(18, 120).toDouble() : 18);
    }

    // 열 너비 조정
    summarySheet.setColumnWidth(0, 6);
    summarySheet.setColumnWidth(1, 22);
    summarySheet.setColumnWidth(2, 14);
    summarySheet.setColumnWidth(3, 20);
    summarySheet.setColumnWidth(4, 40);  // 사이즈 변경 상세 — 넓게
    summarySheet.setColumnWidth(5, 20);

    // 이미지 삽입 슬롯 수집
    final List<_ImageToInsert> imageSlots = [];

    // ── 2. 팀별 시트 ──
    // 팀명으로 그룹화
    final Map<String, List<Map<String, dynamic>>> teamMap = {};
    for (final req in requests) {
      final teamName = (req['teamName'] as String?)?.isNotEmpty == true
          ? req['teamName'] as String
          : req['userName'] as String? ?? '미분류';
      teamMap.putIfAbsent(teamName, () => []).add(req);
    }

    int sheetOrder = 0;
    for (final entry in teamMap.entries) {
      sheetOrder++;
      final teamName = entry.key;
      // 시트 이름 길이 제한 (Excel 최대 31자)
      final sheetName = teamName.length > 28
          ? '${teamName.substring(0, 25)}...'
          : teamName;

      final sheet = excel[sheetName];

      // 팀 타이틀
      _setCell(sheet, 0, 0, '[$sheetName] 디자인 수정 요청', style: titleStyle);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0),
      );
      sheet.setRowHeight(0, 28);

      int rowIdx = 1;

      for (final req in entry.value) {
        // ─ 요청 정보 헤더 ─
        _setCell(sheet, rowIdx, 0, '▶ 주문 / 요청 정보', style: sectionStyle);
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
          CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
        );
        sheet.setRowHeight(rowIdx, 20);
        rowIdx++;

        // ─ 확정 디자인 이미지 자리 확보 (generateGroupOrderExcel과 동일 레이아웃) ─
        final confirmedImgUrl = req['designConfirmedImageUrl'] as String? ?? '';
        if (confirmedImgUrl.isNotEmpty) {
          final imgLabelStyleSheet = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
            horizontalAlign: HorizontalAlign.Center,
            fontSize: 10,
          );
          _setCell(sheet, rowIdx, 0, '확정 디자인', style: imgLabelStyleSheet);
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
            CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
          );
          _setCell(sheet, rowIdx, 1, '', style: CellStyle(fontSize: 9));
          sheet.setRowHeight(rowIdx, 200.0); // generateGroupOrderExcel과 동일
          imageSlots.add(_ImageToInsert(
            url       : confirmedImgUrl,
            sheetName : sheetName,
            sheetIndex: 1,
            row       : rowIdx + 1, // 1-based
            col       : 1,          // B열 — generateGroupOrderExcel과 동일
            widthPx   : 260,        // generateGroupOrderExcel과 동일
            heightPx  : 195,        // generateGroupOrderExcel과 동일
            label     : '확정디자인',
          ));
          rowIdx++;
        }

        // 기본 정보 rows (색상은 아래 별도 행으로 표시)
        final infoRows = [
          ['주문ID',    req['orderId']   ?? req['id'] ?? '-'],
          ['담당자',    req['userName']  ?? '-'],
          ['단체명',    req['teamName']  ?? '-'],
        ];
        for (final info in infoRows) {
          _setCell(sheet, rowIdx, 0, info[0].toString(), style: labelStyle);
          _setCell(sheet, rowIdx, 1, info[1].toString(), style: valueStyle);
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
            CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
          );
          sheet.setRowHeight(rowIdx, 18);
          rowIdx++;
        }

        // 색상 정보 행 (memo 대신 colorName + adjustedColorHex만 표시)
        final colorName = req['colorName'] as String? ?? '';
        final colorHex  = req['adjustedColorHex'] as String? ?? '';
        if (colorName.isNotEmpty) {
          final colorText = colorHex.isNotEmpty ? '$colorName ($colorHex)' : colorName;
          _setCell(sheet, rowIdx, 0, '색상', style: labelStyle);
          _setCell(sheet, rowIdx, 1, colorText, style: valueStyle);
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
            CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
          );
          sheet.setRowHeight(rowIdx, 18);
          rowIdx++;
        }

        // 인원별 사이즈 변경
        final personChanges = req['personChanges'] as List<dynamic>? ?? [];
        if (personChanges.isNotEmpty) {
          rowIdx++; // 빈 행
          _setCell(sheet, rowIdx, 0, '▶ 인원별 사이즈 변경', style: sectionStyle);
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
            CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
          );
          sheet.setRowHeight(rowIdx, 20);
          rowIdx++;

          // 컬럼 헤더
          final personHeaders = ['No', '이름', '성별', '현재 상의', '현재 하의', '변경 상의', '변경 하의', '상의 길이', '하의 길이', '비고'];
          for (int c = 0; c < personHeaders.length; c++) {
            _setCell(sheet, rowIdx, c, personHeaders[c], style: headerStyle);
          }
          sheet.setRowHeight(rowIdx, 22);
          rowIdx++;

          for (int pi = 0; pi < personChanges.length; pi++) {
            final person = personChanges[pi] as Map<dynamic, dynamic>;
            final gender = (person['gender'] ?? person['성별'] ?? '').toString().toLowerCase();
            final isMale = gender == 'm' || gender == 'male' || gender == '남' || gender == '남성';
            final isFemale = gender == 'f' || gender == 'female' || gender == '여' || gender == '여성';
            final pStyle = isMale ? maleStyle : (isFemale ? femaleStyle : (pi.isEven ? evenRowStyle : valueStyle));

            _setCell(sheet, rowIdx, 0, '${pi + 1}', style: pStyle);
            _setCell(sheet, rowIdx, 1, (person['name'] ?? person['이름'] ?? '-').toString(), style: pStyle);
            _setCell(sheet, rowIdx, 2, isMale ? '남' : (isFemale ? '여' : (person['gender'] ?? '-').toString()), style: pStyle);
            // before/after 파싱 (레거시) or currentTopSize 등 신규 키
            final sz = _parsePersonSizes(person);
            _setCell(sheet, rowIdx, 3, sz['curTop']!.isNotEmpty ? sz['curTop']! : '-', style: pStyle);
            _setCell(sheet, rowIdx, 4, sz['curBot']!.isNotEmpty ? sz['curBot']! : '-', style: pStyle);
            _setCell(sheet, rowIdx, 5, sz['newTop']!.isNotEmpty ? sz['newTop']! : '-', style: pStyle);
            _setCell(sheet, rowIdx, 6, sz['newBot']!.isNotEmpty ? sz['newBot']! : '-', style: pStyle);
            _setCell(sheet, rowIdx, 7, sz['topLen']!.isNotEmpty ? sz['topLen']! : '-', style: pStyle);
            _setCell(sheet, rowIdx, 8, sz['botLen']!.isNotEmpty ? sz['botLen']! : '-', style: pStyle);
            _setCell(sheet, rowIdx, 9, (person['note'] ?? person['비고'] ?? '').toString(), style: pStyle);
            sheet.setRowHeight(rowIdx, 18);
            rowIdx++;
          }
        }

        rowIdx += 2; // 다음 요청 간 간격
      }

      // 열 너비 — generateGroupOrderExcel 주문정보 시트와 동일한 레이아웃
      sheet.setColumnWidth(0, 16);   // A열: 레이블 (이미지 행 레이블 포함)
      sheet.setColumnWidth(1, 20);   // B열: 값/이미지
      sheet.setColumnWidth(2, 8);
      sheet.setColumnWidth(3, 13);
      sheet.setColumnWidth(4, 13);
      sheet.setColumnWidth(5, 13);
      sheet.setColumnWidth(6, 13);
      sheet.setColumnWidth(7, 11);
      sheet.setColumnWidth(8, 11);
      sheet.setColumnWidth(9, 18);
    }

    // 기본 Sheet1 제거
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final encoded = excel.encode();
    if (encoded == null) throw Exception('디자인 수정 요청 엑셀 생성 실패');
    return (bytes: Uint8List.fromList(encoded), imageSlots: imageSlots);
  }

  // ─────────────────────────────────────────────────────────────
  // 추가제작 주문 전용 엑셀
  //  시트1: [상단] 디자인 수정·추가제작 이력 + [하단] 인원 명단
  //  시트2(주문정보): 주문자 정보 (기존 generateGroupOrderExcel의 주문정보 시트)
  // ─────────────────────────────────────────────────────────────
  static Uint8List generateAdditionalOrderExcel(OrderModel order) {
    // sync 버전은 이미지 없이 기본 엑셀만 생성 (내부 전용)
    return _buildAdditionalOrderExcelBase(order);
  }

  /// async 버전: 이미지 다운로드 후 삽입
  static Future<Uint8List> generateAdditionalOrderExcelAsync(OrderModel order) async {
    final opts = order.customOptions ?? {};

    // 이미지 URL 수집 (customOptions 우선 → items 폴백)
    final productImageUrl = opts['productImageUrl']?.toString() ??
        opts['designImageUrl']?.toString() ??
        opts['imageUrl']?.toString() ??
        order.items.firstWhere(
          (i) => i.imageUrl != null && i.imageUrl!.isNotEmpty,
          orElse: () => order.items.isNotEmpty
              ? order.items.first
              : OrderItem(productId: '', productName: '', size: '', color: '', quantity: 0, price: 0),
        ).imageUrl ?? '';
    final designFileUrl = opts['designFileUrl']?.toString() ??
        opts['maleRefImageUrl']?.toString() ?? '';
    final confirmedImageUrl = opts['designConfirmedImageUrl']?.toString() ?? '';

    // 기본 xlsx 생성 (sync)
    final baseBytes = _buildAdditionalOrderExcelBase(order,
        hasProductImage: productImageUrl.isNotEmpty,
        hasDesignFile: designFileUrl.isNotEmpty,
        hasConfirmedImage: confirmedImageUrl.isNotEmpty);

    // 이미지가 전혀 없으면 그대로 반환
    if (productImageUrl.isEmpty && designFileUrl.isEmpty && confirmedImageUrl.isEmpty) {
      return baseBytes;
    }

    // 이미지 삽입 목록 구성
    // 주문정보 시트 = sheetIndex 1 (시트1=0, 주문정보=1)
    // row 번호는 _buildAdditionalOrderExcelBase에서 예약한 행 위치와 맞춰야 함
    // 제목(row0) 다음부터: 이미지 행들
    final List<_ImageToInsert> imagesToInsert = [];
    int imgRow = 1; // 1-based row (0=제목)
    if (productImageUrl.isNotEmpty) {
      imagesToInsert.add(_ImageToInsert(
        url: productImageUrl,
        sheetIndex: 1,   // '주문정보' 시트
        sheetName: '주문정보',
        row: imgRow,
        col: 1,          // B열
        widthPx: 300,
        heightPx: 220,
        label: '디자인이미지',
      ));
      imgRow++;
    }
    if (designFileUrl.isNotEmpty) {
      imagesToInsert.add(_ImageToInsert(
        url: designFileUrl,
        sheetIndex: 1,
        sheetName: '주문정보',
        row: imgRow,
        col: 1,
        widthPx: 300,
        heightPx: 220,
        label: '참조이미지',
      ));
      imgRow++;
    }
    if (confirmedImageUrl.isNotEmpty) {
      imagesToInsert.add(_ImageToInsert(
        url: confirmedImageUrl,
        sheetIndex: 1,
        sheetName: '주문정보',
        row: imgRow,
        col: 1,
        widthPx: 300,
        heightPx: 220,
        label: '수정확정이미지',
      ));
    }

    // 이미지 다운로드
    for (final img in imagesToInsert) {
      try {
        final resp = await http.get(Uri.parse(img.url))
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) {
          img.bytes = resp.bodyBytes;
          final ct = resp.headers['content-type'] ?? '';
          img.ext = (ct.contains('png') || img.url.toLowerCase().contains('.png'))
              ? 'png' : 'jpeg';
        }
      } catch (_) {
        // 다운로드 실패 → 건너뜀
      }
    }

    return _insertImagesIntoXlsx(baseBytes, imagesToInsert);
  }

  /// 추가제작 엑셀 기본 구조 생성 (이미지 행 공간 예약 포함)
  static Uint8List _buildAdditionalOrderExcelBase(
    OrderModel order, {
    bool hasProductImage = false,
    bool hasDesignFile = false,
    bool hasConfirmedImage = false,
  }) {
    final excel = Excel.createExcel();
    final opts = order.customOptions ?? {};
    final rawPersons = (opts['persons'] as List<dynamic>?) ?? [];
    final persons = rawPersons.map((p) {
      if (p is Map) return Map<String, dynamic>.from(p as Map);
      return p as Map<String, dynamic>;
    }).toList();

    final teamName = opts['teamName']?.toString() ?? order.id;
    final mainColor = _optText(opts, ['mainColor', 'color', 'colorName'], '-');
    final mainColorHex = _getColorHex(mainColor);
    final fabricName = opts['fabricName']?.toString() ?? opts['fabric']?.toString() ?? '-';
    final defaultLength = _lengthDisplay(opts);

    // ── 스타일 정의 ──
    final purpleTitleStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4A148C'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 13,
    );
    final purpleHeader = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#6A1B9A'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 11,
    );
    final greenHeader = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1B5E20'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 11,
    );
    final sectionLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
      fontSize: 10,
    );
    final greenLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1B5E20'),
      fontSize: 10,
    );
    final grayRowStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FAFAFA'),
      fontSize: 10,
    );
    final normalStyle = CellStyle(fontSize: 10);
    final subHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 10,
    );
    final maleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
      fontColorHex: ExcelColor.fromHexString('#1565C0'),
      bold: true,
      fontSize: 10,
    );
    final femaleStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FCE4EC'),
      fontColorHex: ExcelColor.fromHexString('#C62828'),
      bold: true,
      fontSize: 10,
    );
    final juniorStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E0F2F1'),
      fontColorHex: ExcelColor.fromHexString('#00695C'),
      bold: true,
      fontSize: 10,
    );
    final totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
      fontColorHex: ExcelColor.fromHexString('#4A148C'),
      fontSize: 10,
    );

    // ══════════════════════════════════════════════
    // 시트1: 디자인 수정·추가이력 + 인원 명단
    // ══════════════════════════════════════════════
    final sheet1 = excel['시트1'];
    excel.setDefaultSheet('시트1');
    int row = 0;

    // ── 제목 ──
    _setCell(sheet1, row, 0,
        '디자인 수정 · 추가제작 내역 [${order.id}]', style: purpleTitleStyle);
    sheet1.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
    );
    sheet1.setRowHeight(row, 30);
    row++;

    // ── 디자인 수정 이력 ──
    _setCell(sheet1, row, 0, '▶ 디자인 수정 이력', style: purpleHeader);
    sheet1.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
    );
    sheet1.setRowHeight(row, 22);
    row++;

    final designRevCount = order.designRevisionCount;
    final revisionRequest = opts['designRevisionRequest'] as Map<dynamic, dynamic>?;
    final revisionNote = revisionRequest?['memo']?.toString() ?? '';
    final revisionColor = revisionRequest?['colorName']?.toString() ?? '';
    final revisionStatus = revisionRequest?['status']?.toString() ?? '';
    final revisionRequestedAt = revisionRequest?['requestedAt']?.toString() ?? '';

    final revRows = [
      ['디자인 수정 요청 횟수', '$designRevCount회 / 최대 2회'],
      ['남은 수정 가능 횟수', '${2 - designRevCount.clamp(0, 2)}회'],
      ['최근 요청 메모', revisionNote.isNotEmpty ? revisionNote : '-'],
      ['최근 요청 색상', revisionColor.isNotEmpty ? revisionColor : '-'],
      ['최근 요청 일자', revisionRequestedAt.isNotEmpty
          ? (revisionRequestedAt.length >= 10 ? revisionRequestedAt.substring(0, 10) : revisionRequestedAt)
          : '-'],
      ['최근 요청 상태', revisionStatus.isNotEmpty ? _revStatusLabel(revisionStatus) : '-'],
      ['수정 요청 / 조치 내용', ''],
    ];
    for (int i = 0; i < revRows.length; i++) {
      final isLabel = i < revRows.length - 1;
      final st = isLabel ? sectionLabelStyle : CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#EDE7F6'),
        fontColorHex: ExcelColor.fromHexString('#4A148C'),
        fontSize: 10,
      );
      _setCell(sheet1, row, 0, revRows[i][0], style: st);
      _setCell(sheet1, row, 1, revRows[i][1],
          style: i % 2 == 0 ? grayRowStyle : normalStyle);
      sheet1.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
      );
      // 메모 입력 행은 높이 3배
      sheet1.setRowHeight(row, i == revRows.length - 1 ? 54 : 18);
      row++;
    }
    row++;

    // ── 추가제작 이력 ──
    _setCell(sheet1, row, 0, '▶ 추가제작 이력', style: greenHeader);
    sheet1.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
    );
    sheet1.setRowHeight(row, 22);
    row++;

    final addCount = order.additionalOrderCount;
    final addDeadline = order.additionalOrderDeadline;
    final canAddFree = order.canOrderAdditionalFree;
    final origOrderId = opts['originalOrderId']?.toString() ?? '';
    final origTeamName = opts['originalTeamName']?.toString() ?? '';
    final origTotalCount = opts['originalTotalCount']?.toString() ?? '';
    final origOrderDate = opts['originalOrderDate']?.toString() ?? '';

    final addRows = [
      ['추가제작 신청 횟수', '$addCount회'],
      ['무료 추가제작 마감일',
          '${addDeadline.year}.${addDeadline.month.toString().padLeft(2,'0')}.${addDeadline.day.toString().padLeft(2,'0')}'],
      ['추가제작 가능 여부', canAddFree ? '가능 (마감 전)' : '마감 (새로 주문 필요)'],
      ['원주문 번호', origOrderId.isNotEmpty ? origOrderId : '-'],
      ['원주문 일자', origOrderDate.isNotEmpty
          ? (origOrderDate.length >= 10 ? origOrderDate.substring(0, 10) : origOrderDate)
          : '-'],
      ['원주문 팀명', origTeamName.isNotEmpty ? origTeamName : '-'],
      ['원주문 인원', origTotalCount.isNotEmpty ? '${origTotalCount}명' : '-'],
      ['제작 요청일', ''],
      ['최종 수정 요청 완료', ''],
      ['출고 예정일', ''],
    ];
    for (int i = 0; i < addRows.length; i++) {
      _setCell(sheet1, row, 0, addRows[i][0], style: greenLabelStyle);
      _setCell(sheet1, row, 1, addRows[i][1],
          style: i % 2 == 0 ? grayRowStyle : normalStyle);
      sheet1.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
      );
      sheet1.setRowHeight(row, 18);
      row++;
    }
    row += 2;

    // ── 인원 명단 구분선 ──
    final personCountLabel = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 10,
    );
    _setCell(sheet1, row, 0,
        '팀 인원 정보 | 총 ${persons.length}명 | ${persons.where((p) => (p['gender']?.toString() ?? '') == '남').length}명 남 / ${persons.where((p) => (p['gender']?.toString() ?? '') == '여').length}명 여',
        style: personCountLabel);
    sheet1.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
    );
    sheet1.setRowHeight(row, 22);
    row++;

    // 인원 컬럼 헤더
    final personHeaders = [
      'No', '이름', '성별', '사이즈구분', '선택 사이즈',
      '반영된 상의 사이즈', '상의 수량', '반영된 하의 사이즈', '하의 수량', '비고',
    ];
    for (int c = 0; c < personHeaders.length; c++) {
      _setCell(sheet1, row, c, personHeaders[c], style: subHeaderStyle);
    }
    sheet1.setRowHeight(row, 22);
    row++;

    // 인원 데이터
    for (int i = 0; i < persons.length; i++) {
      final p = persons[i];
      final gender = p['gender']?.toString() ?? '';
      final sizeType = p['sizeType']?.toString() ?? '성인';
      final isMale = gender == '남' || gender == 'm' || gender == 'male';
      final isFemale = gender == '여' || gender == 'f' || gender == 'female';
      final isJunior = sizeType == '주니어';

      final rowStyle = isJunior
          ? juniorStyle
          : (isMale ? maleStyle : (isFemale ? femaleStyle : (i % 2 == 0 ? grayRowStyle : normalStyle)));

      final topSize = p['topSize']?.toString() ?? '-';
      final bottomSize = p['bottomSize']?.toString() ?? '-';
      final personalLength = p['bottomLength']?.toString() ?? defaultLength;
      final note = p['note']?.toString() ?? '';

      _setCell(sheet1, row, 0, '${p['index'] ?? i + 1}', style: rowStyle);
      _setCell(sheet1, row, 1, p['name']?.toString().isNotEmpty == true ? p['name']!.toString() : '-', style: rowStyle);
      _setCell(sheet1, row, 2,
          isMale ? '남' : (isFemale ? '여' : gender.isNotEmpty ? gender : '-'),
          style: rowStyle);
      _setCell(sheet1, row, 3, sizeType, style: rowStyle);
      // 선택 사이즈: topSize와 bottomSize 합쳐서 표시
      _setCell(sheet1, row, 4,
          topSize != '-' || bottomSize != '-'
              ? '상의: $topSize / 하의: $bottomSize'
              : '-',
          style: rowStyle);
      _setCell(sheet1, row, 5, topSize, style: rowStyle);   // 반영된 상의
      _setCell(sheet1, row, 6, '1', style: rowStyle);        // 상의 수량
      _setCell(sheet1, row, 7,
          '$bottomSize${personalLength.isNotEmpty ? " ($personalLength)" : ""}',
          style: rowStyle);  // 반영된 하의 + 길이
      _setCell(sheet1, row, 8, '1', style: rowStyle);        // 하의 수량
      _setCell(sheet1, row, 9, note, style: rowStyle);
      sheet1.setRowHeight(row, 18);
      row++;
    }

    // 합계 행
    _setCell(sheet1, row, 0, '합계', style: totalStyle);
    _setCell(sheet1, row, 1, '${persons.length}명', style: totalStyle);
    _setCell(sheet1, row, 2,
        '남 ${persons.where((p) => (p['gender']?.toString() ?? '') == '남').length}명 / '
        '여 ${persons.where((p) => (p['gender']?.toString() ?? '') == '여').length}명',
        style: totalStyle);
    sheet1.merge(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
    );
    sheet1.setRowHeight(row, 20);

    // 열 너비
    sheet1.setColumnWidth(0, 6);
    sheet1.setColumnWidth(1, 14);
    sheet1.setColumnWidth(2, 7);
    sheet1.setColumnWidth(3, 12);
    sheet1.setColumnWidth(4, 22);
    sheet1.setColumnWidth(5, 16);
    sheet1.setColumnWidth(6, 10);
    sheet1.setColumnWidth(7, 20);
    sheet1.setColumnWidth(8, 10);
    sheet1.setColumnWidth(9, 18);

    // ══════════════════════════════════════════════
    // 시트2: 주문정보 (이미지 + 상세 주문자/배송 정보)
    // ══════════════════════════════════════════════
    final infoSheet = excel['주문정보'];
    int ir = 0;

    // 제목 행 (row 0)
    _setCell(infoSheet, ir, 0, '2FIT 추가제작 주문정보', style: purpleTitleStyle);
    infoSheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: ir),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: ir),
    );
    infoSheet.setRowHeight(ir, 28);
    ir++;

    // ── 이미지 행 예약 (row 1~) ──
    final imgLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 10,
    );
    if (hasProductImage) {
      _setCell(infoSheet, ir, 0, '디자인이미지', style: imgLabelStyle);
      infoSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: ir),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: ir),
      );
      _setCell(infoSheet, ir, 1, '', style: CellStyle(fontSize: 9));
      infoSheet.setRowHeight(ir, 200.0);
      ir++;
    }
    if (hasDesignFile) {
      _setCell(infoSheet, ir, 0, '참조이미지', style: imgLabelStyle);
      infoSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: ir),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: ir),
      );
      _setCell(infoSheet, ir, 1, '', style: CellStyle(fontSize: 9));
      infoSheet.setRowHeight(ir, 200.0);
      ir++;
    }
    if (hasConfirmedImage) {
      _setCell(infoSheet, ir, 0, '수정확정이미지', style: imgLabelStyle);
      infoSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: ir),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: ir),
      );
      _setCell(infoSheet, ir, 1, '', style: CellStyle(fontSize: 9));
      infoSheet.setRowHeight(ir, 200.0);
      ir++;
    }
    ir++; // 이미지 섹션과 주문정보 사이 여백

    // 주문자 정보 섹션
    _setCell(infoSheet, ir, 0, '▶ 주문자 정보', style: purpleHeader);
    infoSheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: ir),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: ir),
    );

    infoSheet.setRowHeight(ir, 20);
    ir++;

    final orderInfoRows = [
      ['주문번호', order.id],
      ['주문일자', '${order.createdAt.year}.${order.createdAt.month.toString().padLeft(2,'0')}.${order.createdAt.day.toString().padLeft(2,'0')} ${order.createdAt.hour.toString().padLeft(2,'0')}:${order.createdAt.minute.toString().padLeft(2,'0')}'],
      ['주문자', order.userName],
      ['연락처', order.userPhone],
      ['이메일', order.userEmail],
      ['배송지', order.userAddress],
      ['팀명', teamName],
      ['색상', '$mainColor${mainColorHex != null ? " ($mainColorHex)" : ""}'],
      ['원단', fabricName],
      ['총 인원', '${persons.length}명'],
    ];
    for (int i = 0; i < orderInfoRows.length; i++) {
      _setCell(infoSheet, ir, 0, orderInfoRows[i][0], style: sectionLabelStyle);
      _setCell(infoSheet, ir, 1, orderInfoRows[i][1],
          style: i % 2 == 0 ? grayRowStyle : normalStyle);
      infoSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: ir),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: ir),
      );
      infoSheet.setRowHeight(ir, 18);
      ir++;
    }

    // 원주문 정보
    if (origOrderId.isNotEmpty) {
      ir++;
      _setCell(infoSheet, ir, 0, '▶ 원주문 정보', style: greenHeader);
      infoSheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: ir),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: ir),
      );
      infoSheet.setRowHeight(ir, 20);
      ir++;
      final origRows = [
        ['원주문 번호', origOrderId],
        ['원주문 일자', origOrderDate.isNotEmpty ? origOrderDate.substring(0, 10) : '-'],
        ['원주문 팀명', origTeamName.isNotEmpty ? origTeamName : '-'],
        ['원주문 인원', origTotalCount.isNotEmpty ? '${origTotalCount}명' : '-'],
      ];
      for (int i = 0; i < origRows.length; i++) {
        _setCell(infoSheet, ir, 0, origRows[i][0], style: greenLabelStyle);
        _setCell(infoSheet, ir, 1, origRows[i][1],
            style: i % 2 == 0 ? grayRowStyle : normalStyle);
        infoSheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: ir),
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: ir),
        );
        infoSheet.setRowHeight(ir, 18);
        ir++;
      }
    }

    infoSheet.setColumnWidth(0, 22);
    infoSheet.setColumnWidth(1, 50);
    infoSheet.setColumnWidth(2, 16);
    infoSheet.setColumnWidth(3, 16);
    infoSheet.setColumnWidth(4, 16);
    infoSheet.setColumnWidth(5, 16);

    // Sheet1 제거
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    excel.setDefaultSheet('시트1');
    final encoded = excel.encode();
    if (encoded == null) throw Exception('추가제작 엑셀 생성 실패');
    return Uint8List.fromList(encoded);
  }
  /// 단체주문 상세 주문서 독립 PDF 생성
  /// 주문 생성 없이 기존 OrderModel 데이터만 사용하며, 저장된 수정값을 우선 반영한다.
  static Future<Uint8List> generateGroupOrderPdf(OrderModel order) async {
    final opts = order.customOptions ?? {};
    final persons = (opts['persons'] as List<dynamic>?) ?? [];
    final teamName = _optText(opts, ['teamName', 'groupName'], order.groupName ?? order.userName);
    final mainColor = _optText(opts, ['mainColor', 'color', 'colorName'], '-');
    final bottomColor = _optText(opts, ['bottomColorName', 'bottomColor'], '');
    final colorText = bottomColor.isEmpty
        ? _colorWithHex(mainColor, opts['adjustedColorHex']?.toString())
        : '상의: ${_colorWithHex(mainColor, opts['adjustedColorHex']?.toString())} / 하의: ${_colorWithHex(bottomColor, opts['bottomColorHex']?.toString())}';
    final orderDate = _fmtFull(order.createdAt);
    final phone = _optText(opts, ['phone', 'contactPhone'], order.userPhone);
    final email = _optText(opts, ['email', 'contactEmail'], order.userEmail);
    final address = _optText(opts, ['address', 'deliveryAddress'], order.userAddress);
    final printType = _printTypeLabel(_optText(opts, ['printType', 'printTypeLabel'], '-'));
    final refImageUrl = _optText(opts, ['refImageUrl', 'maleRefImageUrl', 'femaleRefImageUrl']);
    final refImage = await _pdfImage(refImageUrl);
    final fabric = _optText(opts, ['fabricType', 'fabricName', 'fabric'], '-');
    final fabricWeight = _optText(opts, ['fabricWeight', 'weight'], '-');
    final length = _lengthDisplay(opts);
    final waistband = _extractWaistbandInfo(opts);
    final designUrl = _extractDesignImageUrl(order);
    final designLogoUrl = _optText(opts, ['designLogoUrl']);
    final waistbandLogoUrl = _optText(opts, ['waistbandLogoUrl']);
    final designLogoName = _optText(opts, ['designLogoFileName'], '디자인 로고 파일');
    final waistbandLogoName = _optText(opts, ['waistbandLogoFileName'], '허리밴드 로고 파일');
    final productImage = await _pdfImage(designUrl);
    final designLogoImage = await _pdfImage(designLogoUrl);
    final waistbandLogoImage = await _pdfImage(waistbandLogoUrl);
    final font = pw.Font.ttf((await root_bundle.rootBundle.load('assets/fonts/NotoSansKR.ttf')));
    final pdf = pw.Document();
    final labelStyle = pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800);
    final valueStyle = pw.TextStyle(font: font, fontSize: 9, color: PdfColors.black);
    final headingStyle = pw.TextStyle(font: font, fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900);
    final headerStyle = pw.TextStyle(font: font, fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    final cellStyle = pw.TextStyle(font: font, fontSize: 7.5);

    pw.Widget infoRow(String label, String value) => pw.Row(children: [
      pw.Container(width: 78, padding: const pw.EdgeInsets.all(5), color: PdfColors.indigo50, child: pw.Text(label, style: labelStyle)),
      pw.Expanded(child: pw.Container(padding: const pw.EdgeInsets.all(5), child: pw.Text(value.isEmpty ? '-' : value, style: valueStyle))),
    ]);
    pw.Widget section(String title, pw.Widget child) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.SizedBox(height: 12), pw.Text(title, style: headingStyle), pw.SizedBox(height: 5), child,
    ]);
    pw.Widget imageCard(String title, pw.ImageProvider? image) => pw.Container(
      width: 235, height: 145, padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
      child: image == null ? pw.Center(child: pw.Text('$title\\n이미지 없음', style: cellStyle, textAlign: pw.TextAlign.center)) : pw.Column(children: [pw.Expanded(child: pw.Image(image, fit: pw.BoxFit.contain)), pw.Text(title, style: cellStyle)]),
    );

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 30),
      theme: pw.ThemeData.withFont(base: font, bold: font),
      footer: (context) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('2FIT MALL · 단체주문 상세 주문서 · ${context.pageNumber}', style: cellStyle)),
      build: (context) => [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('2FIT MALL 단체주문서', style: pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: PdfColors.orange100, child: pw.Text('PDF 상세 주문서', style: cellStyle)),
        ]),
        pw.SizedBox(height: 4),
        pw.Text('주문 수정사항과 제작 정보를 포함한 최종 확인용 문서', style: cellStyle),
        pw.SizedBox(height: 12),
        pw.Table(border: pw.TableBorder.all(color: PdfColors.orange400), children: [
          pw.TableRow(children: [infoRow('주문자/담당자', _optText(opts, ['manager', 'managerName'], order.userName)), infoRow('팀명', teamName)]),
          pw.TableRow(children: [infoRow('이메일', email), infoRow('전화번호', phone)]),
          pw.TableRow(children: [infoRow('주문날짜', orderDate), infoRow('주문상태', _statusLabel(order.status))]),
        ]),
        section('1. 디자인 이미지', pw.Wrap(spacing: 8, runSpacing: 8, children: [imageCard('디자인 시안', productImage), imageCard('업로드 디자인 로고', designLogoImage), if (refImage != null) imageCard('참고 이미지', refImage)])),
        section('2. 주문 상세 내역', pw.Table(border: pw.TableBorder.all(color: PdfColors.grey400), columnWidths: {0: const pw.FlexColumnWidth(2.2), 1: const pw.FlexColumnWidth(1.4), 2: const pw.FlexColumnWidth(0.9), 3: const pw.FlexColumnWidth(1.4), 4: const pw.FlexColumnWidth(1.1), 5: const pw.FlexColumnWidth(1.1), 6: const pw.FlexColumnWidth(1.4), 7: const pw.FlexColumnWidth(0.7), 8: const pw.FlexColumnWidth(1.0), 9: const pw.FlexColumnWidth(1.1)}, children: [
          pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.indigo900), children: ['상품명','변경을 원하는 색상','사이즈','인쇄옵션','하의길이','허리밴드','원단/무게','수량','단가','금액'].map((e) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e, style: headerStyle, textAlign: pw.TextAlign.center))).toList()),
          ...order.items.map((item) => pw.TableRow(children: [item.productName, colorText, '${item.size.isEmpty ? '-' : item.size}', printType, length, waistband, '$fabric / $fabricWeight', '${item.quantity}', _formatWon(item.price), _formatWon(item.price * item.quantity)].map((e) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e, style: cellStyle, textAlign: pw.TextAlign.center))).toList())),
        ])),
        section('3. 인원별 상세 사이즈 내역', pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(6), color: PdfColors.orange50, child: pw.Text('전체 인원 공통 적용 · 변경을 원하는 색상: $colorText', style: valueStyle)),
          pw.SizedBox(height: 5),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey400), children: [
          pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.indigo900), children: ['번호','이름','성별','사이즈구분','상의','하의','하의길이','키','몸무게','허리','허벅지','비고'].map((e) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e, style: headerStyle, textAlign: pw.TextAlign.center))).toList()),
          ...persons.asMap().entries.map((entry) { final p = entry.value is Map ? Map<String, dynamic>.from(entry.value as Map) : <String, dynamic>{}; final pLength = _optText(p, ['bottomLength', 'length', '하의길이'], length); final pNote = _optText(p, ['note', '비고'], '-'); final pSizeType = _optText(p, ['sizeType'], '성인'); return pw.TableRow(children: [ '${p['index'] ?? entry.key + 1}', _optText(p, ['name'], '-'), _optText(p, ['gender'], '-'), pSizeType, _optText(p, ['topSize'], '-'), _optText(p, ['bottomSize'], '-'), pLength, _optText(p, ['height'], '-'), _optText(p, ['weight'], '-'), _optText(p, ['waist'], '-'), _optText(p, ['thigh'], '-'), pNote].map((e) => pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e, style: cellStyle, textAlign: pw.TextAlign.center))).toList()); }),
          ]),
        ])),
        section('4. 업로드 파일 / PDF 확인', pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(designLogoName, style: valueStyle),
            if (designLogoUrl.isNotEmpty) pw.UrlLink(destination: designLogoUrl, child: pw.Text('PDF 열기', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.blue))),
          ]),
          pw.Divider(color: PdfColors.grey400),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(waistbandLogoName, style: valueStyle),
            if (waistbandLogoUrl.isNotEmpty) pw.UrlLink(destination: waistbandLogoUrl, child: pw.Text('PDF 열기', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.blue))),
          ]),
          if (waistbandLogoImage != null) pw.Padding(padding: const pw.EdgeInsets.only(top: 6), child: imageCard('허리밴드 로고 미리보기', waistbandLogoImage)),
        ])),
        section('5. 엑셀 반영 항목 및 기타 주문 정보', pw.Table(border: pw.TableBorder.all(color: PdfColors.grey400), children: [
          pw.TableRow(children: [infoRow('주문번호', order.id), infoRow('주문자', order.userName)]),
          pw.TableRow(children: [infoRow('주문유형', order.isAdditionalOrder ? '추가제작' : '단체주문'), infoRow('배송지', address)]),
          pw.TableRow(children: [infoRow('배송메모', _optText(opts, ['deliveryMemo', 'shippingMemo', 'memoText', 'memo'], order.memo ?? '-')), infoRow('결제수단', order.paymentMethod)]),
          pw.TableRow(children: [infoRow('독점디자인', _isExclusive(opts) ? '예' : '아니오'), infoRow('남/여 인원', '남 ${_countGender(order, '남')}명 / 여 ${_countGender(order, '여')}명')]),
          pw.TableRow(children: [infoRow('원단 종류/무게', '$fabric / $fabricWeight'), infoRow('단체주문 메모', _optText(opts, ['memoText', 'memo'], order.memo ?? '-'))]),
          pw.TableRow(children: [infoRow('주머니', opts['pocket'] == true ? '선택함' : '선택 안 함'), infoRow('색상 밝기', _optText(opts, ['colorTone', 'colorLightness'], '-'))]),
          pw.TableRow(children: [infoRow('허리밴드 색상코드', _optText(opts, ['waistbandColorHex'], '-')), infoRow('허리밴드 참고이미지', '${(opts['waistbandRefImages'] as List?)?.length ?? 0}장')]),
        ])),
        section('6. 디자인·추가제작·컬러 수정 이력', pw.Table(border: pw.TableBorder.all(color: PdfColors.grey400), children: [
          pw.TableRow(children: [infoRow('디자인 수정 횟수', '${order.designRevisionCount}회 / 최대 2회'), infoRow('최근 수정 상태', _optText(opts, ['designRevisionStatus', 'revisionStatus'], '-'))]),
          pw.TableRow(children: [infoRow('최근 요청 색상', _optText(opts, ['revisionColor', 'requestedColor'], colorText)), infoRow('최근 수정 내용', _optText(opts, ['revisionNote', 'designRevisionNote'], '-'))]),
          pw.TableRow(children: [infoRow('추가제작 신청 횟수', '${order.additionalOrderCount}회'), infoRow('추가제작 가능 여부', order.canOrderAdditionalFree ? '가능' : '마감')]),
          pw.TableRow(children: [infoRow('컬러/단체명 수정 횟수', '${order.colorEditCount}회 / 최대 2회'), infoRow('무료 추가제작 마감일', _fmtFull(order.additionalOrderDeadline))]),
        ])),
        pw.SizedBox(height: 14),
        pw.Container(alignment: pw.Alignment.centerRight, child: pw.Text('상품 합계 ${_formatWon(order.totalAmount)}  |  배송비 ${_formatWon(order.shippingFee)}  |  총 결제금액 ${_formatWon(order.totalAmount + order.shippingFee)}', style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900))),
      ],
    ));
    return Uint8List.fromList(await pdf.save());
  }

  static Future<Uint8List?> _fetchBytes(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      return response.statusCode == 200 ? response.bodyBytes : null;
    } catch (_) { return null; }
  }

  static Future<pw.ImageProvider?> _pdfImage(String url) async {
    final bytes = await _fetchBytes(url);
    return bytes == null ? null : pw.MemoryImage(bytes);
  }

} // end OrderExcelService


class OrderDateRange {
  final DateTime start;
  final DateTime end;
  const OrderDateRange({required this.start, required this.end});
}

/// 이미지 삽입 정보를 담는 내부 헬퍼 클래스
class _ImageToInsert {
  final String url;
  final int sheetIndex;    // 0-based (sheetName 없을 때 폴백)
  final String? sheetName; // 시트 이름으로 정확히 찾기 (우선 사용)
  final int row;           // 1-based Excel row
  final int col;           // 0-based column index
  final int widthPx;
  final int heightPx;
  final String label;
  Uint8List? bytes;
  String ext; // 'png' or 'jpeg'

  _ImageToInsert({
    required this.url,
    this.sheetIndex = 0,
    this.sheetName,
    required this.row,
    required this.col,
    required this.widthPx,
    required this.heightPx,
    required this.label,
  }) : ext = 'jpeg';
}
