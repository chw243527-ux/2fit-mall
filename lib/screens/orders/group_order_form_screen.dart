import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/net_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
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
const List<String> _kAdultSizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
const List<String> _kJuniorSizes = [
  'XXS(80)',
  'XS(90)',
  'S(100)',
  'M(110)',
  'L(120)',
  'XL(130)'
];
const List<List<String>> _kAdultSizeRows = [
  ['XS', '154~159', '44~51', '85', '68'],
  ['S', '160~165', '52~60', '90', '72'],
  ['M', '166~172', '61~71', '95', '76'],
  ['L', '172~177', '72~78', '100', '80'],
  ['XL', '177~182', '79~85', '105', '84'],
  ['2XL', '182~187', '86~91', '110', '88'],
  ['3XL', '187~191', '91~96', '115', '92'],
];
const List<List<String>> _kJuniorSizeRows = [
  ['XXS(80)', '104~116', '16~20', '58', '55'],
  ['XS(90)', '116~128', '20~25', '63', '58'],
  ['S(100)', '128~140', '25~32', '68', '62'],
  ['M(110)', '140~152', '32~40', '73', '65'],
  ['L(120)', '152~158', '40~48', '78', '68'],
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
  final TextEditingController topSizeCtrl = TextEditingController();
  final TextEditingController bottomSizeCtrl = TextEditingController();

  // 이름
  final TextEditingController nameCtrl = TextEditingController();

  // 사이즈표 토글
  bool showSizeTable = false;

  // 상세 치수 (하의 아래 별도 블록)
  bool showDetail = false;
  final TextEditingController heightCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController waistCtrl = TextEditingController();
  final TextEditingController thighCtrl = TextEditingController();

  _PersonEntry({required this.index});

  // 선택된 사이즈 값 (선택형 우선, 없으면 직접입력)
  String get effectiveTopSize => topSize ?? topSizeCtrl.text.trim();
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
  static const Color _purple = AppColors.primary; // 블랙 (탑텐 강조색)
  static const Color _purpleLight = AppColors.surfaceGray; // 라이트 그레이 배경
  static const Color _bg = AppColors.background; // 페이지 배경

  // loc 의존성 완전 제거 — LanguageProvider.watch 호출 없음

  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // ── 색상 탭 컨트롤러 ──
  late TabController _colorTabCtrl;
  final _hexCtrl = TextEditingController();
  String? _hexError;
  Color _hexPreview = AppColors.primary;

  // ── 수량 ──
  int _count = 5;
  bool _countFixed = false;

  // ── 주문 확정 동의 ──
  bool _orderConfirmed = false;

  // ── 인원 목록 ──
  final List<_PersonEntry> _persons = [];

  // ── 인쇄 타입 ──
  late int _printType;

  // ── 색상 ──
  String? _mainColorName; // 원본 색상 이름
  Color? _mainColor; // 원본 색상 (슬라이더 조절 전)
  double _colorLightness = 0.5; // 0.0(어두움) ~ 1.0(밝음), 기본 0.5

  /// 원본 색상에 lightness 를 적용한 최종 표시 색상
  Color get _adjustedColor {
    if (_mainColor == null) return Colors.transparent;
    final hsl = HSLColor.fromColor(_mainColor!);
    return hsl.withLightness(_colorLightness.clamp(0.05, 0.95)).toColor();
  }

  /// 농도 설명 텍스트
  String get _lightnessLabel {
    if (_colorLightness < 0.25) return context.loc.t('매우_진하게', '매우 진하게');
    if (_colorLightness < 0.4) return context.loc.t('진하게', '진하게');
    if (_colorLightness < 0.6) return context.loc.t('기본', '기본');
    if (_colorLightness < 0.75) return context.loc.t('밝게', '밝게');
    return context.loc.t('매우_밝게', '매우 밝게');
  }

  // ── 원단 ──
  String _fabricType = '일반 봉제'; // constants.fabricTypes[0] 과 동일하게 유지
  String _fabricWeight = '80g';

  // ── 하의 기본 길이 (남/여 분리) ──
  String? _maleLengthSel; // 남성 하의 길이
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
  String? _waistbandLogoFileName; // 파일명 (표시용)
  List<int>? _waistbandLogoBytes; // 파일 바이트 (base64 저장용)

  // ── 참조 이미지 (단일) ──
  String? _refBase64;
  static const _kRefKey = 'group_order_ref_base64';

  // ── 디자인 로고 파일 ──
  String? _designLogoFileName;
  List<int>? _designLogoBytes;

  // ── 기본 정보 ──
  final _teamNameCtrl = TextEditingController();
  final _managerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _addressDetailCtrl = TextEditingController(); // 상세주소
  String _address = '';

  // ── 독점 디자인 ──
  bool _exclusiveDesign = false; // ignore: prefer_final_fields

  // ── 추가 옵션 ──
  bool _hasPocket = false; // 주머니 선택 (+10,000원)

  // ══ 추가 옵션 가격 상수 ══
  static const int _tights9Price = 20000; // 타이즈 9부 추가금
  static const int _exclusivePrice = 0; // 1년 독점 — 무료 제공
  static const int _pocketPrice = 10000; // 주머니 추가금

  // ══ 파생값 ══
  bool get _isAdditional => widget.isAdditionalOrder;
  int get _totalCount => _persons.length;
  // 옵션별: 0=색상변경만, 1=단체명만, 2=단체명+색상, 3=디자인+단체명+색상, 4=디자인+색상+단체명+후면이름
  // ignore: unused_element
  // 0: 색상만, 1: 단체명+색상, 2: 디자인+단체명+색상, 3: 디자인유지+색상+단체명+이름(후면), 4: 디자인변경+색상+단체명+이름(후면)
  bool get _hasColorChange =>
      _printType == 0 ||
      _printType == 1 ||
      _printType == 2 ||
      _printType == 3 ||
      _printType == 4;
  bool get _hasTeamName =>
      _printType == 1 || _printType == 2 || _printType == 3 || _printType == 4;

  bool get _nameEnabled => _totalCount >= 10;
  OrderModel? get _originalOrder => widget.originalOrder;

  /// 허리밴드 옵션 레이블 (중복 선택 반영)
  String get _waistbandOptionLabel {
    if (_waistbandOptions.isEmpty) return context.loc.t('기본_변경없음', '기본 (변경없음)');
    final labels = <String>[];
    if (_waistbandOptions.contains(1))
      labels.add(context.loc.t('디자인_변경', '디자인 변경'));
    if (_waistbandOptions.contains(2))
      labels.add(context.loc.t('색상_변경', '색상 변경'));
    return labels.join(' + ');
  }

  /// 허리밴드 추가 비용 — 전부 무료
  double get _waistbandExtra => 0.0;

  int get _fabricExtra => AppConstants.fabricTypePrices[_fabricType] ?? 0;
  double get _basePrice => widget.product?.price ?? 0.0;
  // 타이즈 9부 선택 여부
  bool get _isTights9 => _maleLengthSel == '9부' || _femaleLengthSel == '9부';

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

  /// 상의 카테고리 단체주문: 인쇄타입·하의길이·허리밴드·주머니 숨김, 하의 사이즈 숨김
  /// - category == '상의'
  /// - category == '단체주문' 이면서 하의/세트가 아닌 subCategory (싱글렛B타입, 스킨슈트 등)
  bool get _isTopOnly {
    final p = widget.product;
    if (p == null) return false;
    if (p.category == '상의') return true;
    if (p.category == '단체주문') {
      // 하의에 해당하는 subCategory면 상의가 아님
      final sub = p.subCategory;
      final isBottom = sub.contains('타이즈') ||
          sub.contains('남성 5부') ||
          sub.contains('여성 2.5부') ||
          sub.contains('숏츠') ||
          sub.contains('트레이닝');
      // 세트(상의+하의)도 상의전용 아님
      final isSet =
          sub.contains('세트') || sub.contains('싱글렛세트') || sub.contains('A타입');
      if (!isBottom && !isSet) return true; // 싱글렛B타입, 스킨슈트, 기타 → 상의전용
    }
    return false;
  }

  // 숏사각(숏쇼츠) 선택 시 주머니 불가
  bool get _isFemaleShortSquare => _femaleLengthSel == '숏쇼츠';
  // 단가 = 기본가 + 심리스 + 9부 + 주머니 (모두 인원당 추가)
  double get _unitPrice =>
      _basePrice +
      _fabricExtra // 심리스: 인원당 +10,000
      +
      (_isTights9 ? _tights9Price : 0) // 9부:    인원당 +20,000
      +
      (_hasPocket ? _pocketPrice : 0); // 주머니: 인원당 +10,000
  double get _subTotal => _unitPrice * _totalCount;
  // 배송비: 5장 이상 무료, 5장 미만 4,000원
  double get _shipping => _totalCount >= AppConstants.groupMinFreeShipping
      ? 0
      : AppConstants.groupAdditionalShippingFee.toDouble();
  // 최종 = 소계(단가×인원) + 배송비 + 허리밴드 + 독점
  // ※ 주머니는 단가에 이미 포함 — 별도 가산 없음
  double get _finalPrice =>
      _subTotal +
      _shipping +
      _waistbandExtra +
      (_exclusiveDesign ? _exclusivePrice : 0);

  String _fmt(num v) => v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ══ 생명주기 ══
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 언어 변경 시 번역 트리거
      context.read<LanguageProvider>().triggerTranslation();
    });
    _printType = widget.initialPrintType.clamp(0, 3);
    // 추가제작: 1장부터 가능 / 신규 단체: 최소 5장
    final minCount = widget.isAdditionalOrder ? 1 : 5;
    _count = widget.initialCount >= minCount ? widget.initialCount : minCount;
    _countFixed = widget.initialCount >= minCount;
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
    for (final p in _persons) {
      p.dispose();
    }
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
      for (int i = 0; i < _persons.length; i++) {
        _persons[i].index = i;
      }
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
      for (int i = 0; i < _persons.length; i++) {
        _persons[i].index = i;
      }
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
      for (int i = 0; i < _persons.length; i++) {
        _persons[i].index = i;
      }
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
      _showSnack(context.loc
          .t('로그인_후_사이즈_프로필을_불러올_수_있습니다', '로그인 후 사이즈 프로필을 불러올 수 있습니다.'));
      return;
    }
    final profiles = context.read<SizeProfileProvider>().profiles;
    if (profiles.isEmpty) {
      _showSnack(context.loc.t('저장된_사이즈_프로필이_없습니다_마이페이지에서_먼저_저장해_주세요',
          '저장된 사이즈 프로필이 없습니다. 마이페이지에서 먼저 저장해 주세요.'));
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
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(context.loc.t('사이즈_프로필_선택', '사이즈 프로필 선택'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(
              context.loc
                  .t('선택하면_해당_팀원_칸에_자_fe6e44', '선택하면 해당 팀원 칸에 자동 입력됩니다.'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 14),
          ...profiles.map((profile) {
            final isMale = profile.gender == 'male';
            return GestureDetector(
              onTap: () {
                setState(() {
                  p.gender = profile.gender;
                  p.sizeType = profile.sizeType;
                  p.topSize =
                      profile.topSize.isNotEmpty ? profile.topSize : null;
                  p.bottomSize =
                      profile.bottomSize.isNotEmpty ? profile.bottomSize : null;
                  p.topSizeCtrl.text = profile.topSize;
                  p.bottomSizeCtrl.text = profile.bottomSize;
                  p.heightCtrl.text = profile.height;
                  p.weightCtrl.text = profile.weight;
                  p.waistCtrl.text = profile.waist;
                  p.thighCtrl.text = profile.thigh;
                  if (profile.height.isNotEmpty || profile.waist.isNotEmpty) {
                    p.showDetail = true;
                  }
                });
                Navigator.pop(context);
                _showSnack('"${profile.profileName}" ' +
                    context.loc.t('사이즈가_적용되었습니다', '사이즈가 적용되었습니다.'));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isMale
                      ? AppColors.info.withValues(alpha: 0.05)
                      : Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMale
                        ? AppColors.info.withValues(alpha: 0.3)
                        : Colors.pink.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMale ? AppColors.info : Colors.pink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(profile.genderLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.profileName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text(
                            context.loc.t('상의', '상의') +
                                ' ${profile.topSize} · ' +
                                context.loc.t('하의', '하의') +
                                ' ${profile.bottomSize}${profile.height.isNotEmpty ? " · " + context.loc.t('키', '키') + " ${profile.height}cm" : ""}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
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
        final nameCtrl =
            TextEditingController(text: context.loc.t('내_사이즈', '내 사이즈'));
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.save_outlined, color: _purple, size: 22),
            SizedBox(width: 8),
            Text(context.loc.t('내_사이즈_저장', '내 사이즈 저장'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                context.loc.t('첫_번째_팀원의_사이즈를_저_69e63d',
                    '첫 번째 팀원의 사이즈를 저장하면\n다음 주문 시 빠르게 불러올 수 있습니다.'),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: context.loc.t('프로필_이름', '프로필 이름'),
                hintText: context.loc.t('예__내_기본_사이즈', '예) 내 기본 사이즈'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              child: Text(context.loc.t('나중에', '나중에'),
                  style: TextStyle(color: Colors.grey.shade500)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final profile = SizeProfile(
                  id: '',
                  userId: user.id,
                  profileName: nameCtrl.text.trim().isEmpty
                      ? context.loc.t('내_사이즈', '내 사이즈')
                      : nameCtrl.text.trim(),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(err), backgroundColor: AppColors.error));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(context.loc.t('사이즈가_저장되었습니다', '사이즈가 저장되었습니다!')),
                      backgroundColor: _purple,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(context.loc.t('저장하기', '저장하기'),
                  style: TextStyle(fontWeight: FontWeight.w700)),
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

  bool _validate() {
    final minQty = _isAdditional ? 1 : 5;
    if (_totalCount < minQty) {
      _showSnack(context.loc.t('최소_minQty명_이상_주문_가능', '최소 ') +
          minQty.toString() +
          context.loc.t('명_이상_주문_가능합니다', '명 이상 주문 가능합니다.'));
      return false;
    }
    if (_mainColorName == null || _mainColorName!.isEmpty) {
      _showSnack(context.loc.t('색상을_선택해_주세요', '색상을 선택해 주세요.'));
      return false;
    }
    if (_teamNameCtrl.text.trim().isEmpty) {
      _showSnack(context.loc.t('단체명을_입력해_주세요', '단체명을 입력해 주세요.'));
      return false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnack(context.loc.t('연락처를_입력해_주세요', '연락처를 입력해 주세요.'));
      return false;
    }
    if (_address.isEmpty) {
      _showSnack(context.loc.t('배송_주소를_입력해_주세요', '배송 주소를 입력해 주세요.'));
      return false;
    }
    if (_addressDetailCtrl.text.trim().isEmpty) {
      _showSnack(context.loc.t('상세주소를_입력해_주세요', '상세주소를 입력해 주세요.'));
      return false;
    }
    if (!_isTopOnly && _maleLengthSel == null) {
      _showSnack(context.loc.t('남성_하의_길이를_선택해_주세요', '남성 하의 길이를 선택해 주세요.'));
      return false;
    }
    if (!_isTopOnly && _femaleLengthSel == null) {
      _showSnack(context.loc.t('여성_하의_길이를_선택해_주세요', '여성 하의 길이를 선택해 주세요.'));
      return false;
    }
    for (int i = 0; i < _persons.length; i++) {
      final p = _persons[i];
      if (p.gender == null) {
        _showSnack((i + 1).toString() +
            context.loc.t('번_인원의_성별을_선택해_주세요', '번 인원의 성별을 선택해 주세요.'));
        return false;
      }
      // 상의 사이즈 확인 (하의/타이즈 단체주문 시 생략)
      if (!_isBottomOnly && p.effectiveTopSize.isEmpty) {
        _showSnack((i + 1).toString() +
            context.loc.t('번_인원의_상의_사이즈를_입력해_주세요', '번 인원의 상의 사이즈를 입력해 주세요.'));
        return false;
      }
      // 하의 사이즈 확인 (상의 카테고리 단체주문 시 생략)
      if (!_isTopOnly && p.effectiveBottomSize.isEmpty) {
        _showSnack((i + 1).toString() +
            context.loc.t('번_인원의_사이즈를_입력해_주세요', '번 인원의 사이즈를 입력해 주세요.'));
        return false;
      }
    }
    // 디자인 요청 사항 필수 확인
    if (_memoCtrl.text.trim().isEmpty) {
      _showSnack(context.loc.t('디자인_요청_사항을_입력해_주세요', '디자인 요청 사항을 입력해 주세요.'));
      return false;
    }
    return true;
  }

  Future<void> _submitOrder({required bool isBuyNow}) async {
    if (!_validate()) return;
    final user = context.read<UserProvider>().user;
    // product.price 를 반드시 _unitPrice(기본가+심리스+9부+주머니 포함 인원당 단가)로 고정
    // CartItem.unitPrice = product.price + extraPrice 이므로 extraPrice: 0 과 함께 사용해야 정확
    final src = widget.product;
    final product = src == null
        ? ProductModel(
            id: 'group_direct_${DateTime.now().millisecondsSinceEpoch}',
            name: '단체주문',
            category: '단체주문',
            subCategory: '',
            price: _unitPrice,
            originalPrice: _unitPrice,
            description: '단체 직접 주문',
            images: [],
            sizes: [],
            colors: [],
            material: '',
            stockCount: 999,
            createdAt: DateTime.now(),
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

    // ── orderId 먼저 생성 (이미지 업로드 경로에 사용) ──
    final orderId = 'GRP_${DateTime.now().millisecondsSinceEpoch}';

    // ── 참고이미지 Storage 업로드 (base64 → URL) ──
    String refImageUrl = '';
    if (_refBase64 != null && _refBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_refBase64!);
        final ref = FirebaseStorage.instance
            .ref('group_orders/${user?.id ?? 'guest'}/$orderId/ref_image.jpg');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        refImageUrl = await ref.getDownloadURL();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ 참고이미지 업로드 실패 (무시): $e');
      }
    }

    // ── 상의 디자인 로고 Storage 업로드 ──
    String designLogoUrl = '';
    if (_designLogoBytes != null && _designLogoFileName != null) {
      try {
        final ext = _designLogoFileName!.contains('.')
            ? _designLogoFileName!.split('.').last.toLowerCase()
            : 'ai';
        final contentTypeMap = {
          'ai': 'application/postscript',
          'svg': 'image/svg+xml',
          'pdf': 'application/pdf',
          'eps': 'application/postscript',
        };
        final ref = FirebaseStorage.instance.ref(
            'group_orders/${user?.id ?? 'guest'}/$orderId/design_logo.$ext');
        await ref.putData(
          Uint8List.fromList(_designLogoBytes!),
          SettableMetadata(
              contentType: contentTypeMap[ext] ?? 'application/octet-stream'),
        );
        designLogoUrl = await ref.getDownloadURL();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ 디자인 로고 업로드 실패 (무시): $e');
      }
    }

    // ── 허리밴드 로고 Storage 업로드 ──
    String waistbandLogoUrl = '';
    if (_waistbandLogoBytes != null && _waistbandLogoFileName != null) {
      try {
        final ext = _waistbandLogoFileName!.contains('.')
            ? _waistbandLogoFileName!.split('.').last.toLowerCase()
            : 'ai';
        final contentTypeMap = {
          'ai': 'application/postscript',
          'svg': 'image/svg+xml',
          'pdf': 'application/pdf',
          'eps': 'application/postscript',
        };
        final ref = FirebaseStorage.instance.ref(
            'group_orders/${user?.id ?? 'guest'}/$orderId/waistband_logo.$ext');
        await ref.putData(
          Uint8List.fromList(_waistbandLogoBytes!),
          SettableMetadata(
              contentType: contentTypeMap[ext] ?? 'application/octet-stream'),
        );
        waistbandLogoUrl = await ref.getDownloadURL();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ 허리밴드 로고 업로드 실패 (무시): $e');
      }
    }

    final customOptions = <String, dynamic>{
      'orderType': _isAdditional ? 'additional' : 'group',
      'designFileUrl': designImg,
      'productImageUrl': designImg,
      'refImageUrl': refImageUrl, // 참고이미지 URL
      'designLogoUrl': designLogoUrl, // 상의 디자인 로고 URL
      'waistbandLogoUrl': waistbandLogoUrl, // 허리밴드 로고 URL
      'originalOrderId':
          _isAdditional && _originalOrder != null ? _originalOrder!.id : null,
      'originalOrderDate': _isAdditional && _originalOrder != null
          ? _originalOrder!.createdAt.toIso8601String()
          : null,
      'originalTeamName': _isAdditional && _originalOrder != null
          ? (_originalOrder!.customOptions?['teamName'] ??
              _originalOrder!.groupName ??
              '')
          : null,
      'originalTotalCount': _isAdditional && _originalOrder != null
          ? (_originalOrder!.groupCount ?? 0)
          : null,
      'originalStatus': _isAdditional && _originalOrder != null
          ? _originalOrder!.status.name
          : null,
      'printType': _printType,
      'mainColor': _mainColorName,
      'adjustedColorHex':
          '#${_adjustedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'colorLightness': _colorLightness,
      'colorTone': _lightnessLabel,
      'fabric': _fabricType,
      'weight': _fabricWeight,
      'pocket': _hasPocket && !_isFemaleShortSquare,
      'maleLength': _maleLengthSel,
      'femaleLength': _femaleLengthSel,
      'waistbandOption': _waistbandOptionLabel,
      'waistbandOptions': _waistbandOptions.toList(),
      'waistbandExtra': _waistbandExtra.toInt(),
      'waistbandColorHex':
          _waistbandOptions.contains(2) ? _waistbandColorHex : '',
      'waistbandRefImages': _waistbandRefImages,
      'waistbandLogoFileName': _waistbandLogoFileName ?? '',
      'waistbandLogoBase64':
          _waistbandLogoBytes != null ? base64Encode(_waistbandLogoBytes!) : '',
      'exclusive': _exclusiveDesign,
      'teamName': _teamNameCtrl.text.trim(),
      'manager': _managerNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'address': _address,
      'addressDetail': _addressDetailCtrl.text.trim(),
      'maleRef': _refBase64 != null,
      'femaleRef': false,
      'designLogoFileName': _designLogoFileName ?? '',
      'designLogoBase64':
          _designLogoBytes != null ? base64Encode(_designLogoBytes!) : '',
      'persons': _persons
          .map((p) => <String, dynamic>{
                'index': p.index,
                'name': _nameEnabled
                    ? p.nameCtrl.text.trim()
                    : '', // 10명 미만은 이름 저장 안 함
                'gender': p.gender,
                'sizeType': p.sizeType,
                'topSize': p.effectiveTopSize,
                'bottomSize': p.effectiveBottomSize,
                'length': (p.gender == 'female')
                    ? _femaleLengthSel
                    : _maleLengthSel, // 성별에 따라 자동 적용
                'height': p.heightCtrl.text.trim(),
                'weight': p.weightCtrl.text.trim(),
                'waist': p.waistCtrl.text.trim(),
                'thigh': p.thighCtrl.text.trim(),
                'hasCustomMeasure': p.showDetail,
              })
          .toList(),
    };

    // ignore: unused_local_variable
    final order = OrderModel(
      id: orderId,
      userId: user?.id ?? 'guest',
      userName: _managerNameCtrl.text.trim().isNotEmpty
          ? _managerNameCtrl.text.trim()
          : _teamNameCtrl.text.trim(),
      userEmail: _emailCtrl.text.trim(),
      userPhone: _phoneCtrl.text.trim(),
      userAddress: _addressDetailCtrl.text.trim().isNotEmpty
          ? '$_address ${_addressDetailCtrl.text.trim()}'
          : _address,
      items: [
        OrderItem(
          productId: product.id,
          productName: product.name,
          size: '단체',
          color: _mainColorName ?? '기본',
          quantity: _totalCount,
          price: _unitPrice,
          customOptions: customOptions,
          imageUrl: product.images.isNotEmpty ? product.images.first : null,
        )
      ],
      totalAmount: _finalPrice,
      shippingFee: _shipping,
      paymentMethod: '무통장입금',
      orderType: _isAdditional ? 'additional' : 'group',
      groupName: _teamNameCtrl.text.trim(),
      groupCount: _totalCount,
      memo: _memoCtrl.text.trim(),
      createdAt: DateTime.now(),
      customOptions: customOptions,
      cashReceiptNum: user?.cashReceiptNum?.isNotEmpty == true
          ? user!.cashReceiptNum
          : null,
    );

    final cart = context.read<CartProvider>();
    if (isBuyNow) {
      cart.clearCart();
      // product.price = _unitPrice (모든 추가비용 포함) → extraPrice: 0 으로 이중계산 방지
      cart.addItem(product, '단체', _mainColorName ?? '기본',
          quantity: _totalCount, extraPrice: 0, customOptions: customOptions);
      if (!mounted) return;
      // 주문 전 사이즈 저장 제안
      _offerSaveSizeAfterOrder();
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CheckoutScreen(cart: cart)));
    } else {
      // 장바구니에 담기 (기존 아이템 유지, 단체 상품 추가)
      // product.price = _unitPrice (모든 추가비용 포함) → extraPrice: 0 으로 이중계산 방지
      cart.addItem(product, '단체', _mainColorName ?? '기본',
          quantity: _totalCount, extraPrice: 0, customOptions: customOptions);
      if (!mounted) return;
      // 장바구니 담기 후 사이즈 저장 제안
      _offerSaveSizeAfterOrder();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(context.loc.t('장바구니에_담았습니다', '장바구니에 담았습니다.') +
                    ' ($_totalCount' +
                    context.loc.t('명', '명') +
                    ' / ${_fmt(_finalPrice)}원)')),
          ]),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: context.loc.t('장바구니_보기', '장바구니 보기'),
            textColor: AppColors.accent,
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
    context.watch<LanguageProvider>();
    final title = _isAdditional
        ? context.loc.t('추가_제작_주문서', '추가 제작 주문서')
        : context.loc.t('단체_주문서', '단체 주문서');
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                // ── 추가제작: 인원별 사이즈 + 기본정보 + 요약만 표시 ──
                if (_isAdditional) ...[
                  _buildPersonListSection(),
                  _buildBasicInfoSection(),
                  _buildCancelPolicySection(),
                  _buildSummarySection(),
                  const SizedBox(height: 32),
                  // ── 신규 단체주문: 전체 섹션 표시 ──
                ] else ...[
                  _buildAllMembersNotice(),
                  if (!_isBottomOnly) _buildPrintTypeSection(),
                  if (!_isBottomOnly) _build2FitLogoBanner(),
                  if (widget.product != null) _buildProductCard(),
                  if (!_isBottomOnly) _buildFabricSection(),
                  if (!_isTopOnly) _buildLengthSection(),
                  if (!_isTopOnly) _buildPocketSection(),
                  if (!_isTopOnly) _buildWaistbandSection(),
                  _buildColorSection(),
                  if (!_isBottomOnly) _buildRefImageSection(),
                  if (!_isTopOnly) _buildWaistbandDesignSection(),
                  _buildMemoSection(),
                  _buildPersonListSection(),
                  _buildBasicInfoSection(),
                  _buildCancelPolicySection(),
                  _buildSummarySection(),
                  const SizedBox(height: 32),
                ],
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  // ══════════════════════════════════════════════
  // 헤더 배너
  // ══════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 영문 서브타이틀
        Text(
          _isAdditional ? 'ADDITIONAL ORDER' : 'GROUP CUSTOM ORDER',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isAdditional
              ? context.loc.t('추가_제작_주문', '추가 제작 주문')
              : context.loc.t('단체_커스텀_주문', '단체 커스텀 주문'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.loc.t('아래_폼을_작성하여_주문을_완료', '아래 폼을 작성하여 주문을 완료해 주세요.'),
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),

        // ── 추가제작: 기존 주문번호 필수 표시 ──
        if (_isAdditional && _originalOrder != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.receipt_long_rounded,
                  color: Colors.white, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.loc.t('기존_주문번호__필수', '기존 주문번호 (필수)'),
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3)),
                      const SizedBox(height: 2),
                      Text(
                        _originalOrder!.id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(context.loc.t('연결됨', '연결됨'),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 16),
        // ── 핵심 안내 칩 목록 (모노크롬 스타일) ──
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _headerChip(Icons.check_circle_rounded,
                context.loc.t('허리밴드_디자인색상_변경_무료', '허리밴드 디자인·색상 변경 무료')),
            _headerChip(Icons.attach_file_rounded,
                context.loc.t('로고_AI_원본파일_필수', '로고 AI 원본파일 필수 (AI/EPS/SVG)')),
            _headerChip(Icons.photo_camera_outlined,
                context.loc.t('앞뒤_사진_첨부_제작_가능', '앞·뒤 사진 첨부 제작 가능')),
            _headerChip(Icons.lock_outlined,
                context.loc.t('1년_독점_사용권_무료_제공', '1년 독점 사용권 무료 제공')),
          ],
        ),
        const SizedBox(height: 12),
        // ── 교환·환불 핵심 안내 ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.white.withValues(alpha: 0.08),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 13),
              SizedBox(width: 6),
              Text(context.loc.t('교환_환불_안내', '교환·환불 안내'),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 5),
            Text(
                context.loc
                    .t('기성품__수령_후_3일_이내_fb7638', '▶  기성품: 수령 후 7일 이내 교환·환불 가능'),
                style: TextStyle(
                    color: Colors.white60, fontSize: 11, height: 1.5)),
            Text(
                context.loc.t('커스텀_단체__주문__의류__390058',
                    '▶  커스텀(단체) 주문: 의류 자체 불량 외 교환·환불 불가'),
                style: TextStyle(
                    color: Colors.white54, fontSize: 11, height: 1.5)),
          ]),
        ),
      ]),
    );
  }

  // ── 헤더 안내 칩 (화이트 테두리 스타일) ──
  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 11),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 수량 섹션
  // ══════════════════════════════════════════════
  Widget _buildCountSection() {
    return _card(
      title: context.loc.t('주문_수량', '주문 수량'),
      icon: Icons.people_outline_rounded,
      child: Column(children: [
        // 수량 조절
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _countBtn(Icons.remove_rounded, () {
            if (_count > (widget.isAdditionalOrder ? 1 : 1)) {
              setState(() {
                _count--;
                if (_countFixed) {
                  while (_persons.length > _count) {
                    _persons.last.dispose();
                    _persons.removeLast();
                  }
                  for (int i = 0; i < _persons.length; i++) {
                    _persons[i].index = i;
                  }
                  _resetInvalidPrintType();
                }
              });
            }
          }),
          Container(
            width: 80,
            alignment: Alignment.center,
            child: Text('$_count' + context.loc.t('명', '명'),
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: _purple)),
          ),
          _countBtn(Icons.add_rounded, () {
            setState(() {
              _count++;
              if (_countFixed) {
                while (_persons.length < _count) {
                  _persons.add(_PersonEntry(index: _persons.length));
                }
                for (int i = 0; i < _persons.length; i++) {
                  _persons[i].index = i;
                }
                _resetInvalidPrintType();
              }
            });
          }),
        ]),
        const SizedBox(height: 4),
        if (!_isAdditional)
          Text(context.loc.t('최소_5명_이상_주문_가능합_5c1358', '최소 5명 이상 주문 가능합니다.'),
              style: TextStyle(fontSize: 11, color: Colors.grey))
        else
          Text(context.loc.t('1장부터_추가제작_가능합니다', '1장부터 추가제작 가능합니다.'),
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
              child: Text(
                  '$_count' + context.loc.t('명으로_주문서_작성하기', '명으로 주문서 작성하기'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
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
              Text('$_totalCount' + context.loc.t('명_확정', '명 확정'),
                  style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ]),
          ),
      ]),
    );
  }

  Widget _countBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _purpleLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _purple, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // ── 전체 인원 공통 적용 안내 배너
  Widget _buildAllMembersNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC02), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.loc.t('아래_모든_선택사항은_전체_인원_6c13d5',
                  '아래 모든 선택사항은 전체 인원에게 동일하게 적용됩니다.\n개인별로 다르게 선택할 수 없습니다.'),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 인쇄 타입 섹션
  // ══════════════════════════════════════════════
  Widget _buildPrintTypeSection() {
    // id, title, desc, badgeColor, condMin (최소 인원), condLabel
    // 0: 색상변경, 1: 단체명+색상, 2: 디자인변경+단체명+색상, 3: 디자인유지+색상변경+단체명+이름(후면), 4: 디자인변경+색상변경+단체명+이름(후면)
    final options = [
      {
        'id': 0,
        'title': context.loc.t('디자인_유지_색상_변경', '디자인 유지 + 색상 변경'),
        'desc': context.loc.t('2FIT_로고_적용_전면_색상_변경_단체명_인쇄_없음',
            '2FIT 로고 적용(전면) + 색상 변경 (단체명 인쇄 없음)'),
        'badgeColor': AppColors.info, // 파랑
        'condMin': 5,
        'condLabel': context.loc.t('5명', '5명↑'),
      },
      {
        'id': 1,
        'title': context.loc.t('디자인_유지_단체명_색상_변경', '디자인 유지 + 단체명 + 색상 변경'),
        'desc': context.loc
            .t('기존_디자인_유지_단체명_전면_색상_변경', '기존 디자인 유지 + 단체명(전면) + 색상 변경'),
        'badgeColor': AppColors.primary, // 블랙
        'condMin': 5,
        'condLabel': context.loc.t('5명', '5명↑'),
      },
      {
        'id': 2,
        'title': context.loc.t('디자인_변경_단체명_색상_변경', '디자인 변경 + 단체명 + 색상 변경'),
        'desc': context.loc
            .t('새_디자인_변경_단체명_전면_색상_변경', '새 디자인 변경 + 단체명(전면) + 색상 변경'),
        'badgeColor': const Color(0xFF00838F), // 청록
        'condMin': 5,
        'condLabel': context.loc.t('5명', '5명↑'),
      },
      {
        'id': 3,
        'title': context.loc
            .t('디자인_유지_색상변경_단체명_이름_후면', '디자인 유지 + 색상변경 + 단체명 + 이름(후면)'),
        'desc': context.loc.t('기존_디자인_유지_색상_변경_단체명_전면_개인_이름_후면_등',
            '기존 디자인 유지 + 색상 변경 + 단체명(전면) + 개인 이름(후면·등)'),
        'badgeColor': AppColors.primary, // 보라
        'condMin': 10,
        'condLabel': context.loc.t('10명', '10명↑'),
      },
      {
        'id': 4,
        'title': context.loc
            .t('디자인_변경_색상변경_단체명_이름_후면', '디자인 변경 + 색상변경 + 단체명 + 이름(후면)'),
        'desc': context.loc.t('새_디자인_변경_색상_변경_단체명_전면_개인_이름_후면_등',
            '새 디자인 변경 + 색상 변경 + 단체명(전면) + 개인 이름(후면·등)'),
        'badgeColor': const Color(0xFFC62828), // 빨강
        'condMin': 10,
        'condLabel': context.loc.t('10명', '10명↑'),
      },
    ];

    return _card(
      title: context.loc.t('인쇄_타입', '인쇄 타입'),
      icon: Icons.print_rounded,
      child: Column(
        children: options.map((opt) {
          final id = opt['id'] as int;
          final condMin = opt['condMin'] as int;
          final condLabel = opt['condLabel'] as String;
          final badgeColor = opt['badgeColor'] as Color;
          final enabled = _totalCount >= condMin;
          final isSel = _printType == id;

          return GestureDetector(
            onTap: enabled
                ? () => setState(() => _printType = id)
                : () => _showSnack(condMin.toString() +
                    context.loc.t('명_이상부터_선택_가능한_옵션', '명 이상부터 선택 가능한 옵션입니다.')),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: !enabled
                    ? Colors.grey.shade100
                    : isSel
                        ? _purpleLight
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !enabled
                      ? Colors.grey.shade200
                      : isSel
                          ? _purple
                          : Colors.grey.shade200,
                  width: isSel ? 1.8 : 1,
                ),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                            color: _purple.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Row(children: [
                // ── 숫자 뱃지 ──
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: !enabled
                        ? Colors.grey.shade300
                        : isSel
                            ? badgeColor
                            : badgeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${id + 1}', // 표시 번호 = id+1 (1~4)
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: !enabled
                          ? Colors.grey.shade500
                          : isSel
                              ? Colors.white
                              : badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // ── 텍스트 ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: !enabled
                              ? Colors.grey.shade400
                              : isSel
                                  ? _purple
                                  : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt['desc'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: !enabled
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ── 조건 뱃지 ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: !enabled
                        ? Colors.grey.shade200
                        : condMin == 10
                            ? const Color(0xFFFCE4EC)
                            : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    condLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: !enabled
                          ? Colors.grey.shade400
                          : condMin == 10
                              ? const Color(0xFFC62828)
                              : AppColors.success,
                    ),
                  ),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 2FIT 로고 안내 배너 (단체명 미선택 시)
  // ══════════════════════════════════════════════
  Widget _build2FitLogoBanner() {
    if (_hasTeamName) return const SizedBox.shrink(); // 단체명 있으면 숨김
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF16213E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF3F51B5).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('2F',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.loc.t('2FIT_로고_자동_적용', '2FIT 로고 자동 적용'),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                    context.loc.t('단체명_변경을_선택하지_않으_ff5e92',
                        '단체명 변경을 선택하지 않으면 전면에 2FIT 로고가 기본 적용됩니다.'),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.4)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3F51B5).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(context.loc.t('기본', '기본'),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 선택 상품 카드
  // ══════════════════════════════════════════════
  Widget _buildProductCard() {
    final p = widget.product!;

    // 디자인 이미지 최우선, 없으면 images.first(착용샷)
    final designImgs = p.sectionImages['design'] ?? [];
    final hasDesign = designImgs.isNotEmpty;

    // 카드 상단에 표시할 대표 이미지 = 디자인 이미지 첫 장 우선
    final heroImg = hasDesign
        ? designImgs.first
        : (p.images.isNotEmpty ? p.images.first : null);

    return _card(
      title: context.loc.t('선택_상품', '선택 상품'),
      icon: Icons.shopping_bag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 상품 정보 행 (작은 썸네일 + 텍스트) ──
          Row(children: [
            // 썸네일: 항상 디자인이미지 우선 표시
            GestureDetector(
              onTap: heroImg != null
                  ? () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(16),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: NetImage(heroImg, fit: BoxFit.contain),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      )
                  : null,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: heroImg != null
                          ? NetImage(
                              heroImg,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            )
                          : _productImgPlaceholder(),
                    ),
                    // 디자인 이미지임을 표시하는 배지
                    if (hasDesign)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _purple,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          child: Text(context.loc.t('디자인', '디자인'),
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(p.category,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('${_fmt(p.price)}' + context.loc.t('원', '원'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _purple,
                              fontSize: 15)),
                      Text(context.loc.t('인', '/인'),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ]),
                  ]),
            ),
          ]),

          // ── 디자인 이미지 섹션 (있을 때만) ──
          if (hasDesign) ...[
            const SizedBox(height: 14),
            // 구분선
            Container(
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.1),
              margin: const EdgeInsets.only(bottom: 12),
            ),
            // 헤더
            Row(children: [
              Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                      color: _purple, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(context.loc.t('디자인_이미지', '디자인 이미지'),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${designImgs.length}' + context.loc.t('장', '장'),
                    style: const TextStyle(
                        fontSize: 10,
                        color: _purple,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(context.loc.t('탭하면_크게_보기', '탭하면 크게 보기'),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ]),
            const SizedBox(height: 8),
            // 디자인 이미지 가로 스크롤
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: designImgs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(16),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: NetImage(designImgs[i], fit: BoxFit.contain),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: NetImage(
                            designImgs[i],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // 대표 배지 (첫 번째 이미지)
                        if (i == 0)
                          Positioned(
                            left: 5,
                            top: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _purple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(context.loc.t('대표', '대표'),
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        // 확대 아이콘
                        Positioned(
                          right: 5,
                          bottom: 5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(Icons.zoom_in_rounded,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── 디자인 이미지 없을 때 안내 ──
          if (!hasDesign) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Icon(Icons.image_outlined,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      context.loc.t('상품_디자인_이미지는_관리자_236f17',
                          '상품 디자인 이미지는 관리자가 등록 후 확인 가능합니다.'),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _productImgPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          Icon(Icons.checkroom_outlined, color: Colors.grey.shade400, size: 28),
    );
  }

  // ══════════════════════════════════════════════
  // 재봉방법 선택 섹션
  // ══════════════════════════════════════════════
  Widget _buildFabricSection() {
    final types = AppConstants.fabricTypes;
    return _card(
      title: context.loc.t('재봉방법_선택', '재봉방법 선택'),
      icon: Icons.content_cut_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 안내 문구
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.20)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline,
                size: 14, color: AppColors.info.withValues(alpha: 0.70)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.loc.t(
                    '심리스무봉제_선택_시_10000원_추가', '심리스(무봉제) 선택 시 +10,000원이 추가됩니다.'),
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.info.withValues(alpha: 0.82)),
              ),
            ),
          ]),
        ),
        Wrap(
            spacing: 10,
            runSpacing: 10,
            children: types.map((t) {
              final isSel = _fabricType == t;
              final extra = AppConstants.fabricTypePrices[t] ?? 0;
              return GestureDetector(
                onTap: () => setState(() => _fabricType = t),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? _purple : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel ? _purple : Colors.grey.shade300,
                      width: isSel ? 2 : 1,
                    ),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                                color: _purple.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(
                            t == '일반 봉제'
                                ? Icons.cut_outlined
                                : Icons.auto_fix_high_outlined,
                            size: 16,
                            color: isSel ? Colors.white : _purple,
                          ),
                          const SizedBox(width: 6),
                          Text(context.loc.t(t, t),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSel ? Colors.white : Colors.black87,
                              )),
                        ]),
                        if (extra > 0) ...[
                          const SizedBox(height: 2),
                          Text('+${_fmt(extra)}' + context.loc.t('원', '원'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSel
                                    ? Colors.white70
                                    : AppColors.warning.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          t == '일반 봉제'
                              ? context.loc
                                  .t('봉제선_있음_내구성_우수', '봉제선 있음 · 내구성 우수')
                              : context.loc
                                  .t('봉제선_없음_착용감_우수', '봉제선 없음 · 착용감 우수'),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSel ? Colors.white60 : Colors.black38,
                          ),
                        ),
                      ]),
                ),
              );
            }).toList()),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 허리밴드 옵션 섹션
  // ══════════════════════════════════════════════
  Widget _buildWaistbandSection() {
    // 1: 디자인 변경(+50,000), 2: 색상 변경(+50,000) — 중복 선택 가능
    final options = [
      {
        'id': 1,
        'label': context.loc.t('디자인_변경', '디자인 변경'),
        'sub': context.loc.t('무료', '무료'),
        'icon': Icons.brush_outlined
      },
      {
        'id': 2,
        'label': context.loc.t('색상_변경', '색상 변경'),
        'sub': context.loc.t('무료', '무료'),
        'icon': Icons.palette_outlined
      },
    ];
    final needsColor = _waistbandOptions.contains(2);

    return _card(
      title: context.loc.t('허리밴드_옵션', '허리밴드 옵션'),
      icon: Icons.style_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 안내 문구 ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_outline,
                size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            Expanded(
                child: Text(
              context.loc.t('허리밴드_디자인_색상_변경_전부_무료', '허리밴드 디자인·색상 변경 전부 무료'),
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w700),
            )),
          ]),
        ),

        // ── ③ 옵션 버튼 (중복 선택 가능) ──
        // 기본(변경없음) 버튼
        GestureDetector(
          onTap: () => setState(() {
            _waistbandOptions.clear();
            _waistbandColorHex = '';
            _waistbandColorCtrl.clear();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _waistbandOptions.isEmpty
                  ? AppColors.border
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _waistbandOptions.isEmpty
                    ? Colors.grey.shade500
                    : Colors.grey.shade300,
                width: _waistbandOptions.isEmpty ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Icon(
                _waistbandOptions.isEmpty
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                size: 18,
                color: _waistbandOptions.isEmpty
                    ? Colors.grey.shade700
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(context.loc.t('기본__변경없음', '기본 (변경없음)'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _waistbandOptions.isEmpty
                            ? Colors.grey.shade800
                            : Colors.grey.shade500,
                      ))),
              Text(context.loc.t('추가비용_없음', '추가비용 없음'),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ),
        ),

        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final id = opt['id'] as int;
              final label = opt['label'] as String;
              final sub = opt['sub'] as String;
              final icon = opt['icon'] as IconData;
              final isSel = _waistbandOptions.contains(id);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSel) {
                    _waistbandOptions.remove(id);
                    if (id == 2) {
                      _waistbandColorHex = '';
                      _waistbandColorCtrl.clear();
                    }
                  } else {
                    _waistbandOptions.add(id);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? _purple : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isSel ? _purple : Colors.grey.shade300,
                        width: 1.5),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                                color: _purple.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isSel
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 16,
                      color: isSel ? Colors.white : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Icon(icon,
                        size: 14,
                        color: isSel ? Colors.white70 : Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : Colors.black87,
                              )),
                          Text(sub,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isSel ? Colors.white70 : AppColors.success,
                                fontWeight: FontWeight.w700,
                              )),
                        ]),
                  ]),
                ),
              );
            }).toList()),

        // ── ④ 선택된 옵션 합계 표시 ──
        if (_waistbandOptions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _purple.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(Icons.receipt_long_rounded, size: 14, color: _purple),
              const SizedBox(width: 6),
              Text(context.loc.t('선택', '선택: ') + _waistbandOptionLabel,
                  style: TextStyle(
                      fontSize: 12,
                      color: _purple,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('+${_fmt(_waistbandExtra)}' + context.loc.t('원', '원'),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ],

        // ── ⑤ 색상 hex 입력 (색상 변경 선택 시만) ──
        if (needsColor) ...[
          const SizedBox(height: 14),
          Text(context.loc.t('허리밴드_색상_HEX_코드', '허리밴드 색상 HEX 코드'),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _waistbandColorHex.length == 7
                    ? _parseHexColor(_waistbandColorHex)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _waistbandColorHex.length != 7
                  ? Icon(Icons.palette_outlined,
                      color: Colors.grey.shade400, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _waistbandColorCtrl,
                maxLength: 7,
                decoration: InputDecoration(
                  hintText: context.loc
                      .t('1A1A1A___예___FF_9357c7', '#1A1A1A  (예: #FF0000)'),
                  counterText: '',
                  prefixText: _waistbandColorCtrl.text.isEmpty ? '#' : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _purple, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                onChanged: (v) {
                  String hex = v.trim();
                  if (!hex.startsWith('#')) hex = '#$hex';
                  if (hex.length <= 7) {
                    setState(
                        () => _waistbandColorHex = hex.length == 7 ? hex : '');
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
              context.loc.t(
                  '6자리_HEX_코드를_입력하_dc4147', '6자리 HEX 코드를 입력하세요 (예: #1245A8)'),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          Text(context.loc.t('빠른_선택__2FIT_팔레트', '빠른 선택 (2FIT 팔레트)'),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AppConstants.twoFitColors.map((c) {
              final hexVal =
                  '#${(c['hex'] as int).toRadixString(16).substring(2).toUpperCase()}';
              final isSelected =
                  _waistbandColorHex.toUpperCase() == hexVal.toUpperCase();
              return GestureDetector(
                onTap: () => setState(() {
                  _waistbandColorHex = hexVal;
                  _waistbandColorCtrl.text = hexVal;
                }),
                child: Tooltip(
                  message: '${c['name']} $hexVal',
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(c['hex'] as int),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? _purple : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: _purple.withValues(alpha: 0.4),
                                  blurRadius: 4)
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? Icon(Icons.check,
                            size: 14,
                            color: _isLightColor(Color(c['hex'] as int))
                                ? Colors.black
                                : Colors.white)
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

  /// 허리밴드 참고 이미지 선택
  Future<void> _pickWaistbandRefImage() async {
    if (_waistbandRefImages.length >= 3) return;
    try {
      final picker = ImagePicker();
      final xfile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      final b64 = base64Encode(bytes);
      if (!mounted) return;
      setState(() => _waistbandRefImages.add(b64));
    } catch (e) {
      _showSnack(context.loc.t('이미지_선택_오류', '이미지 선택 오류: ') + e.toString());
    }
  }

  // 허리밴드 로고 파일 선택 (AI·PDF·PNG·SVG 등 모든 형식)
  Future<void> _pickWaistbandLogoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ai', 'svg', 'pdf', 'eps'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (!mounted) return;
      setState(() {
        _waistbandLogoFileName = file.name;
        _waistbandLogoBytes =
            file.bytes != null ? List<int>.from(file.bytes!) : null;
      });
    } catch (e) {
      _showSnack(context.loc.t('파일_선택_오류', '파일 선택 오류: ') +
          e.toString() +
          context.loc
              .t('_AI_SVG_PDF_EPS_파일만_첨부', '\nAI·SVG·PDF·EPS 파일만 첨부 가능합니다.'));
    }
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
      title: context.loc.t('색상_선택', '색상 선택 *'),
      icon: Icons.palette_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ① 안내 문구 (상의/하의 제작 방식)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(context.loc.t('색상_적용_안내', '색상 적용 안내'),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ]),
            ),
            // 내용
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상의 안내
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(context.loc.t('상의', '상의'),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.t('포인트_색상_또는_전체_색상이_선택한_색상으로_변경됩니다',
                                  '포인트 색상 또는 전체 색상이 선택한 색상으로 변경됩니다.'),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textPrimary,
                                  height: 1.5),
                            ),
                          ),
                        ]),
                    const SizedBox(height: 8),
                    // 하의 안내
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(context.loc.t('하의', '하의'),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.t('골지_느낌의_선택한_색상으로_제작됩니다',
                                  '골지 느낌의 선택한 색상으로 제작됩니다.'),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textPrimary,
                                  height: 1.5),
                            ),
                          ),
                        ]),
                  ]),
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
              boxShadow: [
                BoxShadow(
                    color: _purple.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black54,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            tabs: [
              Tab(text: context.loc.t('기성_19색', '기성 19색')),
              Tab(text: context.loc.t('추가_색상', '추가 색상')),
              Tab(text: context.loc.t('HEX_입력', 'HEX 입력')),
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
    final adjusted = _adjustedColor;
    final isLight = adjusted.computeLuminance() > 0.5;
    final hsl = _mainColor != null ? HSLColor.fromColor(_mainColor!) : null;

    // 그라디언트 바 색상 (원본 색상을 유지하면서 lightness만 변화)
    final darkColor = hsl?.withLightness(0.08).toColor() ?? Colors.black;
    final baseColor = hsl?.withLightness(hsl.lightness).toColor() ??
        (_mainColor ?? Colors.grey);
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
            // 원본 vs 조절 후 비교 (골지 질감 스와치)
            RibColorSwatch(
              color: _mainColor ?? adjusted,
              size: 32,
              isSelected: false,
              isLight: (_mainColor ?? adjusted).computeLuminance() > 0.5,
              borderRadius: 8,
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded,
                size: 14, color: isLight ? Colors.black38 : Colors.white54),
            const SizedBox(width: 4),
            RibColorSwatch(
              color: adjusted,
              size: 40,
              isSelected: true,
              accentColor: Colors.white,
              isLight: isLight,
              borderRadius: 10,
              child: Icon(Icons.check_rounded,
                  size: 18, color: isLight ? Colors.black87 : Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_mainColorName ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isLight ? Colors.black87 : Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '#${adjusted.toARGB32().toRadixString(16).substring(2).toUpperCase()}  ·  $_lightnessLabel',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isLight ? Colors.black54 : Colors.white70,
                      ),
                    ),
                  ]),
            ),
            // 선택 취소
            GestureDetector(
              onTap: () => setState(() {
                _mainColorName = null;
                _mainColor = null;
                _colorLightness = 0.5;
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close,
                    size: 15, color: isLight ? Colors.black87 : Colors.white),
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 라벨
            Row(children: [
              Icon(Icons.tune_rounded, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 5),
              Text(context.loc.t('농도_조절', '농도 조절'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade700)),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 3)
                    ],
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
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 13),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 22),
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
              Text(context.loc.t('어둡게', '어둡게'),
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(context.loc.t('밝게', '밝게'),
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
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
            final name = c['name'] as String;
            final code = c['code'] as String;
            final color = Color(c['hex'] as int);
            final isSel = _mainColorName == name;
            final isLight = color.computeLuminance() > 0.6;
            // 표시용 짧은 이름
            final displayName = name.contains('(')
                ? name.substring(name.indexOf('(') + 1, name.indexOf(')'))
                : name;
            return GestureDetector(
              onTap: () => setState(() {
                _mainColorName = name;
                _mainColor = color;
                _colorLightness =
                    HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
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
                  // 골지 질감 스와치
                  RibColorSwatch(
                    color: color,
                    size: 38,
                    isSelected: isSel,
                    accentColor: _purple,
                    isLight: isLight,
                    borderRadius: 10,
                    child: isSel
                        ? Icon(Icons.check_rounded,
                            size: 18,
                            color: isLight ? Colors.black87 : Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  // 코드
                  Text(code,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: isSel ? _purple : Colors.black54,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center),
                  // 이름
                  Text(displayName,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: isSel
                            ? _purple.withValues(alpha: 0.8)
                            : Colors.black38,
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
            context.loc.t('총_색상_탭선택', '총 ') +
                '\${colors.length}' +
                context.loc.t('가지_기성_색상_탭하여_선택', '가지 기성 색상 • 탭하여 선택'),
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
          '${extended.length}' +
              context.loc.t(
                  '가지_확장_색상_팔레트_원하는_색상을_탭하세요', '가지 확장 색상 팔레트 • 원하는 색상을 탭하세요'),
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
            final color = extended[i];
            final hexStr =
                '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
            final isSel = _mainColor?.toARGB32() == color.toARGB32() &&
                _mainColorName != null &&
                !AppColorPalette.registeredColors
                    .any((c) => c['name'] == _mainColorName);
            final isLight = color.computeLuminance() > 0.6;
            return GestureDetector(
              onTap: () => setState(() {
                _mainColorName = context.loc.t('확장_색상', '확장') + ' ($hexStr)';
                _mainColor = color;
                _colorLightness =
                    HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
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
                      ? [
                          const BoxShadow(
                              color: Colors.black38,
                              blurRadius: 5,
                              spreadRadius: 1)
                        ]
                      : [],
                ),
                child: isSel
                    ? Icon(Icons.check_rounded,
                        size: 11,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: _hexPreview.computeLuminance() > 0.4
                      ? Colors.black87
                      : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 입력 필드
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text('#',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black54)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _hexCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: context.loc
                      .t('RRGGBB__예__FF6B_b87306', 'RRGGBB (예: FF6B35)'),
                  hintStyle: const TextStyle(
                      fontSize: 12, color: Colors.grey, letterSpacing: 1),
                  counterText: '',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        _hexError = null;
                      });
                    } catch (_) {
                      setState(() => _hexError = context.loc
                          .t('올바른_HEX_코드를_입력하세요', '올바른 HEX 코드를 입력하세요'));
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(context.loc.t('적용', '적용'),
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 12),
          // 안내
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.warning),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.loc.t('원하시는_색상의_HEX_코드를_6자리로_입력하세요_n예_빨강__bc66fc',
                      '원하시는 색상의 HEX 코드를 6자리로 입력하세요.\n예) 빨강: FF0000 / 파랑: 0000FF / 노랑: FFFF00'),
                  style: TextStyle(
                      fontSize: 11, color: AppColors.warning, height: 1.5),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          // 자주 쓰는 커스텀 색상 예시
          Text(context.loc.t('자주_쓰는_색상', '자주 쓰는 색상'),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              {'name': context.loc.t('코발트블루', '코발트블루'), 'hex': '0047AB'},
              {'name': context.loc.t('라벤더', '라벤더'), 'hex': 'E6CCFF'},
              {'name': context.loc.t('카멜', '카멜'), 'hex': 'C19A6B'},
              {'name': context.loc.t('민트', '민트'), 'hex': '26C9A0'},
              {'name': context.loc.t('버건디', '버건디'), 'hex': '6D0E19'},
              {'name': context.loc.t('골드', '골드'), 'hex': 'D4AF37'},
            ].map((item) {
              final hexStr = item['hex']!;
              final color = Color(int.parse('FF$hexStr', radix: 16));
              final isLight = color.computeLuminance() > 0.5;
              final isSel = _mainColorName == item['name'];
              return GestureDetector(
                onTap: () {
                  _hexCtrl.text = hexStr;
                  setState(() {
                    _hexPreview = color;
                    _mainColorName = item['name'];
                    _mainColor = color;
                    _colorLightness =
                        HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
                    _hexError = null;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? color : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSel ? _purple : color.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    RibColorSwatch(
                      color: color,
                      size: 14,
                      isLight: isLight,
                      borderRadius: 7,
                    ),
                    const SizedBox(width: 5),
                    Text(item['name']!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? (isLight ? Colors.black87 : Colors.white)
                                : Colors.black87)),
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
      setState(() => _hexError = context.loc
          .t('HEX_코드는_6자리입니다_예_FF6B35', 'HEX 코드는 6자리입니다 (예: FF6B35)'));
      return;
    }
    try {
      final color = Color(int.parse('FF$v', radix: 16));
      setState(() {
        _hexPreview = color;
        _mainColorName =
            context.loc.t('커스텀_색상', '커스텀') + ' (#${v.toUpperCase()})';
        _mainColor = color;
        _colorLightness = HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
        _hexError = null;
      });
    } catch (_) {
      setState(() =>
          _hexError = context.loc.t('올바른_HEX_코드를_입력하세요', '올바른 HEX 코드를 입력하세요'));
    }
  }

  // ══════════════════════════════════════════════
  // 하의 길이 섹션 (남/여 분리)
  // ══════════════════════════════════════════════
  Widget _buildLengthSection() {
    // 남성: 9부~3부 (4개), 여성: 9부~숏쇼츠 (6개 전체)
    final maleLengths = AppConstants.bottomLengths
        .where((l) => ['9부', '5부', '4부', '3부'].contains(l['label']))
        .toList();
    final femaleLengths = AppConstants.bottomLengths; // 전체 (숏쇼츠 포함)

    return _card(
      title: context.loc.t('하의_기본_길이', '하의 기본 길이'),
      icon: Icons.straighten_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 안내 문구
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.loc
                    .t('선택한_길이는_성별에_따라_전원', '선택한 길이는 성별에 따라 전원에게 동일하게 적용됩니다.'),
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ]),
        ),

        // ── 남성 길이 선택
        _buildGenderLengthRow(
          gender: '남성',
          genderColor: AppColors.info,
          genderBg: const Color(0xFFE3F2FD),
          lengths: maleLengths,
          selected: _maleLengthSel,
          onSelect: (label) => setState(() => _maleLengthSel = label),
        ),

        const SizedBox(height: 12),

        // ── 여성 길이 선택
        _buildGenderLengthRow(
          gender: '여성',
          genderColor: const Color(0xFFC62828),
          genderBg: const Color(0xFFFCE4EC),
          lengths: femaleLengths,
          selected: _femaleLengthSel,
          onSelect: (label) {
            setState(() {
              _femaleLengthSel = label;
              // 숏쇼츠 선택 시 주머니 강제 해제
              if (label == '숏쇼츠' && _hasPocket) _hasPocket = false;
            });
          },
        ),

        // ── 숏쇼츠 선택 시 주머니 불가 안내
        if (_femaleLengthSel == '숏쇼츠') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Row(children: [
              const Icon(Icons.block_rounded,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.loc.t('숏사각_숏쇼츠_선택_시_주머니_추가가_불가합니다',
                      '숏사각(숏쇼츠) 선택 시 주머니 추가가 불가합니다.'),
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBF360C),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ],

        // ── 9부 선택 시 추가금 안내
        if (_maleLengthSel == '9부' || _femaleLengthSel == '9부') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.loc.t('타이즈_9부_선택_시_인당_20_000원이_추가됩니다',
                      '타이즈 9부 선택 시 인당 +20,000원이 추가됩니다.'),
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBF360C),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── 성별별 길이 선택 행 ──
  Widget _buildGenderLengthRow({
    required String gender,
    required Color genderColor,
    required Color genderBg,
    required List<Map<String, String>> lengths,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 성별 뱃지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: genderBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(context.loc.t(gender, gender),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: genderColor)),
        ),
        const SizedBox(height: 8),
        // 길이 버튼 목록
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: lengths.map((l) {
            final label = l['label']!;
            final desc = l['desc']!;
            final isSel = selected == label;
            final is9bu = label == '9부';
            final isShort = label == '숏쇼츠';
            return GestureDetector(
              onTap: () => onSelect(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel
                      ? (isShort ? AppColors.accent : genderColor)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel
                        ? (isShort ? AppColors.accent : genderColor)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(children: [
                  Text(context.loc.t(label, label),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isSel ? Colors.white : Colors.black87)),
                  if (desc.isNotEmpty)
                    Text(desc,
                        style: TextStyle(
                            fontSize: 10,
                            color: isSel ? Colors.white70 : Colors.grey)),
                  if (is9bu) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSel
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(context.loc.t('2만원', '+2만원'),
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isSel ? Colors.white : AppColors.accent)),
                    ),
                  ],
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // 주머니 선택 섹션 (선택사항)
  // ══════════════════════════════════════════════
  Widget _buildPocketSection() {
    final disabled = _isFemaleShortSquare; // 숏쇼츠 선택 시 주머니 불가
    return _card(
      title: context.loc.t('주머니__선택사항', '주머니 (선택사항)'),
      icon: Icons.style_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 숏사각 선택 시 불가 안내
        if (disabled) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFB74D)),
            ),
            child: Row(children: [
              const Icon(Icons.block_rounded,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.loc.t('여성_숏사각_숏쇼츠_선택_시_주머니_추가가_불가합니다',
                      '여성 숏사각(숏쇼츠) 선택 시 주머니 추가가 불가합니다.'),
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBF360C),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ],
        // 안내 문구
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.loc.t('주머니_선택_시_인원당_10_000원이_추가됩니다',
                    '주머니 선택 시 인원당 +10,000원이 추가됩니다.'),
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade700, height: 1.4),
              ),
            ),
          ]),
        ),
        // 선택 버튼
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _hasPocket = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_hasPocket ? _purple : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: !_hasPocket ? _purple : Colors.grey.shade300,
                  ),
                ),
                child: Column(children: [
                  Icon(Icons.do_not_disturb_alt_outlined,
                      size: 22,
                      color: !_hasPocket ? Colors.white : Colors.grey.shade500),
                  const SizedBox(height: 4),
                  Text(context.loc.t('주머니_없음', '주머니 없음'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: !_hasPocket ? Colors.white : Colors.black87,
                      )),
                  Text(context.loc.t('기본___0원', '기본 (+0원)'),
                      style: TextStyle(
                        fontSize: 10,
                        color: !_hasPocket ? Colors.white70 : Colors.grey,
                      )),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: disabled ? null : () => setState(() => _hasPocket = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: disabled
                      ? Colors.grey.shade200
                      : (_hasPocket ? _purple : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: disabled
                        ? Colors.grey.shade300
                        : (_hasPocket ? _purple : Colors.grey.shade300),
                  ),
                ),
                child: Column(children: [
                  Icon(Icons.cases_outlined,
                      size: 22,
                      color: disabled
                          ? Colors.grey.shade400
                          : (_hasPocket ? Colors.white : Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(context.loc.t('주머니_있음', '주머니 있음'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: disabled
                            ? Colors.grey.shade400
                            : (_hasPocket ? Colors.white : Colors.black87),
                      )),
                  Text(
                      disabled
                          ? context.loc.t('선택_불가', '선택 불가')
                          : context.loc.t('10_000원_인', '+10,000원/인'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: disabled
                            ? Colors.grey.shade400
                            : (_hasPocket
                                ? Colors.white70
                                : AppColors.warning.withValues(alpha: 0.82)),
                      )),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 디자인 참고 이미지 섹션 (단일 버튼)
  // ══════════════════════════════════════════════
  Widget _buildRefImageSection() {
    return _card(
      title: context.loc.t('디자인_참고_이미지', '디자인 참고 이미지'),
      icon: Icons.design_services_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 안내 박스
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.primary.withValues(alpha: 0.45)),
              const SizedBox(width: 6),
              Text(
                  context.loc
                      .t('원하시는_디자인_파일을_첨부_1521ab', '원하시는 디자인 파일을 첨부해 주세요'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary.withValues(alpha: 0.82))),
            ]),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dotRow(
                        context.loc.t('앞면뒷면_디자인을_모두_첨부',
                            '앞면·뒷면 디자인을 모두 첨부하시면 더욱 정확하게 제작됩니다.'),
                        AppColors.primary.withValues(alpha: 0.70)),
                    const SizedBox(height: 3),
                    _dotRow(
                        context.loc.t('지원_형식_PNG_JPG_PDF_AI_PSD_SVG_등',
                            '지원 형식: PNG · JPG · PDF · AI · PSD · SVG 등'),
                        AppColors.primary.withValues(alpha: 0.70)),
                    const SizedBox(height: 3),
                    _dotRow(
                        context.loc.t('파일이_여러_개일_경우_ZIP으로_압축_후_업로드해_주세요',
                            '파일이 여러 개일 경우 ZIP으로 압축 후 업로드해 주세요.'),
                        AppColors.primary.withValues(alpha: 0.70)),
                  ]),
            ),
          ]),
        ),
        _refImageCard(),
        const SizedBox(height: 16),

        // ── 로고 파일 업로드
        _buildDesignLogoUpload(),
      ]),
    );
  }

  Widget _buildDesignLogoUpload() {
    final hasFile = _designLogoFileName != null;
    final isImage = hasFile &&
        RegExp(r'\.(png|jpg|jpeg|gif|webp|bmp)$', caseSensitive: false)
            .hasMatch(_designLogoFileName!);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 소제목
      Row(children: [
        Icon(Icons.attach_file_rounded,
            size: 14, color: AppColors.primary.withValues(alpha: 0.70)),
        const SizedBox(width: 5),
        Text(context.loc.t('로고_파일_첨부__선택사항', '로고 파일 첨부 (선택사항)'),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary.withValues(alpha: 0.82))),
      ]),
      const SizedBox(height: 6),

      // 안내
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_amber_rounded,
              size: 13, color: AppColors.warning.withValues(alpha: 0.82)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.loc.t('로고_인쇄_품질을_위해_AI_원본_파일_벡터_을_첨부해_주세요_080bc3',
                  '로고 인쇄 품질을 위해 AI 원본 파일(벡터)을 첨부해 주세요.\nAI · EPS · SVG · PDF 권장 / JPG·PNG는 품질 저하 가능'),
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.warning.withValues(alpha: 0.82),
                  height: 1.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      ),

      // 업로드 버튼 or 완료 상태
      if (!hasFile)
        GestureDetector(
          onTap: _pickDesignLogoFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.30), width: 1.5),
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.upload_file_rounded,
                  color: AppColors.warning.withValues(alpha: 0.70), size: 28),
              const SizedBox(height: 5),
              Text(context.loc.t('로고_파일_선택', '로고 파일 선택'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning.withValues(alpha: 0.82))),
              const SizedBox(height: 2),
              Text(
                  context.loc.t('AI___EPS___SVG__e5fe76',
                      'AI · EPS · SVG · PDF (벡터 파일만 허용)'),
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.warning.withValues(alpha: 0.45))),
            ]),
          ),
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.success.withValues(alpha: 0.20)),
          ),
          child: Row(children: [
            if (isImage && _designLogoBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  Uint8List.fromList(_designLogoBytes!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.insert_drive_file_rounded,
                    color: AppColors.warning.withValues(alpha: 0.70), size: 28),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_designLogoFileName!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(context.loc.t('업로드_완료', '업로드 완료'),
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.success.withValues(alpha: 0.70),
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _designLogoFileName = null;
                _designLogoBytes = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Colors.black12, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 15, color: Colors.black54),
              ),
            ),
          ]),
        ),

      if (hasFile) ...[
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDesignLogoFile,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.refresh_rounded,
                size: 14, color: AppColors.warning.withValues(alpha: 0.70)),
            const SizedBox(width: 4),
            Text(context.loc.t('파일_재선택', '파일 재선택'),
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warning.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    ]);
  }

  Widget _dotRow(String text, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Icon(Icons.circle, size: 4, color: color.withValues(alpha: 0.6)),
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Text(text,
            style: TextStyle(fontSize: 11, color: color, height: 1.4)),
      ),
    ]);
  }

  Widget _refImageCard() {
    final b64 = _refBase64;
    return GestureDetector(
      onTap: () => _pickRefImage(),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: b64 != null
              ? Colors.grey.shade900
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _purple.withValues(alpha: 0.4), width: 1.5),
        ),
        child: b64 != null
            ? Stack(children: [
                // 이미지 — contain으로 잘리지 않게
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Center(
                    child: Image.memory(
                      base64Decode(b64),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // 삭제 버튼
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _refBase64 = null);
                      _saveImage(base64: null);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
                // 재선택 안내
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(context.loc.t('탭하여_재선택', '탭하여 재선택'),
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: _purple, size: 36),
                const SizedBox(height: 6),
                Text(context.loc.t('디자인_참고_이미지_선택', '디자인 참고 이미지 선택'),
                    style: TextStyle(
                        color: _purple,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(context.loc.t('탭하여_갤러리에서_선택', '탭하여 갤러리에서 선택'),
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ]),
      ),
    );
  }

  Future<void> _pickRefImage() async {
    try {
      final picker = ImagePicker();
      final xfile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      final b64 = base64Encode(bytes);
      if (!mounted) return;
      setState(() => _refBase64 = b64);
      await _saveImage(base64: b64);
    } catch (e) {
      _showSnack(context.loc.t('이미지_선택_오류', '이미지 선택 오류: ') + e.toString());
    }
  }

  // 상의 디자인 로고 파일 선택 (AI·SVG·PDF만 허용)
  Future<void> _pickDesignLogoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ai', 'svg', 'pdf', 'eps'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (!mounted) return;
      setState(() {
        _designLogoFileName = file.name;
        _designLogoBytes =
            file.bytes != null ? List<int>.from(file.bytes!) : null;
      });
    } catch (e) {
      _showSnack(context.loc.t('파일_선택_오류', '파일 선택 오류: ') +
          e.toString() +
          context.loc
              .t('_AI_SVG_PDF_EPS_파일만_첨부', '\nAI·SVG·PDF·EPS 파일만 첨부 가능합니다.'));
    }
  }

  // ══════════════════════════════════════════════
  // 허리밴드 디자인 참고이미지 + 로고파일 통합 섹션
  // ══════════════════════════════════════════════
  Widget _buildWaistbandDesignSection() {
    final hasFile = _waistbandLogoFileName != null;

    return _card(
      title: context.loc.t('허리밴드_디자인_참고_이미지_b8f5bc', '허리밴드 디자인 참고 이미지 & 로고 파일'),
      icon: Icons.style_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 1) 참고 이미지 소제목
        Row(children: [
          Icon(Icons.photo_library_outlined, size: 14, color: _purple),
          const SizedBox(width: 6),
          Text(context.loc.t('디자인_참고_이미지__최대__f82772', '디자인 참고 이미지 (최대 3장)'),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _purple)),
        ]),
        const SizedBox(height: 8),

        // 안내 박스
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(context.loc.t('업로드_안내', '업로드 안내'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ]),
            const SizedBox(height: 5),
            Text(
                context.loc.t('원하는_문구_텍스트__또는__ef24c2',
                    '• 원하는 문구(텍스트) 또는 무늬(패턴)가 담긴 이미지를 업로드해 주세요.'),
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
            Text(
                context.loc.t('로고__팀명__숫자__그래픽_d10d57',
                    '• 로고, 팀명, 숫자, 그래픽 무늬 등 허리밴드에 넣고 싶은 디자인 참고 이미지도 가능합니다.'),
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
            Text(
                context.loc.t(
                    '선택사항이며_최대_3장까지__660c66', '• 선택사항이며 최대 3장까지 업로드할 수 있습니다.'),
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
          ]),
        ),

        // 이미지 썸네일 + 추가 버튼
        SizedBox(
          height: 90,
          child: Row(children: [
            ..._waistbandRefImages.asMap().entries.map((e) {
              final idx = e.key;
              final b64 = e.value;
              return Container(
                width: 90,
                height: 90,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(b64),
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _waistbandRefImages.removeAt(idx)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ]),
              );
            }),
            if (_waistbandRefImages.length < 3)
              GestureDetector(
                onTap: _pickWaistbandRefImage,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _purple.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: _purple, size: 26),
                        const SizedBox(height: 4),
                        Text(context.loc.t('이미지_추가', '이미지 추가'),
                            style: TextStyle(
                                fontSize: 10,
                                color: _purple,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
              ),
          ]),
        ),

        const SizedBox(height: 20),
        const Divider(color: AppColors.border),
        const SizedBox(height: 12),

        // ── 2) 로고 파일 소제목
        Row(children: [
          Icon(Icons.attach_file_rounded,
              size: 14, color: AppColors.warning.withValues(alpha: 0.82)),
          const SizedBox(width: 6),
          Text(
              context.loc.t('로고_파일_첨부__선택사항__104b69',
                  '로고 파일 첨부 (선택사항 · AI/SVG/PDF/EPS만)'),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning.withValues(alpha: 0.82))),
        ]),
        const SizedBox(height: 8),

        // 안내 박스
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded,
                size: 13, color: AppColors.warning.withValues(alpha: 0.82)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.loc.t('로고_인쇄_품질을_위해_AI_원본_파일_벡터_을_첨부해_주세요_b65465',
                    '로고 인쇄 품질을 위해 AI 원본 파일(벡터)을 첨부해 주세요.\nAI · SVG · PDF · EPS 파일만 첨부 가능합니다.'),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.warning.withValues(alpha: 0.82),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),
        ),

        // 파일 선택 카드
        GestureDetector(
          onTap: _pickWaistbandLogoFile,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: hasFile
                  ? AppColors.success.withValues(alpha: 0.05)
                  : AppColors.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasFile
                    ? AppColors.success.withValues(alpha: 0.30)
                    : AppColors.warning.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: hasFile
                ? Stack(children: [
                    Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.insert_drive_file_rounded,
                                  color:
                                      AppColors.warning.withValues(alpha: 0.70),
                                  size: 26),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 200,
                              child: Text(
                                _waistbandLogoFileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                                context.loc.t('업로드_완료___탭하여_재선_41774f',
                                    '업로드 완료 · 탭하여 재선택'),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.success
                                        .withValues(alpha: 0.70),
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _waistbandLogoFileName = null;
                          _waistbandLogoBytes = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.upload_file_rounded,
                            color: AppColors.warning.withValues(alpha: 0.05),
                            size: 32),
                        const SizedBox(height: 6),
                        Text(context.loc.t('로고_파일_선택', '로고 파일 선택'),
                            style: TextStyle(
                                color:
                                    AppColors.warning.withValues(alpha: 0.82),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                            context.loc.t('AI___SVG___PDF__65d822',
                                'AI · SVG · PDF · EPS (벡터 파일만 허용)'),
                            style: TextStyle(
                                color:
                                    AppColors.warning.withValues(alpha: 0.45),
                                fontSize: 11)),
                      ]),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 허리밴드 로고 파일 업로드 섹션 (개별 — 내부에서만 사용)
  // ══════════════════════════════════════════════
  Widget _buildWaistbandLogoSection() {
    final hasFile = _waistbandLogoFileName != null;
    final isImage = hasFile &&
        RegExp(r'\.(png|jpg|jpeg|gif|webp|bmp)$', caseSensitive: false)
            .hasMatch(_waistbandLogoFileName!);

    return _card(
      title: context.loc.t('허리밴드_로고_파일', '허리밴드 로고 파일'),
      icon: Icons.attach_file_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 안내 박스 (디자인 참고이미지 스타일)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded,
                size: 13, color: AppColors.warning.withValues(alpha: 0.82)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.loc.t('로고_인쇄_품질을_위해_AI_원본_파일_벡터_을_첨부해_주세요_080bc3',
                    '로고 인쇄 품질을 위해 AI 원본 파일(벡터)을 첨부해 주세요.\nAI · EPS · SVG · PDF 권장 / JPG·PNG는 품질 저하 가능'),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.warning.withValues(alpha: 0.82),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),
        ),

        // ── 파일 선택 카드 (이미지 참고이미지 카드와 동일 비율/스타일)
        GestureDetector(
          onTap: _pickWaistbandLogoFile,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              color: hasFile
                  ? AppColors.success.withValues(alpha: 0.05)
                  : AppColors.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasFile
                    ? AppColors.success.withValues(alpha: 0.30)
                    : AppColors.warning.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: hasFile
                ? Stack(children: [
                    // 파일 정보 (중앙 배치)
                    Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 이미지 미리보기 or 파일 아이콘
                            if (isImage && _waistbandLogoBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  Uint8List.fromList(_waistbandLogoBytes!),
                                  height: 72,
                                  fit: BoxFit.contain,
                                ),
                              )
                            else
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.insert_drive_file_rounded,
                                    color: AppColors.warning
                                        .withValues(alpha: 0.70),
                                    size: 30),
                              ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 200,
                              child: Text(
                                _waistbandLogoFileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                                context.loc.t('업로드_완료___탭하여_재선_41774f',
                                    '업로드 완료 · 탭하여 재선택'),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.success
                                        .withValues(alpha: 0.70),
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
                    // 삭제 버튼 (우상단)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _waistbandLogoFileName = null;
                          _waistbandLogoBytes = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.upload_file_rounded,
                            color: AppColors.warning.withValues(alpha: 0.05),
                            size: 36),
                        const SizedBox(height: 6),
                        Text(context.loc.t('로고_파일_선택', '로고 파일 선택'),
                            style: TextStyle(
                              color: AppColors.warning.withValues(alpha: 0.82),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 2),
                        Text(
                            context.loc.t('AI___EPS___SVG__e5fe76',
                                'AI · EPS · SVG · PDF (벡터 파일만 허용)'),
                            style: TextStyle(
                                color:
                                    AppColors.warning.withValues(alpha: 0.45),
                                fontSize: 11)),
                      ]),
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 허리밴드 디자인 참고이미지 섹션 (참고이미지 아래)
  // ══════════════════════════════════════════════
  Widget _buildWaistbandRefImageSection() {
    return _card(
      title: context.loc.t('허리밴드_디자인_참고_이미지', '허리밴드 디자인 참고 이미지'),
      icon: Icons.style_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 안내 박스
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(context.loc.t('업로드_안내', '업로드 안내'),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ]),
              SizedBox(height: 5),
              Text(
                  context.loc.t('원하는_문구_텍스트__또는__ef24c2',
                      '• 원하는 문구(텍스트) 또는 무늬(패턴)가 담긴 이미지를 업로드해 주세요.'),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              Text(
                  context.loc.t('로고__팀명__숫자__그래픽_d10d57',
                      '• 로고, 팀명, 숫자, 그래픽 무늬 등 허리밴드에 넣고 싶은 디자인 참고 이미지도 가능합니다.'),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              Text(
                  context.loc.t('선택사항이며_최대_3장까지__660c66',
                      '• 선택사항이며 최대 3장까지 업로드할 수 있습니다.'),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded,
                    size: 13, color: AppColors.accent),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    context.loc.t('로고를_첨부하실_경우_AI_원본_파일_벡터_파일_이_필요합니다_917818',
                        '로고를 첨부하실 경우 AI 원본 파일(벡터 파일)이 필요합니다.\n(JPG·PNG 등 래스터 이미지로는 로고 인쇄 품질 보장이 어렵습니다.)'),
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.accent,
                        height: 1.5,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ],
          ),
        ),
        // 이미지 썸네일 + 추가 버튼
        SizedBox(
          height: 90,
          child: Row(children: [
            // 업로드된 이미지들
            ..._waistbandRefImages.asMap().entries.map((e) {
              final idx = e.key;
              final b64 = e.value;
              return Container(
                width: 90,
                height: 90,
                margin: const EdgeInsets.only(right: 8),
                child: Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(b64),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _waistbandRefImages.removeAt(idx)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 13),
                      ),
                    ),
                  ),
                ]),
              );
            }),
            // 추가 버튼 (최대 3장)
            if (_waistbandRefImages.length < 3)
              GestureDetector(
                onTap: _pickWaistbandRefImage,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: _purple, size: 26),
                        const SizedBox(height: 4),
                        Text(context.loc.t('이미지_추가', '이미지 추가'),
                            style: TextStyle(
                                fontSize: 10,
                                color: _purple,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // 인원별 사이즈 섹션
  // ══════════════════════════════════════════════
  // ─── 인원 목록 헬퍼 ────────────────────────────

  Widget _buildPersonListSection() {
    return _card(
      title:
          '${context.loc.t('인원별_사이즈', '인원별 사이즈')} (${context.loc.t('총', '총')} ${_totalCount}${context.loc.t('명', '명')})',
      icon: Icons.format_list_numbered_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 추가제작: 기존 주문 동일 디자인 안내 배너
        if (_isAdditional && _originalOrder != null) ...[
          // ── 기존 주문 디자인 확정 이미지
          Builder(builder: (_) {
            // 1순위: 디자인 수정 완료 후 확정된 이미지
            // 2순위: 주문 시 등록된 디자인 파일 이미지 (폴백)
            final confirmedUrl = (_originalOrder!
                        .customOptions?['designConfirmedImageUrl'] as String?)
                    ?.trim() ??
                '';
            final fallbackUrl =
                (_originalOrder!.customOptions?['designFileUrl'] as String?)
                        ?.trim() ??
                    '';
            final originalDesignUrl =
                confirmedUrl.isNotEmpty ? confirmedUrl : fallbackUrl;
            final hasDesignImg = originalDesignUrl.isNotEmpty;
            final isConfirmed = confirmedUrl.isNotEmpty;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF795548).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF795548).withValues(alpha: 0.35)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Color(0xFF795548)),
                      const SizedBox(width: 6),
                      Text(
                          context.loc.t('기존_주문과_동일한_디자인으_7cbf6d',
                              '기존 주문과 동일한 디자인으로 제작됩니다'),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF795548))),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                        context.loc.t('색상___원단___허리밴드__c79c9e',
                            '• 색상 · 원단 · 허리밴드 · 로고 등 모든 옵션은 기존 주문과 동일하게 적용됩니다.'),
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF795548),
                            height: 1.5)),
                    Text(
                        context.loc.t('인원별_사이즈와_주문자_정보_79f799',
                            '• 인원별 사이즈와 주문자 정보만 새로 입력해 주세요.'),
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF795548),
                            height: 1.5)),
                    if (hasDesignImg) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            isConfirmed
                                ? context.loc.t('디자인_확정_이미지', '디자인 확정 이미지')
                                : context.loc
                                    .t('주문_당시_디자인_이미지', '주문 당시 디자인 이미지'),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5D4037)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isConfirmed
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isConfirmed
                                    ? AppColors.success.withValues(alpha: 0.4)
                                    : AppColors.warning.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isConfirmed
                                  ? context.loc.t('수정_완료', '수정 완료')
                                  : context.loc.t('수정_전', '수정 전'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isConfirmed
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          originalDesignUrl,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(
                                      height: 120,
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                                context.loc
                                    .t('이미지를_불러올_수_없습니다', '이미지를 불러올 수 없습니다'),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                          context.loc.t('디자인_확정_이미지는_관리자_07ab20',
                              '• 디자인 확정 이미지는 관리자가 등록한 후 확인 가능합니다.'),
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                              height: 1.5)),
                    ],
                  ]),
            );
          }),
        ],

        // ── 재봉방법 선택사항 표시 배너 (신규 주문만)
        if (!_isAdditional)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
            ),
            child: Row(children: [
              Icon(Icons.content_cut_outlined,
                  size: 15, color: AppColors.primary.withValues(alpha: 0.70)),
              const SizedBox(width: 8),
              Text(context.loc.t('재봉방법', '재봉방법: '),
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600)),
              Text(context.loc.t(_fabricType, _fabricType),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary.withValues(alpha: 0.90))),
              if (_fabricExtra > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                      '+${_fmt(_fabricExtra)}' + context.loc.t('원', '원'),
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.warning.withValues(alpha: 0.90),
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ),

        // ── 색상 통일 안내 배너 (신규 주문만)
        if (!_isAdditional && _mainColorName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _adjustedColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _adjustedColor.withValues(alpha: 0.40), width: 1.5),
            ),
            child: Row(children: [
              // 원본 색상 원
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _mainColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 2)
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded,
                  size: 10, color: Colors.black38),
              const SizedBox(width: 3),
              // 조절 후 색상 원 (더 크게)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _adjustedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 3)
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(context.loc.t('전체_색상_통일', '전체 색상 통일: '),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54)),
                      Text(_mainColorName!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: _purple)),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      Text(
                        '#${_adjustedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text('· ' + _lightnessLabel,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black38,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ],

        // ── 하의 길이 안내 배너 (신규 주문만)
        if (!_isAdditional &&
            (_maleLengthSel != null || _femaleLengthSel != null)) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.straighten_rounded,
                    size: 15, color: AppColors.primary.withValues(alpha: 0.70)),
                const SizedBox(width: 6),
                Text(context.loc.t('하의_길이__성별_통일_적용', '하의 길이 (성별 통일 적용)'),
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const SizedBox(width: 21),
                Icon(Icons.male_rounded,
                    size: 13, color: AppColors.info.withValues(alpha: 0.70)),
                const SizedBox(width: 3),
                Text(context.loc.t('남성', '남성: '),
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.info.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600)),
                Text(
                  _maleLengthSel ?? context.loc.t('미선택', '미선택'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _maleLengthSel != null
                        ? AppColors.primary.withValues(alpha: 0.90)
                        : AppColors.warning.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.female_rounded,
                    size: 13, color: Colors.pink.shade500),
                const SizedBox(width: 3),
                Text(context.loc.t('여성', '여성: '),
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.pink.shade700,
                        fontWeight: FontWeight.w600)),
                Text(
                  _femaleLengthSel ?? context.loc.t('미선택', '미선택'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _femaleLengthSel != null
                        ? AppColors.primary.withValues(alpha: 0.90)
                        : AppColors.warning.withValues(alpha: 0.82),
                  ),
                ),
              ]),
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
            icon:
                const Icon(Icons.person_add_outlined, size: 18, color: _purple),
            label: Text(context.loc.t('인원_추가', '인원 추가'),
                style: TextStyle(color: _purple, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _purple, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
    // 성인 사이즈 표
    final adultHeaders = [
      context.loc.t('사이즈', '사이즈'),
      context.loc.t('키_cm', '키(cm)'),
      context.loc.t('몸무게_kg', '몸무게(kg)'),
      context.loc.t('가슴_cm', '가슴(cm)'),
      context.loc.t('허리_cm', '허리(cm)')
    ];
    final adultRows = [
      ['XS', '154~159', '44~51', '85 cm', '68 cm'],
      ['S', '160~165', '52~60', '90 cm', '72 cm'],
      ['M', '166~172', '61~71', '95 cm', '76 cm'],
      ['L', '172~177', '72~78', '100 cm', '80 cm'],
      ['XL', '177~182', '79~85', '105 cm', '84 cm'],
      ['2XL', '182~187', '86~91', '110 cm', '88 cm'],
      ['3XL', '187~191', '91~96', '115 cm', '92 cm'],
    ];
    // 주니어 사이즈 표
    final juniorHeaders = [
      context.loc.t('사이즈', '사이즈'),
      context.loc.t('키_cm', '키(cm)'),
      context.loc.t('몸무게_kg', '몸무게(kg)'),
      context.loc.t('가슴_cm', '가슴(cm)'),
      context.loc.t('허리_cm', '허리(cm)')
    ];
    final juniorRows = [
      ['XXS(80)', '75~85', '11~13', '54 cm', '48 cm'],
      ['XS(90)', '85~95', '13~15', '58 cm', '51 cm'],
      ['S(100)', '95~105', '15~18', '62 cm', '54 cm'],
      ['M(110)', '105~115', '18~22', '66 cm', '57 cm'],
      ['L(120)', '115~125', '22~27', '70 cm', '60 cm'],
      ['XL(130)', '125~135', '27~33', '74 cm', '63 cm'],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── 허리밴드 색상 표시 (사이즈표 위) - 실제 허리밴드 hex 색상 사용
      if (_waistbandColorHex.length == 7) ...[
        Builder(builder: (context) {
          final wbColor = _parseHexColor(_waistbandColorHex);
          final isLight = wbColor.computeLuminance() > 0.5;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: wbColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: wbColor.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Row(children: [
              // 허리밴드 실제 색상 원
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: wbColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLight ? Colors.black26 : Colors.white,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 3)
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.loc.t('허리밴드_컬러', '허리밴드 컬러'),
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    _waistbandColorHex.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: wbColor.withValues(alpha: 1.0),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ]),
          );
        }),
      ],
      // 헤더 토글
      GestureDetector(
        onTap: () => setState(() => _sizeTableExpanded = !_sizeTableExpanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _sizeTableExpanded
                ? _purple.withValues(alpha: 0.07)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: _sizeTableExpanded
                    ? _purple.withValues(alpha: 0.2)
                    : Colors.grey.shade200),
          ),
          child: Row(children: [
            Icon(Icons.table_chart_outlined,
                size: 15,
                color: _sizeTableExpanded ? _purple : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(context.loc.t('사이즈_참고표_보기', '사이즈 참고표 보기'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
        // ── 성인 사이즈 표
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _purple,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(context.loc.t('성인', '성인'),
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 6),
            Text('Adult Size Guide',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ]),
        ),
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
                  decoration:
                      BoxDecoration(color: _purple.withValues(alpha: 0.08)),
                  children: adultHeaders
                      .map((h) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            child: Text(h,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _purple)),
                          ))
                      .toList(),
                ),
                ...adultRows.map((r) => TableRow(
                      children: r
                          .map((cell) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Text(cell,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.black87)),
                              ))
                          .toList(),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // ── 주니어 사이즈 표
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(context.loc.t('주니어', '주니어'),
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 6),
            Text('Junior Size Guide',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            border:
                Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.05)),
                verticalInside: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.10)),
              ),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.05)),
                  children: juniorHeaders
                      .map((h) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            child: Text(h,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warning
                                        .withValues(alpha: 0.82))),
                          ))
                      .toList(),
                ),
                ...juniorRows.map((r) => TableRow(
                      children: r
                          .map((cell) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Text(cell,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.black87)),
                              ))
                          .toList(),
                    )),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 12, color: AppColors.warning),
            SizedBox(width: 5),
            Expanded(
                child: Text(
              context.loc.t('위_사이즈에_해당하지_않으면_상세치수',
                  "위 사이즈에 해당하지 않으면 '상세치수 입력'을 선택해 주세요."),
              style: TextStyle(fontSize: 10, color: AppColors.warning),
            )),
          ]),
        ),
      ],
    ]);
  }

  // ── 인원 한 줄 카드
  Widget _personRow(_PersonEntry p, int idx) {
    final isMale = p.gender == 'male';
    final isFemale = p.gender == 'female';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.gender == null
              ? Colors.grey.shade200
              : _purple.withValues(alpha: 0.25),
          width: p.gender == null ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 헤더 행 (번호 / 이름 / 성별 / 삭제)
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: p.gender == null
                ? Colors.grey.shade50
                : (isMale
                    ? AppColors.info.withValues(alpha: 0.05)
                    : Colors.pink.shade50),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            // 번호 뱃지
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: p.gender == null
                    ? Colors.grey.shade400
                    : (isMale ? AppColors.info : Colors.pink),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('${idx + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            // 이름 (10명 이상일 때만 입력 가능)
            Expanded(
              child: Tooltip(
                message: _nameEnabled
                    ? ''
                    : context.loc.t('10명_이상일_때_이름_입력_가능', '10명 이상일 때 이름 입력 가능'),
                child: TextField(
                  controller: p.nameCtrl,
                  enabled: _nameEnabled,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _nameEnabled ? Colors.black87 : Colors.grey.shade400,
                  ),
                  decoration: InputDecoration(
                    hintText: _nameEnabled
                        ? context.loc.t('이름_입력', '이름 입력')
                        : context.loc.t('10명_이상_시_입력', '10명 이상 시 입력'),
                    hintStyle:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    filled: true,
                    fillColor:
                        _nameEnabled ? Colors.white : Colors.grey.shade100,
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
                        borderSide:
                            const BorderSide(color: _purple, width: 1.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 성별 버튼 (필수)
            Column(mainAxisSize: MainAxisSize.min, children: [
              if (p.gender == null)
                Text(context.loc.t('필수', '필수*'),
                    style: TextStyle(
                        fontSize: 9,
                        color: AppColors.error.withValues(alpha: 0.70),
                        fontWeight: FontWeight.w700)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _genderBtn(context.loc.t('남', '남'), isMale, AppColors.info,
                    () => setState(() => p.gender = 'male')),
                const SizedBox(width: 5),
                _genderBtn(context.loc.t('여', '여'), isFemale, Colors.pink,
                    () => setState(() => p.gender = 'female')),
              ]),
            ]),
            const SizedBox(width: 6),
            // 사이즈 불러오기 버튼
            GestureDetector(
              onTap: () => _showLoadSizeSheet(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _purple.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.download_outlined, size: 13, color: _purple),
                  const SizedBox(width: 3),
                  Text(context.loc.t('불러오기', '불러오기'),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _purple)),
                ]),
              ),
            ),
            const SizedBox(width: 6),
            // 삭제
            GestureDetector(
              onTap: () => _removePerson(idx),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close,
                    color: AppColors.error.withValues(alpha: 0.45), size: 16),
              ),
            ),
          ]),
        ),

        // ── 본문 (사이즈 입력)
        Padding(
          padding: const EdgeInsets.all(12),
          child: p.gender == null
              // 성별 미선택 시 비활성화 안내
              ? Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wc_rounded,
                          size: 28, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        context.loc.t('성별을_먼저_선택해_주세요', '성별을 먼저 선택해 주세요'),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.loc.t('위_남여_버튼으로_성별을_선택',
                            '위 남/여 버튼으로 성별을 선택하면 사이즈 입력이 활성화됩니다.'),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ① 성인/주니어 구분 선택
                  Row(children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(context.loc.t('사이즈_구분', '사이즈 구분'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const SizedBox(width: 10),
                    _sizeTypeBtn(
                        context.loc.t('성인', '성인'), p, AppColors.primary),
                    const SizedBox(width: 6),
                    _sizeTypeBtn(
                        context.loc.t('주니어', '주니어'), p, AppColors.primary),
                  ]),
                  const SizedBox(height: 10),

                  // ② 사이즈표 토글
                  _buildPersonSizeTable(p),
                  const SizedBox(height: 10),

                  // ③ 상의 사이즈 선택 (하의/타이즈 단체주문 시 숨김)
                  if (!_isBottomOnly) ...[
                    _buildPersonSizeSelector(
                      label: context.loc.t('상의_사이즈', '상의 사이즈 *'),
                      icon: Icons.checkroom_outlined,
                      selected: p.topSize,
                      sizeType: p.sizeType,
                      onSelect: (v) => setState(() => p.topSize = v),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ④ 하의 사이즈 선택 (상의 카테고리일 때 숨김)
                  if (!_isTopOnly) ...[
                    _buildPersonSizeSelector(
                      label: _isBottomOnly
                          ? context.loc.t('사이즈', '사이즈 *')
                          : context.loc.t('하의_사이즈', '하의 사이즈 *'),
                      icon: Icons.accessibility_new_rounded,
                      selected: p.bottomSize,
                      sizeType: p.sizeType,
                      onSelect: (v) => setState(() => p.bottomSize = v),
                    ),
                    const SizedBox(height: 10),

                    // ⑤ 상세치수 토글 (하의 전용)
                    GestureDetector(
                      onTap: () => setState(() => p.showDetail = !p.showDetail),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: p.showDetail
                              ? AppColors.warning.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: p.showDetail
                                ? AppColors.warning.withValues(alpha: 0.30)
                                : Colors.grey.shade300,
                            width: p.showDetail ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(Icons.straighten_rounded,
                              size: 14,
                              color: p.showDetail
                                  ? AppColors.warning.withValues(alpha: 0.82)
                                  : Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(context.loc.t('하의_상세_치수_입력', '하의 상세 치수 입력'),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: p.showDetail
                                      ? AppColors.warning
                                          .withValues(alpha: 0.90)
                                      : Colors.grey.shade600)),
                          const SizedBox(width: 5),
                          Text(context.loc.t('사이즈_미해당_시', '(사이즈 미해당 시)'),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade400)),
                          const Spacer(),
                          Icon(
                              p.showDetail
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: p.showDetail
                                  ? AppColors.warning.withValues(alpha: 0.70)
                                  : Colors.grey.shade400),
                        ]),
                      ),
                    ),

                    // ⑤-1 하의 상세치수 패널 (키·몸무게·허리·허벅지)
                    if (p.showDetail) ...[
                      const SizedBox(height: 8),
                      _detailMeasurePanel(p),
                    ],

                    // ④ 하의 길이 안내 (성별에 따라 적용값 표시, 읽기 전용)
                    const SizedBox(height: 10),
                    Builder(builder: (_) {
                      final isFemale = p.gender == 'female';
                      final lenSel =
                          isFemale ? _femaleLengthSel : _maleLengthSel;
                      final lenLabel = lenSel ??
                          context.loc.t('미선택_위에서_선택해_주세요', '미선택 (위에서 선택해 주세요)');
                      final selected = lenSel != null;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.10)),
                        ),
                        child: Row(children: [
                          Icon(
                              isFemale
                                  ? Icons.female_rounded
                                  : Icons.male_rounded,
                              size: 13,
                              color: isFemale
                                  ? Colors.pink.shade400
                                  : AppColors.info.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Text(context.loc.t('하의_길이', '하의 길이: '),
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w600)),
                          Text(
                            lenLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.90)
                                  : AppColors.warning.withValues(alpha: 0.82),
                            ),
                          ),
                          const Spacer(),
                          if (selected)
                            Icon(Icons.check_circle_rounded,
                                size: 13,
                                color:
                                    AppColors.primary.withValues(alpha: 0.05)),
                        ]),
                      );
                    }),
                  ], // if (!_isTopOnly)
                ]),
        ),
      ]),
    );
  }

  // ── 상의/하의 사이즈 직접입력 필드
  // ignore: unused_element
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
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.black54)),
        const SizedBox(width: 4),
        Text('*',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.error.withValues(alpha: 0.45),
                fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
              letterSpacing: 0),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              ? Icon(Icons.check_circle_rounded,
                  color: _purple.withValues(alpha: 0.6), size: 18)
              : null,
        ),
        onChanged: (_) => setState(() {}), // suffixIcon 갱신
      ),
    ]);
  }

  // ── 팀원별 사이즈표 토글 ─────────────────────────────
  Widget _buildPersonSizeTable(_PersonEntry p) {
    final tableRows = p.sizeType == '성인' ? _kAdultSizeRows : _kJuniorSizeRows;
    final headers = [
      context.loc.t('사이즈', '사이즈'),
      context.loc.t('키_cm', '키(cm)'),
      context.loc.t('몸무게_kg', '몸무게(kg)'),
      context.loc.t('가슴_cm', '가슴(cm)'),
      context.loc.t('허리_cm', '허리(cm)')
    ];
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => p.showSizeTable = !p.showSizeTable),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.showSizeTable
                ? _purple.withValues(alpha: 0.07)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: p.showSizeTable
                    ? _purple.withValues(alpha: 0.3)
                    : Colors.grey.shade200),
          ),
          child: Row(children: [
            Icon(Icons.table_chart_outlined,
                size: 14,
                color: p.showSizeTable ? _purple : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(context.loc.t('사이즈_참고표', '사이즈 참고표'),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.showSizeTable ? _purple : Colors.grey.shade600)),
            const Spacer(),
            Icon(p.showSizeTable ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: p.showSizeTable ? _purple : Colors.grey.shade400),
          ]),
        ),
      ),
      if (p.showSizeTable) ...[
        const SizedBox(height: 6),
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
                  decoration:
                      BoxDecoration(color: _purple.withValues(alpha: 0.08)),
                  children: headers
                      .map((h) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Text(h,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _purple)),
                          ))
                      .toList(),
                ),
                ...tableRows.map((r) => TableRow(
                      children: r
                          .map((cell) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                child: Text(cell,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.black87)),
                              ))
                          .toList(),
                    )),
              ],
            ),
          ),
        ),
      ],
    ]);
  }

  // ── 팀원별 사이즈 선택 버튼 ─────────────────────────
  Widget _buildPersonSizeSelector({
    required String label,
    required IconData icon,
    required String? selected,
    required String sizeType,
    required ValueChanged<String> onSelect,
  }) {
    final sizes = sizeType == '성인' ? _kAdultSizes : _kJuniorSizes;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 13, color: Colors.black54),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.black54)),
      ]),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: sizes.map((size) {
          final isSelected = selected == size;
          return GestureDetector(
            onTap: () => onSelect(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? _purple : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: isSelected ? _purple : Colors.grey.shade300,
                    width: isSelected ? 2 : 1),
              ),
              child: Text(size,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.grey.shade600)),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  // ── 상세 치수 입력 패널
  Widget _detailMeasurePanel(_PersonEntry p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.straighten_rounded,
              size: 14, color: AppColors.warning.withValues(alpha: 0.82)),
          const SizedBox(width: 6),
          Text(context.loc.t('상세_치수_입력', '상세 치수 입력'),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.warning.withValues(alpha: 0.90))),
          const SizedBox(width: 6),
          Text(context.loc.t('사이즈_미해당_시_입력', '(사이즈 미해당 시 입력)'),
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.warning.withValues(alpha: 0.70))),
        ]),
        const SizedBox(height: 10),
        // 2열 그리드: 키, 몸무게, 허리, 허벅지
        Row(children: [
          Expanded(
              child: _measureField(p.heightCtrl, context.loc.t('키', '키'), 'cm',
                  Icons.height_rounded)),
          const SizedBox(width: 8),
          Expanded(
              child: _measureField(p.weightCtrl, context.loc.t('몸무게', '몸무게'),
                  'kg', Icons.monitor_weight_outlined)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _measureField(p.waistCtrl, context.loc.t('허리', '허리'), 'cm',
                  Icons.radio_button_unchecked)),
          const SizedBox(width: 8),
          Expanded(
              child: _measureField(p.thighCtrl, context.loc.t('허벅지', '허벅지'),
                  'cm', Icons.airline_seat_legroom_normal_rounded)),
        ]),
      ]),
    );
  }

  // ── 치수 입력 필드 (라벨 + 단위)
  Widget _measureField(
      TextEditingController ctrl, String label, String unit, IconData icon) {
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
          child: Icon(icon,
              size: 14, color: AppColors.warning.withValues(alpha: 0.05)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 11,
            color: AppColors.warning.withValues(alpha: 0.82),
            fontWeight: FontWeight.w700),
        suffixText: unit,
        suffixStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: AppColors.warning.withValues(alpha: 0.30))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: AppColors.warning.withValues(alpha: 0.20))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: AppColors.warning.withValues(alpha: 0.05), width: 1.5)),
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
          border: Border.all(
              color: isSel ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSel ? Colors.white : Colors.black54)),
      ),
    );
  }

  Widget _genderBtn(String label, bool isSel, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 36,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSel ? color : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: isSel ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSel ? Colors.white : Colors.black54)),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 기본 정보 섹션
  // ══════════════════════════════════════════════
  Widget _buildBasicInfoSection() {
    return _card(
      title: context.loc.t('기본_정보', '기본 정보'),
      icon: Icons.info_outline_rounded,
      child: Column(children: [
        _inputField(context.loc.t('단체명', '단체명 *'), _teamNameCtrl,
            context.loc.t('단체명을_입력해_주세요', '단체명을 입력해 주세요')),
        // ── 인쇄타입 '전면 단체명 변경' 선택 시 안내문구 ──
        if (_hasTeamName)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: Color(0xFFF57C00)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF5D4037), height: 1.5),
                      children: [
                        TextSpan(
                          text: context.loc.t('인쇄_안내', '인쇄 안내: '),
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF57C00)),
                        ),
                        TextSpan(
                          text: context.loc.t(
                              '현재_전면_단체명_인쇄_옵션이_선택되어_있습니다_n위_단체명__53b3f0',
                              '현재 전면 단체명 인쇄 옵션이 선택되어 있습니다.\n위 단체명 입력칸에 입력한 단체명으로 전면에 단체명이 인쇄됩니다.'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        _inputField(context.loc.t('담당자_이름', '담당자 이름'), _managerNameCtrl,
            context.loc.t('담당자_이름', '담당자 이름')),
        _inputField(context.loc.t('연락처', '연락처 *'), _phoneCtrl, '010-0000-0000',
            keyboardType: TextInputType.phone),
        _inputField(
            context.loc.t('이메일', '이메일'), _emailCtrl, 'example@email.com',
            keyboardType: TextInputType.emailAddress),
        // 주소 (카카오 주소검색)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(context.loc.t('배송_주소', '배송 주소 *'),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54)),
              const Spacer(),
              // 저장 주소 선택 버튼
              Builder(builder: (ctx) {
                final user = Provider.of<UserProvider>(ctx, listen: false).user;
                if (user == null || user.addresses.isEmpty)
                  return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => _showSavedAddressPicker(user.addresses),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _purple.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bookmark_outline_rounded,
                          size: 12, color: _purple),
                      const SizedBox(width: 4),
                      Text(context.loc.t('저장_주소_선택', '저장 주소 선택'),
                          style: TextStyle(
                              fontSize: 11,
                              color: _purple,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                );
              }),
            ]),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _openKakaoAddressSearch(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _address.isEmpty ? Colors.grey.shade300 : _purple,
                      width: _address.isEmpty ? 1.0 : 1.5),
                  borderRadius: BorderRadius.circular(8),
                  color: _address.isEmpty
                      ? Colors.white
                      : AppColors.primary.withValues(alpha: 0.05),
                ),
                child: Row(children: [
                  Icon(Icons.location_on_outlined,
                      color: _address.isEmpty ? Colors.grey.shade400 : _purple,
                      size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _address.isEmpty
                          ? context.loc.t('주소_검색_카카오', '주소 검색 (카카오)')
                          : _address,
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              _address.isEmpty ? Colors.grey : Colors.black87),
                    ),
                  ),
                  Icon(Icons.search,
                      color: _address.isEmpty ? Colors.grey.shade400 : _purple,
                      size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            // 상세주소 입력 (필수)
            TextField(
              controller: _addressDetailCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    context.loc.t('상세주소_입력__동_호수_등', '상세주소 입력 (동/호수 등) *'),
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _purple, width: 1.5),
                ),
                prefixIcon: Icon(Icons.home_outlined,
                    size: 16, color: Colors.grey.shade500),
              ),
            ),
          ]),
        ),
        // ── 1년 독점 디자인 소유 체크박스 ──
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _exclusiveDesign
                ? AppColors.surfaceGray
                : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _exclusiveDesign ? _purple : Colors.grey.shade300,
              width: _exclusiveDesign ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _exclusiveDesign,
                  activeColor: _purple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) =>
                      setState(() => _exclusiveDesign = v ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _exclusiveDesign = !_exclusiveDesign),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.5),
                      children: [
                        TextSpan(
                          text: context.loc.t('1년_독점_디자인_소유', '1년 독점 디자인 소유  '),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _exclusiveDesign
                                ? _purple
                                : AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: context.loc.t('선택_무료', '(선택 · 무료)  '),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success),
                        ),
                        TextSpan(
                          text: context.loc.t('무료_제공', '무료 제공'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color:
                                _exclusiveDesign ? _purple : AppColors.success,
                          ),
                        ),
                        TextSpan(
                          text: context.loc.t('1년간_해당_디자인을_타인에게_배포하지_않습니다',
                              '· 1년간 해당 디자인을 타인에게 배포하지 않습니다.'),
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: context.loc.t(
                              '별도_이야기_없으면_매년_2월_1일_홈페이지에_업로드_됩니다',
                              '· 별도 이야기 없으면 매년 2월 1일 홈페이지에 업로드 됩니다.'),
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: context.loc.t(
                              '같은_디자인_희망_시_색상만_변경_가능_같은_색상_제작_불가',
                              '· 같은 디자인 희망 시 색상만 변경 가능 (같은 색상 제작 불가)'),
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF880E4F),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
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

  // ── 저장된 주소 선택 바텀시트 ──
  void _showSavedAddressPicker(List addresses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(children: [
                const Icon(Icons.bookmark_rounded, size: 16, color: _purple),
                const SizedBox(width: 8),
                Text(context.loc.t('저장된_배송지_선택', '저장된 배송지 선택'),
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child:
                      Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: addresses.length,
                itemBuilder: (_, i) {
                  final addr = addresses[i];
                  final isDefault = addr.isDefault == true;
                  return ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDefault
                            ? _purple.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDefault
                            ? Icons.home_rounded
                            : Icons.location_on_outlined,
                        size: 16,
                        color: isDefault ? _purple : Colors.grey.shade500,
                      ),
                    ),
                    title: Text(
                      addr.address1,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: addr.address2.isNotEmpty
                        ? Text(addr.address2,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500))
                        : null,
                    trailing: isDefault
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(context.loc.t('기본', '기본'),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: _purple,
                                    fontWeight: FontWeight.w700)),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _address = addr.address1;
                        _addressDetailCtrl.text = addr.address2;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openKakaoAddressSearch() async {
    final result = await showAddressSearch(context);
    if (result != null && mounted) {
      setState(() {
        _address = result.roadAddress.isNotEmpty
            ? result.roadAddress
            : result.jibunAddress;
      });
    }
  }

  // ══════════════════════════════════════════════
  // 메모 섹션
  // ══════════════════════════════════════════════
  Widget _buildMemoSection() {
    return _card(
      title: context.loc.t('디자인_요청_사항', '디자인 요청 사항 *'),
      icon: Icons.edit_note_rounded,
      child: TextField(
        controller: _memoCtrl,
        maxLines: 4,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: context.loc.t('디자인_요청_사항을_입력해__310427',
              '디자인 요청 사항을 입력해 주세요 (필수)\n예) 색상, 로고 위치, 단체명, 특별 요청 등'),
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _purple, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 금액 요약 섹션
  // ══════════════════════════════════════════════
  Widget _buildSummarySection() {
    return _card(
      title: context.loc.t('금액_요약', '금액 요약'),
      icon: Icons.receipt_long_outlined,
      child: Column(children: [
        // ── 인원당 단가 구성 ──
        if (_hasPocket)
          _sumRow(
              context.loc.t('주머니_추가', '주머니 추가'), '+${_fmt(_pocketPrice)}원/인',
              valueColor: AppColors.accent),
        _sumRow(context.loc.t('기본_단가', '기본 단가'), '${_fmt(_basePrice)}원/인'),
        if (_fabricExtra > 0)
          _sumRow('  ↳ ' + context.loc.t('심리스무봉제_추가', '심리스(무봉제) 추가'),
              '+${_fmt(_fabricExtra)}원/인',
              valueColor: AppColors.accent),
        if (_isTights9)
          _sumRow('  ↳ ' + context.loc.t('타이즈_9부_추가', '타이즈 9부 추가'),
              '+${_fmt(_tights9Price)}원/인',
              valueColor: AppColors.accent),
        _sumRow(
            context.loc.t('인원당_단가_합계', '인원당 단가 합계'), '${_fmt(_unitPrice)}원/인',
            isSub: true),
        const SizedBox(height: 4),
        // ── 인원수 곱하기 ──
        _sumRow(context.loc.t('총_인원', '총 인원'),
            '$_totalCount' + context.loc.t('명', '명')),
        const Divider(height: 20),
        _sumRow(context.loc.t('상품_합계', '상품 합계'),
            '${_fmt(_subTotal)}' + context.loc.t('원', '원')),
        _sumRow(
          context.loc.t('배송비', '배송비'),
          _totalCount >= AppConstants.groupMinFreeShipping
              ? context.loc.t('무료_5장_이상', '무료 (5장 이상)')
              : '+${_fmt(_shipping)}' + context.loc.t('원_5장_미만', '원 (5장 미만)'),
          valueColor: _totalCount >= AppConstants.groupMinFreeShipping
              ? AppColors.success
              : AppColors.warning,
        ),
        if (_waistbandExtra > 0)
          _sumRow(context.loc.t('허리밴드', '허리밴드 ') + _waistbandOptionLabel,
              '+${_fmt(_waistbandExtra)}' + context.loc.t('원', '원'),
              valueColor: AppColors.accent),
        if (_exclusiveDesign)
          _sumRow(context.loc.t('1년_독점_디자인', '1년 독점 디자인'),
              context.loc.t('무료', '무료'),
              valueColor: AppColors.success),
        const Divider(height: 20),
        _sumRow(context.loc.t('최종_결제금액', '최종 결제금액'),
            '${_fmt(_finalPrice)}' + context.loc.t('원', '원'),
            isTotal: true),

        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // ── 동의 체크박스 ──
        GestureDetector(
          onTap: () => setState(() => _orderConfirmed = !_orderConfirmed),
          child: Row(
            children: [
              Icon(
                _orderConfirmed
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 22,
                color: _orderConfirmed ? AppColors.primary : AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.loc
                      .t('주문_내용을_모두_확인하였으며', '주문 내용을 모두 확인하였으며 구매에 동의합니다.'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 주문하기 버튼 ──
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed:
                _orderConfirmed ? () => _submitOrder(isBuyNow: true) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _orderConfirmed ? AppColors.primary : Colors.grey.shade300,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              context.loc.t('주문하기', '주문하기'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sumRow(String label, String value,
      {bool isTotal = false, bool isSub = false, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 2 : 3),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 14 : (isSub ? 12 : 13),
                  fontWeight: isTotal
                      ? FontWeight.w800
                      : (isSub ? FontWeight.w700 : FontWeight.w500),
                  color: isTotal
                      ? AppColors.textPrimary
                      : (isSub
                          ? AppColors.textPrimary
                          : AppColors.textSecondary))),
        ),
        Text(value,
            style: TextStyle(
                fontSize: isTotal ? 16 : (isSub ? 13 : 13),
                fontWeight: isTotal
                    ? FontWeight.w900
                    : (isSub ? FontWeight.w800 : FontWeight.w600),
                color: valueColor ??
                    (isTotal ? AppColors.primary : AppColors.textPrimary))),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  Widget _buildCancelPolicySection() {
    return _card(
      title: context.loc.t('취소_환불_규정', '취소·환불 규정'),
      icon: Icons.policy_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기성품
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceGray,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(context.loc.t('기성품', '기성품'),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.loc.t('수령_후_3일_이내_교환환불_가능', '수령 후 7일 이내 교환·환불 가능'),
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 단체주문
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC62828),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(context.loc.t('커스텀_단체', '커스텀(단체)'),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.loc
                            .t('의류_자체_불량_외_교환환불_불가', '의류 자체 불량 외 교환·환불 불가'),
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    context.loc.t('커스텀_제작_특성상_옷_자체_하자',
                        '커스텀 제작 특성상 옷 자체의 하자가 아닌 경우\n교환·환불이 불가합니다.'),
                    style: TextStyle(
                        fontSize: 11, color: AppColors.error, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 공통 카드 래퍼
  // ══════════════════════════════════════════════
  Widget _card(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x081A1A2E), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 탑텐 스타일 섹션 헤더: 좌측 3px 블랙 보더
        Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 0, 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceGray,
            borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: AppColors.accent, width: 3)),
          ),
          child: Row(children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 7),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -0.2)),
          ]),
        ),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}
