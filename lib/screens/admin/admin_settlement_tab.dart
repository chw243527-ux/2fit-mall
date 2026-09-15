import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../models/models.dart';
import '../../services/order_service.dart';
import '../../utils/theme.dart';
import '../../utils/web_utils.dart'
    if (dart.library.html) '../../utils/web_utils_html.dart';

/// 계약서 제7조·제8조의 매입/재판매 구조를 관리하는 관리자 탭입니다.
/// 계약서의 [확인 필요] 항목은 관리자 설정으로 확정하기 전까지 기본 70/30으로 표시합니다.
class AdminSettlementTab extends StatefulWidget {
  const AdminSettlementTab({super.key});
  @override
  State<AdminSettlementTab> createState() => _AdminSettlementTabState();
}

class _AdminSettlementTabState extends State<AdminSettlementTab> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  double _hqRate = .70;
  bool _showPurchases = false;
  bool _performanceEnabled = false;
  double _performanceTargetSales = 0;
  int _performanceMinOrders = 0;
  double _performanceMaxRefundRate = 100;

  @override
  void initState() {
    super.initState();
    _loadPerformanceSettings();
  }

  Future<void> _loadPerformanceSettings() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('settlement_settings')
          .doc('performance')
          .get();
      final data = snap.data();
      if (!mounted || data == null) return;
      setState(() {
        _performanceEnabled = data['enabled'] == true;
        _performanceTargetSales = (data['targetSales'] as num?)?.toDouble() ?? 0;
        _performanceMinOrders = (data['minOrders'] as num?)?.toInt() ?? 0;
        _performanceMaxRefundRate = (data['maxRefundRate'] as num?)?.toDouble() ?? 100;
      });
    } catch (_) {}
  }

  DateTime _monthStart(DateTime value) => DateTime(value.year, value.month, 1);

  DateTime _previousMonthStart(DateTime value) =>
      DateTime(value.year, value.month - 1, 1);

  bool _isCancelledOrRefunded(OrderModel order) =>
      order.status == OrderStatus.cancelled || order.status == OrderStatus.refunded;

  double _monthSales(List<OrderModel> orders, DateTime month) {
    final start = _monthStart(month);
    final end = DateTime(start.year, start.month + 1, 1);
    return orders
        .where((o) => !o.createdAt.isBefore(start) && o.createdAt.isBefore(end))
        .where((o) => !_isCancelledOrRefunded(o))
        .fold<double>(0, (sum, o) => sum + o.totalAmount);
  }

  int _monthOrderCount(List<OrderModel> orders, DateTime month) {
    final start = _monthStart(month);
    final end = DateTime(start.year, start.month + 1, 1);
    return orders
        .where((o) => !o.createdAt.isBefore(start) && o.createdAt.isBefore(end))
        .where((o) => !_isCancelledOrRefunded(o))
        .length;
  }

  double _monthRefundRate(List<OrderModel> orders, DateTime month) {
    final start = _monthStart(month);
    final end = DateTime(start.year, start.month + 1, 1);
    final monthOrders = orders.where((o) =>
        !o.createdAt.isBefore(start) && o.createdAt.isBefore(end)).toList();
    if (monthOrders.isEmpty) return 0;
    final refunded = monthOrders.where(_isCancelledOrRefunded).length;
    return refunded / monthOrders.length * 100;
  }

  bool _performanceMet(List<OrderModel> orders, DateTime month) {
    if (!_performanceEnabled || _performanceTargetSales <= 0) return false;
    final sales = _monthSales(orders, month);
    final count = _monthOrderCount(orders, month);
    final refundRate = _monthRefundRate(orders, month);
    return sales >= _performanceTargetSales &&
        count >= _performanceMinOrders &&
        refundRate <= _performanceMaxRefundRate;
  }

  double _rateForOrder(List<OrderModel> orders, OrderModel order) {
    // 계약서 제8조 권장안: 전월 성과 달성 시 다음 달 1일부터 60/40 적용.
    return _performanceMet(orders, _previousMonthStart(order.createdAt)) ? .60 : .70;
  }

  double _rateForRange(List<OrderModel> orders) {
    final rates = orders.where((o) => _inRange(o.createdAt)).map((o) => _rateForOrder(orders, o)).toSet();
    return rates.length == 1 ? rates.first : -1;
  }

  Future<void> _savePerformanceSettings() async {
    await FirebaseFirestore.instance.collection('settlement_settings').doc('performance').set({
      'enabled': _performanceEnabled,
      'targetSales': _performanceTargetSales,
      'minOrders': _performanceMinOrders,
      'maxRefundRate': _performanceMaxRefundRate,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _configurePerformance() async {
    var enabled = _performanceEnabled;
    final target = TextEditingController(text: _performanceTargetSales == 0 ? '' : _performanceTargetSales.toStringAsFixed(0));
    final minOrders = TextEditingController(text: _performanceMinOrders.toString());
    final maxRefund = TextEditingController(text: _performanceMaxRefundRate.toStringAsFixed(2));
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('성과 배분 조건 설정'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          StatefulBuilder(builder: (ctx, setLocal) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('성과연동 자동 적용'),
            subtitle: const Text('전월 조건 충족 시 다음 달부터 본사 60%·운영자 40%'),
            value: enabled,
            onChanged: (v) => setLocal(() => enabled = v),
          )),
          TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '전월 최소 정산대상 매출(원)', hintText: '계약서 별지 기준 입력')),
          TextField(controller: minOrders, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '전월 최소 주문 수(선택)')),
          TextField(controller: maxRefund, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '최대 취소·환불률(%, 선택)')),
          const SizedBox(height: 8),
          Text('계약서에 별지 수치가 확정되기 전에는 조건을 임의로 입력하지 마세요.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );
    if (result != true) return;
    setState(() {
      _performanceEnabled = enabled;
      _performanceTargetSales = double.tryParse(target.text.replaceAll(',', '')) ?? 0;
      _performanceMinOrders = int.tryParse(minOrders.text) ?? 0;
      _performanceMaxRefundRate = double.tryParse(maxRefund.text) ?? 100;
    });
    await _savePerformanceSettings();
  }

  String _money(num value) {
    final s = value.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '₩$b';
  }

  String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _inRange(DateTime d) => !d.isBefore(DateTime(_from.year, _from.month, _from.day)) &&
      !d.isAfter(DateTime(_to.year, _to.month, _to.day, 23, 59, 59));

  Future<void> _pickDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: start ? _from : _to,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
        if (_from.isAfter(_to)) _from = _to;
      }
    });
  }

  Future<void> _downloadPdf(List<OrderModel> orders, List<Map<String, dynamic>> purchases) async {
    final filtered = orders.where((o) => _inRange(o.createdAt)).toList();
    final confirmed = filtered.where((o) => o.status != OrderStatus.cancelled && o.status != OrderStatus.refunded).toList();
    final gross = confirmed.fold<double>(0, (s, o) => s + o.totalAmount);
    final orderRates = <String, double>{for (final o in confirmed) o.id: _rateForOrder(orders, o)};
    final hq = confirmed.fold<double>(0, (sum, o) => sum + o.totalAmount * (orderRates[o.id] ?? .70));
    final operatorShare = gross - hq;
    final purchaseTotal = purchases.where((p) {
      final ts = p['purchaseDate'];
      final date = ts is Timestamp ? ts.toDate() : DateTime.tryParse('$ts');
      return date != null && _inRange(date);
    }).fold<double>(0, (s, p) => s + ((p['totalAmount'] as num?)?.toDouble() ?? 0));

    final doc = pw.Document();
    final font = pw.Font.helvetica();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font),
      build: (_) => [
        pw.Header(level: 0, child: pw.Text('2FIT MALL 본사 정산내역', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.Text('정산기간: ${_date(_from)} ~ ${_date(_to)}'),
        pw.SizedBox(height: 16),
        pw.Table.fromTextArray(
          headers: const ['구분', '금액', '비고'],
          data: [
            ['정산대상 상품매출', _money(gross), '취소·환불 확정분 제외'],
            ['본사 공급가', _money(hq), '성과조건 충족 월은 60%, 그 외 70%'],
            ['운영자 매출총이익', _money(operatorShare), '성과조건 충족 월은 40%, 그 외 30%'],
            ['매입 합계', _money(purchaseTotal), '등록된 매입 내역 기준'],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          border: pw.TableBorder.all(color: PdfColors.grey400),
          cellPadding: const pw.EdgeInsets.all(6),
        ),
        pw.SizedBox(height: 18),
        pw.Text('주문별 정산', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Table.fromTextArray(
          headers: const ['주문번호', '주문일', '주문유형', '상태', '배분', '상품매출', '본사 공급가'],
          data: confirmed.map((o) { final rate = orderRates[o.id] ?? .70; return [o.id, _date(o.createdAt), o.orderType == 'group' ? '단체' : '기성품', o.status.label, rate == .60 ? '60/40' : '70/30', _money(o.totalAmount), _money(o.totalAmount * rate)]; }).toList(),
          border: pw.TableBorder.all(color: PdfColors.grey400),
          cellPadding: const pw.EdgeInsets.all(5),
          cellStyle: const pw.TextStyle(fontSize: 8),
        ),
        if (purchases.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text('매입 내역', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: const ['매입일', '공급처', '상품/사유', '수량', '합계'],
            data: purchases.where((p) {
              final ts = p['purchaseDate'];
              final date = ts is Timestamp ? ts.toDate() : DateTime.tryParse('$ts');
              return date != null && _inRange(date);
            }).map((p) => [
              '${p['purchaseDate'] is Timestamp ? _date((p['purchaseDate'] as Timestamp).toDate()) : p['purchaseDate']}',
              p['supplier'] ?? '', p['description'] ?? '', '${p['quantity'] ?? 0}', _money((p['totalAmount'] as num?)?.toDouble() ?? 0)
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey400),
            cellPadding: const pw.EdgeInsets.all(5),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
        pw.SizedBox(height: 20),
        pw.Text('성과조건: ${_performanceEnabled ? '전월 매출 ${_money(_performanceTargetSales)} 이상, 최소 주문 ${_performanceMinOrders}건, 취소·환불률 ${_performanceMaxRefundRate.toStringAsFixed(2)}% 이하 충족 시 다음 달 60/40 적용' : '자동 성과연동 미사용'}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 6),
        pw.Text('※ 본 문서는 협의용 계약서의 확정된 기본 70/30 구조를 기준으로 산출한 관리자 제출용 초안입니다. 할인 기준, 부가세 기준, 성과연동 40% 적용 여부 등 계약서의 [확인 필요] 항목은 최종 계약 확정 후 관리자 설정에서 변경해야 합니다.', style: const pw.TextStyle(fontSize: 8)),
      ],
    ));
    final bytes = Uint8List.fromList(await doc.save());
    final name = '2FIT_본사정산_${_date(_from).replaceAll('-', '')}_${_date(_to).replaceAll('-', '')}.pdf';
    if (kIsWeb) {
      downloadFileWeb(bytes, name, 'application/pdf');
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$name';
      await File(path).writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(path, mimeType: 'application/pdf', name: name)], subject: '2FIT 본사 정산내역'));
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name 다운로드를 시작했습니다.')));
  }

  Future<void> _addPurchase() async {
    final supplier = TextEditingController();
    final desc = TextEditingController();
    final qty = TextEditingController(text: '1');
    final amount = TextEditingController();
    DateTime date = DateTime.now();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
      title: const Text('매입 내역 추가'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: supplier, decoration: const InputDecoration(labelText: '공급처')),
        TextField(controller: desc, decoration: const InputDecoration(labelText: '상품/매입 사유')),
        TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '수량')),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '총 매입액(원)')),
        ListTile(title: Text('매입일 ${_date(date)}'), trailing: const Icon(Icons.calendar_month), onTap: () async { final d = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: date); if (d != null) setLocal(() => date = d); }),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장'))],
    )));
    if (ok != true || amount.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('purchase_records').add({
      'supplier': supplier.text.trim(), 'description': desc.text.trim(), 'quantity': int.tryParse(qty.text) ?? 1,
      'totalAmount': double.tryParse(amount.text.replaceAll(',', '')) ?? 0, 'purchaseDate': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(), 'createdBy': 'admin',
    });
  }

  Widget _dateButton(String label, DateTime value, VoidCallback onTap) => OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.calendar_today, size: 16), label: Text('$label ${_date(value)}'));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.watchAllOrders(),
      builder: (context, orderSnap) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('purchase_records').orderBy('purchaseDate', descending: true).snapshots(),
        builder: (context, purchaseSnap) {
          final orders = orderSnap.data ?? const <OrderModel>[];
          final purchases = purchaseSnap.data?.docs.map((d) => {...d.data(), '_id': d.id}).toList() ?? <Map<String, dynamic>>[];
          final filtered = orders.where((o) => _inRange(o.createdAt)).where((o) => o.status != OrderStatus.cancelled && o.status != OrderStatus.refunded).toList();
          final sales = filtered.fold<double>(0, (s, o) => s + o.totalAmount);
          final hq = filtered.fold<double>(0, (sum, o) => sum + o.totalAmount * _rateForOrder(orders, o));
          final rangeRate = _rateForRange(orders);
          final purchaseTotal = purchases.where((p) { final ts = p['purchaseDate']; final d = ts is Timestamp ? ts.toDate() : DateTime.tryParse('$ts'); return d != null && _inRange(d); }).fold<double>(0, (s, p) => s + ((p['totalAmount'] as num?)?.toDouble() ?? 0));
          return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: Text('매출 정산 · 매입 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))), _dateButton('시작', _from, () => _pickDate(true)), const SizedBox(width: 6), _dateButton('종료', _to, () => _pickDate(false)), const SizedBox(width: 8), FilledButton.icon(onPressed: () => _downloadPdf(orders, purchases), icon: const Icon(Icons.picture_as_pdf, size: 17), label: const Text('본사 제출 PDF'))]),
            const SizedBox(height: 8),
            Row(children: [const Text('계약 배분율', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(width: 10), Text(rangeRate < 0 ? '기간 내 월별 성과 기준 혼합 적용' : '본사 ${((rangeRate < 0 ? .70 : rangeRate) * 100).round()}% / 운영자 ${((1 - (rangeRate < 0 ? .70 : rangeRate)) * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 12), OutlinedButton.icon(onPressed: _configurePerformance, icon: const Icon(Icons.tune, size: 16), label: const Text('성과조건 설정'))]),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _card('정산대상 매출', _money(sales), Icons.payments_outlined, Colors.green),
              _card('본사 공급가', _money(hq), Icons.business_outlined, Colors.indigo),
              _card('운영자 매출총이익', _money(sales - hq), Icons.account_balance_wallet_outlined, Colors.blue),
              _card('매입 합계', _money(purchaseTotal), Icons.inventory_2_outlined, Colors.orange),
            ]),
            const SizedBox(height: 22),
            Row(children: [const Expanded(child: Text('매입 내역', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), FilledButton.icon(onPressed: _addPurchase, icon: const Icon(Icons.add, size: 16), label: const Text('매입 등록'))]),
            const SizedBox(height: 8),
            if (purchases.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('등록된 매입 내역이 없습니다.')) else Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('매입일')), DataColumn(label: Text('공급처')), DataColumn(label: Text('상품/사유')), DataColumn(label: Text('수량')), DataColumn(label: Text('금액')), DataColumn(label: Text('삭제'))], rows: purchases.map((p) { final ts = p['purchaseDate']; final d = ts is Timestamp ? ts.toDate() : DateTime.tryParse('$ts'); return DataRow(cells: [DataCell(Text(d == null ? '-' : _date(d))), DataCell(Text('${p['supplier'] ?? ''}')), DataCell(Text('${p['description'] ?? ''}')), DataCell(Text('${p['quantity'] ?? 0}')), DataCell(Text(_money((p['totalAmount'] as num?)?.toDouble() ?? 0))), DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => FirebaseFirestore.instance.collection('purchase_records').doc('${p['_id']}').delete()))]); }).toList()))),
            const SizedBox(height: 22),
            const Text('주문별 정산 내역', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
            Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('주문번호')), DataColumn(label: Text('주문일')), DataColumn(label: Text('유형')), DataColumn(label: Text('상태')), DataColumn(label: Text('배분')), DataColumn(label: Text('상품매출')), DataColumn(label: Text('본사 공급가')), DataColumn(label: Text('운영자 이익'))], rows: filtered.map((o) { final rate = _rateForOrder(orders, o); return DataRow(cells: [DataCell(Text(o.id)), DataCell(Text(_date(o.createdAt))), DataCell(Text(o.orderType == 'group' ? '단체' : '기성품')), DataCell(Text(o.status.label)), DataCell(Text(rate == .60 ? '60/40' : '70/30')), DataCell(Text(_money(o.totalAmount))), DataCell(Text(_money(o.totalAmount * rate))), DataCell(Text(_money(o.totalAmount * (1 - rate))))]); }).toList())),
            const SizedBox(height: 16),
            Text('계약서 기준: 매입·재판매형, 정산대상 상품매출은 실제 결제 상품대금에서 취소·환불·반품 확정분을 차감합니다. 할인 기준·부가세·성과연동 적용은 최종 계약 확정 후 변경하세요.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ]);
        },
      ),
    );
  }

  Widget _card(String title, String value, IconData icon, Color color) => SizedBox(width: 210, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]))])));
}
