import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../models/models.dart';
import '../../services/inventory_service.dart';
import '../../services/barcode_print_service.dart';

// ════════════════════════════════════════════════════════════
//  관리자 재고관리 탭
// ════════════════════════════════════════════════════════════
class AdminInventoryTab extends StatefulWidget {
  final String adminId;
  const AdminInventoryTab({super.key, required this.adminId});

  @override
  State<AdminInventoryTab> createState() => _AdminInventoryTabState();
}

class _AdminInventoryTabState extends State<AdminInventoryTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;

  static const _tabs = ['재고 현황', '입고', '출고', '재고 조정', '바코드 출력', '이력'];

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 탭 바
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tc,
            isScrollable: true,
            labelColor: const Color(0xFF6A1B9A),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6A1B9A),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              _InventoryDashboard(adminId: widget.adminId),
              _IncomingTab(adminId: widget.adminId),
              _OutgoingTab(adminId: widget.adminId),
              _AdjustTab(adminId: widget.adminId),
              _BarcodeTab(adminId: widget.adminId),
              _LogTab(adminId: widget.adminId),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  공통 위젯
// ════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _SectionTitle(this.text, {this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const Spacer(),
      if (trailing != null) trailing!,
    ]),
  );
}

/// 상품 검색 드롭다운
class _ProductPicker extends StatefulWidget {
  final void Function(InventoryModel?) onPicked;
  final String? initialProductId;
  const _ProductPicker({required this.onPicked, this.initialProductId});
  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  List<InventoryModel> _all = [];
  InventoryModel? _selected;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  List<InventoryModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await InventoryService.fetchAll();
    if (!mounted) return;
    setState(() {
      _all = list;
      _filtered = list;
      _loading = false;
      if (widget.initialProductId != null) {
        _selected = list.firstWhere(
          (e) => e.productId == widget.initialProductId,
          orElse: () => list.first,
        );
      }
    });
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = _all
          .where((e) =>
              e.productName.toLowerCase().contains(lower) ||
              e.productCode.contains(lower))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_all.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('등록된 상품 재고가 없습니다.\n상품관리에서 상품을 먼저 등록해 주세요.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _filter,
          decoration: InputDecoration(
            hintText: '상품명 또는 코드로 검색',
            prefixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final inv = _filtered[i];
            final sel = _selected?.productId == inv.productId;
            return ChoiceChip(
              label: Text(inv.productName,
                  style: TextStyle(fontSize: 12,
                      color: sel ? Colors.white : Colors.black87)),
              selected: sel,
              selectedColor: const Color(0xFF6A1B9A),
              onSelected: (_) {
                setState(() => _selected = inv);
                widget.onPicked(inv);
              },
            );
          },
        ),
      ),
    ]);
  }
}

/// 사이즈·색상 선택 Row
class _SizeColorRow extends StatelessWidget {
  final InventoryModel? inventory;
  final String? selectedSize;
  final String? selectedColor;
  final void Function(String) onSizeChanged;
  final void Function(String) onColorChanged;
  const _SizeColorRow({
    required this.inventory,
    required this.selectedSize,
    required this.selectedColor,
    required this.onSizeChanged,
    required this.onColorChanged,
  });
  @override
  Widget build(BuildContext context) {
    if (inventory == null) return const SizedBox();
    final sizes  = inventory!.stock.keys.toList();
    final colors = inventory!.stock[selectedSize]?.keys.toList() ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(spacing: 16, runSpacing: 8, children: [
        // 사이즈
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('사이즈', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedSize,
            hint: const Text('선택'),
            isDense: true,
            items: sizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) { if (v != null) onSizeChanged(v); },
          ),
        ]),
        // 색상
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('색상', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedColor,
            hint: const Text('선택'),
            isDense: true,
            items: colors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) { if (v != null) onColorChanged(v); },
          ),
        ]),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  1. 재고 현황 대시보드
// ════════════════════════════════════════════════════════════
class _InventoryDashboard extends StatefulWidget {
  final String adminId;
  const _InventoryDashboard({required this.adminId});
  @override
  State<_InventoryDashboard> createState() => _InventoryDashboardState();
}

class _InventoryDashboardState extends State<_InventoryDashboard> {
  List<InventoryModel> _list = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await InventoryService.fetchAll();
    if (!mounted) return;
    setState(() { _list = list; _loading = false; });
  }

  List<InventoryModel> get _filtered {
    if (_search.isEmpty) return _list;
    final q = _search.toLowerCase();
    return _list
        .where((e) => e.productName.toLowerCase().contains(q) || e.productCode.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: Column(children: [
        _SectionTitle('전체 재고 현황',
          trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _load)),
        // 요약 카드
        if (!_loading) _summaryRow(),
        // 검색
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: '상품명 / 코드 검색',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('재고 데이터가 없습니다'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _productCard(_filtered[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _summaryRow() {
    final total      = _list.length;
    final lowStock   = _list.where((e) => e.needsReorder).length;
    final outOfStock = _list.where((e) => e.totalStock == 0).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        _chip('전체 상품', total.toString(), Colors.blue),
        const SizedBox(width: 8),
        _chip('부족 재고', lowStock.toString(), Colors.orange),
        const SizedBox(width: 8),
        _chip('재고 없음', outOfStock.toString(), Colors.red),
      ]),
    );
  }

  Widget _chip(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ]),
    ),
  );

  Widget _productCard(InventoryModel inv) {
    final isLow = inv.needsReorder;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isLow
            ? const BorderSide(color: Colors.orange, width: 1.5)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isLow ? Colors.orange.shade100 : Colors.purple.shade50,
          child: Text(inv.totalStock.toString(),
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: isLow ? Colors.orange : const Color(0xFF6A1B9A))),
        ),
        title: Text(inv.productName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Row(children: [
          Text('코드: ${inv.productCode}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (isLow) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: Colors.orange, borderRadius: BorderRadius.circular(4)),
              child: const Text('부족', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ]),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _stockTable(inv),
          ),
        ],
      ),
    );
  }

  Widget _stockTable(InventoryModel inv) {
    final sizes = inv.stock.keys.toList();
    if (sizes.isEmpty) return const Text('사이즈 정보 없음', style: TextStyle(color: Colors.grey));

    // 모든 색상 수집
    final allColors = <String>{};
    for (final cm in inv.stock.values) allColors.addAll(cm.keys);
    final colors = allColors.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 36,
        columnSpacing: 20,
        columns: [
          const DataColumn(label: Text('사이즈', style: TextStyle(fontSize: 12))),
          ...colors.map((c) => DataColumn(
              label: Text(c, style: const TextStyle(fontSize: 12)))),
          const DataColumn(label: Text('합계', style: TextStyle(fontSize: 12))),
        ],
        rows: sizes.map((size) {
          final total = inv.stockForSize(size);
          return DataRow(cells: [
            DataCell(Text(size, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            ...colors.map((c) {
              final qty = inv.stockForSizeColor(size, c);
              return DataCell(Text(qty.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: qty == 0 ? Colors.red : (qty <= inv.reorderPoint ? Colors.orange : Colors.black87),
                  )));
            }),
            DataCell(Text(total.toString(),
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold,
                  color: total == 0 ? Colors.red : const Color(0xFF6A1B9A),
                ))),
          ]);
        }).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  공통 입출고 폼 (입고/출고/조정 공용)
// ════════════════════════════════════════════════════════════
class _StockFormTab extends StatefulWidget {
  final InventoryLogType type;
  final String adminId;
  const _StockFormTab({required this.type, required this.adminId});
  @override
  State<_StockFormTab> createState() => _StockFormTabState();
}

class _StockFormTabState extends State<_StockFormTab> {
  InventoryModel? _inv;
  String? _size;
  String? _color;
  final _qtyCtrl  = TextEditingController(text: '1');
  final _memoCtrl = TextEditingController();
  final _scanCtrl = TextEditingController();
  bool _saving = false;
  int? _currentStock;
  final _scanFocus = FocusNode();

  @override
  void dispose() {
    _qtyCtrl.dispose(); _memoCtrl.dispose();
    _scanCtrl.dispose(); _scanFocus.dispose();
    super.dispose();
  }

  void _onPickInv(InventoryModel? inv) {
    setState(() {
      _inv = inv;
      _size = inv?.stock.keys.firstOrNull;
      _color = (_size != null) ? inv?.stock[_size]?.keys.firstOrNull : null;
      _updateCurrentStock();
    });
  }

  void _updateCurrentStock() {
    if (_inv != null && _size != null && _color != null) {
      setState(() => _currentStock = _inv!.stockForSizeColor(_size!, _color!));
    } else {
      setState(() => _currentStock = null);
    }
  }

  /// USB 바코드 리더기 스캔 처리
  Future<void> _onScan(String barcode) async {
    _scanCtrl.clear();
    final inv = await InventoryService.fetchByBarcode(barcode.trim());
    if (!mounted) return;
    if (inv == null) {
      _snack('바코드를 찾을 수 없습니다: $barcode', error: true);
      return;
    }
    setState(() {
      _inv   = inv;
      _size  = inv.stock.keys.firstOrNull;
      _color = (_size != null) ? inv.stock[_size]?.keys.firstOrNull : null;
      _updateCurrentStock();
    });
    _snack('${inv.productName} 스캔됨');
  }

  Future<void> _submit() async {
    if (_inv == null || _size == null || _color == null) {
      _snack('상품·사이즈·색상을 선택하세요', error: true);
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) { _snack('수량을 올바르게 입력하세요', error: true); return; }

    setState(() => _saving = true);
    try {
      switch (widget.type) {
        case InventoryLogType.incoming:
          await InventoryService.incoming(
            productId: _inv!.productId, size: _size!, color: _color!,
            quantity: qty, memo: _memoCtrl.text.trim(), adminId: widget.adminId);
        case InventoryLogType.outgoing:
          await InventoryService.outgoing(
            productId: _inv!.productId, size: _size!, color: _color!,
            quantity: qty, memo: _memoCtrl.text.trim(), adminId: widget.adminId);
        case InventoryLogType.adjustment:
          await InventoryService.adjust(
            productId: _inv!.productId, size: _size!, color: _color!,
            newQty: qty, memo: _memoCtrl.text.trim(), adminId: widget.adminId);
        default: break;
      }
      // 재고 새로고침
      final refreshed = await InventoryService.fetchOne(_inv!.productId);
      if (mounted) {
        setState(() {
          _inv = refreshed ?? _inv;
          _updateCurrentStock();
          _saving = false;
        });
        _snack('${widget.type.label} 완료!');
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _snack('오류: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : const Color(0xFF6A1B9A),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isAdjust = widget.type == InventoryLogType.adjustment;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionTitle(widget.type.label),

        // ── USB 바코드 스캔 입력
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            const Icon(Icons.qr_code_scanner, color: Color(0xFF6A1B9A)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _scanCtrl,
                focusNode: _scanFocus,
                decoration: InputDecoration(
                  hintText: '바코드 리더기 or 바코드 번호 입력 후 Enter',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
                onSubmitted: _onScan,
              ),
            ),
          ]),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('또는 직접 선택', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            Expanded(child: Divider()),
          ]),
        ),

        // ── 상품 선택
        _ProductPicker(onPicked: _onPickInv),
        const SizedBox(height: 4),

        // ── 사이즈 / 색상
        _SizeColorRow(
          inventory: _inv,
          selectedSize: _size,
          selectedColor: _color,
          onSizeChanged: (v) {
            setState(() {
              _size = v;
              _color = _inv?.stock[v]?.keys.firstOrNull;
              _updateCurrentStock();
            });
          },
          onColorChanged: (v) {
            setState(() { _color = v; _updateCurrentStock(); });
          },
        ),

        // ── 현재 재고 표시
        if (_currentStock != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('현재 재고: ',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text(_currentStock.toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text(' 개', style: TextStyle(fontSize: 13)),
              ]),
            ),
          ),

        // ── 수량 입력
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isAdjust ? '조정 후 수량' : '${widget.type.label} 수량',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixText: '개',
            ),
          ),
        ),

        // ── 메모
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _memoCtrl,
            decoration: InputDecoration(
              labelText: '메모 (선택)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            maxLines: 2,
          ),
        ),

        // ── 저장 버튼
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.type == InventoryLogType.outgoing
                    ? Colors.red.shade700
                    : const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(widget.type == InventoryLogType.incoming
                      ? Icons.add_box : widget.type == InventoryLogType.outgoing
                          ? Icons.remove_circle : Icons.tune),
              label: Text(_saving ? '처리 중...' : '${widget.type.label} 저장'),
            ),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  2. 입고 탭
// ════════════════════════════════════════════════════════════
class _IncomingTab extends StatelessWidget {
  final String adminId;
  const _IncomingTab({required this.adminId});
  @override
  Widget build(BuildContext context) =>
      _StockFormTab(type: InventoryLogType.incoming, adminId: adminId);
}

// ════════════════════════════════════════════════════════════
//  3. 출고 탭
// ════════════════════════════════════════════════════════════
class _OutgoingTab extends StatelessWidget {
  final String adminId;
  const _OutgoingTab({required this.adminId});
  @override
  Widget build(BuildContext context) =>
      _StockFormTab(type: InventoryLogType.outgoing, adminId: adminId);
}

// ════════════════════════════════════════════════════════════
//  4. 재고 조정 탭
// ════════════════════════════════════════════════════════════
class _AdjustTab extends StatelessWidget {
  final String adminId;
  const _AdjustTab({required this.adminId});
  @override
  Widget build(BuildContext context) =>
      _StockFormTab(type: InventoryLogType.adjustment, adminId: adminId);
}

// ════════════════════════════════════════════════════════════
//  5. 바코드 출력 탭
// ════════════════════════════════════════════════════════════
class _BarcodeTab extends StatefulWidget {
  final String adminId;
  const _BarcodeTab({required this.adminId});
  @override
  State<_BarcodeTab> createState() => _BarcodeTabState();
}

class _BarcodeTabState extends State<_BarcodeTab> {
  InventoryModel? _inv;
  final Set<String> _selSizes  = {};
  final Set<String> _selColors = {};
  int _copies = 1;

  void _onPick(InventoryModel? inv) {
    setState(() {
      _inv = inv;
      _selSizes.clear();
      _selColors.clear();
      if (inv != null) {
        _selSizes.addAll(inv.stock.keys);
        final all = <String>{};
        for (final cm in inv.stock.values) all.addAll(cm.keys);
        _selColors.addAll(all);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allColors = <String>{};
    if (_inv != null) {
      for (final cm in _inv!.stock.values) allColors.addAll(cm.keys);
    }
    final sizes  = _inv?.stock.keys.toList() ?? [];
    final colors = allColors.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('바코드 출력', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // ── 상품 선택
        _ProductPicker(onPicked: _onPick),
        const SizedBox(height: 12),

        if (_inv != null) ...[
          // ── 사이즈 선택
          const Text('사이즈 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: sizes.map((s) {
            final sel = _selSizes.contains(s);
            return FilterChip(
              label: Text(s),
              selected: sel,
              selectedColor: const Color(0xFF6A1B9A).withOpacity(0.2),
              checkmarkColor: const Color(0xFF6A1B9A),
              onSelected: (v) => setState(() => v ? _selSizes.add(s) : _selSizes.remove(s)),
            );
          }).toList()),
          const SizedBox(height: 12),

          // ── 색상 선택
          const Text('색상 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: colors.map((c) {
            final sel = _selColors.contains(c);
            return FilterChip(
              label: Text(c),
              selected: sel,
              selectedColor: const Color(0xFF6A1B9A).withOpacity(0.2),
              checkmarkColor: const Color(0xFF6A1B9A),
              onSelected: (v) => setState(() => v ? _selColors.add(c) : _selColors.remove(c)),
            );
          }).toList()),
          const SizedBox(height: 12),

          // ── 출력 매수
          Row(children: [
            const Text('라벨 매수', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => setState(() { if (_copies > 1) _copies--; }),
              icon: const Icon(Icons.remove_circle_outline)),
            Text('$_copies 매', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => setState(() { if (_copies < 20) _copies++; }),
              icon: const Icon(Icons.add_circle_outline)),
          ]),
          const SizedBox(height: 12),

          // ── 미리보기
          if (_selSizes.isNotEmpty && _selColors.isNotEmpty) ...[
            const Text('미리보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final size in _selSizes)
                    for (final color in _selColors)
                      _barcodePreviewCard(_inv!, size, color),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── 출력 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (_selSizes.isEmpty || _selColors.isEmpty)
                  ? null
                  : () => BarcodePrintService.printLabels(
                        inventory: _inv!,
                        sizes:  _selSizes.toList(),
                        colors: _selColors.toList(),
                        copies: _copies,
                      ),
              icon: const Icon(Icons.print),
              label: Text('바코드 라벨 $_copies매 출력'),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _barcodePreviewCard(InventoryModel inv, String size, String color) {
    final items = BarcodePrintService.generateBarcodes(inv);
    final item  = items.firstWhere(
        (e) => e.size == size && e.color == color,
        orElse: () => BarcodeItem(
          productId: inv.productId, productName: inv.productName,
          size: size, color: color, barcode: '00000000'));

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(inv.productName,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _badgeText(size), const SizedBox(width: 4), _badgeText(color),
        ]),
        const SizedBox(height: 6),
        BarcodeWidget(
          barcode: Barcode.code128(),
          data: item.barcode,
          width: 130,
          height: 50,
          drawText: false,
          errorBuilder: (_, __) => const SizedBox(height: 50),
        ),
        const SizedBox(height: 2),
        Text(item.barcode, style: const TextStyle(fontSize: 8, color: Colors.grey)),
      ]),
    );
  }

  Widget _badgeText(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(t, style: const TextStyle(fontSize: 9)),
  );
}

// ════════════════════════════════════════════════════════════
//  6. 이력 탭
// ════════════════════════════════════════════════════════════
class _LogTab extends StatefulWidget {
  final String adminId;
  const _LogTab({required this.adminId});
  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  List<InventoryLog> _logs = [];
  bool _loading = true;
  String _search = '';
  InventoryLogType? _typeFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await InventoryService.fetchLogs(limit: 200);
    if (!mounted) return;
    setState(() { _logs = logs; _loading = false; });
  }

  List<InventoryLog> get _filtered {
    var list = _logs;
    if (_typeFilter != null) list = list.where((e) => e.type == _typeFilter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((e) =>
          e.productName.toLowerCase().contains(q) ||
          e.productCode.contains(q) ||
          e.size.toLowerCase().contains(q) ||
          e.color.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _SectionTitle('입출고 이력',
        trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _load)),
      // 필터
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: '상품명 / 코드 검색',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<InventoryLogType?>(
            value: _typeFilter,
            hint: const Text('전체', style: TextStyle(fontSize: 12)),
            isDense: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('전체')),
              ...InventoryLogType.values.map((t) =>
                  DropdownMenuItem(value: t, child: Text(t.label))),
            ],
            onChanged: (v) => setState(() => _typeFilter = v),
          ),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _filtered.isEmpty
                ? const Center(child: Text('이력이 없습니다'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _logTile(_filtered[i]),
                  ),
      ),
    ]);
  }

  Widget _logTile(InventoryLog log) {
    final color = switch (log.type) {
      InventoryLogType.incoming   => Colors.green,
      InventoryLogType.outgoing   => Colors.red,
      InventoryLogType.adjustment => Colors.blue,
      InventoryLogType.reorder    => Colors.orange,
    };
    final icon = switch (log.type) {
      InventoryLogType.incoming   => Icons.add_box,
      InventoryLogType.outgoing   => Icons.remove_circle,
      InventoryLogType.adjustment => Icons.tune,
      InventoryLogType.reorder    => Icons.local_shipping,
    };
    final dt = log.createdAt;
    final dtStr = '${dt.year}-${_p(dt.month)}-${_p(dt.day)} ${_p(dt.hour)}:${_p(dt.minute)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Row(children: [
          Text(log.productName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4)),
            child: Text(log.type.label,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${log.size} / ${log.color}  |  ${log.beforeQty} → ${log.afterQty} (${log.type == InventoryLogType.outgoing ? '-' : '+'}${log.quantity})',
              style: const TextStyle(fontSize: 11)),
          if (log.memo.isNotEmpty)
            Text('메모: ${log.memo}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
        trailing: Text(dtStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ),
    );
  }

  String _p(int v) => v.toString().padLeft(2, '0');
}
