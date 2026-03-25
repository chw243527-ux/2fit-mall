import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/constants.dart';
import '../../widgets/pc_layout.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/kakao_address_search.dart';
import '../../services/order_service.dart';
import '../orders/checkout_screen.dart';

// ══════════════════════════════════════════════════════════════
// 단체 주문 폼 v5  (완전 새로 작성)
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
  static const Color _purple      = Color(0xFF6A1B9A);
  static const Color _purpleLight = Color(0xFFF3E5F5);
  static const Color _bg          = Color(0xFFF5F5F5);

  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  final _formKey    = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // ── 수량 ──
  int  _dialCount    = 5;
  int  _inputCount   = 5;
  bool _orderStarted = false;
  bool get _countConfirmed => _orderStarted;

  // ── 인원 목록 ──
  final List<_PersonEntry> _persons = [];

  // ── 인쇄 타입 ──
  // 0=색상변경만, 1=전면(단체명), 2=전면+색상, 3=전면+색상+후면이름
  int _printType = 0;

  // ── 색상 ──
  String? _mainColorName;
  Color?  _mainColor;

  // ── 원단 ──
  String _fabricType   = '일반 (봉제)';
  String _fabricWeight = '80g';

  // ── 허리밴드 ──
  bool    _waistbandEnabled     = false;
  String? _waistbandOption;       // 'design' | 'color' | 'both'
  String? _waistbandColorName;
  Color?  _waistbandColor;

  // ── 하의 기본 길이 ──
  String? _defaultLength;

  // ── 참조 이미지 (Base64) ──
  String? _maleRefBase64;
  String? _femaleRefBase64;
  static const _kMaleKey   = 'group_order_male_ref_base64';
  static const _kFemaleKey = 'group_order_female_ref_base64';

  // ── 기본 정보 ──
  final _teamNameCtrl    = TextEditingController();
  final _managerNameCtrl = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _memoCtrl        = TextEditingController();
  String _address        = '';

  // ── 독점 디자인 ──
  bool _exclusiveDesign = false;

  // ══ 파생값 ══
  bool get _isAdditional    => widget.isAdditionalOrder;
  int  get _minQty          => _isAdditional ? 1 : 5;
  int  get _totalCount      => _persons.length;
  bool get _canUsePrint1    => _isAdditional ? _totalCount >= 1 : _totalCount >= 5;
  bool get _canUsePrint2    => _isAdditional ? _totalCount >= 1 : _totalCount >= 10;
  bool get _hasColorChange  => _printType == 0 || _printType == 2 || _printType == 3;
  bool get _hasTeamName     => _printType == 1 || _printType == 2 || _printType == 3;
  bool get _hasBackName     => _printType == 3;
  bool get _nameInputEnabled => _totalCount >= 10;

  // ══ 가격 ══
  int get _waistbandExtra {
    if (!_waistbandEnabled) return 0;
    switch (_waistbandOption) {
      case 'design': return AppConstants.waistbandNamePrice;
      case 'color':  return AppConstants.waistbandColorPrice;
      case 'both':   return AppConstants.waistbandBothPrice;
      default:       return 0;
    }
  }

  int    get _fabricExtra  => AppConstants.fabricTypePrices[_fabricType] ?? 0;
  double get _basePrice    => widget.product?.price ?? 0.0;
  double get _unitPrice    => _basePrice + _waistbandExtra + _fabricExtra;
  double get _subTotal     => _unitPrice * _totalCount;
  double get _shipping     =>
      _totalCount >= AppConstants.groupMinFreeShipping
          ? 0
          : AppConstants.groupAdditionalShippingFee.toDouble();
  double get _finalPrice   => _subTotal + _shipping;
  bool   get _isFreeShipping => _shipping == 0;

  String _fmt(num v) => v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ══ 생명주기 ══
  @override
  void initState() {
    super.initState();
    _loadSavedImages();
    for (int i = 0; i < _inputCount; i++) {
      _persons.add(_PersonEntry(index: i));
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _teamNameCtrl.dispose();
    _managerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _memoCtrl.dispose();
    for (final p in _persons) { p.dispose(); }
    super.dispose();
  }

  Future<void> _loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _maleRefBase64   = prefs.getString(_kMaleKey);
      _femaleRefBase64 = prefs.getString(_kFemaleKey);
    });
  }

  Future<void> _saveImage({required bool isMale, required String? base64}) async {
    final prefs = await SharedPreferences.getInstance();
    final key   = isMale ? _kMaleKey : _kFemaleKey;
    if (base64 == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, base64);
    }
  }

  // ══ 수량 ══
  void _confirmCount() {
    final n = _dialCount;
    if (n < 1) return;
    setState(() {
      _inputCount   = n;
      _orderStarted = true;
      while (_persons.length < n) { _persons.add(_PersonEntry(index: _persons.length)); }
      while (_persons.length > n) { _persons.last.dispose(); _persons.removeLast(); }
      for (int i = 0; i < _persons.length; i++) { _persons[i].index = i; }
    });
  }

  void _addPerson() {
    setState(() {
      _persons.add(_PersonEntry(index: _persons.length));
      _inputCount = _persons.length;
      _dialCount  = _inputCount;
    });
  }

  void _removePerson(int idx) {
    if (_persons.length <= 1) return;
    setState(() {
      _persons[idx].dispose();
      _persons.removeAt(idx);
      for (int i = 0; i < _persons.length; i++) { _persons[i].index = i; }
      _inputCount = _persons.length;
      _dialCount  = _inputCount;
    });
  }

  // ══ 검증 & 제출 ══
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  bool _validate() {
    if (_totalCount < _minQty) {
      _showSnack('최소 $_minQty명 이상 주문 가능합니다.');
      return false;
    }
    if (_hasColorChange && (_mainColorName == null || _mainColorName!.isEmpty)) {
      _showSnack('색상을 선택해 주세요.');
      return false;
    }
    if (_hasTeamName && _teamNameCtrl.text.trim().isEmpty) {
      _showSnack('단체명을 입력해 주세요.');
      return false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnack('연락처를 입력해 주세요.');
      return false;
    }
    for (int i = 0; i < _persons.length; i++) {
      final p = _persons[i];
      if (p.gender == null) {
        _showSnack('${i + 1}번 인원의 성별을 선택해 주세요.');
        return false;
      }
      final effectiveSize = p.size.isNotEmpty ? p.size : p.customSizeCtrl.text.trim();
      if (effectiveSize.isEmpty) {
        _showSnack('${i + 1}번 인원의 사이즈를 입력해 주세요.');
        return false;
      }
    }
    return true;
  }

  Future<void> _submitOrder({required bool isBuyNow}) async {
    if (!_validate()) return;
    final user    = context.read<UserProvider>().user;
    final product = widget.product ?? ProductModel(
      id: 'group_direct_${DateTime.now().millisecondsSinceEpoch}',
      name: '단체주문', category: '단체주문', subCategory: '',
      price: _unitPrice, originalPrice: _unitPrice,
      description: '단체 직접 주문', images: [], sizes: [], colors: [],
      material: '', stockCount: 999, createdAt: DateTime.now(),
    );

    final customOptions = <String, dynamic>{
      'orderType'    : _isAdditional ? 'additional' : 'group',
      'printType'    : _printType,
      'mainColor'    : _mainColorName,
      'waistband'    : _waistbandEnabled ? _waistbandOption : null,
      'waistbandColor': _waistbandColorName,
      'fabric'       : _fabricType,
      'weight'       : _fabricWeight,
      'defaultLength': _defaultLength,
      'exclusive'    : _exclusiveDesign,
      'teamName'     : _teamNameCtrl.text.trim(),
      'manager'      : _managerNameCtrl.text.trim(),
      'address'      : _address,
      'maleRef'      : _maleRefBase64 != null,
      'femaleRef'    : _femaleRefBase64 != null,
      'persons'      : _persons.map((p) => <String, dynamic>{
        'index'  : p.index,
        'name'   : p.nameCtrl.text.trim(),
        'gender' : p.gender,
        'size'   : p.size.isNotEmpty ? p.size : p.customSizeCtrl.text.trim(),
        'length' : p.length,
        'height' : p.heightCtrl.text.trim(),
        'weight' : p.weightCtrl.text.trim(),
        'thigh'  : p.thighCtrl.text.trim(),
        'waist'  : p.waistCtrl.text.trim(),
      }).toList(),
    };

    final orderId = 'GRP_${DateTime.now().millisecondsSinceEpoch}';
    final order   = OrderModel(
      id: orderId,
      userId: user?.id ?? 'guest',
      userName: _managerNameCtrl.text.trim().isNotEmpty
          ? _managerNameCtrl.text.trim() : _teamNameCtrl.text.trim(),
      userEmail: _emailCtrl.text.trim(),
      userPhone: _phoneCtrl.text.trim(),
      userAddress: _address,
      items: [OrderItem(
        productId: product.id, productName: product.name,
        size: '단체', color: _mainColorName ?? '기본',
        quantity: _totalCount, price: _unitPrice,
        customOptions: customOptions,
      )],
      totalAmount: _finalPrice, shippingFee: _shipping,
      paymentMethod: '무통장입금',
      orderType: _isAdditional ? 'additional' : 'group',
      groupName: _teamNameCtrl.text.trim(), groupCount: _totalCount,
      memo: _memoCtrl.text.trim(), createdAt: DateTime.now(),
      customOptions: customOptions,
    );

    if (isBuyNow) {
      final cart = context.read<CartProvider>();
      cart.clearCart();
      cart.addItem(product, '단체', _mainColorName ?? '기본',
          quantity: _totalCount,
          extraPrice: (_waistbandExtra + _fabricExtra).toDouble(),
          customOptions: customOptions);
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CheckoutScreen(cart: cart)));
    } else {
      try {
        await OrderService.saveOrder(order);
        if (!mounted) return;
        _showSnack('장바구니에 담았습니다. ($_totalCount명 / ${_fmt(_finalPrice)}원)');
      } catch (e) {
        if (kDebugMode) debugPrint('주문 저장 오류: $e');
        if (!mounted) return;
        _showSnack('주문 저장 중 오류가 발생했습니다. 다시 시도해 주세요.');
      }
    }
  }

  // ══ build ══
  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return _buildMobileLayout(context);
  }

  // ════════════════════════════════════════════════════════
  // 모바일 레이아웃
  // ════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(_isAdditional ? '추가 제작 주문서' : '단체 주문서',
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
          child: Column(children: [
            _buildHeaderBanner(),
            _buildCountSection(),          // 수량 (구간배지 + 다이얼)
            _buildPrintTypeSection(),       // 인쇄 타입
            if (_countConfirmed) ...[
              _buildSelectedProductCard(), // 선택 상품
              if (_totalCount >= 10 && _hasTeamName) _buildGroupInfoCard(),
              _buildFabricSection(),       // 원단
              if (_hasColorChange) _buildColorSection(), // 인라인 색상차트
              _buildWaistbandSection(),    // 허리밴드 토글
              _buildLengthSection(),       // 하의 길이
              _buildRefImageSection(),     // 참조 이미지
              _buildPersonListSection(),   // 인원별 사이즈
              _buildBasicInfoSection(),    // 기본 정보
              _buildMemoSection(),         // 메모
              _buildExclusiveSection(),    // 독점 디자인
              _buildSummarySection(),      // 금액 요약
              const SizedBox(height: 32),
            ],
          ]),
        ),
      ),
      bottomNavigationBar: _countConfirmed ? _buildSubmitBar() : null,
    );
  }

  // ════════════════════════════════════════════════════════
  // PC 레이아웃
  // ════════════════════════════════════════════════════════
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(_isAdditional ? '추가 제작 주문서' : '단체 주문서',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: _purple, foregroundColor: Colors.white, elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 3,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Column(children: [
                _buildHeaderBanner(),
                _buildCountSection(),
                _buildPrintTypeSection(),
                if (_countConfirmed) ...[
                  _buildSelectedProductCard(),
                  if (_totalCount >= 10 && _hasTeamName) _buildGroupInfoCard(),
                  _buildFabricSection(),
                  if (_hasColorChange) _buildColorSection(),
                  _buildWaistbandSection(),
                  _buildLengthSection(),
                  _buildRefImageSection(),
                  _buildPersonListSection(),
                  _buildBasicInfoSection(),
                  _buildMemoSection(),
                  _buildExclusiveSection(),
                  const SizedBox(height: 32),
                ],
              ]),
            ),
          ),
        ),
        if (_countConfirmed)
          SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(children: [
                const SizedBox(height: 8),
                _buildPcSummaryPanel(),
                const SizedBox(height: 16),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildPcSummaryPanel() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF4A148C), _purple],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('주문 요약',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _sumRow('기본가 × $_totalCount명', '${_fmt((_basePrice * _totalCount).toInt())}원'),
            if (_waistbandExtra > 0)
              _sumRow('허리밴드 옵션', '+${_fmt(_waistbandExtra * _totalCount)}원'),
            if (_fabricExtra > 0)
              _sumRow('원단 추가금', '+${_fmt(_fabricExtra * _totalCount)}원'),
            _sumRow('배송비', _isFreeShipping ? '무료' : '${_fmt(_shipping.toInt())}원'),
            const Divider(color: Colors.white30, height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('최종 금액',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('${_fmt(_finalPrice.toInt())}원',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            SizedBox(width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _submitOrder(isBuyNow: false),
                style: OutlinedButton.styleFrom(foregroundColor: _purple,
                    side: const BorderSide(color: _purple),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('장바구니에 담기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _submitOrder(isBuyNow: true),
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('바로 구매',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  // 공통 헬퍼
  // ════════════════════════════════════════════════════════
  Widget _section(String title, Widget child, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            if (icon != null) ...[Icon(icon, color: _purple, size: 17), const SizedBox(width: 7)],
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          ]),
        ),
        const Divider(height: 14, indent: 16, endIndent: 16),
        child,
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _infoBanner(String msg, {Color color = _purple}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, color: color, size: 15),
        const SizedBox(width: 7),
        Expanded(child: Text(msg, style: TextStyle(fontSize: 11, color: color))),
      ]),
    );
  }

  Widget _sumRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap, {Color? selColor}) {
    final c = selColor ?? _purple;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? c : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? c : const Color(0xFFDDDDDD)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: sel ? Colors.white : Colors.black54)),
      ),
    );
  }

  Widget _placeholder() => Container(
      width: 64, height: 64,
      color: const Color(0xFFF0E6F8),
      child: const Icon(Icons.inventory_2_rounded, color: _purple, size: 28));

  // ════════════════════════════════════════════════════════
  // 헤더 배너
  // ════════════════════════════════════════════════════════
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF4A148C), _purple],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 9),
          Expanded(child: Text(
            _isAdditional ? '추가 제작 주문' : '단체 커스텀 주문',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          )),
          if (widget.product != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(widget.product!.name,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 5),
        Text(
          _isAdditional ? '추가 제작: 1장부터 주문 가능합니다.' : '최소 5명 이상 · 제작기간 약 3~4주',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 1: 수량 (구간 배지 + 다이얼)
  // ════════════════════════════════════════════════════════
  Widget _buildCountSection() {
    // 구간 정의
    final stages = [
      {'label': '5~9명',  'color': Colors.blue,   'min': 5,  'max': 9},
      {'label': '10~29명','color': Colors.green,   'min': 10, 'max': 29},
      {'label': '30~49명','color': Colors.orange,  'min': 30, 'max': 49},
      {'label': '50명+',  'color': Colors.red,     'min': 50, 'max': 999},
    ];

    // 현재 단계
    Color dialColor = Colors.grey.shade400;
    for (final s in stages) {
      if (_dialCount >= (s['min'] as int) && _dialCount <= (s['max'] as int)) {
        dialColor = s['color'] as Color;
        break;
      }
    }

    return _section(
      '주문 수량',
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── 구간 배지 행 ──
          Row(children: stages.map((s) {
            final active = _dialCount >= (s['min'] as int) && _dialCount <= (s['max'] as int);
            final c      = s['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:  active ? c : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? c : Colors.grey.shade300, width: 1.5),
                ),
                child: Text(s['label'] as String,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : Colors.grey.shade400)),
              ),
            );
          }).toList()),

          const SizedBox(height: 12),

          // ── 최소 인원 안내 ──
          if (!_isAdditional)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Text('최소 5명부터 주문 가능합니다',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
              ]),
            ),

          // ── 다이얼 ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: dialColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dialColor.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Row(children: [
              _DialButton(
                icon: Icons.remove_rounded,
                color: _dialCount <= 1 ? Colors.grey.shade300 : dialColor,
                onTap: () { if (_dialCount > 1) setState(() => _dialCount--); },
                onLongPress: () { if (_dialCount > 5) setState(() => _dialCount -= 5); },
              ),
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$_dialCount',
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: dialColor),
                      textAlign: TextAlign.center),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('명', style: TextStyle(fontSize: 13, color: dialColor.withValues(alpha: 0.7))),
                    // 현재 단계 라벨
                    ...(() {
                      for (final s in stages) {
                        if (_dialCount >= (s['min'] as int) && _dialCount <= (s['max'] as int)) {
                          return [
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (s['color'] as Color).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(s['label'] as String,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: s['color'] as Color,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ];
                        }
                      }
                      return <Widget>[];
                    })(),
                  ]),
                ]),
              ),
              _DialButton(
                icon: Icons.add_rounded,
                color: dialColor,
                onTap: () { if (_dialCount < 200) setState(() => _dialCount++); },
                onLongPress: () { if (_dialCount <= 195) setState(() => _dialCount += 5); },
              ),
            ]),
          ),

          const SizedBox(height: 10),

          // ── 빠른 선택 칩 ──
          Wrap(spacing: 6, runSpacing: 6,
            children: [5, 10, 15, 20, 30, 50].map((n) =>
                _chip('$n명', _dialCount == n, () => setState(() => _dialCount = n))
            ).toList(),
          ),

          const SizedBox(height: 14),

          // ── 확정 버튼 ──
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmCount,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('$_dialCount명으로 주문서 작성하기',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),

          // ── 확정 표시 ──
          if (_orderStarted) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: _purpleLight, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: _purple, size: 16),
                const SizedBox(width: 7),
                Text('$_totalCount명 확정',
                    style: const TextStyle(color: _purple, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
          ],
        ]),
      ),
      icon: Icons.people_alt_rounded,
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 2: 인쇄 타입
  // ════════════════════════════════════════════════════════
  Widget _buildPrintTypeSection() {
    final options = [
      const _PrintOption(0, '색상 변경',        '원하는 색상으로 변경 제작',                 Icons.palette_rounded,      true),
      _PrintOption(1, '전면 (단체명)',          '전면에 단체명 인쇄',                       Icons.group_work_rounded,   _canUsePrint1),
      _PrintOption(2, '조합 (전면+색상)',      '전면 단체명 + 색상 변경',                  Icons.auto_awesome_rounded, _canUsePrint1),
      _PrintOption(3, '조합 + 후면 이름',     '전면 단체명·색상 + 후면 이름 (10명+)',    Icons.badge_rounded,        _canUsePrint2),
    ];

    return _section(
      '인쇄 타입',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(children: options.map((opt) {
          final sel = _printType == opt.id;
          return GestureDetector(
            onTap: opt.enabled ? () => setState(() => _printType = opt.id) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? _purpleLight : (opt.enabled ? Colors.white : const Color(0xFFF8F8F8)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? _purple : (opt.enabled ? const Color(0xFFE0E0E0) : const Color(0xFFEEEEEE)),
                    width: sel ? 2 : 1),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: sel ? _purple : (opt.enabled ? const Color(0xFFF0F0F0) : const Color(0xFFF5F5F5)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(opt.icon,
                      color: sel ? Colors.white : (opt.enabled ? _purple : Colors.grey.shade400),
                      size: 18),
                ),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(opt.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: opt.enabled ? Colors.black87 : Colors.grey.shade400)),
                    if (!opt.enabled) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(_totalCount < 5 ? '5명+' : '10명+',
                            style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ),
                    ],
                  ]),
                  Text(opt.desc,
                      style: TextStyle(fontSize: 10,
                          color: opt.enabled ? Colors.black45 : Colors.grey.shade400)),
                ])),
                if (sel) const Icon(Icons.check_circle_rounded, color: _purple, size: 20),
              ]),
            ),
          );
        }).toList()),
      ),
      icon: Icons.print_rounded,
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 3: 선택 상품 카드 (디자인 이미지 포함)
  // ════════════════════════════════════════════════════════
  Widget _buildSelectedProductCard() {
    final p = widget.product;
    if (p == null) return const SizedBox.shrink();

    final designImgs = p.sectionImages['s1'] ?? [];

    return _section(
      '선택 상품',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: p.images.isNotEmpty
                  ? Image.network(p.images.first, width: 64, height: 64, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('${p.category}  ${p.subCategory}',
                  style: const TextStyle(fontSize: 11, color: Colors.black45)),
              const SizedBox(height: 5),
              Text('${_fmt(p.price.toInt())}원/명',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _purple)),
            ])),
          ]),
          if (designImgs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('디자인 이미지',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
            const SizedBox(height: 6),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: designImgs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(designImgs[i],
                      height: 120, width: 120, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          width: 120, height: 120,
                          child: ColoredBox(color: Color(0xFFEEEEEE),
                              child: Icon(Icons.image_not_supported_rounded,
                                  color: Colors.grey)))),
                ),
              ),
            ),
          ],
        ]),
      ),
      icon: Icons.shopping_bag_rounded,
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 4: 단체 정보
  // ════════════════════════════════════════════════════════
  Widget _buildGroupInfoCard() {
    return _section(
      '단체 정보',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _purpleLight, borderRadius: BorderRadius.circular(12)),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            _infoChip(Icons.people_alt_rounded, '총 $_totalCount명', Colors.indigo),
            _infoChip(
              Icons.local_shipping_rounded,
              _isFreeShipping ? '무료 배송' : '배송비 별도',
              _isFreeShipping ? Colors.green : Colors.grey,
            ),
          ]),
        ),
      ),
      icon: Icons.info_outline_rounded,
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 5: 원단 선택
  // ════════════════════════════════════════════════════════
  Widget _buildFabricSection() {
    final isReadyMade = widget.product != null && !widget.product!.isGroupOnly;
    if (isReadyMade && _fabricType != '일반 (봉제)') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _fabricType = '일반 (봉제)');
      });
    }

    return _section(
      '원단 선택',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isReadyMade)
            _infoBanner('기성품은 일반(봉제) 원단으로 고정됩니다.', color: Colors.blue)
          else ...[
            const Text('소재',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6,
              children: AppConstants.fabricTypes.map((type) {
                final extra = AppConstants.fabricTypePrices[type] ?? 0;
                return _chip(
                  extra > 0 ? '$type (+${_fmt(extra)}원)' : type,
                  _fabricType == type,
                  () => setState(() => _fabricType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          const Text('무게',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6,
            children: AppConstants.fabricWeights.map((w) =>
                _chip(w, _fabricWeight == w, () => setState(() => _fabricWeight = w))
            ).toList(),
          ),
        ]),
      ),
      icon: Icons.layers_rounded,
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 6: 색상 선택 (InlineColorChart – 19색/전체팔레트/HEX)
  // ════════════════════════════════════════════════════════
  Widget _buildColorSection() {
    return _section(
      '색상 선택',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 안내 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.info_outline_rounded, size: 12, color: Colors.orange),
              SizedBox(width: 5),
              Text('상·하의 동일 색상 적용',
                  style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 12),
          // 인라인 색상 차트 (탭: 19색 / 전체팔레트 / HEX)
          InlineColorChart(
            label: '색상',
            selectedColorName: _mainColorName,
            selectedColor: _mainColor,
            onColorSelected: (name, color) => setState(() {
              _mainColorName = name;
              _mainColor     = color;
            }),
            accentColor: _purple,
            required: _hasColorChange,
          ),
        ]),
      ),
      icon: Icons.palette_rounded,
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 7: 허리밴드 (토글 + 확장 옵션)
  // ════════════════════════════════════════════════════════
  Widget _buildWaistbandSection() {
    return _section(
      '허리밴드 변경',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── 토글 카드 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _waistbandEnabled ? _purpleLight : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _waistbandEnabled
                    ? _purple.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
                width: _waistbandEnabled ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _waistbandEnabled ? _purple : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.loop_rounded,
                    color: _waistbandEnabled ? Colors.white : Colors.grey.shade500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('허리밴드 변경',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: _waistbandEnabled ? Colors.black87 : Colors.grey.shade600)),
                Text('기본 허리밴드를 원하는 옵션으로 변경합니다',
                    style: TextStyle(fontSize: 10,
                        color: _waistbandEnabled ? Colors.black45 : Colors.grey.shade400)),
              ])),
              Switch(
                value: _waistbandEnabled,
                onChanged: (v) => setState(() {
                  _waistbandEnabled = v;
                  if (!v) {
                    _waistbandOption   = null;
                    _waistbandColorName = null;
                    _waistbandColor    = null;
                  } else {
                    _waistbandOption = 'design';
                  }
                }),
                activeThumbColor: _purple,
                activeTrackColor: _purple.withValues(alpha: 0.4),
              ),
            ]),
          ),

          // ── 확장 영역 (ON일 때) ──
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _waistbandEnabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // 옵션 선택 버튼 3개
                      const Text('옵션 선택',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Row(children: [
                        _wbBtn('design', '디자인',    Icons.brush_rounded),
                        const SizedBox(width: 8),
                        _wbBtn('color',  '색상 변경',  Icons.palette_rounded),
                        const SizedBox(width: 8),
                        _wbBtn('both',   '둘 다',     Icons.layers_rounded),
                      ]),

                      // 선택된 옵션 가격 표시
                      if (_waistbandOption != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                              color: _purpleLight, borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.check_circle_rounded, color: _purple, size: 15),
                            const SizedBox(width: 7),
                            Text(
                              '${_wbLabel(_waistbandOption)}  +${_fmt(_waistbandExtra)}원/명',
                              style: const TextStyle(
                                  fontSize: 12, color: _purple, fontWeight: FontWeight.w700),
                            ),
                          ]),
                        ),
                      ],

                      // 색상 선택 (color / both 일 때)
                      if (_waistbandOption == 'color' || _waistbandOption == 'both') ...[
                        const SizedBox(height: 14),
                        const Text('허리밴드 색상',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
                        const SizedBox(height: 8),
                        InlineColorChart(
                          label: '허리밴드 색상',
                          selectedColorName: _waistbandColorName,
                          selectedColor: _waistbandColor,
                          onColorSelected: (name, color) => setState(() {
                            _waistbandColorName = name;
                            _waistbandColor     = color;
                          }),
                          accentColor: _purple,
                        ),
                      ],
                    ]),
                  )
                : const SizedBox.shrink(),
          ),
        ]),
      ),
      icon: Icons.loop_rounded,
    );
  }

  String _wbLabel(String? opt) {
    switch (opt) {
      case 'design': return '디자인';
      case 'color':  return '색상 변경';
      case 'both':   return '디자인+색상';
      default:       return '';
    }
  }

  Widget _wbBtn(String value, String label, IconData icon) {
    final sel = _waistbandOption == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _waistbandOption = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? _purple : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? _purple : const Color(0xFFDDDDDD),
                width: sel ? 2 : 1),
            boxShadow: sel ? [BoxShadow(
                color: _purple.withValues(alpha: 0.25),
                blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: sel ? Colors.white : Colors.grey.shade500),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : Colors.black54)),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 8: 하의 길이
  // ════════════════════════════════════════════════════════
  Widget _buildLengthSection() {
    const lengths = ['9부', '5부', '4부', '3부', '2.5부', '숏쇼츠'];
    return _section(
      '하의 길이 선택',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('기본 하의 길이를 선택하면 전체 인원에 일괄 적용됩니다.',
              style: TextStyle(fontSize: 11, color: Colors.black45)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6,
            children: lengths.map((l) => _chip(l, _defaultLength == l,
                () => setState(() => _defaultLength = _defaultLength == l ? null : l))).toList(),
          ),
          if (_defaultLength != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _purpleLight, borderRadius: BorderRadius.circular(8)),
                child: Text('기본 길이: $_defaultLength',
                    style: const TextStyle(fontSize: 12, color: _purple, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  for (final p in _persons) { setState(() => p.length = _defaultLength!); }
                  _showSnack('전체 인원에 $_defaultLength 적용됨');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple, side: const BorderSide(color: _purple),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('전체 적용', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ],
        ]),
      ),
      icon: Icons.height_rounded,
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 9: 참조 이미지
  // ════════════════════════════════════════════════════════
  Widget _buildRefImageSection() {
    return _section(
      '참조 이미지 업로드',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Row(children: [
          Expanded(child: _refCard(label: '남성', base64: _maleRefBase64, isMale: true)),
          const SizedBox(width: 10),
          Expanded(child: _refCard(label: '여성', base64: _femaleRefBase64, isMale: false)),
        ]),
      ),
      icon: Icons.image_rounded,
    );
  }

  Widget _refCard({required String label, required String? base64, required bool isMale}) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: base64 != null ? _purple : const Color(0xFFDDDDDD),
            width: base64 != null ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _pickRefImage(isMale: isMale),
        child: base64 != null
            ? Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(9),
                    child: Image.memory(base64Decode(base64),
                        width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
                Positioned(top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() { isMale ? _maleRefBase64 = null : _femaleRefBase64 = null; });
                      _saveImage(isMale: isMale, base64: null);
                    },
                    child: Container(padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 13)),
                  ),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(isMale ? Icons.male_rounded : Icons.female_rounded,
                    color: _purple, size: 24),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _purple)),
                const Text('탭하여 업로드',
                    style: TextStyle(fontSize: 10, color: Colors.black38)),
              ]),
      ),
    );
  }

  Future<void> _pickRefImage({required bool isMale}) async {
    try {
      final picker = ImagePicker();
      final xfile  = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (xfile == null || !mounted) return;
      final bytes = await xfile.readAsBytes();
      final b64   = base64Encode(bytes);
      setState(() { isMale ? _maleRefBase64 = b64 : _femaleRefBase64 = b64; });
      await _saveImage(isMale: isMale, base64: b64);
    } catch (e) {
      if (mounted) _showSnack('이미지 업로드 오류가 발생했습니다.');
    }
  }

  // ════════════════════════════════════════════════════════
  // 섹션 10: 인원별 사이즈
  // ════════════════════════════════════════════════════════
  Widget _buildPersonListSection() {
    return _section(
      '인원별 사이즈  (총 $_totalCount명)',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(children: [
          if (_hasBackName)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _infoBanner('후면 이름 인쇄 선택됨 – 이름란을 반드시 입력해 주세요.',
                  color: Colors.blue),
            ),
          _buildSizeChart(),
          const SizedBox(height: 10),
          ...List.generate(_persons.length, (i) => _PersonRowWidget(
            key: ValueKey(_persons[i].hashCode),
            entry: _persons[i],
            index: i,
            onRemove: _persons.length > 1 ? () => _removePerson(i) : null,
            defaultLength: _defaultLength,
            nameEnabled: _nameInputEnabled,
            onChanged: () => setState(() {}),
          )),
          const SizedBox(height: 6),
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addPerson,
              icon: const Icon(Icons.person_add_rounded, size: 17),
              label: const Text('인원 추가'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple, side: const BorderSide(color: _purple),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
      icon: Icons.format_list_numbered_rounded,
    );
  }

  Widget _buildSizeChart() {
    const headers = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];
    const rows = [
      ['가슴',   '84', '88', '92', '96',  '100', '106', '112', '118'],
      ['허리',   '68', '72', '76', '80',  '84',  '90',  '96',  '102'],
      ['엉덩이', '88', '92', '96', '100', '104', '110', '116', '122'],
    ];
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Row(children: [
        Icon(Icons.straighten_rounded, color: _purple, size: 15),
        SizedBox(width: 5),
        Text('사이즈 가이드 (단위: cm)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _purple)),
      ]),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: const Color(0xFFEEEEEE)),
            defaultColumnWidth: const FixedColumnWidth(46),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: _purple),
                children: ['구분', ...headers].map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                  child: Text(h, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                )).toList(),
              ),
              ...rows.map((row) => TableRow(
                children: row.map((cell) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                  child: Text(cell, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10)),
                )).toList(),
              )),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 11: 기본 정보
  // ════════════════════════════════════════════════════════
  Widget _buildBasicInfoSection() {
    return _section(
      '기본 정보',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(children: [
          if (_hasTeamName) ...[
            _field(controller: _teamNameCtrl, label: '단체명 / 팀명 *',
                hint: '예: 2FIT 농구팀', icon: Icons.groups_rounded),
            const SizedBox(height: 9),
          ],
          _field(controller: _managerNameCtrl, label: '담당자 이름',
              hint: '예: 홍길동', icon: Icons.person_rounded),
          const SizedBox(height: 9),
          _field(controller: _phoneCtrl, label: '연락처 *',
              hint: '예: 010-1234-5678', icon: Icons.phone_rounded,
              type: TextInputType.phone),
          const SizedBox(height: 9),
          _field(controller: _emailCtrl, label: '이메일',
              hint: '예: order@team.com', icon: Icons.email_rounded,
              type: TextInputType.emailAddress),
          const SizedBox(height: 9),
          GestureDetector(
            onTap: () async {
              final result = await showKakaoAddressSearch(context);
              if (result != null && mounted) setState(() => _address = result.address);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBBBBBB)),
                  borderRadius: BorderRadius.circular(10), color: Colors.white),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, color: _purple, size: 19),
                const SizedBox(width: 9),
                Expanded(child: Text(
                  _address.isNotEmpty ? _address : '배송지 주소 검색',
                  style: TextStyle(fontSize: 13,
                      color: _address.isNotEmpty ? Colors.black87 : Colors.grey),
                )),
                const Icon(Icons.search_rounded, color: Colors.grey, size: 18),
              ]),
            ),
          ),
        ]),
      ),
      icon: Icons.assignment_ind_rounded,
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label, required String hint, required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Icon(icon, color: _purple, size: 19),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _purple, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        isDense: true,
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 12: 메모
  // ════════════════════════════════════════════════════════
  Widget _buildMemoSection() {
    return _section(
      '메모 / 요청사항',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: TextFormField(
          controller: _memoCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '특이사항, 요청사항 등을 자유롭게 입력해 주세요.',
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _purple, width: 2)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ),
      icon: Icons.note_alt_rounded,
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 13: 독점 디자인
  // ════════════════════════════════════════════════════════
  Widget _buildExclusiveSection() {
    return _section(
      '디자인 독점 사용권',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _exclusiveDesign ? _purpleLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _exclusiveDesign ? _purple : const Color(0xFFE0E0E0),
                width: _exclusiveDesign ? 2 : 1),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: _exclusiveDesign ? _purple : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.workspace_premium_rounded,
                  color: _exclusiveDesign ? Colors.white : _purple, size: 18)),
            const SizedBox(width: 11),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('독점 디자인 사용',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text('선택 시 동일 디자인을 타 단체에서 사용하지 않습니다',
                  style: TextStyle(fontSize: 10, color: Colors.black45)),
            ])),
            Switch(
              value: _exclusiveDesign,
              onChanged: (v) => setState(() => _exclusiveDesign = v),
              activeThumbColor: _purple,
              activeTrackColor: _purpleLight,
            ),
          ]),
        ),
      ),
      icon: Icons.workspace_premium_rounded,
    );
  }

  // ════════════════════════════════════════════════════════
  // 섹션 14: 최종 금액 요약
  // ════════════════════════════════════════════════════════
  Widget _buildSummarySection() {
    return _section(
      '최종 금액 요약',
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF4A148C), _purple],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _sumRow('기본가 (${_fmt(_basePrice.toInt())}원 × $_totalCount명)',
                '${_fmt((_basePrice * _totalCount).toInt())}원'),
            if (_waistbandExtra > 0)
              _sumRow('허리밴드 (${_fmt(_waistbandExtra)}원 × $_totalCount명)',
                  '+${_fmt(_waistbandExtra * _totalCount)}원'),
            if (_fabricExtra > 0)
              _sumRow('원단 추가금 (${_fmt(_fabricExtra)}원 × $_totalCount명)',
                  '+${_fmt(_fabricExtra * _totalCount)}원'),
            _sumRow('배송비', _isFreeShipping ? '무료' : '${_fmt(_shipping.toInt())}원'),
            const Divider(color: Colors.white30, height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('최종 결제금액', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('${_fmt(_finalPrice.toInt())}원',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              if (_isFreeShipping)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('무료 배송 적용',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                )
              else
                const SizedBox(),
              Text('$_totalCount명 · 단가 ${_fmt(_unitPrice.toInt())}원/명',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ]),
        ),
      ),
      icon: Icons.calculate_rounded,
    );
  }

  // ════════════════════════════════════════════════════════
  // 하단 제출 바
  // ════════════════════════════════════════════════════════
  Widget _buildSubmitBar() {
    return Container(
      padding: EdgeInsets.only(
          left: 14, right: 14, top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.people_alt_rounded, size: 13, color: _purple),
            const SizedBox(width: 4),
            Text('$_totalCount명', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            if (_isFreeShipping) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text('무료배송',
                    style: TextStyle(fontSize: 9, color: Colors.green.shade700,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          Text('${_fmt(_finalPrice.toInt())}원',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _purple)),
        ]),
        Row(children: [
          OutlinedButton(
            onPressed: () => _submitOrder(isBuyNow: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _purple, side: const BorderSide(color: _purple),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('장바구니', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _submitOrder(isBuyNow: true),
            icon: const Icon(Icons.flash_on_rounded, size: 17),
            label: const Text('바로 구매', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ]),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 인원 데이터 모델
// ════════════════════════════════════════════════════════════════
class _PersonEntry {
  int index;
  final nameCtrl       = TextEditingController();
  final customSizeCtrl = TextEditingController();
  final heightCtrl     = TextEditingController();
  final weightCtrl     = TextEditingController();
  final thighCtrl      = TextEditingController();
  final waistCtrl      = TextEditingController();
  String? gender;
  String  size            = '';
  String  length          = '9부';
  bool    showBodyMeasure = false;

  _PersonEntry({required this.index});

  void dispose() {
    nameCtrl.dispose();
    customSizeCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    thighCtrl.dispose();
    waistCtrl.dispose();
  }
}

// ════════════════════════════════════════════════════════════════
// 인원 행 위젯
// ════════════════════════════════════════════════════════════════
class _PersonRowWidget extends StatefulWidget {
  final _PersonEntry entry;
  final int          index;
  final VoidCallback? onRemove;
  final String?      defaultLength;
  final bool         nameEnabled;
  final VoidCallback onChanged;

  const _PersonRowWidget({
    super.key,
    required this.entry,
    required this.index,
    this.onRemove,
    this.defaultLength,
    required this.nameEnabled,
    required this.onChanged,
  });

  @override
  State<_PersonRowWidget> createState() => _PersonRowWidgetState();
}

class _PersonRowWidgetState extends State<_PersonRowWidget> {
  static const Color _purple  = Color(0xFF6A1B9A);
  static const List<String> _sizes   = ['XS','S','M','L','XL','2XL','3XL','4XL'];
  static const List<String> _lengths = ['9부','5부','4부','3부','2.5부','숏쇼츠'];

  @override
  Widget build(BuildContext context) {
    final e      = widget.entry;
    final accent = e.gender == '남'
        ? Colors.blue.shade700
        : e.gender == '여'
            ? Colors.pink.shade400
            : _purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(11),
        border: Border.all(
            color: e.size.isNotEmpty
                ? accent.withValues(alpha: 0.4)
                : const Color(0xFFE8E8E8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 헤더 ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.center,
              child: Text('${widget.index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: widget.nameEnabled
                  ? TextField(
                      controller: e.nameCtrl,
                      onChanged: (_) => widget.onChanged(),
                      decoration: const InputDecoration(
                        hintText: '이름 (선택)',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        isDense: true, border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 12),
                    )
                  : const Text('이름 (10명 이상 입력 가능)',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            _gBtn('남', e.gender == '남', Colors.blue.shade700, () {
              setState(() => e.gender = '남');
              widget.onChanged();
            }),
            const SizedBox(width: 4),
            _gBtn('여', e.gender == '여', Colors.pink.shade400, () {
              setState(() => e.gender = '여');
              widget.onChanged();
            }),
            if (widget.onRemove != null) ...[
              const SizedBox(width: 5),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.remove_circle_outline_rounded,
                    color: Colors.red, size: 18),
              ),
            ],
          ]),
        ),
        // ── 바디 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // 사이즈 칩 + 직접입력
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: SizedBox(width: 34,
                    child: Text('사이즈', style: TextStyle(fontSize: 10, color: Colors.grey))),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 4, runSpacing: 4,
                    children: _sizes.map((s) {
                      final sel = e.size == s && !e.showBodyMeasure && e.customSizeCtrl.text.isEmpty;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            e.size = s;
                            e.showBodyMeasure = false;
                            e.customSizeCtrl.clear();
                          });
                          widget.onChanged();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: sel ? accent : Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: sel ? accent : const Color(0xFFCCCCCC)),
                          ),
                          child: Text(s,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : Colors.black54)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 5),
                  // 직접 입력 텍스트 필드
                  SizedBox(
                    height: 32,
                    child: TextField(
                      controller: e.customSizeCtrl,
                      onChanged: (v) {
                        setState(() {
                          if (v.isNotEmpty) {
                            e.size = v;
                            e.showBodyMeasure = false;
                          } else {
                            e.size = '';
                          }
                        });
                        widget.onChanged();
                      },
                      decoration: InputDecoration(
                        hintText: '직접 입력 (예: XL, 95 등)',
                        hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(color: accent, width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
                      ),
                      style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
            ]),

            const SizedBox(height: 6),

            // 신체치수 토글
            GestureDetector(
              onTap: () => setState(() {
                e.showBodyMeasure = !e.showBodyMeasure;
                if (e.showBodyMeasure) {
                  e.customSizeCtrl.clear();
                  e.size = '신체치수';
                } else {
                  e.size = '';
                }
                widget.onChanged();
              }),
              child: Row(children: [
                const SizedBox(width: 34),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.showBodyMeasure ? _purple.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: e.showBodyMeasure ? _purple : const Color(0xFFCCCCCC)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.straighten_rounded, size: 12,
                        color: e.showBodyMeasure ? _purple : Colors.grey),
                    const SizedBox(width: 4),
                    Text('사이즈표에 없을 경우 신체치수 입력',
                        style: TextStyle(fontSize: 10,
                            color: e.showBodyMeasure ? _purple : Colors.grey,
                            fontWeight: e.showBodyMeasure ? FontWeight.w700 : FontWeight.normal)),
                  ]),
                ),
              ]),
            ),

            // 신체치수 입력 (펼침)
            if (e.showBodyMeasure) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _purple.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _bodyField(e.heightCtrl, '키 (cm)',         Icons.height_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _bodyField(e.weightCtrl, '몸무게 (kg)',     Icons.monitor_weight_outlined)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _bodyField(e.thighCtrl, '허벅지 (cm)',     Icons.straighten_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _bodyField(e.waistCtrl, '허리 둘레 (cm)', Icons.circle_outlined)),
                  ]),
                ]),
              ),
            ],

            const SizedBox(height: 6),

            // 길이 선택
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const SizedBox(width: 34,
                  child: Text('길이', style: TextStyle(fontSize: 10, color: Colors.grey))),
              Expanded(
                child: Wrap(spacing: 4, runSpacing: 4,
                  children: _lengths.map((l) {
                    final sel = e.length == l;
                    return GestureDetector(
                      onTap: () { setState(() => e.length = l); widget.onChanged(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sel ? Colors.indigo.shade700 : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: sel ? Colors.indigo.shade700 : const Color(0xFFCCCCCC)),
                        ),
                        child: Text(l,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : Colors.black54)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _bodyField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
        prefixIcon: Icon(icon, size: 14, color: _purple),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: _purple.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _purple, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: _purple.withValues(alpha: 0.2))),
      ),
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _gBtn(String label, bool sel, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: sel ? color : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: sel ? color : const Color(0xFFCCCCCC)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: sel ? Colors.white : Colors.grey)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 다이얼 버튼
// ════════════════════════════════════════════════════════════════
class _DialButton extends StatefulWidget {
  final IconData      icon;
  final VoidCallback  onTap;
  final VoidCallback? onLongPress;
  final Color         color;

  const _DialButton({
    required this.icon, required this.onTap,
    this.onLongPress, required this.color,
  });

  @override
  State<_DialButton> createState() => _DialButtonState();
}

class _DialButtonState extends State<_DialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap, onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withValues(alpha: 0.22)
              : widget.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: widget.color.withValues(alpha: 0.4)),
        ),
        child: Icon(widget.icon, color: widget.color, size: 26),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 인쇄 옵션 데이터
// ════════════════════════════════════════════════════════════════
class _PrintOption {
  final int     id;
  final String  name;
  final String  desc;
  final IconData icon;
  final bool    enabled;
  const _PrintOption(this.id, this.name, this.desc, this.icon, this.enabled);
}
