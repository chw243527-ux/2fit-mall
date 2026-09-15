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
    final hq = gross * _hqRate;
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
            ['본사 공급가 (${(_hqRate * 100).round()}%)', _money(hq), '계약서 제7조 기준'],
            ['운영자 매출총이익 (${((1 - _hqRate) * 100).round()}%)', _money(operatorShare), '기본 배분'],
            ['매입 합계', _money(purchaseTotal), '등록된 매입 내역 기준'],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          border: pw.TableBorder.all(color: PdfColors.grey400),
          cellPadding: const pw.EdgeInsets.all(6),
        ),
        pw.SizedBox(height: 18),
        pw.Text('주문별 정산', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Table.fromTextArray(
          headers: const ['주문번호', '주문일', '주문유형', '상태', '상품매출', '본사 공급가'],
          data: confirmed.map((o) => [o.id, _date(o.createdAt), o.orderType == 'group' ? '단체' : '기성품', o.status.label, _money(o.totalAmount), _money(o.totalAmount * _hqRate)]).toList(),
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
          final hq = sales * _hqRate;
          final purchaseTotal = purchases.where((p) { final ts = p['purchaseDate']; final d = ts is Timestamp ? ts.toDate() : DateTime.tryParse('$ts'); return d != null && _inRange(d); }).fold<double>(0, (s, p) => s + ((p['totalAmount'] as num?)?.toDouble() ?? 0));
          return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: Text('매출 정산 · 매입 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))), _dateButton('시작', _from, () => _pickDate(true)), const SizedBox(width: 6), _dateButton('종료', _to, () => _pickDate(false)), const SizedBox(width: 8), FilledButton.icon(onPressed: () => _downloadPdf(orders, purchases), icon: const Icon(Icons.picture_as_pdf, size: 17), label: const Text('본사 제출 PDF'))]),
            const SizedBox(height: 8),
            Row(children: [const Text('계약 배분율', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(width: 10), DropdownButton<double>(value: _hqRate, items: const [DropdownMenuItem(value: .70, child: Text('본사 70% / 운영자 30%')), DropdownMenuItem(value: .60, child: Text('본사 60% / 운영자 40%'))], onChanged: (v) => setState(() => _hqRate = v ?? .70))]),
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
            Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('주문번호')), DataColumn(label: Text('주문일')), DataColumn(label: Text('유형')), DataColumn(label: Text('상태')), DataColumn(label: Text('상품매출')), DataColumn(label: Text('본사 공급가')), DataColumn(label: Text('운영자 이익'))], rows: filtered.map((o) => DataRow(cells: [DataCell(Text(o.id)), DataCell(Text(_date(o.createdAt))), DataCell(Text(o.orderType == 'group' ? '단체' : '기성품')), DataCell(Text(o.status.label)), DataCell(Text(_money(o.totalAmount))), DataCell(Text(_money(o.totalAmount * _hqRate))), DataCell(Text(_money(o.totalAmount * (1 - _hqRate))))])).toList())),
            const SizedBox(height: 16),
            Text('계약서 기준: 매입·재판매형, 정산대상 상품매출은 실제 결제 상품대금에서 취소·환불·반품 확정분을 차감합니다. 할인 기준·부가세·성과연동 적용은 최종 계약 확정 후 변경하세요.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ]);
        },
      ),
    );
  }

  Widget _card(String title, String value, IconData icon, Color color) => SizedBox(width: 210, child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]))])));
}
