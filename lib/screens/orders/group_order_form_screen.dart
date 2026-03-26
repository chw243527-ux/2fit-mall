import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';

import '../orders/checkout_screen.dart';
import '../../widgets/color_picker_widget.dart';

// ══════════════════════════════════════════════════════════════
// 단체 주문 폼 v6 - 완전 재작성
// ══════════════════════════════════════════════════════════════

class GroupOrderFormScreen extends StatefulWidget {
  final ProductModel? product;
  final bool isAdditionalOrder;
  final int initialPrintType;
  final int initialCount;
  final OrderModel? originalOrder; // 추가주문 시 기존 주문 참조

  const GroupOrderFormScreen({
    super.key,
    this.product,
    this.isAdditionalOrder = false,
    this.initialPrintType = 0,
    this.initialCount = 0,
    this.originalOrder,
  });

  @override
  State<GroupOrderFormScreen> createState() => _GroupOrderFormScreenState();
}

// ── 인원 데이터 ──
class _PersonEntry {
  int index;
  String? gender;
  String sizeType = '성인'; // '성인' or '주니어'

  // 상의/하의 직접 입력 컨트롤러
  final TextEditingController topSizeCtrl    = TextEditingController(); // 상의 사이즈 직접입력
  final TextEditingController bottomSizeCtrl = TextEditingController(); // 하의 사이즈 직접입력

  // 이름
  final TextEditingController nameCtrl    = TextEditingController();

  // 상세 치수 (하의 아래 별도 블록)
  bool   showDetail = false;              // 상세치수 패널 토글
  final TextEditingController heightCtrl = TextEditingController(); // 키
  final TextEditingController weightCtrl = TextEditingController(); // 몸무게
  final TextEditingController waistCtrl  = TextEditingController(); // 허리
  final TextEditingController thighCtrl  = TextEditingController(); // 허벅지

  _PersonEntry({required this.index});

  void dispose() {
    nameCtrl.dispose();
    topSizeCtrl.dispose();
    bottomSizeCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    waistCtrl.dispose();
    thighCtrl.dispose();
  }
}

class _GroupOrderFormScreenState extends State<GroupOrderFormScreen>
    with SingleTickerProviderStateMixin {
  static const Color _purple      = Color(0xFF6A1B9A);
  static const Color _purpleLight = Color(0xFFF3E5F5);
  static const Color _bg          = Color(0xFFF5F5F5);

  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  final _formKey    = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // ── 색상 탭 컨트롤러 ──
  late TabController _colorTabCtrl;
  final _hexCtrl     = TextEditingController();
  String? _hexError;
  Color  _hexPreview = const Color(0xFF6A1B9A);

  // ── 수량 ──
  int  _count        = 5;
  bool _countFixed   = false;

  // ── 인원 목록 ──
  final List<_PersonEntry> _persons = [];

  // ── 인쇄 타입 ──
  late int _printType;

  // ── 색상 ──
  String? _mainColorName;   // 원본 색상 이름
  Color?  _mainColor;       // 원본 색상 (슬라이더 조절 전)
  double  _colorLightness = 0.5;  // 0.0(어두움) ~ 1.0(밝음), 기본 0.5

  /// 원본 색상에 lightness 를 적용한 최종 표시 색상
  Color get _adjustedColor {
    if (_mainColor == null) return Colors.transparent;
    final hsl = HSLColor.fromColor(_mainColor!);
    return hsl.withLightness(_colorLightness.clamp(0.05, 0.95)).toColor();
  }

  /// 농도 설명 텍스트
  String get _lightnessLabel {
    if (_colorLightness < 0.25) return '매우 진하게';
    if (_colorLightness < 0.4)  return '진하게';
    if (_colorLightness < 0.6)  return '기본';
    if (_colorLightness < 0.75) return '밝게';
    return '매우 밝게';
  }

  // ── 원단 ──
  String _fabricType   = '일반 (봉제)';
  String _fabricWeight = '80g';

  // ── 하의 기본 길이 ──
  String? _defaultLength;

  // ── 허리밴드 옵션 ──
  // 0: 기본(변경없음), 1: 단체명만, 2: 색상만, 3: 단체명+색상
  int _waistbandOption = 0;
  String _waistbandColorHex = ''; // 색상변경 선택 시 hex 코드 (#RRGGBB)
  final _waistbandColorCtrl = TextEditingController();

  // ── 참조 이미지 ──
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
  bool _exclusiveDesign = false; // ignore: prefer_final_fields

  // ══ 파생값 ══
  bool get _isAdditional   => widget.isAdditionalOrder;
  int  get _totalCount     => _persons.length;
  bool get _hasColorChange => _printType == 0 || _printType == 2 || _printType == 3;
  bool get _hasTeamName    => _printType == 1 || _printType == 2 || _printType == 3;

  bool get _nameEnabled    => _totalCount >= 10;
  OrderModel? get _originalOrder => widget.originalOrder;

  /// 허리밴드 옵션 레이블
  String get _waistbandOptionLabel {
    switch (_waistbandOption) {
      case 1: return '단체명 변경';
      case 2: return '색상 변경';
      case 3: return '단체명+색상 변경';
      default: return '기본 (변경없음)';
    }
  }

  int    get _fabricExtra  => AppConstants.fabricTypePrices[_fabricType] ?? 0;
  double get _basePrice    => widget.product?.price ?? 0.0;
  double get _unitPrice    => _basePrice + _fabricExtra;
  double get _subTotal     => _unitPrice * _totalCount;
  double get _shipping     =>
      _totalCount >= AppConstants.groupMinFreeShipping
          ? 0
          : AppConstants.groupAdditionalShippingFee.toDouble();
  double get _finalPrice   => _subTotal + _shipping;

  String _fmt(num v) => v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ══ 생명주기 ══
  @override
  void initState() {
    super.initState();
    _printType = widget.initialPrintType.clamp(0, 3);
    if (widget.initialCount >= 5) {
      _count     = widget.initialCount;
      _countFixed = true;
      for (int i = 0; i < _count; i++) {
        _persons.add(_PersonEntry(index: i));
      }
    }
    _loadSavedImages();
    _colorTabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _colorTabCtrl.dispose();
    _hexCtrl.dispose();
    _scrollCtrl.dispose();
    _teamNameCtrl.dispose();
    _managerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _memoCtrl.dispose();
    _waistbandColorCtrl.dispose();
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

  void _confirmCount() {
    if (_count < 1) return;
    setState(() {
      _countFixed = true;
      while (_persons.length < _count) {
        _persons.add(_PersonEntry(index: _persons.length));
      }
      while (_persons.length > _count) {
        _persons.last.dispose();
        _persons.removeLast();
      }
      for (int i = 0; i < _persons.length; i++) { _persons[i].index = i; }
    });
  }

  void _addPerson() {
    setState(() {
      _persons.add(_PersonEntry(index: _persons.length));
      _count = _persons.length;
    });
  }

  void _removePerson(int idx) {
    if (_persons.length <= 1) return;
    setState(() {
      _persons[idx].dispose();
      _persons.removeAt(idx);
      for (int i = 0; i < _persons.length; i++) { _persons[i].index = i; }
      _count = _persons.length;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  bool _validate() {
    final minQty = _isAdditional ? 1 : 5;
    if (_totalCount < minQty) {
      _showSnack('최소 $minQty명 이상 주문 가능합니다.');
      return false;
    }
    if (_mainColorName == null || _mainColorName!.isEmpty) {
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
    if (_defaultLength == null) {
      _showSnack('하의 길이를 선택해 주세요.');
      return false;
    }
    for (int i = 0; i < _persons.length; i++) {
      final p = _persons[i];
      if (p.gender == null) {
        _showSnack('${i + 1}번 인원의 성별을 선택해 주세요.');
        return false;
      }
      // 상의 사이즈 확인
      if (p.topSizeCtrl.text.trim().isEmpty) {
        _showSnack('${i + 1}번 인원의 상의 사이즈를 입력해 주세요.');
        return false;
      }
      // 하의 사이즈 확인
      if (p.bottomSizeCtrl.text.trim().isEmpty) {
        _showSnack('${i + 1}번 인원의 하의 사이즈를 입력해 주세요.');
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
      'orderType'      : _isAdditional ? 'additional' : 'group',
      'originalOrderId': _isAdditional && _originalOrder != null ? _originalOrder!.id : null,
      'originalOrderDate': _isAdditional && _originalOrder != null ? _originalOrder!.createdAt.toIso8601String() : null,
      'originalTeamName': _isAdditional && _originalOrder != null ? (_originalOrder!.customOptions?['teamName'] ?? _originalOrder!.groupName ?? '') : null,
      'originalTotalCount': _isAdditional && _originalOrder != null ? (_originalOrder!.groupCount ?? 0) : null,
      'originalStatus': _isAdditional && _originalOrder != null ? _originalOrder!.status.name : null,
      'printType'      : _printType,
      'mainColor'      : _mainColorName,
      'adjustedColorHex': '#${_adjustedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'colorLightness' : _colorLightness,
      'colorTone'      : _lightnessLabel,
      'fabric'       : _fabricType,
      'weight'       : _fabricWeight,
      'defaultLength': _defaultLength,
      'waistbandOption' : _waistbandOptionLabel,
      'waistbandColorHex': (_waistbandOption == 2 || _waistbandOption == 3)
          ? _waistbandColorHex : '',
      'exclusive'    : _exclusiveDesign,
      'teamName'     : _teamNameCtrl.text.trim(),
      'manager'      : _managerNameCtrl.text.trim(),
      'address'      : _address,
      'maleRef'      : _maleRefBase64 != null,
      'femaleRef'    : _femaleRefBase64 != null,
      'persons'      : _persons.map((p) => <String, dynamic>{
        'index'     : p.index,
        'name'      : _nameEnabled ? p.nameCtrl.text.trim() : '', // 10명 미만은 이름 저장 안 함
        'gender'    : p.gender,
        'sizeType'  : p.sizeType,
        'topSize'   : p.topSizeCtrl.text.trim(),
        'bottomSize': p.bottomSizeCtrl.text.trim(),
        'length'    : _defaultLength, // 전원 동일 길이 (개별 선택 불가)
        'height'    : p.heightCtrl.text.trim(),
        'weight'    : p.weightCtrl.text.trim(),
        'waist'     : p.waistCtrl.text.trim(),
        'thigh'     : p.thighCtrl.text.trim(),
        'hasCustomMeasure': p.showDetail,
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

    final cart = context.read<CartProvider>();
    if (isBuyNow) {
      cart.clearCart();
      cart.addItem(product, '단체', _mainColorName ?? '기본',
          quantity: _totalCount,
          extraPrice: _fabricExtra.toDouble(),
          customOptions: customOptions);
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CheckoutScreen(cart: cart)));
    } else {
      // 장바구니에 담기 (기존 아이템 유지, 단체 상품 추가)
      cart.addItem(product, '단체', _mainColorName ?? '기본',
          quantity: _totalCount,
          extraPrice: _fabricExtra.toDouble(),
          customOptions: customOptions);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('장바구니에 담았습니다. ($_totalCount명 / ${_fmt(_finalPrice)}원)')),
          ]),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: '장바구니 보기',
            textColor: const Color(0xFFFFD600),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ),
      );
    }
  }

  // ══ build ══
  @override
  Widget build(BuildContext context) {
    final title = _isAdditional ? '추가 제작 주문서' : '단체 주문서';
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(title,
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
              _buildCountSection(),
              if (_countFixed) ...[
                _buildPrintTypeSection(),
                if (widget.product != null) _buildProductCard(),
                _buildFabricSection(),
                _buildLengthSection(),
                _buildWaistbandSection(),
                _buildColorSection(),
                _buildRefImageSection(),
                _buildPersonListSection(),
                _buildBasicInfoSection(),
                _buildMemoSection(),
                _buildSummarySection(),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _countFixed ? _buildBottomBar() : null,
    );
  }

  // ══════════════════════════════════════════════
  // 헤더 배너
  // ══════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.groups_rounded, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(_isAdditional ? '추가 제작 주문' : '단체 커스텀 주문',
            style: const TextStyle(color: Colors.white,
                fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('아래 폼을 작성하여 주문을 완료해 주세요.',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 수량 섹션
  // ══════════════════════════════════════════════
  Widget _buildCountSection() {
    return _card(
      title: '주문 수량',
      icon: Icons.people_outline_rounded,
      child: Column(children: [
        // 수량 조절
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _countBtn(Icons.remove_rounded, () {
            if (_count > 1) setState(() => _count--);
          }),
          Container(
            width: 80,
            alignment: Alignment.center,
            child: Text('$_count명',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: _purple)),
          ),
          _countBtn(Icons.add_rounded, () {
            setState(() => _count++);
          }),
        ]),
        const SizedBox(height: 4),
        const Text('최소 5명 이상 주문 가능합니다.',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),
        if (!_countFixed)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _count >= 1 ? _confirmCount : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text('$_count명으로 주문서 작성하기',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _purpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle_rounded, color: _purple, size: 18),
              const SizedBox(width: 8),
              Text('$_totalCount명 확정',
                  style: const TextStyle(color: _purple,
                      fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
          ),
      ]),
    );
  }

  Widget _countBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _purpleLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _purple, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 인쇄 타입 섹션
  // ══════════════════════════════════════════════
  Widget _buildPrintTypeSection() {
    final options = [
      {'id': 0, 'title': '색상 변경만', 'desc': '단체 색상만 커스텀'},
      {'id': 1, 'title': '전면 단체명', 'desc': '앞면 단체명 인쇄 (10명↑)'},
      {'id': 2, 'title': '전면 + 색상', 'desc': '단체명 + 색상 변경'},
      {'id': 3, 'title': '전면+색상+후면이름', 'desc': '풀 커스텀 (10명↑)'},
    ];
    return _card(
      title: '인쇄 타입',
      icon: Icons.print_rounded,
      child: Column(
        children: options.map((opt) {
          final id   = opt['id'] as int;
          final isSel = _printType == id;
          return GestureDetector(
            onTap: () => setState(() => _printType = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSel ? _purpleLight : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSel ? _purple : Colors.grey.shade200,
                  width: isSel ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(isSel ? Icons.radio_button_checked_rounded
                           : Icons.radio_button_unchecked_rounded,
                    color: isSel ? _purple : Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(opt['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14,
                          color: isSel ? _purple : Colors.black87,
                        )),
                    Text(opt['desc'] as String,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ]),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 선택 상품 카드
  // ══════════════════════════════════════════════
  Widget _buildProductCard() {
    final p = widget.product!;

    // 디자인 이미지 우선, 없으면 s1(메인배너), 없으면 images.first
    final designImgs = p.sectionImages['design'] ?? [];
    final s1Imgs     = p.sectionImages['s1'] ?? [];
    final imgUrl     = designImgs.isNotEmpty
        ? designImgs.first
        : s1Imgs.isNotEmpty
            ? s1Imgs.first
            : (p.images.isNotEmpty ? p.images.first : null);

    return _card(
      title: '선택 상품',
      icon: Icons.shopping_bag_outlined,
      child: Row(children: [
        // 이미지 (더 크게, 디자인 이미지 표시)
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imgUrl != null
              ? Image.network(
                  imgUrl,
                  width: 72, height: 72, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _productImgPlaceholder(),
                )
              : _productImgPlaceholder(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            Text(p.category,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${_fmt(p.price)}원',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: _purple, fontSize: 15)),
              Text('/인',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _productImgPlaceholder() {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.checkroom_outlined, color: Colors.grey.shade400, size: 28),
    );
  }

  // ══════════════════════════════════════════════
  // 원단 섹션
  // ══════════════════════════════════════════════
  Widget _buildFabricSection() {
    final types   = AppConstants.fabricTypes;
    final weights = AppConstants.fabricWeights;
    return _card(
      title: '원단 선택',
      icon: Icons.layers_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('원단 종류', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: types.map((t) {
          final isSel = _fabricType == t;
          final extra = AppConstants.fabricTypePrices[t] ?? 0;
          return ChoiceChip(
            label: Text('$t${extra > 0 ? ' (+${_fmt(extra)}원)' : ''}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : Colors.black87)),
            selected: isSel,
            onSelected: (_) => setState(() => _fabricType = t),
            selectedColor: _purple,
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(color: isSel ? _purple : Colors.grey.shade300),
            showCheckmark: false,
          );
        }).toList()),
        const SizedBox(height: 12),
        const Text('무게', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: weights.map((w) {
          final isSel = _fabricWeight == w;
          return ChoiceChip(
            label: Text(w,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : Colors.black87)),
            selected: isSel,
            onSelected: (_) => setState(() => _fabricWeight = w),
            selectedColor: _purple,
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(color: isSel ? _purple : Colors.grey.shade300),
            showCheckmark: false,
          );
        }).toList()),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 허리밴드 옵션 섹션
  // ══════════════════════════════════════════════
  Widget _buildWaistbandSection() {
    const options = [
      {'id': 0, 'label': '기본 (변경없음)', 'icon': Icons.remove_circle_outline},
      {'id': 1, 'label': '단체명 변경',     'icon': Icons.text_fields},
      {'id': 2, 'label': '색상 변경',       'icon': Icons.palette},
      {'id': 3, 'label': '단체명+색상',     'icon': Icons.auto_awesome},
    ];
    final needsColor = _waistbandOption == 2 || _waistbandOption == 3;

    return _card(
      title: '허리밴드 옵션',
      icon: Icons.style_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 안내 문구
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 14, color: Color(0xFFE65100)),
            const SizedBox(width: 6),
            Expanded(child: Text(
              '단체명/색상 변경 시 추가 비용이 발생할 수 있습니다.',
              style: const TextStyle(fontSize: 11, color: Color(0xFFE65100)),
            )),
          ]),
        ),
        // 옵션 버튼들
        Wrap(spacing: 8, runSpacing: 8, children: options.map((opt) {
          final id = opt['id'] as int;
          final label = opt['label'] as String;
          final isSel = _waistbandOption == id;
          return GestureDetector(
            onTap: () => setState(() {
              _waistbandOption = id;
              if (id != 2 && id != 3) _waistbandColorHex = '';
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSel ? _purple : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSel ? _purple : Colors.grey.shade300, width: 1.5),
                boxShadow: isSel
                    ? [BoxShadow(color: _purple.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (isSel) const Icon(Icons.check_circle, color: Colors.white, size: 14),
                if (isSel) const SizedBox(width: 4),
                Text(label, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : Colors.black87,
                )),
              ]),
            ),
          );
        }).toList()),

        // 색상 hex 입력 필드 (색상 변경 선택 시만 표시)
        if (needsColor) ...[
          const SizedBox(height: 14),
          const Text('허리밴드 색상 HEX 코드',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
          const SizedBox(height: 6),
          Row(children: [
            // 미리보기 박스
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _waistbandColorHex.length == 7
                    ? _parseHexColor(_waistbandColorHex)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _waistbandColorHex.length != 7
                  ? Icon(Icons.palette_outlined, color: Colors.grey.shade400, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _waistbandColorCtrl,
                maxLength: 7,
                decoration: InputDecoration(
                  hintText: '#1A1A1A  (예: #FF0000)',
                  counterText: '',
                  prefixText: _waistbandColorCtrl.text.isEmpty ? '#' : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _purple, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                onChanged: (v) {
                  String hex = v.trim();
                  if (!hex.startsWith('#')) hex = '#$hex';
                  if (hex.length <= 7) {
                    setState(() => _waistbandColorHex = hex.length == 7 ? hex : '');
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            '6자리 HEX 코드를 입력하세요 (예: #1245A8)',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          // 2FIT 팔레트 색상 빠른 선택
          const SizedBox(height: 10),
          const Text('빠른 선택 (2FIT 팔레트)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children:
            AppConstants.twoFitColors.map((c) {
              final hexVal = '#${(c['hex'] as int).toRadixString(16).substring(2).toUpperCase()}';
              final isSelected = _waistbandColorHex.toUpperCase() == hexVal.toUpperCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _waistbandColorHex = hexVal;
                    _waistbandColorCtrl.text = hexVal;
                  });
                },
                child: Tooltip(
                  message: '${c['name']} $hexVal',
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Color(c['hex'] as int),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? _purple : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: _purple.withValues(alpha: 0.4), blurRadius: 4)]
                          : [],
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 14,
                            color: _isLightColor(Color(c['hex'] as int))
                                ? Colors.black : Colors.white)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ]),
    );
  }

  /// 색상이 밝은지 판단 (UI 글자색 결정용)
  static bool _isLightColor(Color color) {
    final r = color.r * 255;
    final g = color.g * 255;
    final b = color.b * 255;
    return (r * 299 + g * 587 + b * 114) / 1000 >= 128;
  }

  /// hex 문자열을 Color로 변환
  static Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  // ══════════════════════════════════════════════
  // 색상 섹션
  // ══════════════════════════════════════════════
  Widget _buildColorSection() {
    return _card(
      title: '색상 선택 *',
      icon: Icons.palette_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ① 안내 문구
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: Colors.blue.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '기성 19색 중 선택하거나, 추가 색상 / HEX 코드로 원하는 색상을 지정하세요.',
                style: TextStyle(fontSize: 11, color: Colors.blue.shade700, height: 1.4),
              ),
            ),
          ]),
        ),

        // ② 선택된 색상 표시 배너 + 농도 조절 슬라이더
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _mainColorName != null
              ? _buildColorAdjustPanel()
              : const SizedBox.shrink(),
        ),

        // ③ 탭바
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TabBar(
            controller: _colorTabCtrl,
            indicator: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [BoxShadow(color: _purple.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            tabs: const [
              Tab(text: '기성 19색'),
              Tab(text: '추가 색상'),
              Tab(text: 'HEX 입력'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ④ 탭 콘텐츠
        SizedBox(
          height: 320,
          child: TabBarView(
            controller: _colorTabCtrl,
            children: [
              _buildRegisteredColors(),
              _buildExtendedColors(),
              _buildHexInput(),
            ],
          ),
        ),
      ]),
    );
  }

  // ── 색상 선택 후 농도 조절 패널
  Widget _buildColorAdjustPanel() {
    final adjusted   = _adjustedColor;
    final isLight    = adjusted.computeLuminance() > 0.5;
    final hsl        = _mainColor != null ? HSLColor.fromColor(_mainColor!) : null;

    // 그라디언트 바 색상 (원본 색상을 유지하면서 lightness만 변화)
    final darkColor  = hsl?.withLightness(0.08).toColor() ?? Colors.black;
    final baseColor  = hsl?.withLightness(hsl.lightness).toColor() ?? (_mainColor ?? Colors.grey);
    final lightColor = hsl?.withLightness(0.95).toColor() ?? Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: adjusted.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── 색상 미리보기 바 (큰 프리뷰)
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: adjusted,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            // 원본 vs 조절 후 비교
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _mainColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 14,
                color: isLight ? Colors.black38 : Colors.white54),
            const SizedBox(width: 4),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: adjusted,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
              ),
              child: Icon(Icons.check_rounded, size: 18,
                  color: isLight ? Colors.black87 : Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_mainColorName ?? '',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900,
                      color: isLight ? Colors.black87 : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis),
                Text(
                  '#${adjusted.toARGB32().toRadixString(16).substring(2).toUpperCase()}  ·  $_lightnessLabel',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: isLight ? Colors.black54 : Colors.white70,
                  ),
                ),
              ]),
            ),
            // 선택 취소
            GestureDetector(
              onTap: () => setState(() {
                _mainColorName  = null;
                _mainColor      = null;
                _colorLightness = 0.5;
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 15,
                    color: isLight ? Colors.black87 : Colors.white),
              ),
            ),
          ]),
        ),

        // ── 농도 슬라이더
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 라벨
            Row(children: [
              Icon(Icons.tune_rounded, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 5),
              Text('농도 조절',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: adjusted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: adjusted.withValues(alpha: 0.3)),
                ),
                child: Text(_lightnessLabel,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: adjusted.withValues(alpha: 0.9),
                    )),
              ),
            ]),
            const SizedBox(height: 8),

            // 그라디언트 트랙 + 슬라이더
            Stack(children: [
              // 그라디언트 배경 바
              Positioned(
                left: 0, right: 0,
                top: 18, // 슬라이더 thumb 중앙에 맞춤
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      colors: [darkColor, baseColor, lightColor],
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3)],
                  ),
                ),
              ),
              // 슬라이더 (투명 트랙, thumb만 보임)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 0,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayColor: adjusted.withValues(alpha: 0.2),
                  thumbColor: adjusted,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                ),
                child: Slider(
                  value: _colorLightness,
                  min: 0.05,
                  max: 0.95,
                  onChanged: (v) => setState(() => _colorLightness = v),
                ),
              ),
            ]),
            const SizedBox(height: 4),

            // 양 끝 라벨
            Row(children: [
              Text('어둡게', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('밝게', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ]),
    );
  }

  // 탭1: 기성품 19색
  Widget _buildRegisteredColors() {
    final colors = AppColorPalette.registeredColors;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 상단: 스와치 그리드
        Wrap(
          spacing: 6,
          runSpacing: 10,
          children: colors.map((c) {
            final name    = c['name'] as String;
            final code    = c['code'] as String;
            final color   = Color(c['hex'] as int);
            final isSel   = _mainColorName == name;
            final isLight = color.computeLuminance() > 0.6;
            // 표시용 짧은 이름
            final displayName = name.contains('(') 
                ? name.substring(name.indexOf('(') + 1, name.indexOf(')'))
                : name;
            return GestureDetector(
              onTap: () => setState(() {
                _mainColorName    = name;
                _mainColor        = color;
                _colorLightness   = HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                decoration: BoxDecoration(
                  color: isSel ? _purpleLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? _purple : Colors.grey.shade200,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // 원형 스와치
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? _purple : (isLight ? Colors.grey.shade300 : Colors.transparent),
                            width: isSel ? 2.5 : 1,
                          ),
                          boxShadow: isSel
                              ? [const BoxShadow(color: Color(0x446A1B9A), blurRadius: 8, spreadRadius: 1)]
                              : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3)],
                        ),
                      ),
                      if (isSel)
                        Icon(Icons.check_rounded, size: 18,
                            color: isLight ? Colors.black87 : Colors.white),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 코드
                  Text(code,
                      style: TextStyle(
                        fontSize: 9.5, fontWeight: FontWeight.w900,
                        color: isSel ? _purple : Colors.black54,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center),
                  // 이름
                  Text(displayName,
                      style: TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w500,
                        color: isSel ? _purple.withValues(alpha: 0.8) : Colors.black38,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        // 하단: 선택 안내
        Center(
          child: Text(
            '총 ${colors.length}가지 기성 색상 • 탭하여 선택',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ),
      ]),
    );
  }

  // 탭2: 추가 색상 (확장 팔레트)
  Widget _buildExtendedColors() {
    final extended = AppColorPalette.extendedPalette;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 안내
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '${extended.length}가지 확장 색상 팔레트 • 원하는 색상을 탭하세요',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ),
      // 팔레트 그리드
      Expanded(
        child: GridView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1.0,
          ),
          itemCount: extended.length,
          itemBuilder: (_, i) {
            final color   = extended[i];
            final hexStr  = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
            final isSel   = _mainColor?.toARGB32() == color.toARGB32() && _mainColorName != null &&
                            !AppColorPalette.registeredColors.any((c) => c['name'] == _mainColorName);
            final isLight = color.computeLuminance() > 0.6;
            return GestureDetector(
              onTap: () => setState(() {
                _mainColorName  = '확장 ($hexStr)';
                _mainColor      = color;
                _colorLightness = HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSel ? Colors.white : Colors.transparent,
                    width: isSel ? 2.5 : 0,
                  ),
                  boxShadow: isSel
                      ? [const BoxShadow(color: Colors.black38, blurRadius: 5, spreadRadius: 1)]
                      : [],
                ),
                child: isSel
                    ? Icon(Icons.check_rounded, size: 11,
                        color: isLight ? Colors.black87 : Colors.white)
                    : null,
              ),
            );
          },
        ),
      ),
    ]);
  }

  // 탭3: HEX 직접 입력
  Widget _buildHexInput() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 미리보기
      Container(
        height: 56,
        decoration: BoxDecoration(
          color: _hexPreview,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            '#${_hexPreview.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2,
              color: _hexPreview.computeLuminance() > 0.4 ? Colors.black87 : Colors.white,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      // 입력 필드
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text('#', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black54)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: _hexCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: 'RRGGBB (예: FF6B35)',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1),
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              errorText: _hexError,
              errorStyle: const TextStyle(fontSize: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _purple, width: 1.5)),
            ),
            onChanged: (v) {
              if (v.length == 6) {
                try {
                  final color = Color(int.parse('FF$v', radix: 16));
                  setState(() {
                    _hexPreview = color;
                    _hexError   = null;
                  });
                } catch (_) {
                  setState(() => _hexError = '올바른 HEX 코드를 입력하세요');
                }
              } else {
                setState(() => _hexError = null);
              }
            },
            onSubmitted: (_) => _applyHex(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _applyHex,
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('적용', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
      const SizedBox(height: 12),
      // 안내
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, size: 14, color: Colors.orange),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              '원하시는 색상의 HEX 코드를 6자리로 입력하세요.\n예) 빨강: FF0000 / 파랑: 0000FF / 노랑: FFFF00',
              style: TextStyle(fontSize: 11, color: Colors.orange, height: 1.5),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      // 자주 쓰는 커스텀 색상 예시
      const Text('자주 쓰는 색상', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8, runSpacing: 6,
        children: [
          {'name': '코발트블루', 'hex': '0047AB'},
          {'name': '라벤더',    'hex': 'E6CCFF'},
          {'name': '카멜',      'hex': 'C19A6B'},
          {'name': '민트',      'hex': '26C9A0'},
          {'name': '버건디',    'hex': '6D0E19'},
          {'name': '골드',      'hex': 'D4AF37'},
        ].map((item) {
          final hexStr = item['hex']!;
          final color  = Color(int.parse('FF$hexStr', radix: 16));
          final isLight = color.computeLuminance() > 0.5;
          final isSel  = _mainColorName == item['name'];
          return GestureDetector(
            onTap: () {
              _hexCtrl.text = hexStr;
              setState(() {
                _hexPreview     = color;
                _mainColorName  = item['name'];
                _mainColor      = color;
                _colorLightness = HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
                _hexError       = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? color : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSel ? _purple : color.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 12, height: 12,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)))),
                const SizedBox(width: 5),
                Text(item['name']!,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: isSel ? (isLight ? Colors.black87 : Colors.white) : Colors.black87)),
              ]),
            ),
          );
        }).toList(),
      ),
    ]));
  }

  void _applyHex() {
    final v = _hexCtrl.text.trim().replaceAll('#', '');
    if (v.length != 6) {
      setState(() => _hexError = 'HEX 코드는 6자리입니다 (예: FF6B35)');
      return;
    }
    try {
      final color = Color(int.parse('FF$v', radix: 16));
      setState(() {
        _hexPreview     = color;
        _mainColorName  = '커스텀 (#${v.toUpperCase()})';
        _mainColor      = color;
        _colorLightness = HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
        _hexError       = null;
      });
    } catch (_) {
      setState(() => _hexError = '올바른 HEX 코드를 입력하세요');
    }
  }

  // ══════════════════════════════════════════════
  // 하의 길이 섹션
  // ══════════════════════════════════════════════
  Widget _buildLengthSection() {
    final lengths = AppConstants.bottomLengths;
    return _card(
      title: '하의 기본 길이',
      icon: Icons.straighten_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: lengths.map((l) {
          final label = l['label']!;
          final desc  = l['desc']!;
          final isSel = _defaultLength == label;
          return GestureDetector(
            onTap: () => setState(() => _defaultLength = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? _purple : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isSel ? _purple : Colors.grey.shade300),
              ),
              child: Column(children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13,
                        color: isSel ? Colors.white : Colors.black87)),
                Text(desc,
                    style: TextStyle(
                        fontSize: 10,
                        color: isSel ? Colors.white70 : Colors.grey)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 참조 이미지 섹션
  // ══════════════════════════════════════════════
  Widget _buildRefImageSection() {
    return _card(
      title: '참조 이미지 (선택)',
      icon: Icons.image_outlined,
      child: Row(children: [
        Expanded(child: _refImageCard(isMale: true)),
        const SizedBox(width: 12),
        Expanded(child: _refImageCard(isMale: false)),
      ]),
    );
  }

  Widget _refImageCard({required bool isMale}) {
    final b64   = isMale ? _maleRefBase64 : _femaleRefBase64;
    final label = isMale ? '남성 참조' : '여성 참조';
    final color = isMale ? Colors.blue.shade50 : Colors.pink.shade50;
    final borderColor = isMale ? Colors.blue.shade200 : Colors.pink.shade200;
    final iconColor   = isMale ? Colors.blue : Colors.pink;

    return GestureDetector(
      onTap: () => _pickRefImage(isMale: isMale),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: b64 != null ? null : color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          image: b64 != null
              ? DecorationImage(
                  image: MemoryImage(base64Decode(b64)),
                  fit: BoxFit.cover)
              : null,
        ),
        child: b64 != null
            ? Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isMale) _maleRefBase64 = null;
                      else _femaleRefBase64 = null;
                    });
                    _saveImage(isMale: isMale, base64: null);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              )
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: iconColor, size: 30),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(color: iconColor,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }

  Future<void> _pickRefImage({required bool isMale}) async {
    try {
      final picker = ImagePicker();
      final xfile  = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (xfile == null) return;
      final bytes  = await xfile.readAsBytes();
      final b64    = base64Encode(bytes);
      if (!mounted) return;
      setState(() {
        if (isMale) _maleRefBase64   = b64;
        else         _femaleRefBase64 = b64;
      });
      await _saveImage(isMale: isMale, base64: b64);
    } catch (e) {
      _showSnack('이미지 선택 오류: $e');
    }
  }

  // ══════════════════════════════════════════════
  // 인원별 사이즈 섹션
  // ══════════════════════════════════════════════
  // ─── 인원 목록 헬퍼 ────────────────────────────

  Widget _buildPersonListSection() {
    return _card(
      title: '인원별 사이즈 (총 $_totalCount명)',
      icon: Icons.format_list_numbered_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── 색상 통일 안내 배너
        if (_mainColorName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _purpleLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _purple.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              // 원본 → 조절 후 비교
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: _mainColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.black38),
              const SizedBox(width: 3),
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: _adjustedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(text: TextSpan(
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  children: [
                    const TextSpan(text: '전체 색상 통일: ',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                    TextSpan(text: _mainColorName!,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: _purple)),
                    TextSpan(text: '  ·  $_lightnessLabel',
                        style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                )),
              ),
            ]),
          ),
        ],

        // ── 하의 길이 통일 안내 배너
        if (_defaultLength != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(children: [
              Icon(Icons.straighten_rounded, size: 16, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              Text('하의 길이 통일: ', style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
              Text(_defaultLength!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.teal.shade800)),
              Text(' (전원 동일)', style: TextStyle(fontSize: 10, color: Colors.teal.shade500)),
            ]),
          ),
        ],

        // ── 사이즈 표 (접기/펴기)
        _buildSizeTable(),
        const SizedBox(height: 12),

        // ── 인원 목록
        ...List.generate(_persons.length, (i) => _personRow(_persons[i], i)),
        const SizedBox(height: 8),

        // ── 인원 추가 버튼
        Center(
          child: OutlinedButton.icon(
            onPressed: _addPerson,
            icon: const Icon(Icons.person_add_outlined, size: 18, color: _purple),
            label: const Text('인원 추가', style: TextStyle(color: _purple, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _purple, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          ),
        ),
      ]),
    );
  }

  // ── 사이즈 참고표 (접기/펴기)
  bool _sizeTableExpanded = false;

  Widget _buildSizeTable() {
    // 상의 기준 사이즈 표
    final headers = ['사이즈', '키(cm)', '몸무게(kg)', '가슴(cm)', '허리(cm)'];
    final rows = [
      ['XS',  '154~159', '44~51',  '85 cm',  '68 cm'],
      ['S',   '160~165', '52~60',  '90 cm',  '72 cm'],
      ['M',   '166~172', '61~71',  '95 cm',  '76 cm'],
      ['L',   '172~177', '72~78',  '100 cm', '80 cm'],
      ['XL',  '177~182', '79~85',  '105 cm', '84 cm'],
      ['2XL', '182~187', '86~91',  '110 cm', '88 cm'],
      ['3XL', '187~191', '91~96',  '115 cm', '92 cm'],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 헤더 토글
      GestureDetector(
        onTap: () => setState(() => _sizeTableExpanded = !_sizeTableExpanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _sizeTableExpanded ? _purple.withValues(alpha: 0.07) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _sizeTableExpanded ? _purple.withValues(alpha: 0.2) : Colors.grey.shade200),
          ),
          child: Row(children: [
            Icon(Icons.table_chart_outlined, size: 15,
                color: _sizeTableExpanded ? _purple : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text('사이즈 참고표 보기',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: _sizeTableExpanded ? _purple : Colors.grey.shade600,
                )),
            const Spacer(),
            Icon(_sizeTableExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: _sizeTableExpanded ? _purple : Colors.grey.shade400),
          ]),
        ),
      ),
      if (_sizeTableExpanded) ...[
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade100),
                verticalInside: BorderSide(color: Colors.grey.shade100),
              ),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _purple.withValues(alpha: 0.08)),
                  children: headers.map((h) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text(h, style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800, color: _purple)),
                  )).toList(),
                ),
                ...rows.map((r) => TableRow(
                  children: r.map((cell) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(cell, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  )).toList(),
                )),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 12, color: Colors.orange),
            SizedBox(width: 5),
            Expanded(child: Text(
              '위 사이즈에 해당하지 않으면 \'상세치수 입력\'을 선택해 주세요.',
              style: TextStyle(fontSize: 10, color: Colors.orange),
            )),
          ]),
        ),
      ],
    ]);
  }

  // ── 인원 한 줄 카드
  Widget _personRow(_PersonEntry p, int idx) {
    final isMale   = p.gender == 'male';
    final isFemale = p.gender == 'female';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.gender == null ? Colors.grey.shade200 : _purple.withValues(alpha: 0.25),
          width: p.gender == null ? 1 : 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── 헤더 행 (번호 / 이름 / 성별 / 삭제)
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: p.gender == null
                ? Colors.grey.shade50
                : (isMale ? Colors.blue.shade50 : Colors.pink.shade50),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            // 번호 뱃지
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: p.gender == null ? Colors.grey.shade400
                    : (isMale ? Colors.blue : Colors.pink),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${idx + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            // 이름 (10명 이상일 때만 입력 가능)
            Expanded(
              child: Tooltip(
                message: _nameEnabled ? '' : '10명 이상일 때 이름 입력 가능',
                child: TextField(
                  controller: p.nameCtrl,
                  enabled: _nameEnabled,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _nameEnabled ? Colors.black87 : Colors.grey.shade400,
                  ),
                  decoration: InputDecoration(
                    hintText: _nameEnabled ? '이름 입력' : '10명 이상 시 입력',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    filled: true,
                    fillColor: _nameEnabled ? Colors.white : Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: _purple, width: 1.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 성별 버튼
            _genderBtn('남', isMale, Colors.blue, () => setState(() => p.gender = 'male')),
            const SizedBox(width: 5),
            _genderBtn('여', isFemale, Colors.pink, () => setState(() => p.gender = 'female')),
            const SizedBox(width: 8),
            // 삭제
            GestureDetector(
              onTap: () => _removePerson(idx),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.red.shade400, size: 16),
              ),
            ),
          ]),
        ),

        // ── 본문 (사이즈 입력)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ① 성인/주니어 구분 선택
            Row(children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF6A1B9A)),
              const SizedBox(width: 5),
              const Text('사이즈 구분', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const SizedBox(width: 10),
              _sizeTypeBtn('성인', p, Colors.indigo),
              const SizedBox(width: 6),
              _sizeTypeBtn('주니어', p, Colors.teal),
            ]),
            const SizedBox(height: 8),

            // ② 상의 사이즈 직접입력
            _sizeInputField(
              label: '상의 사이즈',
              icon: Icons.checkroom_outlined,
              ctrl: p.topSizeCtrl,
              hint: p.sizeType == '주니어' ? '예) 110, 120, 130, 140 등' : '예) M, L, XL, 95 등',
            ),
            const SizedBox(height: 10),

            // ③ 하의 사이즈 직접입력
            _sizeInputField(
              label: '하의 사이즈',
              icon: Icons.accessibility_new_rounded,
              ctrl: p.bottomSizeCtrl,
              hint: p.sizeType == '주니어' ? '예) 110, 120, 130, 140 등' : '예) M, L, XL, 95 등',
            ),
            const SizedBox(height: 10),

            // ③ 상세치수 토글 버튼 (하의 바로 아래 별도 블록)
            GestureDetector(
              onTap: () => setState(() => p.showDetail = !p.showDetail),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: p.showDetail ? Colors.orange.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: p.showDetail ? Colors.orange.shade300 : Colors.grey.shade300,
                    width: p.showDetail ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.straighten_rounded, size: 14,
                      color: p.showDetail ? Colors.orange.shade700 : Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text('상세 치수 입력',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: p.showDetail ? Colors.orange.shade800 : Colors.grey.shade600,
                      )),
                  const SizedBox(width: 5),
                  Text('(사이즈 미해당 시)',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  const Spacer(),
                  Icon(p.showDetail ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: p.showDetail ? Colors.orange.shade600 : Colors.grey.shade400),
                ]),
              ),
            ),

            // ③-1 상세치수 패널 (키·몸무게·허리·허벅지)
            if (p.showDetail) ...[
              const SizedBox(height: 8),
              _detailMeasurePanel(p),
            ],

            // ④ 하의 길이 통일 안내 (읽기 전용)
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(children: [
                Icon(Icons.straighten_rounded, size: 13, color: Colors.teal.shade500),
                const SizedBox(width: 6),
                Text('하의 길이: ',
                    style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                Text(
                  _defaultLength ?? '미선택 (위에서 선택해 주세요)',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: _defaultLength != null ? Colors.teal.shade800 : Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                if (_defaultLength != null)
                  Icon(Icons.check_circle_rounded, size: 13, color: Colors.teal.shade500),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── 상의/하의 사이즈 직접입력 필드
  Widget _sizeInputField({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    required String hint,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 라벨
      Row(children: [
        Icon(icon, size: 13, color: Colors.black54),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black54)),
        const SizedBox(width: 4),
        Text('*', style: TextStyle(fontSize: 11, color: Colors.red.shade400, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w400, letterSpacing: 0),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _purple, width: 1.5)),
          suffixIcon: ctrl.text.isNotEmpty
              ? Icon(Icons.check_circle_rounded, color: _purple.withValues(alpha: 0.6), size: 18)
              : null,
        ),
        onChanged: (_) => setState(() {}), // suffixIcon 갱신
      ),
    ]);
  }

  // ── 상세 치수 입력 패널
  Widget _detailMeasurePanel(_PersonEntry p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.straighten_rounded, size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text('상세 치수 입력',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.orange.shade800)),
          const SizedBox(width: 6),
          Text('(사이즈 미해당 시 입력)',
              style: TextStyle(fontSize: 10, color: Colors.orange.shade600)),
        ]),
        const SizedBox(height: 10),
        // 2열 그리드: 키, 몸무게, 허리, 허벅지
        Row(children: [
          Expanded(child: _measureField(p.heightCtrl, '키', 'cm', Icons.height_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _measureField(p.weightCtrl, '몸무게', 'kg', Icons.monitor_weight_outlined)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _measureField(p.waistCtrl, '허리', 'cm', Icons.radio_button_unchecked)),
          const SizedBox(width: 8),
          Expanded(child: _measureField(p.thighCtrl, '허벅지', 'cm', Icons.airline_seat_legroom_normal_rounded)),
        ]),
      ]),
    );
  }

  // ── 치수 입력 필드 (라벨 + 단위)
  Widget _measureField(TextEditingController ctrl, String label, String unit, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Icon(icon, size: 14, color: Colors.orange.shade500),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w700),
        suffixText: unit,
        suffixStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.orange.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.orange.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.orange.shade500, width: 1.5)),
      ),
    );
  }

  Widget _sizeTypeBtn(String label, _PersonEntry p, Color color) {
    final isSel = p.sizeType == label;
    return GestureDetector(
      onTap: () => setState(() {
        p.sizeType = label;
        p.topSizeCtrl.clear();
        p.bottomSizeCtrl.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? color : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSel ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800,
                color: isSel ? Colors.white : Colors.black54)),
      ),
    );
  }

  Widget _genderBtn(String label, bool isSel, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 36, height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSel ? color : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSel ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800,
                color: isSel ? Colors.white : Colors.black54)),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 기본 정보 섹션
  // ══════════════════════════════════════════════
  Widget _buildBasicInfoSection() {
    return _card(
      title: '기본 정보',
      icon: Icons.info_outline_rounded,
      child: Column(children: [
        if (_hasTeamName) _inputField('단체명 *', _teamNameCtrl, '단체명을 입력해 주세요'),
        _inputField('담당자 이름', _managerNameCtrl, '담당자 이름'),
        _inputField('연락처 *', _phoneCtrl, '010-0000-0000',
            keyboardType: TextInputType.phone),
        _inputField('이메일', _emailCtrl, 'example@email.com',
            keyboardType: TextInputType.emailAddress),
        // 주소
        GestureDetector(
          onTap: () => _showAddressDialog(),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  _address.isEmpty ? '배송 주소 입력' : _address,
                  style: TextStyle(
                      fontSize: 13,
                      color: _address.isEmpty ? Colors.grey : Colors.black87),
                ),
              ),
              Icon(Icons.search, color: Colors.grey.shade400, size: 18),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: Colors.black54)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _purple, width: 1.5)),
          ),
        ),
      ]),
    );
  }

  void _showAddressDialog() {
    final ctrl = TextEditingController(text: _address);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('배송 주소'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '주소를 입력하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              setState(() => _address = ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 메모 섹션
  // ══════════════════════════════════════════════
  Widget _buildMemoSection() {
    return _card(
      title: '요청 사항',
      icon: Icons.edit_note_rounded,
      child: TextField(
        controller: _memoCtrl,
        maxLines: 3,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: '추가 요청 사항을 입력해 주세요 (선택)',
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _purple, width: 1.5)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 금액 요약 섹션
  // ══════════════════════════════════════════════
  Widget _buildSummarySection() {
    return _card(
      title: '금액 요약',
      icon: Icons.receipt_long_outlined,
      child: Column(children: [
        _sumRow('기본 단가', '${_fmt(_basePrice)}원'),
        if (_fabricExtra > 0)
          _sumRow('원단 추가', '+${_fmt(_fabricExtra)}원'),
        _sumRow('단가 합계', '${_fmt(_unitPrice)}원/인'),
        _sumRow('총 인원', '$_totalCount명'),
        const Divider(height: 20),
        _sumRow('상품 합계', '${_fmt(_subTotal)}원'),
        _sumRow(
          '배송비',
          _totalCount >= AppConstants.groupMinFreeShipping ? '무료' : '+${_fmt(_shipping)}원',
          valueColor: _totalCount >= AppConstants.groupMinFreeShipping
              ? Colors.green.shade700 : null,
        ),
        const Divider(height: 20),
        _sumRow('최종 결제금액', '${_fmt(_finalPrice)}원',
            isTotal: true),
      ]),
    );
  }

  Widget _sumRow(String label, String value,
      {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 14 : 13,
                  fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
                  color: isTotal ? Colors.black87 : Colors.black54)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: isTotal ? 16 : 13,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
                color: valueColor ?? (isTotal ? _purple : Colors.black87))),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 하단 제출 바
  // ══════════════════════════════════════════════
  Widget _buildBottomBar() {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + safeBottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
            Text('$_totalCount명', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('${_fmt(_finalPrice)}원',
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w900, color: _purple)),
          ]),
        ),
        OutlinedButton(
          onPressed: () => _submitOrder(isBuyNow: false),
          style: OutlinedButton.styleFrom(
            foregroundColor: _purple,
            side: const BorderSide(color: _purple),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: const Text('장바구니',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _submitOrder(isBuyNow: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            elevation: 0,
          ),
          child: const Text('바로 구매',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 공통 카드 래퍼
  // ══════════════════════════════════════════════
  Widget _card({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: _purple, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
        ]),
        const Divider(height: 16),
        child,
      ]),
    );
  }
}
