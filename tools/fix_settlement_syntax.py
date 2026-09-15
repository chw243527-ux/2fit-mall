from pathlib import Path

path = Path('/home/ubuntu/2fit_mall_work/lib/screens/admin/admin_settlement_tab.dart')
text = path.read_text()
start = text.index('  @override\n  Widget build(BuildContext context) {')
end = text.index('\n  Widget _card(', start)
replacement = r'''  Widget _purchaseTable(List<Map<String, dynamic>> purchases) {
    if (purchases.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('등록된 매입 내역이 없습니다.'),
      );
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('매입일')),
            DataColumn(label: Text('공급처')),
            DataColumn(label: Text('상품/사유')),
            DataColumn(label: Text('수량')),
            DataColumn(label: Text('금액')),
            DataColumn(label: Text('삭제')),
          ],
          rows: purchases.map((p) {
            final ts = p['purchaseDate'];
            final date = ts is Timestamp
                ? ts.toDate()
                : DateTime.tryParse('$ts');
            final amount = (p['totalAmount'] as num?)?.toDouble() ?? 0;
            return DataRow(cells: [
              DataCell(Text(date == null ? '-' : _date(date))),
              DataCell(Text('${p['supplier'] ?? ''}')),
              DataCell(Text('${p['description'] ?? ''}')),
              DataCell(Text('${p['quantity'] ?? 0}')),
              DataCell(Text(_money(amount))),
              DataCell(IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => FirebaseFirestore.instance
                    .collection('purchase_records')
                    .doc('${p['_id']}')
                    .delete(),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _orderSettlementTable(List<OrderModel> orders) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('주문번호')),
            DataColumn(label: Text('주문일')),
            DataColumn(label: Text('유형')),
            DataColumn(label: Text('상태')),
            DataColumn(label: Text('배분')),
            DataColumn(label: Text('상품매출')),
            DataColumn(label: Text('본사 공급가')),
            DataColumn(label: Text('운영자 이익')),
          ],
          rows: orders.map((order) {
            final rate = _rateForOrder(orders, order);
            return DataRow(cells: [
              DataCell(Text(order.id)),
              DataCell(Text(_date(order.createdAt))),
              DataCell(Text(order.orderType == 'group' ? '단체' : '기성품')),
              DataCell(Text(order.status.label)),
              DataCell(Text(rate == .60 ? '60/40' : '70/30')),
              DataCell(Text(_money(order.totalAmount))),
              DataCell(Text(_money(order.totalAmount * rate))),
              DataCell(Text(_money(order.totalAmount * (1 - rate)))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.watchAllOrders(),
      builder: (context, orderSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('purchase_records')
              .orderBy('purchaseDate', descending: true)
              .snapshots(),
          builder: (context, purchaseSnap) {
            final orders = orderSnap.data ?? const <OrderModel>[];
            final purchases = purchaseSnap.data?.docs
                    .map((doc) => {...doc.data(), '_id': doc.id})
                    .toList() ??
                <Map<String, dynamic>>[];
            final filtered = orders
                .where((order) => _inRange(order.createdAt))
                .where((order) => !_isCancelledOrRefunded(order))
                .toList();
            final sales = filtered.fold<double>(
                0, (sum, order) => sum + order.totalAmount);
            final hq = filtered.fold<double>(
                0,
                (sum, order) =>
                    sum + order.totalAmount * _rateForOrder(orders, order));
            final rangeRate = _rateForRange(orders);
            final purchaseTotal = purchases.where((purchase) {
              final ts = purchase['purchaseDate'];
              final date = ts is Timestamp
                  ? ts.toDate()
                  : DateTime.tryParse('$ts');
              return date != null && _inRange(date);
            }).fold<double>(
                0,
                (sum, purchase) =>
                    sum + ((purchase['totalAmount'] as num?)?.toDouble() ?? 0));
            final rateLabel = rangeRate < 0
                ? '기간 내 월별 성과 기준 혼합 적용'
                : '본사 ${(rangeRate * 100).round()}% / 운영자 ${((1 - rangeRate) * 100).round()}%';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('매출 정산 · 매입 관리',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      _dateButton('시작', _from, () => _pickDate(true)),
                      const SizedBox(width: 6),
                      _dateButton('종료', _to, () => _pickDate(false)),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _downloadPdf(orders, purchases),
                        icon: const Icon(Icons.picture_as_pdf, size: 17),
                        label: const Text('본사 제출 PDF'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('계약 배분율',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 10),
                      Text(rateLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _configurePerformance,
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('성과조건 설정'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _card('정산대상 매출', _money(sales),
                          Icons.payments_outlined, Colors.green),
                      _card('본사 공급가', _money(hq),
                          Icons.business_outlined, Colors.indigo),
                      _card('운영자 매출총이익', _money(sales - hq),
                          Icons.account_balance_wallet_outlined, Colors.blue),
                      _card('매입 합계', _money(purchaseTotal),
                          Icons.inventory_2_outlined, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                          child: Text('매입 내역',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800))),
                      FilledButton.icon(
                        onPressed: _addPurchase,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('매입 등록'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _purchaseTable(purchases),
                  const SizedBox(height: 22),
                  const Text('주문별 정산 내역',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _orderSettlementTable(filtered),
                  const SizedBox(height: 16),
                  Text(
                    '계약서 기준: 매입·재판매형, 정산대상 상품매출은 실제 결제 상품대금에서 취소·환불·반품 확정분을 차감합니다. 할인 기준·부가세·성과연동 적용은 최종 계약 확정 후 변경하세요.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
'''
path.write_text(text[:start] + replacement + text[end:])
print('rewrote settlement build section')
