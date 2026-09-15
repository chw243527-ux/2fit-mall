from pathlib import Path

path = Path('/home/ubuntu/2fit_mall_work/lib/screens/admin/admin_settlement_tab.dart')
text = path.read_text()
start = text.index('            return SingleChildScrollView(\n              padding: const EdgeInsets.all(20),')
end = text.index('\n          },\n        );\n      },\n    );\n  }\n\n  Widget _card', start)
replacement = r'''            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isMobile = width < 600;
                final isTablet = width >= 600 && width < 1024;
                final horizontalPadding = isMobile ? 14.0 : (isTablet ? 20.0 : 28.0);
                final cardWidth = isMobile
                    ? width - horizontalPadding * 2
                    : isTablet
                        ? (width - horizontalPadding * 2 - 12) / 2
                        : 230.0;

                final headerActions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _dateButton('시작', _from, () => _pickDate(true)),
                    _dateButton('종료', _to, () => _pickDate(false)),
                    FilledButton.icon(
                      onPressed: () => _downloadPdf(orders, purchases),
                      icon: const Icon(Icons.picture_as_pdf, size: 17),
                      label: const Text('본사 제출 PDF'),
                    ),
                  ],
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 18, horizontalPadding, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMobile) ...[
                        const Text(
                          '매출 정산 · 매입 관리',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        headerActions,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(
                              child: Text(
                                '매출 정산 · 매입 관리',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 16),
                            headerActions,
                          ],
                        ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('계약 배분율',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(rateLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            OutlinedButton.icon(
                              onPressed: _configurePerformance,
                              icon: const Icon(Icons.tune, size: 16),
                              label: const Text('성과조건 설정'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _card('정산대상 매출', _money(sales),
                              Icons.payments_outlined, Colors.green,
                              width: cardWidth),
                          _card('본사 공급가', _money(hq),
                              Icons.business_outlined, Colors.indigo,
                              width: cardWidth),
                          _card('운영자 매출총이익', _money(sales - hq),
                              Icons.account_balance_wallet_outlined, Colors.blue,
                              width: cardWidth),
                          _card('매입 합계', _money(purchaseTotal),
                              Icons.inventory_2_outlined, Colors.orange,
                              width: cardWidth),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                              child: Text('매입 내역',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800))),
                          FilledButton.icon(
                            onPressed: _addPurchase,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('매입 등록'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _purchaseTable(purchases),
                      const SizedBox(height: 24),
                      const Text('주문별 정산 내역',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
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
            );'''
text = text[:start] + replacement + text[end:]
old = "  Widget _card(String title, String value, IconData icon, Color color) {\n    return SizedBox(\n      width: 210,"
new = "  Widget _card(String title, String value, IconData icon, Color color, {double width = 230}) {\n    return SizedBox(\n      width: width,"
if old not in text:
    raise SystemExit('card signature not found')
text = text.replace(old, new, 1)
path.write_text(text)
print('responsive settlement layout written')
