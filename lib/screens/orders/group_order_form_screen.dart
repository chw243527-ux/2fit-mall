import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/net_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';

import '../orders/checkout_screen.dart';
import '../cart/cart_screen.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/address_search_widget.dart';
import '../../utils/navigation_helper.dart';

// ══════════════════════════════════════════════════════════════
// 단체 주문 폼 v6 - 완전 재작성
// ══════════════════════════════════════════════════════════════

// 사이즈 옵션 상수
const List<String> _kAdultSizes  = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
const List<String> _kJuniorSizes = ['XXS(80)', 'XS(90)', 'S(100)', 'M(110)', 'L(120)', 'XL(130)'];
const List<List<String>> _kAdultSizeRows = [
  ['XS',  '154~159', '44~51',  '85', '68'],
  ['S',   '160~165', '52~60',  '90', '72'],
  ['M',   '166~172', '61~71',  '95', '76'],
  ['L',   '172~177', '72~78',  '100','80'],
  ['XL',  '177~182', '79~85',  '105','84'],
  ['2XL', '182~187', '86~91',  '110','88'],
  ['3XL', '187~191', '91~96',  '115','92'],
];
const List<List<String>> _kJuniorSizeRows = [
  ['XXS(80)', '104~116', '16~20', '58', '55'],
  ['XS(90)',  '116~128', '20~25', '63', '58'],
  ['S(100)',  '128~140', '25~32', '68', '62'],
  ['M(110)',  '140~152', '32~40', '73', '65'],
  ['L(120)',  '152~158', '40~48', '78', '68'],
  ['XL(130)', '158~165', '48~55', '83', '72'],
];

class GroupOrderFormScreen extends StatefulWidget {
  final ProductModel? product;
  final bool isAdditionalOrder;
  final int initialPrintType;
  final int initialCount;
  final OrderModel? originalOrder; // 추가주문 시 기존 주문 참조
  final bool isBottomOrder; // 하의 카테고리 + 단체주문: 인쇄/재봉/디자인이미지/상의사이즈 숨김

  const GroupOrderFormScreen({
    super.key,
    this.product,
    this.isAdditionalOrder = false,
    this.initialPrintType = 0,
    this.initialCount = 0,
    this.originalOrder,
    this.isBottomOrder = false,
  });

  @override
  State<GroupOrderFormScreen> createState() => _GroupOrderFormScreenState();
}

// ── 인원 데이터 ──
class _PersonEntry {
  int index;
  String? gender;
  String sizeType = '성인'; // '성인' or '주니어'

  // 선택형 사이즈
  String? topSize;
  String? bottomSize;

  // 직접입력 컨트롤러 (호환성 유지 - 불러오기 등에서 사용)
  final TextEditingController topSizeCtrl    = TextEditingController();
  final TextEditingController bottomSizeCtrl = TextEditingController();

  // 이름
  final TextEditingController nameCtrl = TextEditingController();

  // 사이즈표 토글
  bool showSizeTable = false;

  // 상세 치수 (하의 아래 별도 블록)
  bool   showDetail = false;
  final TextEditingController heightCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController waistCtrl  = TextEditingController();
  final TextEditingController thighCtrl  = TextEditingController();

  _PersonEntry({required this.index});

  // 선택된 사이즈 값 (선택형 우선, 없으면 직접입력)
  String get effectiveTopSize    => topSize ?? topSizeCtrl.text.trim();
  String get effectiveBottomSize => bottomSize ?? bottomSizeCtrl.text.trim();

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
  // ── 탑텐 스타일 상수 ──
  static const Color _purple      = Color(0xFF1A1A1A);  // 블랙 (탑텐 강조색)
  static const Color _purpleLight = Color(0xFFF0F0F0);  // 라이트 그레이 배경
  static const Color _bg          = Color(0xFFF8F8F8);  // 페이지 배경

  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  final _formKey    = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // ── 색상 탭 컨트롤러 ──
  late TabController _colorTabCtrl;
  final _hexCtrl     = TextEditingController();
  String? _hexError;
  Color  _hexPreview = const Color(0xFF1A1A1A);

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
  String _fabricType   = '일반 봉제'; // constants.fabricTypes[0] 과 동일하게 유지
  String _fabricWeight = '80g';

  // ── 하의 기본 길이 (남/여 분리) ──
  String? _maleLengthSel;   // 남성 하의 길이
  String? _femaleLengthSel; // 여성 하의 길이

  // ── 허리밴드 옵션 (중복 선택 가능) ── 전부 무료
  // 1: 디자인 변경(무료), 2: 색상 변경(무료)
  // 빈 Set = 기본(변경없음)
  final Set<int> _waistbandOptions = {};
  String _waistbandColorHex = ''; // 색상변경 선택 시 hex 코드 (#RRGGBB)
  final _waistbandColorCtrl = TextEditingController();

  // ── 허리밴드 디자인 참조 이미지 (최대 3장) ──
  final List<String> _waistbandRefImages = []; // base64 목록

  // ── 허리밴드 로고 파일 ──
  String? _waistbandLogoFileName;  // 파일명 (표시용)
  List<int>? _waistbandLogoBytes;  // 파일 바이트 (base64 저장용)

  // ── 참조 이미지 (단일) ──
  String? _refBase64;
  static const _kRefKey = 'group_order_ref_base64';

  // ── 디자인 로고 파일 ──
  String? _designLogoFileName;
  List<int>? _designLogoBytes;

  // ── 기본 정보 ──
  final _teamNameCtrl       = TextEditingController();
  final _managerNameCtrl    = TextEditingController();
  final _phoneCtrl          = TextEditingController();
  final _emailCtrl          = TextEditingController();
  final _memoCtrl           = TextEditingController();
  final _addressDetailCtrl  = TextEditingController(); // 상세주소
  String _address        = '';

  // ── 독점 디자인 ──
  bool _exclusiveDesign = false; // ignore: prefer_final_fields

  // ── 추가 옵션 ──
  bool _hasPocket = false; // 주머니 선택 (+10,000원)

  // ══ 추가 옵션 가격 상수 ══
  static const int _tights9Price    = 20000; // 타이즈 9부 추가금
  static const int _exclusivePrice  = 0; // 1년 독점 — 무료 제공
  static const int _pocketPrice     = 10000; // 주머니 추가금

  // ══ 파생값 ══
  bool get _isAdditional   => widget.isAdditionalOrder;
  int  get _totalCount     => _persons.length;
  // 옵션별: 0=색상변경만, 1=단체명만, 2=단체명+색상, 3=디자인+단체명+색상, 4=디자인+색상+단체명+후면이름
  // ignore: unused_element
  // 0: 색상만, 1: 단체명+색상, 2: 디자인+단체명+색상, 3: 디자인유지+색상+단체명+이름(후면), 4: 디자인변경+색상+단체명+이름(후면)
  bool get _hasColorChange => _printType == 0 || _printType == 1 || _printType == 2 || _printType == 3 || _printType == 4;
  bool get _hasTeamName    => _printType == 1 || _printType == 2 || _printType == 3 || _printType == 4;

  bool get _nameEnabled    => _totalCount >= 10;
  OrderModel? get _originalOrder => widget.originalOrder;

  /// 허리밴드 옵션 레이블 (중복 선택 반영)
  String get _waistbandOptionLabel {
    if (_waistbandOptions.isEmpty) return '기본 (변경없음)';
    final labels = <String>[];
    if (_waistbandOptions.contains(1)) labels.add('디자인 변경');
    if (_waistbandOptions.contains(2)) labels.add('색상 변경');
    return labels.join(' + ');
  }

  /// 허리밴드 추가 비용 — 전부 무료
  double get _waistbandExtra => 0.0;

  int    get _fabricExtra  => AppConstants.fabricTypePrices[_fabricType] ?? 0;
  double get _basePrice    => widget.product?.price ?? 0.0;
  // 타이즈 9부 선택 여부
  bool get _isTights9      => _maleLengthSel == '9부' || _femaleLengthSel == '9부';
  /// 타이즈 또는 하의 단체주문: 하의 사이즈만 입력 (상의 사이즈 불필요)
  /// 하의 카테고리 단체주문: 인쇄/재봉/디자인이미지/상의사이즈 숨김
  /// widget.isBottomOrder(명시 전달) OR product.category=='하의' 둘 다 체크
  bool get _isBottomOnly {
    if (widget.isBottomOrder) return true;
    final p = widget.product;
    if (p == null) return false;
    return p.category == '하의' ||
        p.subCategory.contains('타이즈') ||
        p.subCategory.contains('남성 5부') ||
        p.subCategory.contains('여성 2.5부') ||
        p.name.contains('타이즈');
  }
  // 숏사각(숏쇼츠) 선택 시 주머니 불가
  bool get _isFemaleShortSquare => _femaleLengthSel == '숏쇼츠';
  // 단가 = 기본가 + 심리스 + 9부 + 주머니 (모두 인원당 추가)
  double get _unitPrice    => _basePrice
      + _fabricExtra                          // 심리스: 인원당 +10,000
      + (_isTights9 ? _tights9Price : 0)     // 9부:    인원당 +20,000
      + (_hasPocket ? _pocketPrice : 0);     // 주머니: 인원당 +10,000
  double get _subTotal     => _unitPrice * _totalCount;
  // 배송비: 5인 이상 무료, 미만 4,000원
  double get _shipping     => _totalCount >= AppConstants.groupMinFreeShipping ? 0 : AppConstants.groupAdditionalShippingFee.toDouble();
  // 최종 = 소계(단가×인원) + 배송비 + 허리밴드 + 독점
  // ※ 주머니는 단가에 이미 포함 — 별도 가산 없음
  double get _finalPrice   => _subTotal + _shipping + _waistbandExtra
      + (_exclusiveDesign ? _exclusivePrice : 0);

  String _fmt(num v) => v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ══ 생명주기 ══
  @override
  void initState() {
    super.initState();
    _printType = widget.initialPrintType.clamp(0, 3); // 최대 id: 3
    _count = widget.initialCount >= 5 ? widget.initialCount : 5;
    // 기존 주문 편집 or initialCount가 설정된 경우 바로 확정 상태로 시작
    _countFixed = widget.initialCount >= 5;
    for (int i = 0; i < _count; i++) {
      _persons.add(_PersonEntry(index: i));
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
    _addressDetailCtrl.dispose();
    _waistbandColorCtrl.dispose();
    for (final p in _persons) { p.dispose(); }
    super.dispose();
  }

  Future<void> _loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _refBase64 = prefs.getString(_kRefKey);
    });
  }

  Future<void> _saveImage({required String? base64}) async {
    final prefs = await SharedPreferences.getInstance();
    if (base64 == null) {
      await prefs.remove(_kRefKey);
    } else {
      await prefs.setString(_kRefKey, base64);
    }
  }

  // ignore: unused_element
  void _applyCount() {
    if (_count < 1) return;
    setState(() {
      while (_persons.length < _count) {
        _persons.add(_PersonEntry(index: _persons.length));
      }
      while (_persons.length > _count) {
        _persons.last.dispose();
        _persons.removeLast();
      }
      for (int i = 0; i < _persons.length; i++) { _persons[i].index = i; }
      _resetInvalidPrintType();
    });
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
      _resetInvalidPrintType();
    });
  }

  void _addPerson() {
    setState(() {
      _persons.add(_PersonEntry(index: _persons.length));
      _count = _persons.length;
      _resetInvalidPrintType();
    });
  }

  void _removePerson(int idx) {
    if (_persons.length <= 1) return;
    setState(() {
      _persons[idx].dispose();
      _persons.removeAt(idx);
      for (int i = 0; i < _persons.length; i++) { _persons[i].index = i; }
      _count = _persons.length;
      _resetInvalidPrintType();
    });
  }

  /// 인원 변경 시 선택된 인쇄 옵션이 조건 미달이면 자동 리셋
  void _resetInvalidPrintType() {
    // 5번(id=4) 옵션은 10명 이상 필요
    if ((_printType == 3 || _printType == 4) && _totalCount < 10) {
      _printType = 0;
    }
    // 나머지 옵션(0~3)은 5명 이상 필요
    if (_totalCount < 5) {
      _printType = 0;
    }
  }

  // ── 사이즈 프로필 불러오기 바텀시트 ──────────────────────────
  void _showLoadSizeSheet(_PersonEntry p) {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      _showSnack('로그인 후 사이즈 프로필을 불러올 수 있습니다.');
      return;
    }
    final profiles = context.read<SizeProfileProvider>().profiles;
    if (profiles.isEmpty) {
      _showSnack('저장된 사이즈 프로필이 없습니다. 마이페이지에서 먼저 저장해 주세요.');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('사이즈 프로필 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text('선택하면 해당 팀원 칸에 자동 입력됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 14),
          ...profiles.map((profile) {
            final isMale = profile.gender == 'male';
            return GestureDetector(
              onTap: () {
                setState(() {
                  p.gender        = profile.gender;
                  p.sizeType      = profile.sizeType;
                  p.topSize    = profile.topSize.isNotEmpty ? profile.topSize : null;
                  p.bottomSize = profile.bottomSize.isNotEmpty ? profile.bottomSize : null;
                  p.topSizeCtrl.text    = profile.topSize;
                  p.bottomSizeCtrl.text = profile.bottomSize;
                  p.heightCtrl.text = profile.height;
                  p.weightCtrl.text = profile.weight;
                  p.waistCtrl.text  = profile.waist;
                  p.thighCtrl.text  = profile.thigh;
                  if (profile.height.isNotEmpty || profile.waist.isNotEmpty) {
                    p.showDetail = true;
                  }
                });
                Navigator.pop(context);
                _showSnack('"${profile.profileName}" 사이즈가 적용되었습니다.');
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMale
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.pink.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMale ? Colors.blue : Colors.pink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(profile.genderLabel,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(profile.profileName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      Text(
                        '상의 ${profile.topSize} · 하의 ${profile.bottomSize}'
                        '${profile.height.isNotEmpty ? " · 키 ${profile.height}cm" : ""}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ]),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey.shade400),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  // ── 주문 후 내 사이즈 저장 제안 ─────────────────────────────
  void _offerSaveSizeAfterOrder() {
    final user = context.read<UserProvider>().user;
    if (user == null || _persons.isEmpty) return;

    // 본인(첫 번째 팀원)의 사이즈만 저장 제안
    final me = _persons.first;
    if (me.effectiveTopSize.isEmpty || me.effectiveBottomSize.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController(text: '내 사이즈');
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.save_outlined, color: _purple, size: 22),
            SizedBox(width: 8),
            Text('내 사이즈 저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('첫 번째 팀원의 사이즈를 저장하면\n다음 주문 시 빠르게 불러올 수 있습니다.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: '프로필 이름',
                hintText: '예) 내 기본 사이즈',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _purple, width: 1.5)),
                isDense: true,
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('나중에', style: TextStyle(color: Colors.grey.shade500)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final profile = SizeProfile(
                  id: '',
                  userId: user.id,
                  profileName: nameCtrl.text.trim().isEmpty ? '내 사이즈' : nameCtrl.text.trim(),
                  gender: me.gender ?? 'male',
                  sizeType: me.sizeType,
                  topSize: me.effectiveTopSize,
                  bottomSize: me.effectiveBottomSize,
                  height: me.heightCtrl.text.trim(),
                  weight: me.weightCtrl.text.trim(),
                  waist: me.waistCtrl.text.trim(),
                  thigh: me.thighCtrl.text.trim(),
                );
                final err = await context
                    .read<SizeProfileProvider>()
                    .saveProfile(user.id, profile);
                if (!mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: Colors.red));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('사이즈가 저장되었습니다!'),
                      backgroundColor: _purple,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  // ── HEX 색상 적용 ──────────────────────────────────────────
  void _applyHexColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) {
      setState(() => _hexError = '6자리 HEX 코드를 입력해 주세요');
      return;
    }
    try {
      final color = Color(int.parse('FF$clean', radix: 16));
      setState(() {
        _mainColor     = color;
        _mainColorName = '#${clean.toUpperCase()}';
        _hexError      = null;
      });
    } catch (_) {
      setState(() => _hexError = '올바른 HEX 코드가 아닙니다');
    }
  }

  // ── 색상 유틸 ─────────────────────────────────────────────
  static bool _isLightColor(Color color) {
    final r = color.r * 255;
    final g = color.g * 255;
    final b = color.b * 255;
    return (r * 299 + g * 587 + b * 114) / 1000 >= 128;
  }

  static Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  // ── 허리밴드 참고 이미지 선택 ──────────────────────────────
  Future<void> _pickWaistbandRefImage() async {
    if (_waistbandRefImages.length >= 3) return;
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      final b64 = base64Encode(bytes);
      if (!mounted) return;
      setState(() => _waistbandRefImages.add(b64));
    } catch (e) {
      _showSnack('이미지 선택 오류: $e');
    }
  }

  // ── 허리밴드 로고 파일 선택 ────────────────────────────────
  Future<void> _pickWaistbandLogoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (!mounted) return;
      setState(() {
        _waistbandLogoFileName = file.name;
        _waistbandLogoBytes    = file.bytes != null ? List<int>.from(file.bytes!) : null;
      });
    } catch (e) {
      _showSnack('파일 선택 오류: $e');
    }
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
    if (_teamNameCtrl.text.trim().isEmpty) {
      _showSnack('단체명을 입력해 주세요.');
      return false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnack('연락처를 입력해 주세요.');
      return false;
    }
    if (_address.isEmpty) {
      _showSnack('배송 주소를 입력해 주세요.');
      return false;
    }
    if (_addressDetailCtrl.text.trim().isEmpty) {
      _showSnack('상세주소를 입력해 주세요.');
      return false;
    }
    if (_maleLengthSel == null) {
      _showSnack('남성 하의 길이를 선택해 주세요.');
      return false;
    }
    if (_femaleLengthSel == null) {
      _showSnack('여성 하의 길이를 선택해 주세요.');
      return false;
    }
    for (int i = 0; i < _persons.length; i++) {
      final p = _persons[i];
      if (p.gender == null) {
        _showSnack('${i + 1}번 인원의 성별을 선택해 주세요.');
        return false;
      }
      // 상의 사이즈 확인 (하의/타이즈 단체주문 시 생략)
      if (!_isBottomOnly && p.effectiveTopSize.isEmpty) {
        _showSnack('${i + 1}번 인원의 상의 사이즈를 입력해 주세요.');
        return false;
      }
      // 하의 사이즈 확인
      if (p.effectiveBottomSize.isEmpty) {
        _showSnack('${i + 1}번 인원의 사이즈를 입력해 주세요.');
        return false;
      }
    }
    // 디자인 요청 사항 필수 확인
    if (_memoCtrl.text.trim().isEmpty) {
      _showSnack('디자인 요청 사항을 입력해 주세요.');
      return false;
    }
    return true;
  }

  Future<void> _submitOrder({required bool isBuyNow}) async {
    if (!_validate()) return;
    final user    = context.read<UserProvider>().user;
    // product.price 를 반드시 _unitPrice(기본가+심리스+9부+주머니 포함 인원당 단가)로 고정
    // CartItem.unitPrice = product.price + extraPrice 이므로 extraPrice: 0 과 함께 사용해야 정확
    final src = widget.product;
    final product = src == null
        ? ProductModel(
            id: 'group_direct_${DateTime.now().millisecondsSinceEpoch}',
            name: '단체주문', category: '단체주문', subCategory: '',
            price: _unitPrice, originalPrice: _unitPrice,
            description: '단체 직접 주문', images: [], sizes: [], colors: [],
            material: '', stockCount: 999, createdAt: DateTime.now(),
          )
        : ProductModel(
            // 원본 상품의 모든 메타데이터 유지, price 만 _unitPrice 로 교체
            id: src.id, name: src.name,
            category: src.category, subCategory: src.subCategory,
            price: _unitPrice, originalPrice: _unitPrice,
            description: src.description,
            images: src.images, sizes: src.sizes, colors: src.colors,
            material: src.material,
            isNew: src.isNew, newExpiresAt: src.newExpiresAt,
            isSale: src.isSale,
            isFreeShipping: src.isFreeShipping, isGroupOnly: src.isGroupOnly,
            rating: src.rating, reviewCount: src.reviewCount,
            stockCount: src.stockCount, salesCount: src.salesCount,
            isActive: src.isActive, createdAt: src.createdAt,
            productCode: src.productCode,
            sectionImages: src.sectionImages,
            nameTranslations: src.nameTranslations,
            descriptionTranslations: src.descriptionTranslations,
            bottomLength: src.bottomLength,
          );

    // 상세페이지 디자인 이미지 (sectionImages['design'] 첫 번째 이미지)
    final designImg = (product.sectionImages['design'] ?? []).isNotEmpty
        ? product.sectionImages['design']!.first
        : (product.images.isNotEmpty ? product.images.first : '');

    final customOptions = <String, dynamic>{
      'orderType'      : _isAdditional ? 'additional' : 'group',
      'designFileUrl'  : designImg,
      'productImageUrl': designImg,
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
      'pocket'       : _hasPocket && !_isFemaleShortSquare,
      'maleLength'   : _maleLengthSel,
      'femaleLength' : _femaleLengthSel,
      'waistbandOption' : _waistbandOptionLabel,
      'waistbandOptions': _waistbandOptions.toList(),
      'waistbandExtra'  : _waistbandExtra.toInt(),
      'waistbandColorHex': _waistbandOptions.contains(2) ? _waistbandColorHex : '',
      'waistbandRefImages': _waistbandRefImages,
      'waistbandLogoFileName': _waistbandLogoFileName ?? '',
      'waistbandLogoBase64'  : _waistbandLogoBytes != null ? base64Encode(_waistbandLogoBytes!) : '',
      'exclusive'    : _exclusiveDesign,
      'teamName'     : _teamNameCtrl.text.trim(),
      'manager'      : _managerNameCtrl.text.trim(),
      'phone'        : _phoneCtrl.text.trim(),
      'email'        : _emailCtrl.text.trim(),
      'address'      : _address,
      'addressDetail': _addressDetailCtrl.text.trim(),
      'maleRef'      : _refBase64 != null,
      'femaleRef'    : false,
      'designLogoFileName': _designLogoFileName ?? '',
      'designLogoBase64'  : _designLogoBytes != null ? base64Encode(_designLogoBytes!) : '',
      'persons'      : _persons.map((p) => <String, dynamic>{
        'index'     : p.index,
        'name'      : _nameEnabled ? p.nameCtrl.text.trim() : '', // 10명 미만은 이름 저장 안 함
        'gender'    : p.gender,
        'sizeType'  : p.sizeType,
        'topSize'   : p.effectiveTopSize,
        'bottomSize': p.effectiveBottomSize,
        'length'    : (p.gender == 'female') ? _femaleLengthSel : _maleLengthSel, // 성별에 따라 자동 적용
        'height'    : p.heightCtrl.text.trim(),
        'weight'    : p.weightCtrl.text.trim(),
        'waist'     : p.waistCtrl.text.trim(),
        'thigh'     : p.thighCtrl.text.trim(),
        'hasCustomMeasure': p.showDetail,
      }).toList(),
    };

    final orderId = 'GRP_${DateTime.now().millisecondsSinceEpoch}';
    // ignore: unused_local_variable
    final order   = OrderModel(
      id: orderId,
      userId: user?.id ?? 'guest',
      userName: _managerNameCtrl.text.trim().isNotEmpty
          ? _managerNameCtrl.text.trim() : _teamNameCtrl.text.trim(),
      userEmail: _emailCtrl.text.trim(),
      userPhone: _phoneCtrl.text.trim(),
      userAddress: _addressDetailCtrl.text.trim().isNotEmpty
          ? '$_address ${_addressDetailCtrl.text.trim()}'
          : _address,
      items: [OrderItem(
        productId: product.id, productName: product.name,
        size: '단체', color: _mainColorName ?? '기본',
        quantity: _totalCount, price: _unitPrice,
        customOptions: customOptions,
        imageUrl: product.images.isNotEmpty ? product.images.first : null,
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
      // product.price = _unitPrice (모든 추가비용 포함) → extraPrice: 0 으로 이중계산 방지
      cart.addItem(product, '단체', _mainColorName ?? '기본',
          quantity: _totalCount,
          extraPrice: 0,
          customOptions: customOptions);
      if (!mounted) return;
      // 주문 전 사이즈 저장 제안
      _offerSaveSizeAfterOrder();
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CheckoutScreen(cart: cart)));
    } else {
      // 장바구니에 담기 (기존 아이템 유지, 단체 상품 추가)
      // product.price = _unitPrice (모든 추가비용 포함) → extraPrice: 0 으로 이중계산 방지
      cart.addItem(product, '단체', _mainColorName ?? '기본',
          quantity: _totalCount,
          extraPrice: 0,
          customOptions: customOptions);
      if (!mounted) return;
      // 장바구니 담기 후 사이즈 저장 제안
      _offerSaveSizeAfterOrder();
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
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
        leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => goBackOrHome(context)),
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
                _buildAllMembersNotice(),
                if (!_isBottomOnly) _buildPrintTypeSection(),
                if (!_isBottomOnly) _build2FitLogoBanner(),
                if (widget.product != null) _buildProductCard(),
                if (!_isBottomOnly) _buildFabricSection(),
                _buildLengthSection(),
                _buildPocketSection(),
                _buildWaistbandSection(),
                _buildColorSection(),
                if (!_isBottomOnly) _buildRefImageSection(),
                _buildWaistbandLogoSection(),
                _buildWaistbandRefImageSection(),
                _buildMemoSection(),
                _buildPersonListSection(),
                _buildBasicInfoSection(),
                _buildCancelPolicySection(),
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
  // 헤더 배너 (탑텐 블랙)
  // ══════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      color: _purple,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          _isAdditional ? 'ADDITIONAL ORDER' : 'GROUP CUSTOM ORDER',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2.5),
        ),
        const SizedBox(height: 6),
        Text(
          _isAdditional ? '추가 제작 주문' : '단체 커스텀 주문',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        const Text('아래 폼을 작성하여 주문을 완료해 주세요.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 14),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _hChip(Icons.check_circle_outline_rounded, '허리밴드 변경 무료'),
          _hChip(Icons.attach_file_rounded, 'AI 원본파일 필수'),
          _hChip(Icons.lock_outline_rounded, '1년 독점 무료'),
          _hChip(Icons.local_shipping_outlined, '5명↑ 무료배송'),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white.withValues(alpha: 0.07),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.swap_horiz_rounded, color: Colors.white60, size: 12),
              SizedBox(width: 5),
              Text('교환·환불 안내', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
            SizedBox(height: 4),
            Text('▶ 기성품: 수령 후 3일 이내 가능', style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5)),
            Text('▶ 커스텀: 의류 자체 불량 외 불가', style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5)),
          ]),
        ),
      ]),
    );
  }

  Widget _hChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white60, size: 10),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 수량 섹션 (탑텐 블랙)
  // ══════════════════════════════════════════════
  Widget _buildCountSection() {
    return _card(
      title: '주문 인원',
      icon: Icons.groups_outlined,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _cBtn(Icons.remove_rounded, () {
            if (_count > 1) setState(() {
              _count--;
              if (_countFixed) {
                while (_persons.length > _count) { _persons.last.dispose(); _persons.removeLast(); }
                for (int i = 0; i < _persons.length; i++) { _persons[i].index = i; }
                _resetInvalidPrintType();
              }
            });
          }),
          Container(
            width: 88, alignment: Alignment.center,
            child: Text('$_count명', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _purple)),
          ),
          _cBtn(Icons.add_rounded, () => setState(() {
            _count++;
            if (_countFixed) {
              while (_persons.length < _count) { _persons.add(_PersonEntry(index: _persons.length)); }
              for (int i = 0; i < _persons.length; i++) { _persons[i].index = i; }
              _resetInvalidPrintType();
            }
          })),
        ]),
        const SizedBox(height: 4),
        const Text('최소 5명 이상 주문 가능', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),
        if (!_countFixed)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _count >= 1 ? _confirmCount : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple, foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(), elevation: 0,
              ),
              child: Text('$_count명으로 주문서 작성', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFFF0F0F0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check, color: _purple, size: 18),
              const SizedBox(width: 8),
              Text('$_totalCount명 확정', style: const TextStyle(color: _purple, fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
          ),
      ]),
    );
  }

  Widget _cBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 44, height: 44,
      color: const Color(0xFFF0F0F0),
      child: Icon(icon, color: _purple, size: 22),
    ),
  );

  // ── 전체 인원 공통 안내 배너
  Widget _buildAllMembersNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFF57F17)),
        const SizedBox(width: 8),
        Expanded(child: Text(loc.groupOrderAllMembersNotice,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037), fontWeight: FontWeight.w600, height: 1.5))),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 인쇄 타입 섹션
  // ══════════════════════════════════════════════
  Widget _buildPrintTypeSection() {
    // 0: 색상, 1: 단체명+색상, 2: 디자인+단체명+색상, 3: 디자인유지+색상+단체명+이름, 4: 디자인변경+색상+단체명+이름
    final opts = [
      (0, '디자인 유지 + 색상 변경', '2FIT 로고(전면) + 색상 변경', 5, '5명↑'),
      (1, '디자인 유지 + 단체명 + 색상', '기존 디자인 유지 + 단체명(전면)', 5, '5명↑'),
      (2, '디자인 변경 + 단체명 + 색상', '새 디자인 + 단체명(전면)', 5, '5명↑'),
      (3, '디자인유지 + 색상 + 단체명 + 이름(후면)', '기존 디자인 + 색상 + 이름(후면·등)', 10, '10명↑'),
      (4, '디자인변경 + 색상 + 단체명 + 이름(후면)', '새 디자인 + 색상 + 이름(후면·등)', 10, '10명↑'),
    ];

    return _card(
      title: '인쇄 타입',
      icon: Icons.print_outlined,
      child: Column(
        children: opts.map((o) {
          final id = o.$1; final condMin = o.$4;
          final enabled = _totalCount >= condMin;
          final isSel = _printType == id;
          return GestureDetector(
            onTap: enabled
                ? () => setState(() => _printType = id)
                : () => _showSnack('${condMin}명 이상부터 선택 가능합니다.'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: !enabled ? const Color(0xFFF8F8F8) : isSel ? const Color(0xFF1A1A1A) : Colors.white,
                border: Border.all(color: !enabled ? const Color(0xFFE0E0E0) : isSel ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC)),
              ),
              child: Row(children: [
                Container(
                  width: 26, height: 26,
                  alignment: Alignment.center,
                  color: !enabled ? const Color(0xFFE0E0E0) : isSel ? Colors.white : const Color(0xFF1A1A1A),
                  child: Text('${id + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                      color: !enabled ? const Color(0xFFAAAAAA) : isSel ? const Color(0xFF1A1A1A) : Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: !enabled ? const Color(0xFFBBBBBB) : isSel ? Colors.white : const Color(0xFF1A1A1A))),
                  Text(o.$3, style: TextStyle(fontSize: 10, color: !enabled ? const Color(0xFFCCCCCC) : isSel ? Colors.white60 : const Color(0xFF888888))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  color: !enabled ? const Color(0xFFF0F0F0) : condMin == 10 ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
                  child: Text(o.$5, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: !enabled ? const Color(0xFFAAAAAA) : condMin == 10 ? Colors.white : const Color(0xFF1A1A1A))),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 2FIT 로고 배너
  Widget _build2FitLogoBanner() {
    if (_hasTeamName) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1A1A1A),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          color: Colors.white.withValues(alpha: 0.1),
          alignment: Alignment.center,
          child: const Text('2F', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('2FIT 로고 자동 적용', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          SizedBox(height: 2),
          Text('단체명 미선택 시 전면에 2FIT 로고가 기본 적용됩니다.', style: TextStyle(fontSize: 10, color: Colors.white54, height: 1.4)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: Colors.white.withValues(alpha: 0.15),
          child: const Text('기본', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 선택 상품 카드
  // ══════════════════════════════════════════════
  Widget _buildProductCard() {
    final p = widget.product!;
    final designImgs = p.sectionImages['design'] ?? [];
    final hasDesign = designImgs.isNotEmpty;
    final heroImg = hasDesign ? designImgs.first : (p.images.isNotEmpty ? p.images.first : null);

    return _card(
      title: '선택 상품',
      icon: Icons.shopping_bag_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: heroImg != null ? () => _showImgDialog(heroImg) : null,
            child: Stack(children: [
              Container(
                width: 72, height: 72,
                color: const Color(0xFFF5F5F5),
                child: heroImg != null ? NetImage(heroImg, fit: BoxFit.cover) : const Icon(Icons.checkroom, color: Color(0xFFBBBBBB)),
              ),
              if (hasDesign) Positioned(left: 0, bottom: 0,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), color: _purple,
                  child: const Text('디자인', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800)))),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 4),
            Text('${_fmt(p.price)}원 / 인',
                style: const TextStyle(fontWeight: FontWeight.w900, color: _purple, fontSize: 14)),
          ])),
        ]),
        if (hasDesign) ...[
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          const Text('디자인 이미지', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          SizedBox(height: 100, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: designImgs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _showImgDialog(designImgs[i]),
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E0E0))),
                child: NetImage(designImgs[i], fit: BoxFit.cover),
              ),
            ),
          )),
        ],
      ]),
    );
  }

  void _showImgDialog(String url) => showDialog(
    context: context,
    builder: (_) => Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(16),
      child: Stack(alignment: Alignment.topRight, children: [
        ClipRRect(borderRadius: BorderRadius.circular(4), child: NetImage(url, fit: BoxFit.contain)),
        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ])),
  );

  Widget _productImgPlaceholder() => Container(
    width: 72, height: 72, color: const Color(0xFFF5F5F5),
    child: const Icon(Icons.checkroom_outlined, color: Color(0xFFBBBBBB), size: 28),
  );

  // ══════════════════════════════════════════════
  // 재봉방법 선택
  // ══════════════════════════════════════════════
  Widget _buildFabricSection() {
    return _card(
      title: '재봉방법',
      icon: Icons.content_cut_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFFF8F8F8),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 13, color: Color(0xFF888888)),
            const SizedBox(width: 6),
            const Expanded(child: Text('심리스(무봉제) 선택 시 +10,000원 추가', style: TextStyle(fontSize: 11, color: Color(0xFF666666)))),
          ]),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: AppConstants.fabricTypes.map((t) {
          final isSel = _fabricType == t;
          final extra = AppConstants.fabricTypePrices[t] ?? 0;
          return GestureDetector(
            onTap: () => setState(() => _fabricType = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSel ? _purple : Colors.white,
                border: Border.all(color: isSel ? _purple : const Color(0xFFCCCCCC)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(t == '일반 봉제' ? Icons.cut_outlined : Icons.auto_fix_high_outlined,
                      size: 14, color: isSel ? Colors.white : _purple),
                  const SizedBox(width: 6),
                  Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                      color: isSel ? Colors.white : const Color(0xFF1A1A1A))),
                ]),
                if (extra > 0) ...[
                  const SizedBox(height: 2),
                  Text('+${_fmt(extra)}원', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white70 : const Color(0xFFE65100))),
                ],
                const SizedBox(height: 2),
                Text(t == '일반 봉제' ? '봉제선 있음' : '봉제선 없음',
                    style: TextStyle(fontSize: 10, color: isSel ? Colors.white54 : const Color(0xFF888888))),
              ]),
            ),
          );
        }).toList()),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 하의 길이 섹션
  // ══════════════════════════════════════════════
  Widget _buildLengthSection() {
    final maleLengths = AppConstants.bottomLengths
        .where((l) => ['9부', '5부', '4부', '3부'].contains(l['label'])).toList();
    final femaleLengths = AppConstants.bottomLengths;

    return _card(
      title: '하의 기본 길이',
      icon: Icons.straighten_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFFF8F8F8),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF888888)),
            const SizedBox(width: 6),
            const Expanded(child: Text('선택한 길이는 성별에 따라 전원에게 동일 적용됩니다.', style: TextStyle(fontSize: 11, color: Color(0xFF666666)))),
          ]),
        ),
        _buildGenderLengthRow(gender: '남성', genderColor: const Color(0xFF1A1A1A), genderBg: const Color(0xFFF0F0F0), lengths: maleLengths, selected: _maleLengthSel, onSelect: (v) => setState(() => _maleLengthSel = v)),
        const SizedBox(height: 12),
        _buildGenderLengthRow(gender: '여성', genderColor: const Color(0xFF555555), genderBg: const Color(0xFFF8F8F8), lengths: femaleLengths, selected: _femaleLengthSel, onSelect: (v) => setState(() => _femaleLengthSel = v)),
      ]),
    );
  }

  Widget _buildGenderLengthRow({
    required String gender,
    required Color genderColor,
    required Color genderBg,
    required List<Map<String, String>> lengths,
    required String? selected,
    required ValueChanged<String?> onSelect,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: genderColor,
          child: Text(gender, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 8),
        if (selected != null)
          Text(selected, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: lengths.map((l) {
        final label = l['label']!;
        final isSel = selected == label;
        final extraPrice = int.tryParse(l['extra'] ?? '0') ?? 0;
        return GestureDetector(
          onTap: () => onSelect(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? _purple : Colors.white,
              border: Border.all(color: isSel ? _purple : const Color(0xFFCCCCCC)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: isSel ? Colors.white : const Color(0xFF1A1A1A))),
              if (extraPrice > 0)
                Text('+${_fmt(extraPrice)}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: isSel ? Colors.white70 : const Color(0xFFE65100))),
            ]),
          ),
        );
      }).toList()),
    ]);
  }

  // ══════════════════════════════════════════════
  // 주머니 섹션
  // ══════════════════════════════════════════════
  Widget _buildPocketSection() {
    final disabled = _isFemaleShortSquare;
    return _card(
      title: '주머니 옵션',
      icon: Icons.inventory_2_outlined,
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _hasPocket = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: !_hasPocket ? const Color(0xFF1A1A1A) : Colors.white,
              alignment: Alignment.center,
              child: Column(children: [
                Icon(Icons.remove_circle_outline, size: 18,
                    color: !_hasPocket ? Colors.white : const Color(0xFF888888)),
                const SizedBox(height: 4),
                Text('없음', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: !_hasPocket ? Colors.white : const Color(0xFF888888))),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: disabled ? null : () => setState(() => _hasPocket = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: disabled ? const Color(0xFFF5F5F5) : _hasPocket ? const Color(0xFF1A1A1A) : Colors.white,
              alignment: Alignment.center,
              child: Column(children: [
                Icon(Icons.add_box_outlined, size: 18,
                    color: disabled ? const Color(0xFFCCCCCC) : _hasPocket ? Colors.white : const Color(0xFF1A1A1A)),
                const SizedBox(height: 4),
                Text('있음 (+${_fmt(_pocketPrice)}원/인)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: disabled ? const Color(0xFFCCCCCC) : _hasPocket ? Colors.white : const Color(0xFF1A1A1A))),
                if (disabled) Text('선택 불가', style: const TextStyle(fontSize: 10, color: Color(0xFFCCCCCC))),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 허리밴드 옵션
  // ══════════════════════════════════════════════
  Widget _buildWaistbandSection() {
    const opts = [
      (1, '디자인 변경', Icons.brush_outlined),
      (2, '색상 변경', Icons.palette_outlined),
    ];
    final needsColor = _waistbandOptions.contains(2);

    return _card(
      title: '허리밴드 옵션',
      icon: Icons.style_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 무료 안내
        Container(
          width: double.infinity, padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          color: const Color(0xFFF0F0F0),
          child: const Row(children: [
            Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF1A1A1A)),
            SizedBox(width: 6),
            Text('허리밴드 디자인·색상 변경 전부 무료',
                style: TextStyle(fontSize: 12, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700)),
          ]),
        ),

        // 기본 옵션
        GestureDetector(
          onTap: () => setState(() { _waistbandOptions.clear(); _waistbandColorHex = ''; _waistbandColorCtrl.clear(); }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 6),
            color: _waistbandOptions.isEmpty ? const Color(0xFF1A1A1A) : Colors.white,
            child: Row(children: [
              Icon(_waistbandOptions.isEmpty ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                  size: 16, color: _waistbandOptions.isEmpty ? Colors.white : const Color(0xFF888888)),
              const SizedBox(width: 8),
              Text('기본 (변경없음)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _waistbandOptions.isEmpty ? Colors.white : const Color(0xFF888888))),
              const Spacer(),
              Text('추가비용 없음', style: TextStyle(fontSize: 11,
                  color: _waistbandOptions.isEmpty ? Colors.white54 : const Color(0xFF888888))),
            ]),
          ),
        ),

        Wrap(spacing: 8, runSpacing: 8, children: opts.map((o) {
          final id = o.$1; final label = o.$2; final icon = o.$3;
          final isSel = _waistbandOptions.contains(id);
          return GestureDetector(
            onTap: () => setState(() {
              if (isSel) { _waistbandOptions.remove(id); if (id == 2) { _waistbandColorHex = ''; _waistbandColorCtrl.clear(); } }
              else { _waistbandOptions.add(id); }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? _purple : Colors.white,
                border: Border.all(color: isSel ? _purple : const Color(0xFFCCCCCC)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isSel ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 14, color: isSel ? Colors.white : const Color(0xFF888888)),
                const SizedBox(width: 6),
                Icon(icon, size: 13, color: isSel ? Colors.white60 : const Color(0xFF888888)),
                const SizedBox(width: 5),
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white : const Color(0xFF1A1A1A))),
                  Text('무료', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white60 : const Color(0xFF2E7D32))),
                ]),
              ]),
            ),
          );
        }).toList()),

        if (_waistbandOptions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(10),
            color: const Color(0xFFF8F8F8),
            child: Row(children: [
              const Icon(Icons.receipt_long_outlined, size: 13, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 6),
              Text('선택: $_waistbandOptionLabel', style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('+${_fmt(_waistbandExtra)}원', style: const TextStyle(fontSize: 13, color: Color(0xFFE65100), fontWeight: FontWeight.w700)),
            ]),
          ),
        ],

        if (needsColor) ...[
          const SizedBox(height: 14),
          const Text('허리밴드 HEX 색상 코드', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
          const SizedBox(height: 6),
          Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _waistbandColorHex.length == 7 ? _parseHexColor(_waistbandColorHex) : const Color(0xFFEEEEEE),
                border: Border.all(color: const Color(0xFFCCCCCC)),
              ),
              child: _waistbandColorHex.length != 7 ? const Icon(Icons.palette_outlined, color: Color(0xFFAAAAAA), size: 16) : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(
              controller: _waistbandColorCtrl,
              maxLength: 7,
              decoration: InputDecoration(
                hintText: '#1A1A1A', counterText: '',
                prefixText: _waistbandColorCtrl.text.isEmpty ? '#' : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A1A1A), width: 1.5)),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              onChanged: (v) {
                String hex = v.trim();
                if (!hex.startsWith('#')) hex = '#$hex';
                if (hex.length <= 7) setState(() => _waistbandColorHex = hex.length == 7 ? hex : '');
              },
            )),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 5, runSpacing: 5, children: AppConstants.twoFitColors.map((c) {
            final hexVal = '#${(c['hex'] as int).toRadixString(16).substring(2).toUpperCase()}';
            final isSel = _waistbandColorHex.toUpperCase() == hexVal.toUpperCase();
            return GestureDetector(
              onTap: () => setState(() { _waistbandColorHex = hexVal; _waistbandColorCtrl.text = hexVal; }),
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: Color(c['hex'] as int),
                  border: Border.all(color: isSel ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC), width: isSel ? 2 : 1),
                ),
                child: isSel ? Icon(Icons.check, size: 14, color: _isLightColor(Color(c['hex'] as int)) ? Colors.black : Colors.white) : null,
              ),
            );
          }).toList()),
        ],
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 색상 선택
  // ══════════════════════════════════════════════
  Widget _buildColorSection() {
    return _card(
      title: '색상 선택 *',
      icon: Icons.palette_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 색상 안내
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCCCCCC))),
          child: Column(children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFF8F8F8),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF1A1A1A)),
                const SizedBox(width: 6),
                const Text('색상 적용 안내', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: const Color(0xFF1A1A1A),
                    child: const Text('상의', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white))),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('포인트 또는 전체 색상이 선택 색상으로 변경됩니다.', style: TextStyle(fontSize: 11, color: Color(0xFF444444), height: 1.5))),
                ]),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: const Color(0xFF555555),
                    child: const Text('하의', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white))),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('허리밴드(기본색) 유지, 나머지 부분이 변경됩니다.', style: TextStyle(fontSize: 11, color: Color(0xFF444444), height: 1.5))),
                ]),
              ]),
            ),
          ]),
        ),

        // TabBar (팔레트 / 빠른선택 / HEX직접입력)
        Container(
          color: const Color(0xFFF8F8F8),
          child: TabBar(
            controller: _colorTabCtrl,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            labelColor: const Color(0xFF1A1A1A),
            unselectedLabelColor: const Color(0xFF888888),
            indicatorColor: const Color(0xFF1A1A1A),
            indicatorWeight: 2,
            tabs: const [Tab(text: '팔레트'), Tab(text: '빠른 선택'), Tab(text: 'HEX 직접')],
          ),
        ),
        SizedBox(
          height: 220,
          child: TabBarView(
            controller: _colorTabCtrl,
            children: [
              _colorPickerTab(),
              _quickColorTab(),
              _hexInputTab(),
            ],
          ),
        ),

        // 선택된 색상 표시
        if (_mainColorName != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            color: const Color(0xFFF8F8F8),
            child: Row(children: [
              Container(width: 20, height: 20, color: _mainColor, margin: const EdgeInsets.only(right: 4)),
              const Text('→ ', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              Container(width: 28, height: 28, color: _adjustedColor,
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCCCCCC)))),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_mainColorName!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                Text('#${_adjustedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()} · $_lightnessLabel',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF888888), fontFamily: 'monospace')),
              ]),
            ]),
          ),

          // 농도 슬라이더
          const SizedBox(height: 10),
          Row(children: [
            const Text('밝기 조절', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
            const SizedBox(width: 8),
            Text(_lightnessLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          ]),
          Slider(
            value: _colorLightness, min: 0.05, max: 0.95, divisions: 18,
            activeColor: const Color(0xFF1A1A1A),
            inactiveColor: const Color(0xFFE0E0E0),
            onChanged: (v) => setState(() => _colorLightness = v),
          ),
        ],
      ]),
    );
  }

  Widget _colorPickerTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      child: ColorPickerWidget(
        onColorSelected: (name, color) => setState(() {
          _mainColorName = name;
          _mainColor = color;
          _colorLightness = HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
        }),
        selectedColorName: _mainColorName,
      ),
    );
  }

  Widget _quickColorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      child: Wrap(spacing: 8, runSpacing: 8, children: AppConstants.twoFitColors.map((c) {
        final name = c['name'] as String;
        final colorVal = Color(c['hex'] as int);
        final isSel = _mainColorName == name;
        return GestureDetector(
          onTap: () => setState(() {
            _mainColorName = name; _mainColor = colorVal;
            _colorLightness = HSLColor.fromColor(colorVal).lightness.clamp(0.05, 0.95);
          }),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: colorVal,
                border: Border.all(color: isSel ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0), width: isSel ? 2.5 : 1),
              ),
              child: isSel ? Icon(Icons.check, size: 18, color: _isLightColor(colorVal) ? Colors.black : Colors.white) : null,
            ),
            const SizedBox(height: 3),
            Text(name, style: const TextStyle(fontSize: 9, color: Color(0xFF555555))),
          ]),
        );
      }).toList()),
    );
  }

  Widget _hexInputTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            color: _mainColor ?? const Color(0xFFEEEEEE),
            child: _mainColor == null ? const Icon(Icons.palette_outlined, color: Color(0xFFAAAAAA)) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: TextField(
            controller: _hexCtrl,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: '#1A1A1A',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              errorText: _hexError,
              border: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A1A1A), width: 1.5)),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
            ),
          )),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _applyHexColor(_hexCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(), elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: const Text('적용', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        const Text('6자리 HEX 코드 입력 (예: #1A1A1A)', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 디자인 참고 이미지
  // ══════════════════════════════════════════════
  Widget _buildRefImageSection() {
    return _card(
      title: '디자인 참고 이미지',
      icon: Icons.design_services_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFFF8F8F8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF888888)),
              SizedBox(width: 6),
              Text('원하시는 디자인 파일을 첨부해 주세요', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
            ]),
            const SizedBox(height: 6),
            _dotRow('앞면·뒷면 디자인을 모두 첨부하면 더욱 정확합니다.'),
            _dotRow('지원: PNG · JPG · PDF · AI · PSD · SVG 등'),
            _dotRow('여러 파일은 ZIP으로 압축 후 업로드해 주세요.'),
          ]),
        ),
        _refImageCard(),
        const SizedBox(height: 14),
        _buildDesignLogoUpload(),
      ]),
    );
  }

  Widget _dotRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('·  ', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.5))),
      ]),
    );
  }

  Widget _refImageCard() {
    return GestureDetector(
      onTap: () async {
        try {
          final picker = ImagePicker();
          final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
          if (xfile == null) return;
          final bytes = await xfile.readAsBytes();
          final b64 = base64Encode(bytes);
          await _saveImage(base64: b64);
          if (!mounted) return;
          setState(() => _refBase64 = b64);
        } catch (e) { _showSnack('이미지 선택 오류: $e'); }
      },
      child: Container(
        width: double.infinity, height: 110,
        decoration: BoxDecoration(
          color: _refBase64 != null ? const Color(0xFFF8F8F8) : Colors.white,
          border: Border.all(color: _refBase64 != null ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC),
              width: _refBase64 != null ? 1.5 : 1),
        ),
        child: _refBase64 != null
            ? Stack(children: [
                Center(child: Image.memory(base64Decode(_refBase64!), height: 90, fit: BoxFit.contain)),
                Positioned(top: 6, right: 6, child: GestureDetector(
                  onTap: () async { await _saveImage(base64: null); setState(() => _refBase64 = null); },
                  child: Container(padding: const EdgeInsets.all(3), color: Colors.black54,
                    child: const Icon(Icons.close, color: Colors.white, size: 14)),
                )),
                Positioned(bottom: 6, left: 0, right: 0, child: Center(
                  child: Text('업로드됨 · 탭하여 재선택', style: const TextStyle(fontSize: 10, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
                )),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF888888), size: 30),
                const SizedBox(height: 6),
                const Text('디자인 참고 이미지 업로드', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
                const SizedBox(height: 2),
                const Text('탭하여 선택', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
              ]),
      ),
    );
  }

  Widget _buildDesignLogoUpload() {
    final hasFile = _designLogoFileName != null;
    final isImage = hasFile && RegExp(r'\.(png|jpg|jpeg|gif|webp|bmp)$', caseSensitive: false).hasMatch(_designLogoFileName!);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.attach_file_rounded, size: 13, color: Color(0xFF888888)),
        const SizedBox(width: 5),
        const Text('로고 파일 첨부 (선택)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
      ]),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 8),
        color: const Color(0xFFFFF8E1),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFF57F17)),
          const SizedBox(width: 6),
          const Expanded(child: Text('AI · EPS · SVG · PDF 권장 / JPG·PNG는 품질 저하 가능\n로고 인쇄 품질을 위해 벡터 파일을 첨부해 주세요.',
              style: TextStyle(fontSize: 11, color: Color(0xFF7B5800), height: 1.5))),
        ]),
      ),
      GestureDetector(
        onTap: () async {
          try {
            final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false, withData: true);
            if (result == null || result.files.isEmpty) return;
            final file = result.files.first;
            if (!mounted) return;
            setState(() { _designLogoFileName = file.name; _designLogoBytes = file.bytes != null ? List<int>.from(file.bytes!) : null; });
          } catch (e) { _showSnack('파일 선택 오류: $e'); }
        },
        child: Container(
          width: double.infinity, height: 90,
          decoration: BoxDecoration(
            color: hasFile ? const Color(0xFFF8F8F8) : Colors.white,
            border: Border.all(color: hasFile ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC)),
          ),
          child: hasFile
              ? Stack(children: [
                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (isImage && _designLogoBytes != null)
                      Image.memory(Uint8List.fromList(_designLogoBytes!), height: 56, fit: BoxFit.contain)
                    else
                      Container(width: 44, height: 44, color: const Color(0xFFF0F0F0),
                        child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF888888), size: 26)),
                    const SizedBox(height: 4),
                    Text(_designLogoFileName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  ])),
                  Positioned(top: 5, right: 5, child: GestureDetector(
                    onTap: () => setState(() { _designLogoFileName = null; _designLogoBytes = null; }),
                    child: Container(padding: const EdgeInsets.all(2), color: Colors.black54,
                      child: const Icon(Icons.close, color: Colors.white, size: 13)),
                  )),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.upload_file_rounded, color: Color(0xFF888888), size: 28),
                  const SizedBox(height: 4),
                  const Text('로고 파일 선택', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
                ]),
        ),
      ),
    ]);
  }

  // ══════════════════════════════════════════════
  // 허리밴드 로고 업로드
  // ══════════════════════════════════════════════
  Widget _buildWaistbandLogoSection() {
    if (_waistbandOptions.isEmpty) return const SizedBox.shrink();
    final hasFile = _waistbandLogoFileName != null;
    final isImage = hasFile && RegExp(r'\.(png|jpg|jpeg|gif|webp|bmp)$', caseSensitive: false).hasMatch(_waistbandLogoFileName!);

    return _card(
      title: '허리밴드 로고 파일',
      icon: Icons.upload_file_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 10),
          color: const Color(0xFFFFF8E1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFF57F17)),
            const SizedBox(width: 6),
            const Expanded(child: Text('AI · EPS · SVG · PDF 권장\nJPG·PNG는 인쇄 품질 저하 가능',
                style: TextStyle(fontSize: 11, color: Color(0xFF7B5800), height: 1.5))),
          ]),
        ),
        GestureDetector(
          onTap: _pickWaistbandLogoFile,
          child: Container(
            height: 110, width: double.infinity,
            decoration: BoxDecoration(
              color: hasFile ? const Color(0xFFF8F8F8) : Colors.white,
              border: Border.all(color: hasFile ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC)),
            ),
            child: hasFile
                ? Stack(children: [
                    Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (isImage && _waistbandLogoBytes != null)
                        Image.memory(Uint8List.fromList(_waistbandLogoBytes!), height: 60, fit: BoxFit.contain)
                      else
                        Container(width: 44, height: 44, color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF888888), size: 26)),
                      const SizedBox(height: 4),
                      Text(_waistbandLogoFileName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                    ])),
                    Positioned(top: 5, right: 5, child: GestureDetector(
                      onTap: () => setState(() { _waistbandLogoFileName = null; _waistbandLogoBytes = null; }),
                      child: Container(padding: const EdgeInsets.all(2), color: Colors.black54,
                        child: const Icon(Icons.close, color: Colors.white, size: 13)),
                    )),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.upload_file_rounded, color: Color(0xFF888888), size: 28),
                    const SizedBox(height: 4),
                    const Text('허리밴드 로고 파일 선택', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
                  ]),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 허리밴드 참고 이미지
  // ══════════════════════════════════════════════
  Widget _buildWaistbandRefImageSection() {
    if (_waistbandOptions.isEmpty) return const SizedBox.shrink();
    return _card(
      title: '허리밴드 참고 이미지 (최대 3장)',
      icon: Icons.photo_library_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('원하시는 디자인/색상 참고 이미지를 첨부해 주세요.',
            style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            ..._waistbandRefImages.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(right: 8),
              child: Stack(children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1A1A1A))),
                  child: Image.memory(base64Decode(e.value), fit: BoxFit.cover),
                ),
                Positioned(top: 4, right: 4, child: GestureDetector(
                  onTap: () => setState(() => _waistbandRefImages.removeAt(e.key)),
                  child: Container(padding: const EdgeInsets.all(2), color: Colors.black54,
                    child: const Icon(Icons.close, color: Colors.white, size: 13)),
                )),
              ]),
            )),
            if (_waistbandRefImages.length < 3)
              GestureDetector(
                onTap: _pickWaistbandRefImage,
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    border: Border.all(color: const Color(0xFFCCCCCC), style: BorderStyle.solid),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF888888), size: 24),
                    const SizedBox(height: 4),
                    const Text('추가', style: TextStyle(fontSize: 10, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 요청사항 메모
  // ══════════════════════════════════════════════
  Widget _buildMemoSection() {
    return _card(
      title: '디자인 요청사항 *',
      icon: Icons.edit_note_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 10),
          color: const Color(0xFFF8F8F8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.lightbulb_outline_rounded, size: 13, color: Color(0xFF888888)),
              SizedBox(width: 5),
              Text('구체적일수록 정확한 제작이 가능합니다', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
            ]),
            const SizedBox(height: 6),
            _dotRow('로고/단체명 위치, 크기, 색상'),
            _dotRow('전면·후면 각각 어떻게 인쇄할지'),
            _dotRow('특별한 폰트나 스타일 요청'),
          ]),
        ),
        TextField(
          controller: _memoCtrl,
          maxLines: 5,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: '예) 전면 왼쪽 상단에 단체명 흰색, 후면 중앙에 번호 인쇄...',
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
            border: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A1A1A), width: 1.5)),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 인원별 사이즈 섹션
  // ══════════════════════════════════════════════
  Widget _buildPersonListSection() {
    return _card(
      title: '인원별 사이즈 (총 $_totalCount명)',
      icon: Icons.format_list_numbered_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 재봉방법 요약
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          color: const Color(0xFFF8F8F8),
          child: Row(children: [
            const Icon(Icons.content_cut_outlined, size: 13, color: Color(0xFF888888)),
            const SizedBox(width: 6),
            Text('재봉: $_fabricType', style: const TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w600)),
            if (_fabricExtra > 0) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: const Color(0xFFE65100),
                child: Text('+${_fmt(_fabricExtra)}원', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
            ],
          ]),
        ),
        if (_mainColorName != null) ...[
          Container(
            padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 8),
            color: const Color(0xFFF8F8F8),
            child: Row(children: [
              Container(width: 18, height: 18, color: _mainColor),
              const Text(' → ', style: TextStyle(color: Color(0xFF888888))),
              Container(width: 24, height: 24, color: _adjustedColor,
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCCCCCC)))),
              const SizedBox(width: 8),
              Text('$_mainColorName · $_lightnessLabel', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            ]),
          ),
        ],
        // 인원 카드 목록
        ..._persons.asMap().entries.map((e) => _buildPersonCard(e.key, e.value)),
        // 추가 버튼
        GestureDetector(
          onTap: _addPerson,
          child: Container(
            width: double.infinity, height: 44, margin: const EdgeInsets.only(top: 8),
            color: const Color(0xFFF0F0F0),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add, color: Color(0xFF1A1A1A), size: 18),
              SizedBox(width: 6),
              Text('인원 추가', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildPersonCard(int idx, _PersonEntry p) {
    final isMale = p.gender == 'male';
    final isFemale = p.gender == 'female';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: p.gender != null ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: p.gender != null ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
          child: Row(children: [
            Container(
              width: 22, height: 22,
              color: p.gender != null ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE0E0E0),
              alignment: Alignment.center,
              child: Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                  color: p.gender != null ? Colors.white : const Color(0xFF888888))),
            ),
            if (_nameEnabled) ...[
              const SizedBox(width: 8),
              Expanded(child: SizedBox(height: 28, child: TextField(
                controller: p.nameCtrl,
                style: TextStyle(fontSize: 12, color: p.gender != null ? Colors.white : const Color(0xFF333333)),
                decoration: InputDecoration(
                  hintText: '이름 (선택)',
                  hintStyle: TextStyle(fontSize: 11, color: p.gender != null ? Colors.white38 : const Color(0xFFAAAAAA)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(borderSide: BorderSide(color: p.gender != null ? Colors.white30 : const Color(0xFFCCCCCC))),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: p.gender != null ? Colors.white24 : const Color(0xFFDDDDDD))),
                ),
              ))),
            ] else
              const Expanded(child: SizedBox()),
            const SizedBox(width: 6),
            // 성별 버튼
            Row(mainAxisSize: MainAxisSize.min, children: [
              _genderBtn('남', isMale, const Color(0xFF1A1A1A), () => setState(() => p.gender = 'male')),
              const SizedBox(width: 4),
              _genderBtn('여', isFemale, const Color(0xFF555555), () => setState(() => p.gender = 'female')),
            ]),
            const SizedBox(width: 6),
            // 불러오기
            GestureDetector(
              onTap: () => _showLoadSizeSheet(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                color: p.gender != null ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE8E8E8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.download_outlined, size: 12, color: p.gender != null ? Colors.white70 : const Color(0xFF888888)),
                  const SizedBox(width: 3),
                  Text('불러오기', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: p.gender != null ? Colors.white70 : const Color(0xFF888888))),
                ]),
              ),
            ),
            const SizedBox(width: 4),
            // 삭제
            GestureDetector(
              onTap: () => _removePerson(idx),
              child: Icon(Icons.close, size: 16, color: p.gender != null ? Colors.white54 : const Color(0xFFAAAAAA)),
            ),
          ]),
        ),
        // 사이즈 입력 영역
        Padding(
          padding: const EdgeInsets.all(12),
          child: p.gender == null
              ? Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  color: const Color(0xFFF8F8F8),
                  child: Column(children: [
                    const Icon(Icons.wc_rounded, size: 24, color: Color(0xFFCCCCCC)),
                    const SizedBox(height: 6),
                    const Text('성별을 먼저 선택해 주세요', style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                  ]),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // 성인/주니어
                  Row(children: [
                    const Text('구분', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                    const SizedBox(width: 10),
                    _sizeTypeBtn('성인', p, const Color(0xFF1A1A1A)),
                    const SizedBox(width: 6),
                    _sizeTypeBtn('주니어', p, const Color(0xFF555555)),
                  ]),
                  const SizedBox(height: 10),
                  _buildPersonSizeTable(p),
                  const SizedBox(height: 10),
                  if (!_isBottomOnly) ...[
                    _buildPersonSizeSelector(label: '상의 사이즈 *', icon: Icons.checkroom_outlined, selected: p.topSize, sizeType: p.sizeType, onSelect: (v) => setState(() => p.topSize = v)),
                    const SizedBox(height: 10),
                  ],
                  _buildPersonSizeSelector(label: '하의 사이즈 *', icon: Icons.straighten_outlined, selected: p.bottomSize, sizeType: p.sizeType, onSelect: (v) => setState(() => p.bottomSize = v)),
                  const SizedBox(height: 10),
                  // 상세 치수
                  GestureDetector(
                    onTap: () => setState(() => p.showDetail = !p.showDetail),
                    child: Row(children: [
                      Icon(p.showDetail ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: const Color(0xFF888888)),
                      const SizedBox(width: 4),
                      Text(p.showDetail ? '상세 치수 접기' : '상세 치수 입력 (선택사항)',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  if (p.showDetail) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _detailField('키(cm)', p.heightCtrl),
                      _detailField('몸무게(kg)', p.weightCtrl),
                      _detailField('허리(cm)', p.waistCtrl),
                      _detailField('허벅지(cm)', p.thighCtrl),
                    ]),
                  ],
                ]),
        ),
      ]),
    );
  }

  Widget _detailField(String hint, TextEditingController ctrl) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint, isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A1A1A), width: 1.5)),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
        ),
      ),
    );
  }

  Widget _genderBtn(String label, bool active, Color activeColor, VoidCallback fn) {
    return GestureDetector(
      onTap: fn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.1),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF1A1A1A) : Colors.white54)),
      ),
    );
  }

  Widget _sizeTypeBtn(String label, _PersonEntry p, Color activeColor) {
    final isSel = p.sizeType == label;
    return GestureDetector(
      onTap: () => setState(() { p.sizeType = label; p.topSize = null; p.bottomSize = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border.all(color: isSel ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: isSel ? Colors.white : const Color(0xFF888888))),
      ),
    );
  }

  Widget _buildPersonSizeTable(_PersonEntry p) {
    final rows = p.sizeType == '성인' ? _kAdultSizeRows : _kJuniorSizeRows;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => setState(() => p.showSizeTable = !p.showSizeTable),
        child: Row(children: [
          Icon(p.showSizeTable ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 15, color: const Color(0xFF888888)),
          const SizedBox(width: 3),
          Text(p.showSizeTable ? '사이즈표 닫기' : '사이즈표 보기',
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
        ]),
      ),
      if (p.showSizeTable) ...[
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: const Color(0xFFE0E0E0), width: 0.5),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
                children: ['사이즈', '키(cm)', '몸무게(kg)', '상의', '하의'].map((h) =>
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(h, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)))).toList(),
              ),
              ...rows.map((r) => TableRow(
                children: r.map((cell) =>
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(cell, style: const TextStyle(fontSize: 11, color: Color(0xFF333333))))).toList(),
              )),
            ],
          ),
        ),
      ],
    ]);
  }

  Widget _buildPersonSizeSelector({required String label, required IconData icon, required String? selected, required String sizeType, required ValueChanged<String?> onSelect}) {
    final sizes = sizeType == '성인' ? _kAdultSizes : _kJuniorSizes;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 13, color: const Color(0xFF888888)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: sizes.map((s) {
        final isSel = selected == s;
        return GestureDetector(
          onTap: () => onSelect(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFF1A1A1A) : Colors.white,
              border: Border.all(color: isSel ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC)),
            ),
            child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: isSel ? Colors.white : const Color(0xFF1A1A1A))),
          ),
        );
      }).toList()),
    ]);
  }

  // ══════════════════════════════════════════════
  // 기본 정보 섹션
  // ══════════════════════════════════════════════
  Widget _buildBasicInfoSection() {
    return _card(
      title: '주문자 정보',
      icon: Icons.person_outline_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _inputField('단체명 *', _teamNameCtrl, '예) 2FIT 배구팀'),
        _inputField('담당자 이름', _managerNameCtrl, '예) 홍길동'),
        _inputField('연락처 *', _phoneCtrl, '010-0000-0000', keyboardType: TextInputType.phone),
        _inputField('이메일', _emailCtrl, '예) example@mail.com', keyboardType: TextInputType.emailAddress),
        // 주소
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('배송 주소 *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
              const Spacer(),
              Builder(builder: (ctx) {
                final user = Provider.of<UserProvider>(ctx, listen: false).user;
                if (user == null || user.addresses.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => _showSavedAddressPicker(user.addresses),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: const Color(0xFFF0F0F0),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.bookmark_outline_rounded, size: 11, color: Color(0xFF1A1A1A)),
                      const SizedBox(width: 3),
                      const Text('저장 주소', style: TextStyle(fontSize: 11, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700)),
                    ]),
                  ),
                );
              }),
            ]),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _openKakaoAddressSearch(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: _address.isEmpty ? const Color(0xFFCCCCCC) : const Color(0xFF1A1A1A),
                      width: _address.isEmpty ? 1 : 1.5),
                  color: _address.isEmpty ? Colors.white : const Color(0xFFF8F8F8),
                ),
                child: Row(children: [
                  Icon(Icons.location_on_outlined, size: 15,
                      color: _address.isEmpty ? const Color(0xFF888888) : const Color(0xFF1A1A1A)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_address.isEmpty ? '주소 검색 (카카오)' : _address,
                      style: TextStyle(fontSize: 13, color: _address.isEmpty ? const Color(0xFFAAAAAA) : const Color(0xFF1A1A1A)))),
                  Icon(Icons.search, size: 16, color: _address.isEmpty ? const Color(0xFF888888) : const Color(0xFF1A1A1A)),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _addressDetailCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: '상세주소 입력 (동/호수 등) *',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                filled: true, fillColor: Colors.white,
                border: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A1A1A), width: 1.5)),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
                prefixIcon: const Icon(Icons.home_outlined, size: 15, color: Color(0xFF888888)),
              ),
            ),
          ]),
        ),
        // 독점 사용권 체크박스
        GestureDetector(
          onTap: () => setState(() => _exclusiveDesign = !_exclusiveDesign),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(12),
            color: _exclusiveDesign ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
            child: Row(children: [
              Icon(_exclusiveDesign ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 20, color: _exclusiveDesign ? Colors.white : const Color(0xFF888888)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('1년 독점 디자인 사용권 신청',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                        color: _exclusiveDesign ? Colors.white : const Color(0xFF1A1A1A))),
                Text('무료 · 같은 디자인 색상만 변경 가능',
                    style: TextStyle(fontSize: 11, color: _exclusiveDesign ? Colors.white60 : const Color(0xFF888888))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: _exclusiveDesign ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE0E0E0),
                child: Text('FREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                    color: _exclusiveDesign ? Colors.white : const Color(0xFF888888))),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  void _inputFieldBuilder() {} // placeholder (unused)

  Widget _inputField(String label, TextEditingController ctrl, String hint, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            filled: true, fillColor: Colors.white,
            border: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A1A1A), width: 1.5)),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
          ),
        ),
      ]),
    );
  }

  // ── 저장된 주소 선택
  void _showSavedAddressPicker(List addresses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(0))),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.8, expand: false,
          builder: (_, sc) => Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
              child: Row(children: [
                const Icon(Icons.bookmark_rounded, size: 15, color: Color(0xFF1A1A1A)),
                const SizedBox(width: 8),
                const Text('저장된 배송지 선택', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF888888))),
              ]),
            ),
            Expanded(child: ListView.builder(
              controller: sc,
              itemCount: addresses.length,
              itemBuilder: (_, i) {
                final addr = addresses[i];
                final name = addr is Map ? (addr['name'] ?? '배송지 ${i + 1}') : '배송지 ${i + 1}';
                final address = addr is Map ? (addr['address'] ?? '') : addr.toString();
                return GestureDetector(
                  onTap: () { setState(() => _address = address.toString()); Navigator.pop(context); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 3),
                      Text(address.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  void _openKakaoAddressSearch() async {
    final result = await showKakaoAddressSearch(context);
    if (result != null && mounted) {
      setState(() { _address = result.roadAddress.isNotEmpty ? result.roadAddress : result.jibunAddress; });
    }
  }

  // ══════════════════════════════════════════════
  // 취소·환불 규정
  // ══════════════════════════════════════════════
  Widget _buildCancelPolicySection() {
    return _card(
      title: '취소·환불 규정',
      icon: Icons.policy_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 기성품
        Container(
          padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: const Color(0xFFF8F8F8), border: Border.all(color: const Color(0xFFE0E0E0))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), color: const Color(0xFF2E7D32),
              child: const Text('기성품', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            const Expanded(child: Text('수령 후 3일 이내 교환·환불 가능',
                style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700, height: 1.5))),
          ]),
        ),
        // 커스텀
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF8F8F8), border: Border.all(color: const Color(0xFFE0E0E0))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), color: const Color(0xFFC62828),
                child: const Text('커스텀(단체)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              const Expanded(child: Text('의류 자체 불량 외 교환·환불 불가',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC62828), fontWeight: FontWeight.w700, height: 1.5))),
            ]),
            const SizedBox(height: 6),
            const Text('커스텀 제작 특성상 옷 자체의 하자가 아닌 경우\n교환·환불이 불가합니다.',
                style: TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.6)),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 금액 요약
  // ══════════════════════════════════════════════
  Widget _buildSummarySection() {
    return _card(
      title: '금액 요약',
      icon: Icons.receipt_long_outlined,
      child: Column(children: [
        _sumRow('기본 단가', '${_fmt(_basePrice)}원/인'),
        if (_fabricExtra > 0) _sumRow('  ↳ 심리스 추가', '+${_fmt(_fabricExtra)}원/인', valueColor: const Color(0xFFE65100)),
        if (_isTights9) _sumRow('  ↳ 타이즈 9부 추가', '+${_fmt(_tights9Price)}원/인', valueColor: const Color(0xFFE65100)),
        if (_hasPocket) _sumRow('  ↳ 주머니 추가', '+${_fmt(_pocketPrice)}원/인', valueColor: const Color(0xFFE65100)),
        _sumRow('인원당 단가', '${_fmt(_unitPrice)}원/인', isSub: true),
        const SizedBox(height: 4),
        _sumRow('총 인원', '$_totalCount명'),
        const Divider(height: 20, color: Color(0xFFEEEEEE)),
        _sumRow('상품 합계', '${_fmt(_subTotal)}원'),
        _sumRow('배송비',
            _totalCount >= AppConstants.groupMinFreeShipping ? '무료' : '+${_fmt(_shipping)}원',
            valueColor: _totalCount >= AppConstants.groupMinFreeShipping ? const Color(0xFF2E7D32) : null),
        if (_waistbandExtra > 0) _sumRow('허리밴드 옵션', '+${_fmt(_waistbandExtra)}원', valueColor: const Color(0xFFE65100)),
        if (_exclusiveDesign) _sumRow('1년 독점 사용권', '무료', valueColor: const Color(0xFF2E7D32)),
        const Divider(height: 20, color: Color(0xFFEEEEEE)),
        _sumRow('최종 결제금액', '${_fmt(_finalPrice)}원', isTotal: true),
      ]),
    );
  }

  Widget _sumRow(String label, String value, {bool isTotal = false, bool isSub = false, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 2 : 3),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(
            fontSize: isTotal ? 14 : (isSub ? 12 : 13),
            fontWeight: isTotal ? FontWeight.w800 : (isSub ? FontWeight.w700 : FontWeight.w500),
            color: isTotal ? const Color(0xFF1A1A1A) : (isSub ? const Color(0xFF1A1A1A) : const Color(0xFF666666))))),
        Text(value, style: TextStyle(
            fontSize: isTotal ? 16 : (isSub ? 13 : 13),
            fontWeight: isTotal ? FontWeight.w900 : (isSub ? FontWeight.w800 : FontWeight.w600),
            color: valueColor ?? (isTotal ? const Color(0xFF1A1A1A) : const Color(0xFF333333)))),
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
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('$_totalCount명', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
            Text('${_fmt(_finalPrice)}원', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          ]),
        ),
        OutlinedButton(
          onPressed: () => _submitOrder(isBuyNow: false),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A1A1A),
            side: const BorderSide(color: Color(0xFF1A1A1A)),
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: const Text('장바구니', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _submitOrder(isBuyNow: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            elevation: 0,
          ),
          child: const Text('바로 구매', style: TextStyle(fontWeight: FontWeight.w800)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 2, 0, 2),
          decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF1A1A1A), width: 3))),
          child: Row(children: [
            Icon(icon, color: const Color(0xFF1A1A1A), size: 16),
            const SizedBox(width: 7),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), letterSpacing: -0.2)),
          ]),
        ),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}
