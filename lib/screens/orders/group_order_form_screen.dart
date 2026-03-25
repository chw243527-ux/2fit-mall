import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
// 단체 주문 폼 (완전 재작성 – 버그 없는 클린 버전)
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
  // ── 색상 상수 ──
  static const Color _purple     = Color(0xFF6A1B9A);
  static const Color _purpleLight = Color(0xFFF3E5F5);

  // ── 지역화 ──
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  // ── 폼 & 스크롤 ──
  final _formKey   = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // ── 수량 다이얼 ──
  int _inputCount = 5;
  int _dialCount  = 5;
  bool get _countConfirmed => _inputCount >= 1;

  // ── 인원 목록 ──
  final List<_PersonEntry> _persons = [];

  // ── 인쇄 타입 ──
  // 0=색상변경만, 1=단체명변경, 2=단체명+색상, 3=단체명+색상+이름
  int _printType = 0;

  // ── 색상 ──
  String? _mainColorName;
  Color?  _mainColor;
  String? _bottomColorName;
  Color?  _bottomColor;
  bool _useSeparateBottomColor = false;

  // ── 원단 ──
  String _fabricType   = '일반 (봉제)';
  String _fabricWeight = '80g';

  // ── 허리밴드 ──
  bool    _addWaistbandDesign = false;
  String? _waistbandOption;   // null | 'name' | 'color' | 'both'
  String? _waistbandColorName;
  Color?  _waistbandColor;

  // ── 하의 길이 ──
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

  // ═══════════════ 파생 속성 ═══════════════
  bool get _isAdditional  => widget.isAdditionalOrder;
  int  get _minQty        => _isAdditional ? 1 : 5;
  int  get _totalCount    => _persons.length;
  bool get _canUsePrint1  => _isAdditional ? _totalCount >= 1 : _totalCount >= 5;
  bool get _canUsePrint2  => _isAdditional ? _totalCount >= 1 : _totalCount >= 10;
  bool get _hasColorChange => _printType == 0 || _printType == 2 || _printType == 3;
  bool get _hasTeamName    => _printType == 1 || _printType == 2 || _printType == 3;

  double get _discountRate {
    if (_totalCount >= 50) return 0.10;
    if (_totalCount >= 30) return 0.05;
    return 0.0;
  }

  int get _waistbandExtra {
    switch (_waistbandOption) {
      case 'name':  return AppConstants.waistbandNamePrice;
      case 'color': return AppConstants.waistbandColorPrice;
      case 'both':  return AppConstants.waistbandBothPrice;
      default:      return 0;
    }
  }

  int    get _fabricExtra => AppConstants.fabricTypePrices[_fabricType] ?? 0;
  double get _basePrice   => widget.product?.price ?? 0.0;
  double get _unitPrice   => _basePrice + _waistbandExtra + _fabricExtra;
  double get _subTotal    => _unitPrice * _totalCount;
  double get _discount    => _subTotal * _discountRate;
  double get _shipping    =>
      _totalCount >= AppConstants.groupMinFreeShipping
          ? 0
          : AppConstants.groupAdditionalShippingFee.toDouble();
  double get _finalPrice  => _subTotal - _discount + _shipping;

  String _fmt(num v) => v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ═══════════════════════════════════════════
  // 생명주기
  // ═══════════════════════════════════════════
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
    for (final p in _persons) {
      p.dispose();
    }
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
    final key = isMale ? _kMaleKey : _kFemaleKey;
    if (base64 == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, base64);
    }
  }

  // ═══════════════════════════════════════════
  // 수량 조작
  // ═══════════════════════════════════════════
  void _confirmCount() {
    final n = _dialCount;
    if (n < 1) return;
    setState(() {
      _inputCount = n;
      while (_persons.length < n) {
        _persons.add(_PersonEntry(index: _persons.length));
      }
      while (_persons.length > n) {
        _persons.last.dispose();
        _persons.removeLast();
      }
      for (int i = 0; i < _persons.length; i++) {
        _persons[i].index = i;
      }
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
      for (int i = 0; i < _persons.length; i++) {
        _persons[i].index = i;
      }
      _inputCount = _persons.length;
      _dialCount  = _inputCount;
    });
  }

  // ═══════════════════════════════════════════
  // 검증 & 주문 제출
  // ═══════════════════════════════════════════
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
      _showSnack(loc.groupFormColorRequired);
      return false;
    }
    if (_hasTeamName && _teamNameCtrl.text.trim().isEmpty) {
      _showSnack(loc.groupFormTeamRequired);
      return false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnack(loc.groupFormPhoneRequired);
      return false;
    }
    for (int i = 0; i < _persons.length; i++) {
      final p = _persons[i];
      if (p.gender == null) {
        _showSnack('${i + 1}번 인원의 성별을 선택해 주세요.');
        return false;
      }
      if (p.size.isEmpty) {
        _showSnack('${i + 1}번 인원의 사이즈를 선택해 주세요.');
        return false;
      }
    }
    return true;
  }

  Future<void> _submitOrder({required bool isBuyNow}) async {
    if (!_validate()) return;

    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    final product = widget.product ?? ProductModel(
      id          : 'group_direct_${DateTime.now().millisecondsSinceEpoch}',
      name        : '단체주문',
      category    : '단체주문',
      subCategory : '',
      price       : _unitPrice,
      originalPrice: _unitPrice,
      description : '단체 직접 주문',
      images      : [],
      sizes       : [],
      colors      : [],
      material    : '',
      stockCount  : 999,
      createdAt   : DateTime.now(),
    );

    final customOptions = <String, dynamic>{
      'orderType'    : _isAdditional ? 'additional' : 'group',
      'printType'    : _printType,
      'mainColor'    : _mainColorName,
      'bottomColor'  : _useSeparateBottomColor ? _bottomColorName : null,
      'waistband'    : _waistbandOption,
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
        'index' : p.index,
        'name'  : p.nameCtrl.text.trim(),
        'gender': p.gender,
        'size'  : p.size,
        'length': p.length,
      }).toList(),
    };

    final orderId = 'GRP_${DateTime.now().millisecondsSinceEpoch}';
    final order = OrderModel(
      id           : orderId,
      userId       : user?.id ?? 'guest',
      userName     : _managerNameCtrl.text.trim().isNotEmpty
          ? _managerNameCtrl.text.trim()
          : _teamNameCtrl.text.trim(),
      userEmail    : _emailCtrl.text.trim(),
      userPhone    : _phoneCtrl.text.trim(),
      userAddress  : _address,
      items        : [
        OrderItem(
          productId   : product.id,
          productName : product.name,
          size        : '단체',
          color       : _mainColorName ?? '기본',
          quantity    : _totalCount,
          price       : _unitPrice,
          customOptions: customOptions,
        ),
      ],
      totalAmount  : _finalPrice,
      shippingFee  : _shipping,
      paymentMethod: '무통장입금',
      orderType    : _isAdditional ? 'additional' : 'group',
      groupName    : _teamNameCtrl.text.trim(),
      groupCount   : _totalCount,
      memo         : _memoCtrl.text.trim(),
      createdAt    : DateTime.now(),
      customOptions: customOptions,
    );

    if (isBuyNow) {
      final cart = context.read<CartProvider>();
      cart.clearCart();
      cart.addItem(
        product,
        '단체',
        _mainColorName ?? '기본',
        quantity   : _totalCount,
        extraPrice : (_waistbandExtra + _fabricExtra).toDouble(),
        customOptions: customOptions,
      );
      if (!mounted) return;
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => CheckoutScreen(cart: cart)));
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

  // ═══════════════════════════════════════════
  // build
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final body = Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          children: [
            _buildHeaderBanner(),
            _buildCountInputSection(),
            _buildPrintTypeSection(),
            if (_countConfirmed) ...[
              _buildSelectedProductCard(),
              if (_totalCount >= 10 && _hasTeamName) _buildGroupInfoCard(),
              _buildFabricTypeSection(),
              if (_hasColorChange) _buildColorSection(),
              _buildWaistbandSection(),
              _buildLengthGuideSection(),
              _buildBottomRefImageSection(),
              _buildPersonListSection(),
              _buildBasicInfoSection(),
              _buildMemoSection(),
              _buildExclusiveDesignSection(),
              _buildSummarySection(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _isAdditional ? '추가 제작 주문서' : loc.groupFormTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: body,
      bottomNavigationBar: _countConfirmed ? _buildSubmitBar() : null,
    );
  }

  // ═══════════════════════════════════════════
  // PC 레이아웃
  // ═══════════════════════════════════════════
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _isAdditional ? '추가 제작 주문서' : loc.groupFormTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
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
          // 왼쪽: 폼
          Expanded(
            flex: 3,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                child: Column(
                  children: [
                    _buildHeaderBanner(),
                    _buildCountInputSection(),
                    _buildPrintTypeSection(),
                    if (_countConfirmed) ...[
                      _buildSelectedProductCard(),
                      if (_totalCount >= 10 && _hasTeamName) _buildGroupInfoCard(),
                      _buildFabricTypeSection(),
                      if (_hasColorChange) _buildColorSection(),
                      _buildWaistbandSection(),
                      _buildLengthGuideSection(),
                      _buildBottomRefImageSection(),
                      _buildPersonListSection(),
                      _buildBasicInfoSection(),
                      _buildMemoSection(),
                      _buildExclusiveDesignSection(),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // 오른쪽: 요약 패널
          if (_countConfirmed)
            SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildPcSummaryPanel(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPcSummaryPanel() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A148C), _purple],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('주문 요약',
                style: TextStyle(color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _wSumRow('기본가 × $_totalCount명',
                '${_fmt((_basePrice * _totalCount).toInt())}원'),
            if (_waistbandExtra > 0)
              _wSumRow('허리밴드 옵션', '+${_fmt(_waistbandExtra * _totalCount)}원'),
            if (_fabricExtra > 0)
              _wSumRow('원단 추가금', '+${_fmt(_fabricExtra * _totalCount)}원'),
            if (_discountRate > 0)
              _wSumRow('단체 할인 (${(_discountRate * 100).toInt()}%)',
                  '-${_fmt(_discount.toInt())}원',
                  highlight: true),
            _wSumRow('배송비', _shipping == 0 ? '무료' : '${_fmt(_shipping.toInt())}원'),
            const Divider(color: Colors.white30, height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('최종 금액',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('${_fmt(_finalPrice.toInt())}원',
                  style: const TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _submitOrder(isBuyNow: false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,
                  side: const BorderSide(color: _purple),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('장바구니에 담기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _submitOrder(isBuyNow: true),
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: Text(loc.groupFormBuyNowBtn,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 공통 헬퍼
  // ═══════════════════════════════════════════════════════════

  /// 섹션 공통 래퍼
  Widget _section(String title, Widget child, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(children: [
            if (icon != null) ...[
              Icon(icon, color: _purple, size: 18),
              const SizedBox(width: 8),
            ],
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A))),
          ]),
        ),
        const Divider(height: 16, indent: 20, endIndent: 20),
        child,
        const SizedBox(height: 4),
      ]),
    );
  }

  /// 정보 배너
  Widget _infoBanner(String msg, {Color color = _purple}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg, style: TextStyle(fontSize: 12, color: color))),
      ]),
    );
  }

  /// 옵션 타일 (Switch 포함)
  Widget _optionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: value ? _purpleLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? _purple : const Color(0xFFE0E0E0),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: value ? _purple : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: value ? Colors.white : _purple, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              if (badge.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                          fontSize: 10, color: Colors.orange.shade800,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _purple,
          activeTrackColor: _purpleLight,
        ),
      ]),
    );
  }

  /// 인포 행
  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.black54)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  /// 합계 행
  Widget _wSumRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
            Text(value,
                style: TextStyle(
                    color: highlight ? Colors.yellow : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
    );
  }

  /// 히어로 배지
  Widget _heroBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 0: 헤더 배너
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), _purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.groups_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isAdditional ? '추가 제작 주문' : '단체 커스텀 주문',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900),
            ),
          ),
          if (widget.product != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.product!.name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Text(
          _isAdditional
              ? '추가 제작: 1장부터 주문 가능합니다.'
              : '최소 5명 이상 · 제작기간 약 3~4주',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
        ),
        if (!_isAdditional) ...[
          const SizedBox(height: 12),
          Row(children: [
            _heroBadge(Icons.discount_rounded, '30명+ 5% 할인'),
            const SizedBox(width: 8),
            _heroBadge(Icons.star_rounded, '50명+ 10% 할인'),
            const SizedBox(width: 8),
            _heroBadge(Icons.local_shipping_rounded, '5명+ 무료배송'),
          ]),
        ],
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 1: 수량 입력
  // ═══════════════════════════════════════════════════════════
  Widget _buildCountInputSection() {
    final stages = [
      {'min': 1,  'max': 4,   'label': '1~4명',          'color': Colors.grey},
      {'min': 5,  'max': 9,   'label': '5~9명',           'color': Colors.blue},
      {'min': 10, 'max': 29,  'label': '10~29명',         'color': Colors.green},
      {'min': 30, 'max': 49,  'label': '30~49명 (5%↓)',  'color': Colors.orange},
      {'min': 50, 'max': 999, 'label': '50명+ (10%↓)',   'color': Colors.red},
    ];
    Color  stageColor = Colors.grey;
    String stageLabel = '';
    for (final s in stages) {
      if (_dialCount >= (s['min'] as int) &&
          _dialCount <= (s['max'] as int)) {
        stageColor = s['color'] as Color;
        stageLabel = s['label'] as String;
        break;
      }
    }

    return _section(
      loc.groupFormQtyLabel,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 다이얼 컨트롤
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: stageColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: stageColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(children: [
              _DialButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (_dialCount > 1) setState(() => _dialCount--);
                },
                onLongPress: () {
                  if (_dialCount > 5) setState(() => _dialCount -= 5);
                },
                color: _dialCount <= 1 ? Colors.grey.shade300 : stageColor,
              ),
              Expanded(
                child: Column(children: [
                  Text(
                    '$_dialCount',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: stageColor),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    loc.groupFormPersonUnit,
                    style: TextStyle(
                        fontSize: 12,
                        color: stageColor.withValues(alpha: 0.7)),
                  ),
                ]),
              ),
              _DialButton(
                icon: Icons.add_rounded,
                onTap: () {
                  if (_dialCount < 200) setState(() => _dialCount++);
                },
                onLongPress: () {
                  if (_dialCount <= 195) setState(() => _dialCount += 5);
                },
                color: stageColor,
              ),
            ]),
          ),
          const SizedBox(height: 10),
          // 단계 배지
          if (stageLabel.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: stageColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                stageLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: stageColor),
              ),
            ),
          const SizedBox(height: 10),
          // 빠른 선택 칩
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [5, 10, 15, 20, 30, 50].map((n) {
              final sel = _dialCount == n;
              return GestureDetector(
                onTap: () => setState(() => _dialCount = n),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? _purple : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? _purple : const Color(0xFFDDDDDD)),
                  ),
                  child: Text(
                    '$n명',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : Colors.black54),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // 확인 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmCount,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                '$_dialCount명으로 주문서 작성하기',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          // 확정 상태 표시
          if (_countConfirmed) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: _purple, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$_totalCount명 · ${_fmt(_finalPrice)}원',
                  style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                if (_discountRate > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      '${(_discountRate * 100).toInt()}% 할인',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ]),
            ),
          ],
        ]),
      ),
      icon: Icons.people_alt_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 2: 인쇄 타입
  // ═══════════════════════════════════════════════════════════
  Widget _buildPrintTypeSection() {
    final options = [
      const _PrintOption(0, '색상 변경', '원하는 색상으로 제작',
          Icons.palette_rounded, true),
      _PrintOption(1, '단체명 변경', '허리밴드에 단체명 인쇄',
          Icons.group_work_rounded, _canUsePrint1),
      _PrintOption(2, '단체명 + 색상', '단체명 인쇄 & 색상 변경',
          Icons.auto_awesome_rounded, _canUsePrint1),
      _PrintOption(3, '단체명 + 색상 + 이름',
          '단체명·이름 인쇄 & 색상 변경 (10명+)',
          Icons.badge_rounded, _canUsePrint2),
    ];

    return _section(
      loc.groupOrderPrint,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: options.map((opt) {
            final sel = _printType == opt.id;
            return GestureDetector(
              onTap: opt.enabled
                  ? () => setState(() => _printType = opt.id)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? _purpleLight
                      : (opt.enabled
                          ? Colors.white
                          : const Color(0xFFF8F8F8)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? _purple
                        : (opt.enabled
                            ? const Color(0xFFE0E0E0)
                            : const Color(0xFFEEEEEE)),
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: sel
                          ? _purple
                          : (opt.enabled
                              ? const Color(0xFFF0F0F0)
                              : const Color(0xFFF5F5F5)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      opt.icon,
                      color: sel
                          ? Colors.white
                          : (opt.enabled ? _purple : Colors.grey.shade400),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            opt.name,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: opt.enabled
                                    ? Colors.black87
                                    : Colors.grey.shade400),
                          ),
                          if (!opt.enabled) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                _canUsePrint2
                                    ? ''
                                    : (_totalCount < 5 ? '5명+' : '10명+'),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ),
                          ],
                        ]),
                        Text(
                          opt.desc,
                          style: TextStyle(
                              fontSize: 11,
                              color: opt.enabled
                                  ? Colors.black54
                                  : Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  if (sel)
                    const Icon(Icons.check_circle_rounded,
                        color: _purple, size: 22),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
      icon: Icons.print_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 3: 선택 상품 카드
  // ═══════════════════════════════════════════════════════════
  Widget _buildSelectedProductCard() {
    final p = widget.product;
    if (p == null) return const SizedBox.shrink();

    return _section(
      '선택 상품',
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: p.images.isNotEmpty
                  ? Image.network(
                      p.images.first,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _productPlaceholder(),
                    )
                  : _productPlaceholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${p.category} · ${p.subCategory}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_fmt(p.price.toInt())}원/명',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _purple),
                    ),
                  ]),
            ),
          ]),
        ),
      ),
      icon: Icons.shopping_bag_rounded,
    );
  }

  Widget _productPlaceholder() => Container(
        width: 70,
        height: 70,
        color: const Color(0xFFF0E6F8),
        child:
            const Icon(Icons.inventory_2_rounded, color: _purple, size: 32),
      );

  // ═══════════════════════════════════════════════════════════
  // 섹션 4: 단체 정보 카드 (10명+ & 단체명 옵션)
  // ═══════════════════════════════════════════════════════════
  Widget _buildGroupInfoCard() {
    return _section(
      loc.groupFormOrderInfoTitle,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _purpleLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            _infoRow(Icons.people_alt_rounded, '인원수', '$_totalCount명',
                Colors.indigo),
            const SizedBox(height: 8),
            _infoRow(
              Icons.discount_rounded,
              '단체 할인',
              _discountRate > 0
                  ? '${(_discountRate * 100).toInt()}% 적용 중'
                  : '없음',
              _discountRate > 0 ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.monetization_on_rounded,
              '예상 절감 금액',
              _discountRate > 0 ? '-${_fmt(_discount)}원' : '0원',
              Colors.green,
            ),
          ]),
        ),
      ),
      icon: Icons.info_outline_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 5: 원단 선택
  // ═══════════════════════════════════════════════════════════
  Widget _buildFabricTypeSection() {
    final isReadyMade =
        widget.product != null && !widget.product!.isGroupOnly;
    if (isReadyMade && _fabricType != '일반 (봉제)') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _fabricType = '일반 (봉제)');
      });
    }

    return _section(
      loc.fabricSelectTitle,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loc.groupFormFabricCostNote,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 14),
          if (isReadyMade)
            _infoBanner('기성품은 일반(봉제) 원단으로 고정됩니다.',
                color: Colors.blue)
          else ...[
            // 소재 선택
            const Text('원단 소재',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: AppConstants.fabricTypes.map((type) {
                final sel = _fabricType == type;
                final extra =
                    AppConstants.fabricTypePrices[type] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _fabricType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? _purple : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? _purple : const Color(0xFFDDDDDD)),
                      ),
                      child: Column(children: [
                        Text(
                          type,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color:
                                  sel ? Colors.white : Colors.black87),
                        ),
                        if (extra > 0)
                          Text(
                            '+${_fmt(extra)}원',
                            style: TextStyle(
                                fontSize: 10,
                                color: sel
                                    ? Colors.white70
                                    : Colors.orange),
                          ),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // 무게 선택
          const Text('원단 무게',
              style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: AppConstants.fabricWeights.map((w) {
              final sel = _fabricWeight == w;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _fabricWeight = w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? _purple : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              sel ? _purple : const Color(0xFFDDDDDD)),
                    ),
                    child: Text(
                      w,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
      icon: Icons.layers_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 6: 색상 선택
  // ═══════════════════════════════════════════════════════════
  Widget _buildColorSection() {
    final isSinglet =
        widget.product?.subCategory.contains('싱글렛') ?? false;

    return _section(
      loc.groupFormSingletColorTitle,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loc.groupFormSingletColorDesc,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 14),
          // 메인 색상
          const Text('메인 색상 *',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ColorPickerWidget(
            selectedColorName: _mainColorName,
            selectedColor: _mainColor,
            onColorSelected: (name, color) => setState(() {
              _mainColorName = name;
              _mainColor = color;
            }),
          ),
          // 싱글렛 하의 분리 색상
          if (isSinglet) ...[
            const SizedBox(height: 16),
            Row(children: [
              Checkbox(
                value: _useSeparateBottomColor,
                onChanged: (v) =>
                    setState(() => _useSeparateBottomColor = v ?? false),
                activeColor: _purple,
              ),
              Text(loc.groupFormColorSplitLabel,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
            if (_useSeparateBottomColor) ...[
              const SizedBox(height: 8),
              const Text('하의 색상',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ColorPickerWidget(
                selectedColorName: _bottomColorName,
                selectedColor: _bottomColor,
                onColorSelected: (name, color) => setState(() {
                  _bottomColorName = name;
                  _bottomColor = color;
                }),
              ),
            ],
          ],
        ]),
      ),
      icon: Icons.palette_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 7: 허리밴드 옵션
  // ═══════════════════════════════════════════════════════════
  Widget _buildWaistbandSection() {
    return _section(
      loc.groupFormWaistbandNote,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loc.groupFormWaistbandDesc,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 12),
          _optionTile(
            icon: Icons.toggle_on_rounded,
            title: loc.groupFormWaistbandChange,
            subtitle: '허리밴드 변경 옵션을 선택합니다',
            badge: '',
            value: _addWaistbandDesign,
            onChanged: (v) => setState(() {
              _addWaistbandDesign = v;
              if (!v) _waistbandOption = null;
            }),
          ),
          if (_addWaistbandDesign) ...[
            const SizedBox(height: 12),
            const Text('변경 옵션',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...[
              ('name',  loc.groupFormWaistbandName,      '+${_fmt(AppConstants.waistbandNamePrice)}원'),
              ('color', loc.groupFormWaistbandColor,     '+${_fmt(AppConstants.waistbandColorPrice)}원'),
              ('both',  loc.groupFormWaistbandNameColor, '+${_fmt(AppConstants.waistbandBothPrice)}원'),
            ].map((opt) {
              final sel = _waistbandOption == opt.$1;
              return GestureDetector(
                onTap: () => setState(
                    () => _waistbandOption = sel ? null : opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? _purpleLight : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? _purple : const Color(0xFFE0E0E0),
                        width: sel ? 2 : 1),
                  ),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded,
                        color: sel ? _purple : Colors.grey.shade300,
                        size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(opt.$2,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: sel ? _purple : Colors.black87)),
                    ),
                    Text(opt.$3,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sel ? _purple : Colors.orange)),
                  ]),
                ),
              );
            }),
            // 허리밴드 색상 선택
            if (_waistbandOption == 'color' ||
                _waistbandOption == 'both') ...[
              const SizedBox(height: 12),
              Text(loc.groupFormWaistbandColorLabel,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ColorPickerWidget(
                selectedColorName: _waistbandColorName,
                selectedColor: _waistbandColor,
                onColorSelected: (name, color) => setState(() {
                  _waistbandColorName = name;
                  _waistbandColor = color;
                }),
              ),
            ],
          ],
        ]),
      ),
      icon: Icons.loop_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 8: 하의 길이 가이드
  // ═══════════════════════════════════════════════════════════
  Widget _buildLengthGuideSection() {
    const lengths = ['9부', '5부', '4부', '3부', '2.5부', '숏쇼츠'];

    return _section(
      loc.groupFormLengthCompare,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loc.groupFormBottomLengthCompare,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 14),
          const Text('기본 하의 길이 (전체 적용)',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lengths.map((l) {
              final sel = _defaultLength == l;
              return GestureDetector(
                onTap: () =>
                    setState(() => _defaultLength = sel ? null : l),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? _purple : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? _purple : const Color(0xFFDDDDDD)),
                  ),
                  child: Text(l,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : Colors.black54)),
                ),
              );
            }).toList(),
          ),
          if (_defaultLength != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: _purple, size: 16),
                const SizedBox(width: 6),
                Text(
                  '전체 인원 기본 길이: $_defaultLength',
                  style: const TextStyle(
                      fontSize: 12,
                      color: _purple,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    for (final p in _persons) {
                      setState(() => p.length = _defaultLength!);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('전체 적용',
                      style: TextStyle(fontSize: 12, color: _purple)),
                ),
              ]),
            ),
          ],
        ]),
      ),
      icon: Icons.height_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 9: 참조 이미지 업로드
  // ═══════════════════════════════════════════════════════════
  Widget _buildBottomRefImageSection() {
    return _section(
      loc.groupFormImageUpload,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Row(children: [
          Expanded(
            child: _refImageCard(
              label: loc.groupFormMale,
              base64: _maleRefBase64,
              isMale: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _refImageCard(
              label: loc.groupFormFemale,
              base64: _femaleRefBase64,
              isMale: false,
            ),
          ),
        ]),
      ),
      icon: Icons.image_rounded,
    );
  }

  Widget _refImageCard({
    required String label,
    required String? base64,
    required bool isMale,
  }) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: base64 != null ? _purple : const Color(0xFFDDDDDD),
          width: base64 != null ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pickRefImage(isMale: isMale),
        child: base64 != null
            ? Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.memory(
                    base64Decode(base64),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isMale) {
                          _maleRefBase64 = null;
                        } else {
                          _femaleRefBase64 = null;
                        }
                      });
                      _saveImage(isMale: isMale, base64: null);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ])
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isMale
                        ? Icons.male_rounded
                        : Icons.female_rounded,
                    color: _purple,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _purple)),
                  const SizedBox(height: 4),
                  const Text('탭하여 업로드',
                      style: TextStyle(
                          fontSize: 10, color: Colors.black38)),
                ],
              ),
      ),
    );
  }

  Future<void> _pickRefImage({required bool isMale}) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 60);
      if (xfile == null || !mounted) return;
      final bytes = await xfile.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() {
        if (isMale) {
          _maleRefBase64 = b64;
        } else {
          _femaleRefBase64 = b64;
        }
      });
      await _saveImage(isMale: isMale, base64: b64);
    } catch (e) {
      if (mounted) _showSnack(loc.groupFormImageError);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 10: 인원별 사이즈
  // ═══════════════════════════════════════════════════════════
  Widget _buildPersonListSection() {
    return _section(
      '${loc.groupFormPersonTotalLabel} · $_totalCount명',
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(children: [
          _buildSizeChart(),
          const SizedBox(height: 12),
          ...List.generate(
            _persons.length,
            (i) => _PersonRowWidget(
              key: ValueKey(_persons[i].hashCode),
              entry: _persons[i],
              index: i,
              onRemove:
                  _persons.length > 1 ? () => _removePerson(i) : null,
              defaultLength: _defaultLength,
              onChanged: () => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addPerson,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text(loc.groupFormAddPerson),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: _purple),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
      ['가슴', '84', '88', '92', '96', '100', '106', '112', '118'],
      ['허리', '68', '72', '76', '80', '84',  '90',  '96',  '102'],
      ['엉덩이', '88', '92', '96', '100', '104', '110', '116', '122'],
    ];

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(children: [
        const Icon(Icons.straighten_rounded, color: _purple, size: 16),
        const SizedBox(width: 6),
        Text(
          loc.groupFormSizeConditionTitle,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _purple),
        ),
      ]),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: const Color(0xFFEEEEEE)),
            defaultColumnWidth: const FixedColumnWidth(50),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: _purple),
                children: ['구분', ...headers]
                    .map((h) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          child: Text(h,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
              ),
              ...rows.map(
                (row) => TableRow(
                  children: row
                      .map((cell) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 4),
                            child: Text(cell,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 11: 기본 정보
  // ═══════════════════════════════════════════════════════════
  Widget _buildBasicInfoSection() {
    return _section(
      loc.groupFormOrderInfoTitle,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(children: [
          if (_hasTeamName) ...[
            _formField(
              controller: _teamNameCtrl,
              label: '단체명 / 팀명 *',
              hint: '예: 2FIT 농구팀',
              icon: Icons.groups_rounded,
            ),
            const SizedBox(height: 10),
          ],
          _formField(
            controller: _managerNameCtrl,
            label: '담당자 이름',
            hint: '예: 홍길동',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 10),
          _formField(
            controller: _phoneCtrl,
            label: '연락처 *',
            hint: '예: 010-1234-5678',
            icon: Icons.phone_rounded,
            type: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _formField(
            controller: _emailCtrl,
            label: '이메일',
            hint: '예: order@team.com',
            icon: Icons.email_rounded,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          // 주소 검색
          GestureDetector(
            onTap: () async {
              final result = await showKakaoAddressSearch(context);
              if (result != null && mounted) {
                setState(() => _address = result.address);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBBBBBB)),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Row(children: [
                const Icon(Icons.location_on_rounded,
                    color: _purple, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _address.isNotEmpty
                        ? _address
                        : loc.groupFormAddressHint,
                    style: TextStyle(
                      fontSize: 14,
                      color: _address.isNotEmpty
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.search_rounded,
                    color: Colors.grey, size: 20),
              ]),
            ),
          ),
        ]),
      ),
      icon: Icons.assignment_ind_rounded,
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _purple, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _purple, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 12: 메모
  // ═══════════════════════════════════════════════════════════
  Widget _buildMemoSection() {
    return _section(
      '메모 / 요청사항',
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: TextFormField(
          controller: _memoCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '특이사항, 요청사항 등을 자유롭게 입력해 주세요.',
            hintStyle: const TextStyle(fontSize: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _purple, width: 2),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ),
      icon: Icons.note_alt_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 13: 독점 디자인
  // ═══════════════════════════════════════════════════════════
  Widget _buildExclusiveDesignSection() {
    return _section(
      '디자인 독점 사용권',
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: _optionTile(
          icon: Icons.workspace_premium_rounded,
          title: '독점 디자인 사용',
          subtitle: '선택 시 동일 디자인을 타 단체에서 사용하지 않습니다',
          badge: '',
          value: _exclusiveDesign,
          onChanged: (v) => setState(() => _exclusiveDesign = v),
        ),
      ),
      icon: Icons.workspace_premium_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 14: 최종 금액 요약
  // ═══════════════════════════════════════════════════════════
  Widget _buildSummarySection() {
    return _section(
      loc.groupFormSummaryTitle,
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A148C), _purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _wSumRow(
              '기본가 (${_fmt(_basePrice.toInt())}원 × $_totalCount명)',
              '${_fmt((_basePrice * _totalCount).toInt())}원',
            ),
            if (_waistbandExtra > 0)
              _wSumRow(
                '허리밴드 옵션 (+${_fmt(_waistbandExtra)}원 × $_totalCount명)',
                '+${_fmt(_waistbandExtra * _totalCount)}원',
              ),
            if (_fabricExtra > 0)
              _wSumRow(
                '원단 추가금 (+${_fmt(_fabricExtra)}원 × $_totalCount명)',
                '+${_fmt(_fabricExtra * _totalCount)}원',
              ),
            if (_discountRate > 0)
              _wSumRow(
                '단체 할인 (${(_discountRate * 100).toInt()}%)',
                '-${_fmt(_discount.toInt())}원',
                highlight: true,
              ),
            _wSumRow('배송비',
                _shipping == 0 ? '무료' : '${_fmt(_shipping.toInt())}원'),
            const Divider(color: Colors.white30, height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              const Text('최종 결제금액',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13)),
              Text(
                '${_fmt(_finalPrice.toInt())}원',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900),
              ),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Icon(Icons.people_alt_rounded,
                  color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                '$_totalCount명 · 단가 ${_fmt(_unitPrice.toInt())}원/명',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11),
              ),
            ]),
          ]),
        ),
      ),
      icon: Icons.calculate_rounded,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 하단 제출 바
  // ═══════════════════════════════════════════════════════════
  Widget _buildSubmitBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // 무료 배송 띠
        if (_totalCount >= AppConstants.groupMinFreeShipping)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.local_shipping_rounded,
                  color: Colors.green, size: 14),
              const SizedBox(width: 4),
              const Text('무료 배송 적용 중',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (_discountRate > 0)
                Text(
                  '${(_discountRate * 100).toInt()}% 단체 할인',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.w700),
                ),
            ]),
          ),
        // 금액 + 버튼
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.people_alt_rounded,
                  size: 14, color: _purple),
              const SizedBox(width: 4),
              Text('$_totalCount명',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
            Text(
              '${_fmt(_finalPrice.toInt())}원',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _purple),
            ),
          ]),
          Row(children: [
            OutlinedButton(
              onPressed: () => _submitOrder(isBuyNow: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: _purple),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('장바구니',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _submitOrder(isBuyNow: true),
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: Text(loc.groupFormBuyNowBtn,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ]),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 인원 데이터 모델
// ══════════════════════════════════════════════════════════════
class _PersonEntry {
  int index;
  final nameCtrl = TextEditingController();
  String? gender;
  String  size   = '';
  String  length = '9부';

  _PersonEntry({required this.index});

  void dispose() => nameCtrl.dispose();
}

// ══════════════════════════════════════════════════════════════
// 인원 행 위젯
// ══════════════════════════════════════════════════════════════
class _PersonRowWidget extends StatefulWidget {
  final _PersonEntry entry;
  final int index;
  final VoidCallback? onRemove;
  final String? defaultLength;
  final VoidCallback onChanged;

  const _PersonRowWidget({
    super.key,
    required this.entry,
    required this.index,
    this.onRemove,
    this.defaultLength,
    required this.onChanged,
  });

  @override
  State<_PersonRowWidget> createState() => _PersonRowWidgetState();
}

class _PersonRowWidgetState extends State<_PersonRowWidget> {
  static const Color _purple  = Color(0xFF6A1B9A);
  static const List<String> _sizes   = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];
  static const List<String> _lengths = ['9부', '5부', '4부', '3부', '2.5부', '숏쇼츠'];

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final accent = e.gender == '남'
        ? Colors.blue.shade700
        : e.gender == '여'
            ? Colors.pink.shade400
            : _purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: e.size.isNotEmpty
              ? accent.withValues(alpha: 0.4)
              : const Color(0xFFE8E8E8),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더 (번호 + 이름 + 성별 + 삭제)
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.center,
              child: Text(
                '${widget.index + 1}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: e.nameCtrl,
                onChanged: (_) => widget.onChanged(),
                decoration: const InputDecoration(
                  hintText: '이름 (선택)',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  isDense: true,
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 13),
              ),
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
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.remove_circle_outline_rounded,
                    color: Colors.red, size: 20),
              ),
            ],
          ]),
        ),
        // 바디: 사이즈 + 길이
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // 사이즈
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(
                width: 40,
                child: Text('사이즈',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: _sizes.map((s) {
                    final sel = e.size == s;
                    return GestureDetector(
                      onTap: () {
                        setState(() => e.size = s);
                        widget.onChanged();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? accent : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: sel
                                  ? accent
                                  : const Color(0xFFCCCCCC)),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : Colors.black54)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            // 길이
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(
                width: 40,
                child: Text('길이',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: _lengths.map((l) {
                    final sel = e.length == l;
                    return GestureDetector(
                      onTap: () {
                        setState(() => e.length = l);
                        widget.onChanged();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel
                              ? Colors.indigo.shade700
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: sel
                                  ? Colors.indigo.shade700
                                  : const Color(0xFFCCCCCC)),
                        ),
                        child: Text(l,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : Colors.black54)),
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

  Widget _gBtn(
      String label, bool sel, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? color : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: sel ? color : const Color(0xFFCCCCCC)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : Colors.grey)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 다이얼 버튼
// ══════════════════════════════════════════════════════════════
class _DialButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color color;

  const _DialButton({
    required this.icon,
    required this.onTap,
    this.onLongPress,
    required this.color,
  });

  @override
  State<_DialButton> createState() => _DialButtonState();
}

class _DialButtonState extends State<_DialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withValues(alpha: 0.2)
              : widget.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: widget.color.withValues(alpha: 0.4)),
        ),
        child: Icon(widget.icon, color: widget.color, size: 26),
      ),
    );
  }
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
