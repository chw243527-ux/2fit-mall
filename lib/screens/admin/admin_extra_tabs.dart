import '../../utils/theme.dart';
// admin_extra_tabs.dart — 매출통계, 재고관리, 직원계정 탭 위젯
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart' hide Border;
import '../../utils/web_utils.dart'
    if (dart.library.html) '../../utils/web_utils_html.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/models.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import 'admin_inventory_tab.dart';

// ══════════════════════════════════════════════
// 매출 통계 탭 위젯
// ══════════════════════════════════════════════
class AdminSalesStatsTab extends StatefulWidget {
  const AdminSalesStatsTab({super.key});

  @override
  State<AdminSalesStatsTab> createState() => _AdminSalesStatsTabState();
}

class _AdminSalesStatsTabState extends State<AdminSalesStatsTab> {
  String _fmtMillions(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _fmtPrice(double amount) {
    final n = amount.toInt();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _statsKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportOrdersToExcel(List<OrderModel> orders) async {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('내보낼 주문이 없습니다.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['주문내역'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A1A2E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    final headers = [
      '주문번호', '회원명', '연락처', '배송주소', '주문금액', '배송비', '결제방법', '주문유형', '상태', '주문일시',
      '내 매출(30%)', '본사 매출(70%)',
      // 단체주문 옵션
      '팀명', '담당자', '총인원', '메인색상', '색상HEX', '밝기',
      '재봉방법', '원단무게', '주머니', '하의기장', '허리밴드옵션', '허리밴드색상HEX',
      '독점디자인', '인쇄방식',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (int r = 0; r < orders.length; r++) {
      final o = orders[r];
      final opts = o.customOptions ?? {};
      final isGroup = o.orderType == 'group';
      // 주머니: bool 또는 string 모두 처리
      String pocketVal = '-';
      if (isGroup) {
        final p = opts['pocket'];
        if (p == true || p == 'true')
          pocketVal = '있음';
        else if (p == false || p == 'false')
          pocketVal = '없음';
        else
          pocketVal = '없음';
      }
      final myRevenue = (o.totalAmount * 0.3).roundToDouble();
      final hqRevenue = (o.totalAmount * 0.7).roundToDouble();
      final row = [
        o.id,
        o.userName,
        o.userPhone,
        o.userAddress,
        o.totalAmount.toStringAsFixed(0),
        o.shippingFee.toStringAsFixed(0),
        o.paymentMethod,
        isGroup ? '단체' : '개인',
        o.status.label,
        '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}-${o.createdAt.day.toString().padLeft(2, '0')} ${o.createdAt.hour.toString().padLeft(2, '0')}:${o.createdAt.minute.toString().padLeft(2, '0')}',
        myRevenue.toStringAsFixed(0),
        hqRevenue.toStringAsFixed(0),
        // 단체주문 옵션 (비단체주문은 '-')
        isGroup ? (opts['teamName'] ?? o.groupName ?? '-') : '-',
        isGroup ? (opts['manager'] ?? '-') : '-',
        isGroup ? (o.groupCount?.toString() ?? '-') : '-',
        isGroup ? (opts['mainColor'] ?? '-') : '-',
        isGroup ? (opts['adjustedColorHex'] ?? '-') : '-',
        isGroup ? (opts['colorTone'] ?? '-') : '-',
        isGroup ? (opts['fabric'] ?? '-') : '-',
        isGroup ? (opts['weight'] ?? '-') : '-',
        pocketVal,
        isGroup ? (opts['defaultLength'] ?? '-') : '-',
        isGroup ? (opts['waistbandOption'] ?? '-') : '-',
        isGroup
            ? ((opts['waistbandColorHex'] ?? '').toString().isEmpty
                ? '-'
                : opts['waistbandColorHex'].toString())
            : '-',
        isGroup
            ? ((opts['exclusive'] == true || opts['exclusive'] == 'true')
                ? '선택'
                : '미선택')
            : '-',
        isGroup ? (opts['printType'] ?? '-') : '-',
      ];
      final rowStyle = CellStyle(
        backgroundColorHex: r % 2 == 0
            ? ExcelColor.fromHexString('#FFFFFF')
            : ExcelColor.fromHexString('#F5F5F5'),
      );
      for (int c = 0; c < row.length; c++) {
        final cell = sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        cell.value = TextCellValue(row[c].toString());
        cell.cellStyle = rowStyle;
      }
    }

    // 요약 시트
    final summarySheet = excel['요약'];
    final now = DateTime.now();
    final totalRevenue = orders.fold<double>(0, (s, o) => s + o.totalAmount);
    final myTotalRev = (totalRevenue * 0.3).roundToDouble();
    final hqTotalRev = (totalRevenue * 0.7).roundToDouble();
    final monthOrders = orders
        .where((o) =>
            o.createdAt.year == now.year && o.createdAt.month == now.month)
        .toList();
    final monthRevenue =
        monthOrders.fold<double>(0, (s, o) => s + o.totalAmount);
    final myMonthRev = (monthRevenue * 0.3).roundToDouble();
    final hqMonthRev = (monthRevenue * 0.7).roundToDouble();

    // 매출 분배 스타일
    final myRevStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      fontColorHex: ExcelColor.fromHexString('#1B5E20'),
    );
    final hqRevStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
      fontColorHex: ExcelColor.fromHexString('#0D47A1'),
    );

    final summaryData = [
      ['총 주문 수', '${orders.length}건', ''],
      ['총 매출액 (합계)', '₩${_fmtPrice(totalRevenue)}', '100%'],
      ['  └ 내 매출 (30%)', '₩${_fmtPrice(myTotalRev)}', '30%'],
      ['  └ 본사 매출 (70%)', '₩${_fmtPrice(hqTotalRev)}', '70%'],
      ['이번 달 주문', '${monthOrders.length}건', ''],
      ['이번 달 매출 (합계)', '₩${_fmtPrice(monthRevenue)}', '100%'],
      ['  └ 내 매출 (30%)', '₩${_fmtPrice(myMonthRev)}', '30%'],
      ['  └ 본사 매출 (70%)', '₩${_fmtPrice(hqMonthRev)}', '70%'],
      [
        '평균 주문액',
        orders.isEmpty ? '₩0' : '₩${_fmtPrice(totalRevenue / orders.length)}',
        ''
      ],
      ['개인 주문', '${orders.where((o) => o.orderType != 'group').length}건', ''],
      ['단체 주문', '${orders.where((o) => o.orderType == 'group').length}건', ''],
      [
        '다운로드 일시',
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        ''
      ],
    ];

    // 요약 시트 헤더 (3컬럼)
    final h0 = summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    h0.value = TextCellValue('항목');
    h0.cellStyle = headerStyle;
    final h1 = summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0));
    h1.value = TextCellValue('금액 / 값');
    h1.cellStyle = headerStyle;
    final h2 = summarySheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0));
    h2.value = TextCellValue('비율');
    h2.cellStyle = headerStyle;

    for (int r = 0; r < summaryData.length; r++) {
      final label = summaryData[r][0];
      final isMyRev = label.contains('내 매출');
      final isHqRev = label.contains('본사 매출');
      for (int c = 0; c < summaryData[r].length; c++) {
        final cell = summarySheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        cell.value = TextCellValue(summaryData[r][c]);
        if (isMyRev)
          cell.cellStyle = myRevStyle;
        else if (isHqRev) cell.cellStyle = hqRevStyle;
      }
    }

    final encoded = excel.encode();
    if (encoded == null) return;
    final uint8List = Uint8List.fromList(encoded);
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final fileName = '2FIT_MALL_주문내역_$dateStr.xlsx';
    const mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    if (kIsWeb) {
      downloadFileWeb(uint8List, fileName, mimeType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.download_done_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    const Text('📂 화면 하단 다운로드 바 또는 내 PC → 다운로드 폴더 확인',
                        style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ]),
            backgroundColor: const Color(0xFF217346),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } else {
      // 모바일: 바로 공유 시트 열기
      try {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await File(filePath).writeAsBytes(uint8List, flush: true);
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath, mimeType: mimeType, name: fileName)],
            subject: '2FIT MALL 주문내역 엑셀',
            text: '공유 시트에서 "내 파일에 저장" 또는 "다운로드"를 선택하세요.\n파일명: $fileName',
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('파일 저장 오류: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.watchAllOrders(),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final now = DateTime.now();

        // 월별 매출 집계 (최근 6개월)
        final monthlyData = <String, double>{};
        for (int i = 5; i >= 0; i--) {
          final m = DateTime(now.year, now.month - i, 1);
          final key = '${m.month}월';
          monthlyData[key] = 0;
        }
        for (final o in orders) {
          final m = DateTime(now.year, now.month - 5, 1);
          if (o.createdAt.isAfter(m)) {
            final key = '${o.createdAt.month}월';
            monthlyData[key] = (monthlyData[key] ?? 0) + o.totalAmount;
          }
        }

        // 주문 상태별 집계
        final statusCount = <String, int>{};
        for (final o in orders) {
          statusCount[o.status.label] = (statusCount[o.status.label] ?? 0) + 1;
        }

        final totalRevenue =
            orders.fold<double>(0, (s, o) => s + o.totalAmount);
        final myRevenue = (totalRevenue * 0.3).roundToDouble();
        final hqRevenue = (totalRevenue * 0.7).roundToDouble();
        final todayOrders = orders
            .where((o) =>
                o.createdAt.year == now.year &&
                o.createdAt.month == now.month &&
                o.createdAt.day == now.day)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('매출 통계',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _exportOrdersToExcel(orders),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text('엑셀 다운로드'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF217346),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // KPI 카드 — 총 매출 + 분배 (3열)
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  _statsKpiCard('총 매출', '₩${_fmtMillions(totalRevenue)}',
                      Icons.monetization_on_rounded, const Color(0xFF4CAF50)),
                  _statsKpiCard(
                      '내 매출 (30%)',
                      '₩${_fmtMillions(myRevenue)}',
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFF2196F3)),
                  _statsKpiCard('본사 매출 (70%)', '₩${_fmtMillions(hqRevenue)}',
                      Icons.business_rounded, const Color(0xFF9C27B0)),
                ],
              ),
              const SizedBox(height: 8),
              // KPI 카드 — 주문 현황 (3열)
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  _statsKpiCard('총 주문', '${orders.length}건',
                      Icons.receipt_long_rounded, const Color(0xFF00BCD4)),
                  _statsKpiCard('오늘 주문', '${todayOrders}건', Icons.today_rounded,
                      const Color(0xFFFF9800)),
                  _statsKpiCard(
                      '평균 주문액',
                      orders.isEmpty
                          ? '₩0'
                          : '₩${_fmtMillions(totalRevenue / orders.length)}',
                      Icons.analytics_rounded,
                      const Color(0xFFE91E63)),
                ],
              ),
              const SizedBox(height: 24),

              // 월별 매출 바 차트
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('월별 매출',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: monthlyData.values.isEmpty
                              ? 100
                              : (monthlyData.values
                                          .reduce((a, b) => a > b ? a : b) *
                                      1.2)
                                  .clamp(1, double.infinity),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                final key =
                                    monthlyData.keys.elementAt(groupIndex);
                                return BarTooltipItem(
                                  '$key\n₩${_fmtMillions(rod.toY)}',
                                  const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final keys = monthlyData.keys.toList();
                                  if (value.toInt() < keys.length) {
                                    return Text(keys[value.toInt()],
                                        style: const TextStyle(fontSize: 11));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) => Text(
                                    _fmtMillions(value),
                                    style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          barGroups: monthlyData.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.value,
                                  color: AppColors.error,
                                  width: 20,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 주문 상태 파이 차트 + 주문 유형별
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('주문 상태 분포',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: orders.isEmpty
                                ? Center(child: Text('주문 없음'))
                                : PieChart(
                                    PieChartData(
                                      sections: statusCount.entries.map((e) {
                                        final colors = {
                                          '주문 대기': AppColors.warning,
                                          '주문 확인': AppColors.info,
                                          '제작/준비 중': AppColors.primary,
                                          '배송 중': AppColors.primary,
                                          '배송 완료': AppColors.success,
                                          '주문 취소': AppColors.error,
                                        };
                                        return PieChartSectionData(
                                          value: e.value.toDouble(),
                                          title: '${e.key}\n${e.value}',
                                          color: colors[e.key] ?? Colors.grey,
                                          radius: 70,
                                          titleStyle: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }).toList(),
                                      centerSpaceRadius: 30,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('주문 유형별',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          ...['personal', 'group'].map((type) {
                            final count =
                                orders.where((o) => o.orderType == type).length;
                            final revenue = orders
                                .where((o) => o.orderType == type)
                                .fold<double>(0, (s, o) => s + o.totalAmount);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type == 'personal' ? '개인 주문' : '단체 주문',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$count건 · ₩${_fmtMillions(revenue)}',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: orders.isEmpty
                                        ? 0
                                        : count / orders.length,
                                    backgroundColor: Colors.grey.shade200,
                                    color: type == 'personal'
                                        ? AppColors.info
                                        : AppColors.warning,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
// 재고 관리 탭 위젯 → admin_inventory_tab.dart 참조
// ══════════════════════════════════════════════
// (export 대신 admin_screen.dart에서 직접 import)

// ══════════════════════════════════════════════
// 직원 계정 관리 탭 위젯
// ══════════════════════════════════════════════
class AdminStaffTab extends StatefulWidget {
  const AdminStaffTab({super.key});

  @override
  State<AdminStaffTab> createState() => _AdminStaffTabState();
}

class _AdminStaffTabState extends State<AdminStaffTab> {
  static const _staffRoles = [
    '총괄 관리자',
    '매장 관리자',
    '운영 매니저',
    'CS 담당',
    '콘텐츠 담당',
    '재고 담당',
  ];

  Future<void> _syncStaffAdminClaim({
    required String targetUid,
    required bool grant,
    String? staffRole,
  }) async {
    final current = FirebaseAuth.instance.currentUser;
    final token = await current?.getIdToken();
    if (current == null || token == null || token.isEmpty) {
      throw StateError('관리자 로그인 세션이 만료되었습니다. 다시 로그인해주세요.');
    }
    final response = await http.post(
      Uri.parse('https://us-central1-fit-mall.cloudfunctions.net/setStaffAdminClaim'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'targetUid': targetUid,
        'grant': grant,
        'currentUid': current.uid,
        if (staffRole != null) 'staffRole': staffRole,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('관리자 권한 동기화에 실패했습니다.');
    }
  }

  void _showAddStaffDialog() {
    final emailCtrl = TextEditingController();
    String staffRole = '운영 매니저';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('직원 계정에 관리자 권한 부여'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('이미 가입된 회원의 이메일을 입력하면 관리자 권한을 부여합니다.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: staffRole,
              decoration: const InputDecoration(
                labelText: '직급',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: _staffRoles
                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setDialogState(() => staffRole = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소')),
          ElevatedButton(
            onPressed: () async {
              try {
                final email = emailCtrl.text.trim().toLowerCase();
                if (email.isEmpty) return;

              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();

              if (query.docs.isNotEmpty) {
                await _syncStaffAdminClaim(
                  targetUid: query.docs.first.id,
                  grant: true,
                  staffRole: staffRole,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$email 님에게 관리자 권한을 부여했습니다')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('해당 이메일의 회원을 찾을 수 없습니다')),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('직원 권한 저장에 실패했습니다: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('권한 부여'),
          ),
        ],
      ),
      ),
    );
  }

  void _showStaffRoleDialog(Map<String, dynamic> staff) {
    String staffRole = (staff['staffRole'] as String?) ?? '운영 매니저';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('${staff['name'] ?? '직원'} 직급 설정'),
          content: DropdownButtonFormField<String>(
            value: _staffRoles.contains(staffRole) ? staffRole : '운영 매니저',
            decoration: const InputDecoration(
              labelText: '직급',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: _staffRoles
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (value) {
              if (value != null) setDialogState(() => staffRole = value);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  final targetUid = staff['id'] as String?;
                  if (targetUid == null || targetUid.isEmpty) {
                    throw StateError('직원 계정 식별자가 없습니다.');
                  }
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(targetUid)
                      .update({
                    'staffRole': staffRole,
                    'staffRoleUpdatedAt': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('직급을 $staffRole(으)로 변경했습니다.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('직급 저장에 실패했습니다: $e')),
                    );
                  }
                }
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevokeDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('관리자 권한 해제: ${staff['name'] ?? ''}'),
        content: Text('${staff['email']} 님의 관리자 권한을 해제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소')),
          ElevatedButton(
            onPressed: () async {
              try {
                final targetUid = staff['id'] as String?;
                if (targetUid == null || targetUid.isEmpty) {
                  throw StateError('직원 계정 식별자가 없습니다.');
                }
                await _syncStaffAdminClaim(
                  targetUid: targetUid,
                  grant: false,
                );
              if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${staff['name']} 님의 관리자 권한이 해제되었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('관리자 권한 해제에 실패했습니다: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('해제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AuthService.watchAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final staffList =
            snapshot.data!.where((u) => u['isAdmin'] == true).toList();
        final allUsers = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('직원 계정 관리',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Builder(builder: (context) {
                    final compact = MediaQuery.of(context).size.width < 480;
                    return compact
                        ? IconButton.filled(
                            onPressed: _showAddStaffDialog,
                            icon: const Icon(Icons.person_add_rounded),
                            tooltip: '직원 추가',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(44, 44),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _showAddStaffDialog,
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: const Text('직원 추가'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                  }),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '총 ${staffList.length}명의 관리자 / 전체 회원 ${allUsers.length}명',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...staffList.map((staff) {
                final email = staff['email'] as String? ?? '';
                final name = staff['name'] as String? ?? '이름없음';
                final staffRole = staff['staffRole'] as String? ?? '직급 미지정';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('관리자',
                                      style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(staffRole,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.info,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(email,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showStaffRoleDialog(staff),
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.info),
                            tooltip: '직급 수정',
                          ),
                          IconButton(
                        onPressed: () => _showRevokeDialog(staff),
                        icon: const Icon(Icons.remove_circle_outline_rounded,
                            color: AppColors.error),
                        tooltip: '권한 해제',
                      ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
// 디자인 요청 엑셀 내보내기 헬퍼 함수
// ══════════════════════════════════════════════
Future<void> exportDesignRequestsToExcel(
  BuildContext context,
  List<Map<String, dynamic>> requests,
) async {
  if (requests.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('내보낼 디자인 요청이 없습니다.'),
          backgroundColor: AppColors.warning),
    );
    return;
  }

  String fmtPrice(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  final excelFile = Excel.createExcel();
  final sheet = excelFile['디자인요청'];

  final headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#6A1B9A'),
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
  );
  final subHeaderStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#E1BEE7'),
    fontColorHex: ExcelColor.fromHexString('#4A148C'),
  );

  // ── 헤더 ──
  final headers = [
    '번호',
    '주문번호',
    '고객명',
    '요청유형',
    '요청내용',
    '상태',
    '요청일시',
    '메인색상',
    '색상HEX',
    '재봉방법',
    '원단무게',
    '주머니',
    '하의기장',
    '팀명',
    '담당자',
  ];
  for (int i = 0; i < headers.length; i++) {
    final cell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
    cell.value = TextCellValue(headers[i]);
    cell.cellStyle = i < 7 ? headerStyle : subHeaderStyle;
  }

  // ── 데이터 행 ──
  for (int r = 0; r < requests.length; r++) {
    final req = requests[r];
    final createdAt = req['createdAt'] as DateTime? ?? DateTime.now();
    final opts = req['customOptions'] as Map<String, dynamic>? ?? {};

    final pocketRaw = opts['pocket'];
    String pocketVal = '-';
    if (pocketRaw == true || pocketRaw == 'true')
      pocketVal = '있음';
    else if (pocketRaw == false || pocketRaw == 'false') pocketVal = '없음';

    final rowData = [
      '${r + 1}',
      req['orderId'] as String? ?? req['id'] as String? ?? '-',
      req['userName'] as String? ?? '-',
      req['requestType'] as String? ?? '디자인 수정',
      req['description'] as String? ?? '-',
      req['status'] as String? ?? '대기중',
      '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} '
          '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
      opts['mainColor'] as String? ?? '-',
      opts['adjustedColorHex'] as String? ?? '-',
      opts['fabric'] as String? ?? '-',
      opts['weight'] as String? ?? '-',
      pocketVal,
      opts['defaultLength'] as String? ?? '-',
      opts['teamName'] as String? ?? '-',
      opts['manager'] as String? ?? '-',
    ];

    final rowStyle = CellStyle(
      backgroundColorHex: r % 2 == 0
          ? ExcelColor.fromHexString('#FFFFFF')
          : ExcelColor.fromHexString('#FAF5FF'),
    );
    for (int c = 0; c < rowData.length; c++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
      cell.value = TextCellValue(rowData[c]);
      cell.cellStyle = rowStyle;
    }
  }

  // ── 요약 시트 ──
  final summary = excelFile['요약'];
  final now = DateTime.now();
  final statusCounts = <String, int>{};
  for (final req in requests) {
    final s = req['status'] as String? ?? '대기중';
    statusCounts[s] = (statusCounts[s] ?? 0) + 1;
  }

  final summaryHeaderStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#6A1B9A'),
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
  );
  final sh0 =
      summary.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
  sh0.value = TextCellValue('항목');
  sh0.cellStyle = summaryHeaderStyle;
  final sh1 =
      summary.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0));
  sh1.value = TextCellValue('값');
  sh1.cellStyle = summaryHeaderStyle;

  final summaryData = [
    ['총 요청 수', '${requests.length}건'],
    ['대기중', '${statusCounts['대기중'] ?? 0}건'],
    ['처리중', '${statusCounts['처리중'] ?? 0}건'],
    ['완료', '${statusCounts['완료'] ?? 0}건'],
    ['거절', '${statusCounts['거절'] ?? 0}건'],
    [
      '다운로드 일시',
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'
    ],
  ];
  for (int r = 0; r < summaryData.length; r++) {
    for (int c = 0; c < 2; c++) {
      summary
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
          .value = TextCellValue(summaryData[r][c]);
    }
  }

  // ── 인코딩 & 다운로드 ──
  final encoded = excelFile.encode();
  if (encoded == null) return;
  final uint8List = Uint8List.fromList(encoded);
  final dateStr =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final fileName = '2FIT_디자인요청_$dateStr.xlsx';
  const mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  if (kIsWeb) {
    downloadFileWeb(uint8List, fileName, mimeType);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.download_done_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$fileName 다운로드 완료'),
          ]),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  } else {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(uint8List);
      await SharePlus.instance.share(
        ShareParams(
            files: [XFile(file.path, mimeType: mimeType)],
            subject: '2FIT 디자인요청'),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('저장 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // fmtPrice 사용 억제
  if (false) fmtPrice(0);
}
