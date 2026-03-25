import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/pc_layout.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../orders/checkout_screen.dart';

// ══════════════════════════════════════════════════════════════
// 단체 주문 폼 (완전 재작성 - 버그 없는 버전)
// ══════════════════════════════════════════════════════════════
class GroupOrderFormScreen extends StatefulWidget {
  final ProductModel? product;
  final bool isAdditionalOrder;
  const GroupOrderFormScreen({
    super.key,
    this.product,
    this.isAdditionalOrder = false,
  });

  @override
  State<GroupOrderFormScreen> createState() => _GroupOrderFormScreenState();
}

class _GroupOrderFormScreenState extends State<GroupOrderFormScreen> {
  static const Color _purple = Color(0xFF6A1B9A);
  static const Color _bgGrey = Color(0xFFF7F7F7);

  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // ── 수량 ──
  int _qty = 5;

  // ── 인쇄 타입 0=일반,1=이름인쇄,2=단체명+이름인쇄 ──
  int _printType = 0;

  // ── 원단 ──
  String _fabric = '일반 (봉제)';
  String _weight = '80g';

  // ── 색상 변경 ──
  bool _changeColor = false;
  String _colorName = '';

  // ── 허리밴드 ──
  bool _waistbandName = false;    // 단체명 추가 (+5,000)
  bool _waistbandColor = false;   // 색상 변경 (+3,000)

  // ── 독점 디자인 ──
  bool _exclusive = false;

  // ── 인원별 사이즈 ──
  final List<_PersonRow> _persons = [];

  // ── 기본 정보 ──
  final _teamCtrl    = TextEditingController();
  final _managerCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _addrCtrl    = TextEditingController();
  final _memoCtrl    = TextEditingController();

  bool get _isAdditional => widget.isAdditionalOrder;
  int get _minQty => _isAdditional ? 1 : 5;

  // 가격 계산
  double get _basePrice => widget.product?.price ?? 0.0;
  double get _waistbandExtra {
    double e = 0;
    if (_waistbandName) e += 5000;
    if (_waistbandColor) e += 3000;
    return e;
  }
  double get _fabricExtra => _fabric == '고기능 (봉제)' || _fabric == '고기능 (무봉제)' ? 2000 : 0;
  double get _unitPrice => _basePrice + _waistbandExtra + _fabricExtra;
  double get _totalPrice => _unitPrice * _qty;
  int get _shipping => _qty >= 5 ? 0 : 3000;
  double get _finalPrice => _totalPrice + _shipping;

  String _fmt(num v) => v.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _qty; i++) {
      _persons.add(_PersonRow(index: i + 1));
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _teamCtrl.dispose();
    _managerCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addrCtrl.dispose();
    _memoCtrl.dispose();
    for (final p in _persons) p.dispose();
    super.dispose();
  }

  void _updateQty(int newQty) {
    if (newQty < 1 || newQty > 200) return;
    setState(() {
      final diff = newQty - _persons.length;
      if (diff > 0) {
        for (int i = 0; i < diff; i++) {
          _persons.add(_PersonRow(index: _persons.length + 1));
        }
      } else if (diff < 0) {
        _persons.removeRange(_persons.length + diff, _persons.length);
      }
      _qty = newQty;
    });
  }

  void _submitOrder({required bool isBuyNow}) {
    // 최소 수량 검사
    if (_qty < _minQty) {
      _toast('최소 ${_minQty}명 이상 주문 가능합니다.');
      return;
    }
    // 색상 변경 선택 시 색상명 필수
    if (_changeColor && _colorName.trim().isEmpty) {
      _toast('원하시는 색상명을 입력해주세요.');
      return;
    }
    // 담당자 정보 검사
    if (_teamCtrl.text.trim().isEmpty) {
      _toast('단체명/팀명을 입력해주세요.');
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _toast('연락처를 입력해주세요.');
      return;
    }
    // 인원 사이즈 검사
    for (int i = 0; i < _persons.length; i++) {
      if (_persons[i].size.isEmpty) {
        _toast('${i + 1}번 인원의 사이즈를 선택해주세요.');
        return;
      }
    }

    final customOptions = <String, dynamic>{
      'orderType': 'group',
      'isAdditional': _isAdditional,
      'printType': _printType,
      'fabric': _fabric,
      'weight': _weight,
      'changeColor': _changeColor,
      'colorName': _colorName,
      'waistbandName': _waistbandName,
      'waistbandColor': _waistbandColor,
      'exclusive': _exclusive,
      'teamName': _teamCtrl.text.trim(),
      'manager': _managerCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'address': _addrCtrl.text.trim(),
      'memo': _memoCtrl.text.trim(),
      'persons': _persons.map((p) => {
        'index': p.index,
        'name': p.nameCtrl.text.trim(),
        'gender': p.gender,
        'size': p.size,
        'length': p.length,
      }).toList(),
      'qty': _qty,
      'unitPrice': _unitPrice,
      'totalPrice': _finalPrice,
    };

    final cart = context.read<CartProvider>();
    final product = widget.product ?? ProductModel(
      id: 'group_direct_${DateTime.now().millisecondsSinceEpoch}',
      name: '단체주문',
      category: '단체주문',
      subCategory: '',
      price: _unitPrice,
      originalPrice: _unitPrice,
      description: '직접 단체주문',
      images: [],
      sizes: [],
      colors: [],
      material: '',
      stockCount: 999,
      createdAt: DateTime.now(),
    );

    if (isBuyNow) {
      cart.clearCart();
      cart.addItem(product, '단체', '단체', quantity: _qty,
          extraPrice: _waistbandExtra + _fabricExtra, customOptions: customOptions);
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CheckoutScreen(cart: context.read<CartProvider>())));
    } else {
      cart.addItem(product, '단체', '단체', quantity: _qty,
          extraPrice: _waistbandExtra + _fabricExtra, customOptions: customOptions);
      _toast('장바구니에 담았습니다. (${_qty}명 / ${_fmt(_finalPrice)}원)');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        title: Text(_isAdditional ? '추가 제작 주문서' : '단체주문 주문서',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          child: Column(
            children: [
              _buildHeader(),
              _buildSection('👥 주문 수량', _buildQtySection()),
              _buildSection('🖨️ 인쇄 타입', _buildPrintTypeSection()),
              _buildSection('👕 원단 선택', _buildFabricSection()),
              _buildSection('🎨 색상 변경', _buildColorSection()),
              _buildSection('🔧 허리밴드 옵션', _buildWaistbandSection()),
              _buildSection('📏 인원별 사이즈', _buildPersonsSection()),
              _buildSection('📝 담당자 정보', _buildContactSection()),
              _buildSection('💡 메모', _buildMemoSection()),
              _buildSection('⭐ 디자인 독점 사용', _buildExclusiveSection()),
              _buildSection('💰 최종 금액 확인', _buildSummarySection()),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitBar(),
    );
  }

  // ── 헤더 배너 ──
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _purple,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              _isAdditional ? '추가 제작 주문' : '단체 주문',
              style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w900),
            ),
            if (widget.product != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(widget.product!.name,
                    style: const TextStyle(color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          const SizedBox(height: 6),
          Text(
            _isAdditional ? '추가제작: 1장부터 주문 가능' : '최소 5명 이상 / 제작기간 약 3~4주',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
          ),
          if (!_isAdditional) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️  최종 디자인 확정 후 주문해주세요. 주문 후 디자인 변경이 불가합니다.',
                style: TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 섹션 래퍼 ──
  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          content,
        ],
      ),
    );
  }

  // ── 수량 섹션 ──
  Widget _buildQtySection() {
    Color accent = _qty >= 50 ? _purple
        : _qty >= 30 ? const Color(0xFFE65100)
        : _qty >= 10 ? const Color(0xFF2E7D32)
        : _qty >= 5  ? const Color(0xFF1565C0)
        : const Color(0xFF888888);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 수량 조절 컨트롤
          Container(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(children: [
              // 감소
              _qtyBtn(Icons.remove_rounded, () => _updateQty(_qty - 1), accent),
              const SizedBox(width: 12),
              // 직접 입력
              Expanded(
                child: Column(children: [
                  Text('$_qty',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                          color: accent)),
                  Text('명', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: accent)),
                ]),
              ),
              const SizedBox(width: 12),
              // 증가
              _qtyBtn(Icons.add_rounded, () => _updateQty(_qty + 1), accent),
            ]),
          ),
          const SizedBox(height: 10),
          // 할인 배지
          if (_qty >= 5)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _qty >= 50 ? '🎉 20% 할인 적용 (50명 이상)' :
                _qty >= 30 ? '🎉 10% 할인 적용 (30명 이상)' :
                _qty >= 10 ? '✅ 이름 인쇄 가능 (10명 이상)' :
                             '✅ 단체 제작 가능 (5명 이상)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
              ),
            ),
          if (_qty < _minQty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('최소 ${_minQty}명 이상 주문 가능합니다.',
                  style: const TextStyle(fontSize: 12, color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ── 인쇄 타입 ──
  Widget _buildPrintTypeSection() {
    final options = [
      _PrintOption(0, '기본 인쇄', '번호만 인쇄 (기본 포함)', Icons.tag_rounded, _qty >= 1),
      _PrintOption(1, '이름 인쇄', '번호 + 이름 인쇄 (10명 이상)', Icons.person_rounded, _qty >= 10),
      _PrintOption(2, '단체명+이름', '번호 + 단체명 + 이름 (10명 이상)', Icons.groups_rounded, _qty >= 10),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: options.map((opt) {
          final selected = _printType == opt.id;
          return GestureDetector(
            onTap: opt.enabled ? () => setState(() => _printType = opt.id) : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? _purple.withValues(alpha: 0.07) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? _purple : const Color(0xFFDDDDDD),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Icon(opt.icon,
                    color: selected ? _purple : (opt.enabled ? Colors.grey : Colors.grey.shade300),
                    size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.name, style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: opt.enabled ? Colors.black87 : Colors.grey.shade400)),
                    Text(opt.desc, style: TextStyle(
                        fontSize: 11,
                        color: opt.enabled ? Colors.grey : Colors.grey.shade300)),
                  ],
                )),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: _purple, size: 20),
                if (!opt.enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('10명 이상', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 원단 ──
  Widget _buildFabricSection() {
    final fabrics = ['일반 (봉제)', '일반 (무봉제)', '고기능 (봉제)', '고기능 (무봉제)'];
    final weights = ['80g', '100g', '120g'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('원단 종류', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: fabrics.map((f) {
              final sel = _fabric == f;
              final isExtra = f.contains('고기능');
              return GestureDetector(
                onTap: () => setState(() => _fabric = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _purple : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? _purple : const Color(0xFFDDDDDD)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(f, style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? Colors.white : Colors.black87)),
                    if (isExtra) ...[
                      const SizedBox(width: 4),
                      Text('+2,000원', style: TextStyle(
                          fontSize: 10,
                          color: sel ? Colors.white70 : Colors.orange)),
                    ],
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text('원단 무게', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            children: weights.map((w) {
              final sel = _weight == w;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _weight = w),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _purple : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sel ? _purple : const Color(0xFFDDDDDD)),
                    ),
                    child: Text(w, style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? Colors.white : Colors.black87)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── 색상 변경 ──
  Widget _buildColorSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Switch(
              value: _changeColor,
              onChanged: (v) => setState(() => _changeColor = v),
              activeThumbColor: _purple,
            ),
            const SizedBox(width: 8),
            const Text('원하는 색상으로 변경', style: TextStyle(fontSize: 14)),
          ]),
          if (_changeColor) ...[
            const SizedBox(height: 10),
            TextFormField(
              onChanged: (v) => setState(() => _colorName = v),
              decoration: InputDecoration(
                hintText: '예: 네이비, 레드, #FF0000 등',
                prefixIcon: const Icon(Icons.palette_rounded, color: _purple),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _purple, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
          if (!_changeColor)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('기본 색상으로 제작됩니다. 색상 변경 시 위 스위치를 켜주세요.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  // ── 허리밴드 ──
  Widget _buildWaistbandSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: [
          _optionTile(
            '단체명 추가 인쇄',
            '허리밴드에 단체명을 인쇄합니다',
            '+5,000원/명',
            _waistbandName,
            (v) => setState(() => _waistbandName = v),
          ),
          const SizedBox(height: 8),
          _optionTile(
            '색상 변경',
            '허리밴드 색상을 변경합니다',
            '+3,000원/명',
            _waistbandColor,
            (v) => setState(() => _waistbandColor = v),
          ),
          if (_waistbandExtra > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '허리밴드 옵션 추가금: +${_fmt(_waistbandExtra)}원/명',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _purple),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionTile(String title, String sub, String badge,
      bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? _purple.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? _purple : const Color(0xFFDDDDDD),
            width: value ? 2 : 1),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: value ? _purple.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(badge, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: value ? _purple : Colors.grey)),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _purple,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }

  // ── 인원별 사이즈 ──
  Widget _buildPersonsSection() {
    const sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];
    const lengths = ['기본', '9부', '5부', '4부', '3부', '숏쇼트'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: [
          // 인원 수 표시 + 추가/삭제 버튼
          Row(children: [
            Text('총 ${_persons.length}명',
                style: const TextStyle(fontWeight: FontWeight.w700, color: _purple)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _updateQty(_qty + 1),
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('인원 추가', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: _purple),
            ),
            if (_persons.length > _minQty)
              TextButton.icon(
                onPressed: () => _updateQty(_qty - 1),
                icon: const Icon(Icons.person_remove_rounded, size: 16),
                label: const Text('삭제', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
          ]),
          const SizedBox(height: 8),
          // 인원 목록
          ...List.generate(_persons.length, (i) {
            final p = _persons[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bgGrey,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 번호 + 이름
                  Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _purple, borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text('${i + 1}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: p.nameCtrl,
                        decoration: const InputDecoration(
                          hintText: '이름 (선택)',
                          isDense: true,
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    // 성별
                    _genderBtn('남', p.gender == '남', () => setState(() => p.gender = '남')),
                    const SizedBox(width: 4),
                    _genderBtn('여', p.gender == '여', () => setState(() => p.gender = '여')),
                  ]),
                  const SizedBox(height: 10),
                  // 사이즈
                  Row(children: [
                    const Text('사이즈: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Expanded(
                      child: Wrap(
                        spacing: 4, runSpacing: 4,
                        children: sizes.map((s) {
                          final sel = p.size == s;
                          return GestureDetector(
                            onTap: () => setState(() => p.size = s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: sel ? _purple : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: sel ? _purple : const Color(0xFFCCCCCC)),
                              ),
                              child: Text(s, style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                  color: sel ? Colors.white : Colors.black87)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // 하의 길이
                  Row(children: [
                    const Text('길이: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Expanded(
                      child: Wrap(
                        spacing: 4, runSpacing: 4,
                        children: lengths.map((l) {
                          final sel = p.length == l;
                          return GestureDetector(
                            onTap: () => setState(() => p.length = l),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: sel ? Colors.indigo.shade700 : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: sel ? Colors.indigo.shade700 : const Color(0xFFCCCCCC)),
                              ),
                              child: Text(l, style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                  color: sel ? Colors.white : Colors.black87)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _genderBtn(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? (label == '남' ? Colors.blue.shade700 : Colors.pink.shade400)
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? (label == '남' ? Colors.blue.shade700 : Colors.pink.shade400)
                : const Color(0xFFCCCCCC),
          ),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey)),
      ),
    );
  }

  // ── 담당자 정보 ──
  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: [
          _textField(_teamCtrl, '단체명 / 팀명 *', '예: 2FIT 농구팀', Icons.groups_rounded, required: true),
          const SizedBox(height: 10),
          _textField(_managerCtrl, '담당자 이름', '예: 홍길동', Icons.person_rounded),
          const SizedBox(height: 10),
          _textField(_phoneCtrl, '연락처 *', '예: 010-1234-5678', Icons.phone_rounded,
              keyboardType: TextInputType.phone, required: true),
          const SizedBox(height: 10),
          _textField(_emailCtrl, '이메일', '예: order@team.com', Icons.email_rounded,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _textField(_addrCtrl, '배송 주소', '주소를 입력해주세요', Icons.location_on_rounded),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _purple, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _purple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  // ── 메모 ──
  Widget _buildMemoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: TextFormField(
        controller: _memoCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: '특이사항, 요청사항 등을 입력해주세요.',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _purple, width: 2),
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ── 독점 디자인 ──
  Widget _buildExclusiveSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('디자인 독점 사용권',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('선택 시 동일 디자인 타 단체 사용 제한',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        )),
        Switch(
          value: _exclusive,
          onChanged: (v) => setState(() => _exclusive = v),
          activeThumbColor: _purple,
        ),
      ]),
    );
  }

  // ── 최종 금액 요약 ──
  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow('기본가 (${_fmt(_basePrice)}원 × $_qty명)',
                '${_fmt(_basePrice * _qty)}원'),
            if (_waistbandExtra > 0)
              _summaryRow('허리밴드 옵션 (${_fmt(_waistbandExtra)}원 × $_qty명)',
                  '+${_fmt(_waistbandExtra * _qty)}원'),
            if (_fabricExtra > 0)
              _summaryRow('원단 추가금 (${_fmt(_fabricExtra)}원 × $_qty명)',
                  '+${_fmt(_fabricExtra * _qty)}원'),
            _summaryRow('배송비', _shipping == 0 ? '무료' : '${_fmt(_shipping)}원'),
            const Divider(color: Colors.white30, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('최종 결제금액',
                    style: TextStyle(color: Colors.white70, fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('${_fmt(_finalPrice)}원',
                    style: const TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Icon(Icons.people_alt_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text('$_qty명 | 단가 ${_fmt(_unitPrice)}원/명',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12,
              fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── 하단 구매 버튼 ──
  Widget _buildSubmitBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 금액 요약
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.people_alt_rounded, size: 16, color: _purple),
                const SizedBox(width: 4),
                Text('$_qty명',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('배송비: ${_shipping == 0 ? "무료" : "${_fmt(_shipping)}원"}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('최종 결제금액',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('${_fmt(_finalPrice)}원',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                        color: _purple)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          // 버튼
          Row(children: [
            // 장바구니
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: () => _submitOrder(isBuyNow: false),
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text('장바구니', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: _purple, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 바로 구매
            Expanded(
              flex: 6,
              child: ElevatedButton.icon(
                onPressed: () => _submitOrder(isBuyNow: true),
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('바로 구매하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── PC 레이아웃 ──
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isAdditional ? '추가 제작 주문서' : '단체주문 주문서',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측: 폼
          Expanded(
            flex: 6,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildSection('👥 주문 수량', _buildQtySection()),
                    _buildSection('🖨️ 인쇄 타입', _buildPrintTypeSection()),
                    _buildSection('👕 원단 선택', _buildFabricSection()),
                    _buildSection('🎨 색상 변경', _buildColorSection()),
                    _buildSection('🔧 허리밴드 옵션', _buildWaistbandSection()),
                    _buildSection('📏 인원별 사이즈', _buildPersonsSection()),
                    _buildSection('📝 담당자 정보', _buildContactSection()),
                    _buildSection('💡 메모', _buildMemoSection()),
                    _buildSection('⭐ 디자인 독점 사용', _buildExclusiveSection()),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // 우측: 요약 + 버튼
          SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummarySection(),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _submitOrder(isBuyNow: true),
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('바로 구매하기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _submitOrder(isBuyNow: false),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('장바구니에 담기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _purple,
                        side: const BorderSide(color: _purple, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 인원 행 데이터
// ══════════════════════════════════════════════════════════════
class _PersonRow {
  final int index;
  final nameCtrl = TextEditingController();
  String gender = '남';
  String size = '';
  String length = '기본';

  _PersonRow({required this.index});

  void dispose() => nameCtrl.dispose();
}

// ══════════════════════════════════════════════════════════════
// 인쇄 옵션 데이터
// ══════════════════════════════════════════════════════════════
class _PrintOption {
  final int id;
  final String name;
  final String desc;
  final IconData icon;
  final bool enabled;
  const _PrintOption(this.id, this.name, this.desc, this.icon, this.enabled);
}
