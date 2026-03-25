import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../../utils/app_localizations.dart';
import '../../utils/constants.dart';
import '../../widgets/pc_layout.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/color_picker_widget.dart';
import '../orders/checkout_screen.dart';
import '../../widgets/kakao_address_search.dart';
import '../../services/order_service.dart';

// ══════════════════════════════════════════════════════════════
// 단체 주문 폼
// ══════════════════════════════════════════════════════════════
class GroupOrderFormScreen extends StatefulWidget {
  final ProductModel? product;
  /// true = 추가제작 모드: 1장부터 모든 옵션 선택 가능
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
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  final _scrollCtrl = ScrollController();
  final _formKey = GlobalKey<FormState>();

  // ── 기본 정보 ──
  final _teamNameCtrl = TextEditingController();
  final _managerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  // ── 인쇄 타입 ──
  int _printType = 0;

  // ── 색상 ──
  String? _mainColorName;
  Color? _mainColor;
  String? _waistbandColorName;
  Color? _waistbandColorValue;

  // ── 싱글렛세트 전용: 하의 별도 색상 ──
  String? _bottomColorName;
  Color? _bottomColor;
  bool _useSeparateBottomColor = false; // 상·하의 색상 분리 여부

  // ── 원단 타입 ──
  String _fabricType = '일반 (봉제)'; // 기본 원단: 일반(봉제)
  String _fabricWeight = '80g';       // 기본 무게: 80g

  // ── 하의 길이 기본 설정 (전체 인원 공통 적용) ──
  String? _defaultLength; // null=각자 선택, '9부','5부','4부','3부','2.5부','숏쇼트'

  // ── 디자인 독점 사용권 ──
  bool _exclusiveDesign = false;

  // ── 허리밴드 추가 (선택사항, 중복선택 가능)
  bool _addWaistbandDesign = false;   // 허리밴드 변경 활성화 체크박스
  // 중복선택 가능: 'name'=단체명, 'color'=색상 (각각 독립 선택 가능)
  bool _waistbandName = false;        // 단체명 변경
  bool _waistbandColor = false;       // 색상 변경
  String? _waistbandOption;           // deprecated (하위 호환용)
  // 허리밴드 디자인 파일 업로드 (참고 이미지)
  String? _waistbandDesignBase64;     // 허리밴드 디자인 참고 이미지 base64
  // 팀로고/단체명 이미지 업로드
  String? _teamLogoBase64;            // 팀 로고/단체명 이미지 base64
  // 직접 주문(상품 없이) 시 사용자 커스텀 디자인 이미지 업로드
  String? _customDesignBase64;        // 사용자가 직접 업로드한 디자인 참고 이미지

  // ── 하의 참조 이미지 (남자/여자 각각) — Base64로 저장, SharedPreferences로 영구 유지 ──
  String? _maleRefBase64;
  String? _femaleRefBase64;

  static const _kMaleKey   = 'group_order_male_ref_base64';
  static const _kFemaleKey = 'group_order_female_ref_base64';

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

  // ── 인원별 사이즈 ──
  final List<_PersonEntry> _persons = [];

  // ── 수량(인원수) 다이얼 ──
  int _inputCount = 5; // 확정된 수량 (기본 5명으로 시작)
  int _dialCount = 5;  // 다이얼 UI에 표시 중인 수량 (미확정)

  bool get _countConfirmed => _inputCount >= 1;

  @override
  void initState() {
    super.initState();
    _loadSavedImages(); // SharedPreferences에서 저장된 이미지 불러오기
    // 초기 5명 persons 세팅 (화면 진입 즉시 폼 표시)
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

  void _confirmCount() {
    final n = _dialCount;
    if (n < 1) return;
    setState(() {
      _inputCount = n;
      // 인원수에 맞게 persons 조정
      // 늘어난 경우: 추가
      while (_persons.length < n) {
        _persons.add(_PersonEntry(index: _persons.length));
      }
      // 줄어든 경우: 제거
      while (_persons.length > n) {
        _persons.last.dispose();
        _persons.removeLast();
      }
      // index 재정렬
      for (int i = 0; i < _persons.length; i++) {
        _persons[i].index = i;
      }
    });
  }

  void _dialDecrement() {
    if (_dialCount > 1) setState(() => _dialCount--);
  }

  void _dialIncrement() {
    if (_dialCount < 200) setState(() => _dialCount++);
  }

  void _addPerson() {
    setState(() {
      _persons.add(_PersonEntry(index: _persons.length));
      _inputCount = _persons.length;
      _dialCount = _inputCount;
    });
  }

  void _removePerson(int index) {
    if (_persons.length > 1) {
      setState(() {
        _persons[index].dispose();
        _persons.removeAt(index);
        for (int i = 0; i < _persons.length; i++) {
          _persons[i].index = i;
        }
        _inputCount = _persons.length;
        _dialCount = _inputCount;
      });
    }
  }

  int get _totalCount => _persons.length;
  // 추가제작 모드: 1장부터 모든 옵션 활성화
  bool get _isAdditional => widget.isAdditionalOrder;
  /// 옵션1~3: 5장 이상 (추가제작은 1장부터)
  bool get _canUsePrintType1 => _isAdditional ? _totalCount >= 1 : _totalCount >= 5;
  /// 옵션4: 10장 이상 (추가제작은 1장부터)
  bool get _canUsePrintType2 => _isAdditional ? _totalCount >= 1 : _totalCount >= 10;
  bool get _nameEnabled => _isAdditional ? _totalCount >= 1 : _totalCount >= 10;
  bool get _measureEnabled => _isAdditional ? _totalCount >= 1 : _totalCount >= 5;

  // 현재 선택된 옵션 기반 파생 속성
  /// 색상 변경 포함 여부 (옵션1, 3, 4)
  bool get _hasColorChange => _printType == 0 || _printType == 2 || _printType == 3;
  /// 단체명 변경 포함 여부 (옵션2, 3, 4)
  bool get _hasTeamName => _printType == 1 || _printType == 2 || _printType == 3;
  /// 이름 변경 포함 여부 (옵션4만)
  bool get _hasNameChange => _printType == 3;

  // 수량 할인 제거 - 항상 0
  double get _discountRate => 0.0;

  String _discountLabel([BuildContext? ctx]) => '';

  int get _waistbandExtra {
    // 중복선택 가능 - 각 옵션별 가격 합산
    int total = 0;
    if (_waistbandName) total += AppConstants.waistbandNamePrice;
    if (_waistbandColor) total += AppConstants.waistbandColorPrice;
    return total;
  }
  int get _fabricExtra => AppConstants.fabricTypePrices[_fabricType] ?? 0;

  String _fmt(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  AppLocalizations _loc(BuildContext ctx) => ctx.read<LanguageProvider>().loc;

  @override
  Widget build(BuildContext context) {
    // PC 웹이면 PC 전용 2컬럼 레이아웃 사용
    if (isPcWeb(context)) return _buildPcLayout(context);

    // ── 모바일 레이아웃 ──
    final bodyContent = Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          children: [
            _buildHeaderBanner(),
            _buildCountInputSection(),
            // 항상 옵션 카드 표시 (5장 미만이면 비활성화 상태)
            _buildPrintTypeSection(),
            if (_countConfirmed) ...[
              _buildSelectedProductCard(),
              // 단체 정보 카드: 10인 이상 & 단체명 변경 옵션 선택 시
              if (_totalCount >= 10 && _hasTeamName) _buildGroupInfoCard(),
              _buildFabricTypeSection(),
              // 색상 섹션: 옵션1(색상만), 옵션3(단체명+색상), 옵션4(전체)에서만 표시
              if (_hasColorChange) _buildColorSection(),
              _buildWaistbandSection(),
              _buildLengthGuideSection(),
              _buildBottomRefImageSection(),
              // 팀로고/단체명 업로드 (인원별 사이즈 위)
              _buildTeamLogoUploadSection(),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.watch<LanguageProvider>().loc.groupFormTitle),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: bodyContent,
      bottomNavigationBar: _countConfirmed ? _buildSubmitBar() : null,
    );
  }

  // ── PC 전용 2컬럼 레이아웃 ──
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(context.watch<LanguageProvider>().loc.groupFormTitle),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 좌측: 주문서 입력 폼 ──
                  Expanded(
                    flex: 7,
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      child: Column(
                        children: [
                          _buildHeaderBanner(),
                          _buildCountInputSection(),
                          // 항상 옵션 카드 표시 (5장 미만이면 비활성화)
                          _buildPrintTypeSection(),
                          if (_countConfirmed) ...[
                            _buildSelectedProductCard(),
                            // 단체 정보 카드: 10인 이상 & 단체명 변경 옵션 선택 시
                            if (_totalCount >= 10 && _hasTeamName) _buildGroupInfoCard(),
                            _buildFabricTypeSection(),
                            if (_hasColorChange) _buildColorSection(),
                            _buildWaistbandSection(),
                            _buildLengthGuideSection(),
                            _buildBottomRefImageSection(),
                            // 팀로고/단체명 업로드 (인원별 사이즈 위)
                            _buildTeamLogoUploadSection(),
                            _buildPersonListSection(),
                            _buildBasicInfoSection(),
                            _buildMemoSection(),
                            _buildExclusiveDesignSection(),
                            const SizedBox(height: 80),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // ── 우측: 요약 + 제출 패널 ──
                  if (_countConfirmed)
                    SizedBox(
                      width: 320,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSummarySection(),
                          const SizedBox(height: 16),
                          _buildPcSubmitPanel(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── PC 전용 제출 패널 ──
  Widget _buildPcSubmitPanel() {
    final bool canSubmit = _isAdditional ? _totalCount >= 1 : _totalCount >= 5;
    final basePrice  = widget.product?.price ?? 0.0;
    final waistTotal = _waistbandExtra * _totalCount;
    final fabricTotal= _fabricExtra * _totalCount;
    final subtotal   = (basePrice * _totalCount) + waistTotal + fabricTotal;
    final total      = subtotal.toInt();
    // 5장 이상 무료배송
    final shipping   = _totalCount >= 5 ? 0 : 3000;
    final finalTotal = total + shipping;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 14, offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.watch<LanguageProvider>().loc.groupFormOrderSummary,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          if (_totalCount > 0) ...[
            _pcSummaryRow(loc.groupFormPeopleLabel, '$_totalCount${loc.groupFormPersonUnit2}'),
            if (widget.product != null)
              _pcSummaryRow(loc.groupFormUnitPrice, '${_fmt(widget.product!.price.toInt())}${loc.wonUnit2}'),
            if (_waistbandExtra > 0)
              _pcSummaryRow(loc.groupFormWaistbandExtra, '+${_fmt(_waistbandExtra.toInt())}${loc.wonUnit2}'),
            if (_fabricExtra > 0)
              _pcSummaryRow(loc.groupFormFabricExtra, '+${_fmt(_fabricExtra.toInt())}${loc.wonUnit2}'),
            const Divider(height: 20),
            _pcSummaryRow(loc.groupFormItemTotal, '${_fmt(subtotal.toInt())}${loc.wonUnit2}'),
            _pcSummaryRow(loc.groupFormShippingLabel, _totalCount >= 5 ? '🚚 무료배송 (5장 이상)' : '${_fmt(3000)}${loc.wonUnit2}'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.watch<LanguageProvider>().loc.groupFormFinalPriceLabel,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                Text('${_fmt(finalTotal)}${context.watch<LanguageProvider>().loc.wonUnit}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        color: Color(0xFF6A1B9A))),
              ],
            ),
            const SizedBox(height: 20),
          ],
          if (!canSubmit)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
              ),
              child: Text(
                _isAdditional ? context.watch<LanguageProvider>().loc.groupFormQtyInputFirst : context.watch<LanguageProvider>().loc.groupFormMin5Required,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                textAlign: TextAlign.center,
              ),
            ),
          if (widget.product != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canSubmit ? _addToCart : null,
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: Text(context.watch<LanguageProvider>().loc.groupFormCartBtn,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canSubmit ? _buyNow : null,
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(context.watch<LanguageProvider>().loc.groupFormBuyNowBtn,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          if (widget.product != null) const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: canSubmit ? _submitOrder : null,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                canSubmit
                    ? (_isAdditional ? loc.groupFormCheckAdditional : loc.groupFormCheckOrder)
                    : (_isAdditional ? loc.groupFormNeedQty : loc.groupFormNeedMin5),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit
                    ? const Color(0xFF4A148C)
                    : const Color(0xFFBBBBBB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pcSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  // ── 헤더 배너 ──
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF6A1B9A),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                _isAdditional ? loc.groupFormAdditionalOrder : loc.groupFormGroupOrder,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
              const Spacer(),
              if (widget.product != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.product!.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isAdditional
                ? loc.groupFormAdditionalPeriod
                : loc.groupFormPeriod,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
          ),
          if (!_isAdditional) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.design_services_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '⚠️ 주문확정은 디자인 확정 이후에 진행됩니다. 디자인 확인 후 최종 주문이 확정됩니다.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 수량 입력 섹션 (다이얼 버튼 방식) ──
  Widget _buildCountInputSection() {
    // 할인 단계별 색상/라벨 계산
    Color dialAccent() {
      if (_dialCount >= 50) return const Color(0xFF6A1B9A);
      if (_dialCount >= 30) return const Color(0xFFFF6B35);
      if (_dialCount >= 10) return const Color(0xFF2E7D32);
      if (_dialCount >= 5)  return const Color(0xFF1565C0);
      return const Color(0xFF888888);
    }
    String dialStatusBadge() {
      if (_dialCount >= 10) return context.watch<LanguageProvider>().loc.groupFormNamePrintBadge;
      if (_dialCount >= 5)  return context.watch<LanguageProvider>().loc.groupFormGroupMakeBadge;
      return _isAdditional ? '' : context.watch<LanguageProvider>().loc.groupFormBelow5Badge;
    }
    final accent = dialAccent();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: Color(0xFF6A1B9A), size: 20),
              const SizedBox(width: 8),
              Text(context.watch<LanguageProvider>().loc.groupFormQtyLabel,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(context.watch<LanguageProvider>().loc.groupFormRequired,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(context.watch<LanguageProvider>().loc.groupFormQtyHint,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 18),

          // ── 다이얼 컨트롤 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── 감소 버튼 ──
                    _DialButton(
                      icon: Icons.remove_rounded,
                      color: accent,
                      enabled: _dialCount > 1,
                      onTap: _dialDecrement,
                      onLongPress: () {
                        // 길게 누르면 5씩 감소
                        final next = (_dialCount - 5).clamp(1, 200);
                        setState(() => _dialCount = next);
                      },
                    ),
                    const SizedBox(width: 24),

                    // ── 수량 표시 ──
                    Column(
                      children: [
                        Text(
                          '$_dialCount',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: accent,
                            height: 1.0,
                          ),
                        ),
                        Text(context.watch<LanguageProvider>().loc.countPersonUnit,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: accent.withValues(alpha: 0.7))),
                      ],
                    ),
                    const SizedBox(width: 24),

                    // ── 증가 버튼 ──
                    _DialButton(
                      icon: Icons.add_rounded,
                      color: accent,
                      enabled: _dialCount < 200,
                      onTap: _dialIncrement,
                      onLongPress: () {
                        // 길게 누르면 5씩 증가
                        final next = (_dialCount + 5).clamp(1, 200);
                        setState(() => _dialCount = next);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 단계 배지 ──
                if (dialStatusBadge().isNotEmpty)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dialStatusBadge(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 빠른 수량 선택 칩 ──
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [5, 10, 15, 20, 30, 50].map((n) {
              final selected = _dialCount == n;
              return GestureDetector(
                onTap: () => setState(() => _dialCount = n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.white,
                    border: Border.all(
                        color: selected ? accent : const Color(0xFFDDDDDD)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$n${loc.groupFormPersonUnit2}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── 확인 버튼 ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (!_isAdditional && _dialCount < 1)
                  ? null
                  : _confirmCount,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                _countConfirmed && _totalCount == _dialCount
                    ? '$_dialCount${context.watch<LanguageProvider>().loc.groupFormPersonUnit} ${context.watch<LanguageProvider>().loc.groupFormConfirmedSuffix}'
                    : '$_dialCount${context.watch<LanguageProvider>().loc.groupFormPersonUnit}${context.watch<LanguageProvider>().loc.groupFormConfirmSuffix}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),

          // ── 확정 후 상태 표시 ──
          if (_countConfirmed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF6A1B9A), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isAdditional
                        ? '$_totalCount${loc.groupFormPersonUnit2} · ${loc.homeGroupOnly}'
                        : '$_totalCount${context.watch<LanguageProvider>().loc.groupFormPersonUnit} · 단체커스텀',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6A1B9A)),
                  ),
                  const Spacer(),
                  if (_measureEnabled) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isAdditional ? loc.groupFormActualMeasure : loc.groupFormActualActive,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    ),
                  ],
                  if (_nameEnabled) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isAdditional ? loc.nameAvailableLabel : loc.nameEnabledLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountHintCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.2),
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(_isAdditional ? Icons.add_circle_outline_rounded : Icons.groups_rounded,
              size: 48, color: const Color(0xFF6A1B9A)),
          const SizedBox(height: 14),
          Text(
            _isAdditional ? loc.enterQtyFirstMsg : loc.enterPersonCountFirst,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6A1B9A))),
          const SizedBox(height: 8),
          Text(
            _isAdditional
                ? '1장부터 입력 가능합니다.\n수량 입력 후 모든 옵션(인쇄 타입·컬러·이름 등)을 선택할 수 있습니다.'
                : loc.allOptionsOrderMsg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 16),
          if (_isAdditional)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _hintBadge(Icons.looks_one_rounded, '1장부터 가능', const Color(0xFF795548)),
                const SizedBox(width: 10),
                _hintBadge(Icons.palette_rounded, loc.allOptionsSelectedBadge, const Color(0xFF6A1B9A)),
                const SizedBox(width: 10),
                _hintBadge(Icons.schedule_rounded, '1주일 이내', const Color(0xFF2E7D32)),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _hintBadge(Icons.format_paint_rounded, '5인↑ 실측 입력', const Color(0xFF2E7D32)),
                const SizedBox(width: 10),
                _hintBadge(Icons.person_rounded, '10인↑ 이름 입력', const Color(0xFF1565C0)),
                const SizedBox(width: 10),
                _hintBadge(Icons.local_shipping_rounded, '5장↑ 무료배송', const Color(0xFF00838F)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _hintBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── 인쇄 타입 ──
  // ── 선택 상품 디자인 미리보기 카드 ──
  Widget _buildSelectedProductCard() {
    final product = widget.product;
    // product가 없으면 디자인 업로드 카드 표시 (사이드바에서 직접 접근한 경우)
    if (product == null) return _buildCustomDesignUploadCard();

    final images = product.images;
    final hasImages = images.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🎨 ${loc.groupFormProductLabel}'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 썸네일 (여러 장 가로 스크롤)
              if (hasImages)
                SizedBox(
                  height: 110,
                  width: images.length == 1 ? 110 : 200,
                  child: images.length == 1
                      ? _productThumb(images[0], 110)
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length > 4 ? 4 : images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => _productThumb(images[i], 94),
                        ),
                )
              else
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_not_supported_rounded,
                      size: 36, color: Color(0xFF6A1B9A)),
                ),

              const SizedBox(width: 14),

              // 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.localizedName(_lang),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (product.category.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category +
                              (product.subCategory.isNotEmpty ? ' · ${product.subCategory}' : ''),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6A1B9A),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(context.watch<LanguageProvider>().loc.basePriceLabel,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                        const SizedBox(width: 4),
                        Text(
                          '${_fmt(product.price.toInt())}원',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900,
                              color: Color(0xFF6A1B9A)),
                        ),
                      ],
                    ),
                    if (product.material.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(product.material,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF888888)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productThumb(String url, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.startsWith('http')
          ? Image.network(
              url,
              width: size, height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size, height: size,
                color: const Color(0xFFF3E5F5),
                child: const Icon(Icons.broken_image_rounded,
                    color: Color(0xFF6A1B9A), size: 28),
              ),
            )
          : Container(
              width: size, height: size,
              color: const Color(0xFFF3E5F5),
              child: const Icon(Icons.image_rounded,
                  color: Color(0xFF6A1B9A), size: 28),
            ),
    );
  }

  Widget _buildPrintTypeSection() {
    // ─────────────────────────────────────────────────────────
    // 4가지 커스텀 옵션 정의
    //   0: 색상변경 (단체명 변경안함)          → 5장↑ 무료
    //   1: 단체명변경(전면) (색상변경안함)      → 5장↑ 무료
    //   2: 단체명변경(전면) + 색상변경          → 5장↑ 무료
    //   3: 단체명변경(전면)+색상변경+이름변경(후면) → 10장↑
    // ─────────────────────────────────────────────────────────
    final freeMin = _isAdditional ? '1장 이상' : '5장 이상 무료';
    final nameMin = _isAdditional ? '1장 이상' : '10장 이상';

    final types = [
      {
        'label': loc.printType1Label,
        'cond': freeMin,
        'desc': loc.printType3Desc,    // "상의·하의 동일 색상으로 변경"
        'enabled': _canUsePrintType1,
        'free': true,
        'color': const Color(0xFF1565C0),
        'icon': Icons.palette_outlined,
      },
      {
        'label': loc.printType2Label,
        'cond': freeMin,
        'desc': '',
        'enabled': _canUsePrintType1,
        'free': true,
        'color': const Color(0xFF2E7D32),
        'icon': Icons.text_fields_rounded,
      },
      {
        'label': loc.printType3Label,
        'cond': freeMin,
        'desc': loc.printType3Desc,
        'enabled': _canUsePrintType1,
        'free': true,
        'color': const Color(0xFF6A1B9A),
        'icon': Icons.auto_awesome_rounded,
      },
      {
        'label': loc.printType4Label,
        'cond': nameMin,
        'desc': loc.printType4Desc,
        'enabled': _canUsePrintType2,
        'free': false,
        'color': const Color(0xFFC62828),
        'icon': Icons.badge_outlined,
      },
    ];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🎨 커스텀 옵션 선택', required: true),
          const SizedBox(height: 4),
          // 인원수 / 할인율 표시
          Row(
            children: [
              Text(
                '현재 $_totalCount${loc.groupFormPersonUnit}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 5장 미만 안내
          if (!_canUsePrintType1 && !_isAdditional)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF7A5000)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      '5장 이상부터 커스텀 옵션을 선택할 수 있습니다',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7A5000)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          // 옵션 카드 목록
          ...types.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            final isEnabled = t['enabled'] as bool;
            final isSelected = _printType == i;
            final color = t['color'] as Color;
            final isFree = t['free'] as bool;

            return GestureDetector(
              onTap: isEnabled
                  ? () => setState(() {
                        _printType = i;
                        // 옵션1 (색상변경만): 하의도 동일 색상 연동 활성화
                        // 옵션2 (단체명만): 색상변경 없으므로 하의 별도색 비활성화
                        if (i == 1) {
                          _useSeparateBottomColor = false;
                        }
                      })
                  : () {
                      final msg = _isAdditional
                          ? loc.qtyRequiredToSelect
                          : i == 3
                              ? '10장 이상부터 선택 가능합니다'
                              : '5장 이상부터 선택 가능합니다';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.07)
                      : isEnabled
                          ? const Color(0xFFF7F8FA)
                          : const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : isEnabled
                            ? AppColors.border
                            : const Color(0xFFDDDDDD),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 선택 원형 체크
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? color : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? color : const Color(0xFFCCCCCC),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // 레이블 + 설명
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isEnabled
                                  ? (isSelected ? color : const Color(0xFF222222))
                                  : const Color(0xFFAAAAAA),
                            ),
                          ),
                          if ((t['desc'] as String).isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              t['desc'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isEnabled
                                    ? color.withValues(alpha: 0.75)
                                    : const Color(0xFFBBBBBB),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 조건 배지 + 무료 배지
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? color.withValues(alpha: 0.12)
                                : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t['cond'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isEnabled ? color : const Color(0xFFAAAAAA),
                            ),
                          ),
                        ),
                        if (isFree) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 단체 주문 정보 카드 (10인 이상 활성화) ──
  Widget _buildGroupInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.watch<LanguageProvider>().loc.groupFormOrderInfoTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(context.watch<LanguageProvider>().loc.groupForm10Plus, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            loc.summaryInputPrompt,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // 10인 이상: 단체명 정보
          _buildInfoRow(Icons.groups_rounded, loc.teamNameLabel, _teamNameCtrl.text.isEmpty ? loc.enterInBasicSection : _teamNameCtrl.text, const Color(0xFF6A1B9A)),
          const SizedBox(height: 8),

          // 컬러 정보 (색상 변경 옵션 선택 시에만 표시)
          if (_hasColorChange) ...[
            _buildInfoRow(Icons.palette_rounded, loc.mainColorSummary, _mainColorName ?? loc.selectInColorSection, const Color(0xFF1565C0), colorSwatch: _mainColor),
            const SizedBox(height: 8),
          ],

          // 이름 안내 (이름 변경 옵션 선택 시에만 표시)
          if (_hasNameChange)
            _buildInfoRow(Icons.badge_rounded, loc.personalNameLabel, loc.enterInPersonSection, const Color(0xFF2E7D32)),

          // 단체 주문 안내
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, {Color? colorSwatch}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        if (colorSwatch != null) ...[
          Container(width: 14, height: 14, decoration: BoxDecoration(color: colorSwatch, shape: BoxShape.circle, border: Border.all(color: Colors.black12))),
          const SizedBox(width: 4),
        ],
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: value.contains('섹션') ? AppColors.textSecondary : const Color(0xFF1A1A1A)))),
      ],
    );
  }

  Widget _buildDiscountInfoItem(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF888888))),
          const SizedBox(height: 2),
          if (color != null) ...[
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black12))),
            const SizedBox(height: 2),
          ],
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF333333)), textAlign: TextAlign.center, softWrap: true),
        ],
      ),
    );
  }

  // ── 색상 선택 ──
  // ── 색상 선택 (상세페이지와 동일 스타일) ──
  Widget _buildColorSection() {
    final isSingletSet = widget.product != null &&
        ((widget.product!.category == '세트' &&
                widget.product!.subCategory.contains('싱글렛세트')) ||
            widget.product!.category.contains('싱글렛세트') ||
            widget.product!.subCategory.contains('싱글렛세트'));

    const palette = AppColorPalette.registeredColors;
    final freeColors = AppConstants.freeColors;

    // HEX 코드를 복사하는 함수
    void copyHexToClipboard(String hex) {
      Clipboard.setData(ClipboardData(text: hex));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('색상 코드 $hex 복사되었습니다'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF333333),
        ),
      );
    }

    Widget colorGrid(
      String? selectedName,
      Color? selectedColor,
      void Function(String name, Color color) onTap,
    ) {
      // 현재 포켬릿에서 선택된 색상의 HEX 값
      String? selectedHex;
      if (selectedColor != null) {
        final r = (selectedColor.r * 255).round();
        final g = (selectedColor.g * 255).round();
        final b = (selectedColor.b * 255).round();
        selectedHex = '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}${g.toRadixString(16).padLeft(2, '0').toUpperCase()}${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택된 색상 표시 + HEX 코드
          if (selectedName != null && selectedColor != null) ...[
            Builder(builder: (_) {
              final found = palette.firstWhere(
                (c) => c['name'] == selectedName,
                orElse: () => <String, dynamic>{},
              );
              final isFree = found.isNotEmpty ? freeColors.contains(selectedName) : true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selectedColor.withValues(alpha: 0.3), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(selectedName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          GestureDetector(
                            onTap: selectedHex != null ? () => copyHexToClipboard(selectedHex!) : null,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    selectedHex ?? '',
                                    style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: Colors.white, letterSpacing: 1,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF888888)),
                                const SizedBox(width: 3),
                                const Text('탭하여 복사',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFree ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isFree ? '기본 색상' : '+20,000원',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isFree ? const Color(0xFF2E7D32) : const Color(0xFFCC0000),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // 색상 팔레트 그리드
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: palette.map((c) {
              final name = c['name'] as String;
              final hex  = c['hex'] as int;
              final code = c['code'] as String;
              final sel  = selectedName == name;
              final isFree = freeColors.contains(name);
              // HEX 문자열
              final hexColor = Color(hex);
              final hr = (hexColor.r * 255).round();
              final hg = (hexColor.g * 255).round();
              final hb = (hexColor.b * 255).round();
              final hexStr = '#${hr.toRadixString(16).padLeft(2, '0').toUpperCase()}${hg.toRadixString(16).padLeft(2, '0').toUpperCase()}${hb.toRadixString(16).padLeft(2, '0').toUpperCase()}';
              return GestureDetector(
                onTap: () => onTap(name, Color(hex)),
                onLongPress: () => copyHexToClipboard(hexStr),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RibColorSwatch(
                      color: Color(hex),
                      size: 40,
                      isSelected: sel,
                      accentColor: const Color(0xFF6A1B9A),
                      isLight: Color(hex).computeLuminance() > 0.5,
                      child: sel
                          ? Icon(Icons.check_rounded,
                              size: 18,
                              color: Color(hex).computeLuminance() > 0.5
                                  ? const Color(0xFF333333)
                                  : Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w400,
                        color: sel ? const Color(0xFF6A1B9A) : const Color(0xFF666666),
                      ),
                    ),
                    if (!isFree)
                      const Text('+₩',
                          style: TextStyle(fontSize: 8, color: Color(0xFFCC0000))),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // HEX 직접 입력 버튼
          _buildHexColorInput(selectedHex, (hexCode) {
            // HEX 코드를 파싱하여 색상 선택
            try {
              final cleaned = hexCode.replaceAll('#', '');
              if (cleaned.length == 6) {
                final colorVal = int.parse('FF$cleaned', radix: 16);
                final color = Color(colorVal);
                onTap('HEX: $hexCode', color);
              }
            } catch (_) {}
          }),
          const SizedBox(height: 4),
          Text(loc.productColorExtraFull,
              style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🎨 ${loc.colorSelect}', required: true),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
            ),
            child: Text(loc.productColorExtraNote,
                style: const TextStyle(fontSize: 10, color: Color(0xFFE65100), fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 14),

          // 옵션①·③ 선택 시: 상의·하의 동일 색상 변경 안내
          if (_printType == 0 || _printType == 2 || _printType == 3) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '상의와 하의가 동일한 색상으로 변경됩니다',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 싱글렛세트: 상·하의 색상 분리 옵션
          if (isSingletSet) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.palette_rounded, size: 16, color: Color(0xFF6A1B9A)),
                    const SizedBox(width: 6),
                    Text(context.watch<LanguageProvider>().loc.groupFormSingletColorTitle,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF6A1B9A))),
                  ]),
                  const SizedBox(height: 8),
                  Text(context.watch<LanguageProvider>().loc.groupFormSingletColorDesc,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() {
                      _useSeparateBottomColor = !_useSeparateBottomColor;
                      if (!_useSeparateBottomColor) {
                        _bottomColorName = null;
                        _bottomColor = null;
                      }
                    }),
                    child: Row(children: [
                      Checkbox(
                        value: _useSeparateBottomColor,
                        onChanged: (v) => setState(() {
                          _useSeparateBottomColor = v ?? false;
                          if (!_useSeparateBottomColor) {
                            _bottomColorName = null;
                            _bottomColor = null;
                          }
                        }),
                        activeColor: const Color(0xFF6A1B9A),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(context.watch<LanguageProvider>().loc.groupFormColorSplitLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(context.watch<LanguageProvider>().loc.groupFormPhantomChart,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 메인 컬러 (상의 or 전체)
          Text(
            isSingletSet
                ? (_useSeparateBottomColor ? loc.topColorLabel : loc.fullColorLabel)
                : loc.mainColorLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          colorGrid(_mainColorName, _mainColor, (name, color) {
            setState(() { _mainColorName = name; _mainColor = color; });
          }),

          // 싱글렛세트: 하의 색상 분리
          if (isSingletSet && _useSeparateBottomColor) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(loc.bottomAutoLengthNotice,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6A1B9A))),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(context.watch<LanguageProvider>().loc.groupFormBottomColorLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            colorGrid(_bottomColorName, _bottomColor, (name, color) {
              setState(() { _bottomColorName = name; _bottomColor = color; });
            }),
            const SizedBox(height: 10),
            if (_mainColorName != null || _bottomColorName != null)
              _buildSingletSetColorPreview(),
          ],
        ],
      ),
    );
  }


  // ── HEX 색상 직접 입력 위젯 ──
  Widget _buildHexColorInput(String? currentHex, void Function(String hex) onApply) {
    final ctrl = TextEditingController(text: currentHex ?? '');
    bool isValid = false;
    Color? previewColor;

    return StatefulBuilder(builder: (context, setLocal) {
      void validate(String val) {
        final cleaned = val.replaceAll('#', '').trim();
        final valid = cleaned.length == 6 &&
            RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(cleaned);
        Color? color;
        if (valid) {
          try {
            color = Color(int.parse('FF$cleaned', radix: 16));
          } catch (_) {}
        }
        setLocal(() { isValid = valid; previewColor = color; });
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tag_rounded, size: 14, color: Color(0xFF555555)),
                const SizedBox(width: 6),
                const Text('HEX 색상 직접 입력',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
                const SizedBox(width: 6),
                const Text('(예: #FF3366)',
                    style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // 미리보기 색상 박스
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: previewColor ?? const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: previewColor == null
                      ? const Icon(Icons.palette_outlined, size: 18, color: Color(0xFFCCCCCC))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: validate,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        letterSpacing: 1.5, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: '#RRGGBB',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Color(0xFFCCCCCC),
                          fontWeight: FontWeight.normal),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: isValid
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFDDDDDD))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF6A1B9A), width: 1.5)),
                      isDense: true,
                      prefixText: ctrl.text.isNotEmpty && !ctrl.text.startsWith('#') ? '#' : null,
                      suffixIcon: isValid
                          ? const Icon(Icons.check_circle_rounded,
                              size: 16, color: Color(0xFF2E7D32))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  child: ElevatedButton(
                    onPressed: isValid
                        ? () {
                            final cleaned = ctrl.text.replaceAll('#', '').trim().toUpperCase();
                            onApply('#$cleaned');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFDDDDDD),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('적용',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── 싱글렛세트 색상 팬텀차트 미리보기 ──
  Widget _buildSingletSetColorPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 14, color: Color(0xFF6A1B9A)),
              const SizedBox(width: 6),
              Text(context.watch<LanguageProvider>().loc.groupFormPhantomChartPreview,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6A1B9A))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _colorPreviewItem(
                  loc.topLabel,
                  _mainColorName,
                  _mainColor,
                  Icons.accessibility_new_rounded,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.add_rounded, size: 18, color: Color(0xFF888888)),
              const SizedBox(width: 10),
              Expanded(
                child: _colorPreviewItem(
                  loc.bottomLabel,
                  _bottomColorName ?? _mainColorName,
                  _bottomColor ?? _mainColor,
                  Icons.airline_seat_legroom_normal_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.phantomChartNotice,
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _colorPreviewItem(String label, String? colorName, Color? color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color != null ? color.withValues(alpha: 0.4) : const Color(0xFFE0E0E0),
          width: color != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color ?? const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
            child: Icon(icon, size: 18,
                color: color != null
                    ? (color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
                    : const Color(0xFFCCCCCC)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
          Text(
            colorName ?? loc.notSelectedLabel,
            style: TextStyle(
              fontSize: 10,
              color: colorName != null ? const Color(0xFF333333) : const Color(0xFFBBBBBB),
              fontWeight: colorName != null ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  // ── 허리밴드 ──
  // ── 원단 소재 + 무게 선택 ──
  Widget _buildFabricTypeSection() {
    // 기성품 여부: product가 있고 isGroupOnly가 false이면 기성품
    final isReadyMade = widget.product != null && !widget.product!.isGroupOnly;
    // 기성품이면 일반(봉제)으로 고정
    if (isReadyMade && _fabricType != '일반 (봉제)') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _fabricType = '일반 (봉제)');
      });
    }
    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(loc.fabricSelectTitle),
          const SizedBox(height: 4),
          Text(context.watch<LanguageProvider>().loc.groupFormFabricCostNote,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),

          // ── 소재 선택 (심리스/일반) ──
          if (isReadyMade) ...[
            // 기성품: 일반(봉제) 고정 + 안내 메시지
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.readyMadeFabricNote,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 배송 안내
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF558B2F).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFF558B2F)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🚚 단체커스텀 배송안내: 5장 이상 무료배송',
                      style: TextStyle(fontSize: 12, color: Color(0xFF558B2F), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ] else
          Row(
            children: AppConstants.fabricTypes.map((type) {
              final isSelected = _fabricType == type;
              final isSeamless = type.contains('심리스');
              final accentColor = isSeamless ? const Color(0xFF6A1B9A) : const Color(0xFF1565C0);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _fabricType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: isSeamless ? 0 : 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.07)
                          : const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? accentColor : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? accentColor : const Color(0xFFCCCCCC),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? accentColor : const Color(0xFF333333),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 가격 표시: 일반=기본 70,000원 / 심리스=+10,000원 추가
                        if (isSeamless) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A1B9A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '+10,000원 추가',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(context.watch<LanguageProvider>().loc.groupFormSkinFriction,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              loc.basePrice,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? const Color(0xFF1565C0) : const Color(0xFF555555),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(context.watch<LanguageProvider>().loc.groupFormNormalStitch,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // ── 무게 선택 (80g / 90g) ──
          _sectionHeader(loc.weightSelectionHeader),
          const SizedBox(height: 4),
          Text(context.watch<LanguageProvider>().loc.groupFormFabricWeightNote,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: AppConstants.fabricWeights.map((w) {
              final isSelected = _fabricWeight == w;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _fabricWeight = w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: w == '80g' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1565C0).withValues(alpha: 0.07)
                          : const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1565C0) : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1565C0) : const Color(0xFFCCCCCC),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              w,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? const Color(0xFF1565C0) : const Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          w == '80g' ? loc.weight80gDesc : loc.weight90gDesc,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),
          if (!isReadyMade)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.seamlessNotice,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6A1B9A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 허리밴드 옵션 (선택사항, 중복선택 가능) ──
  Widget _buildWaistbandSection() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목: 허리밴드 (선택사항 표시)
          Row(
            children: [
              _sectionHeader('👖 허리밴드'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                ),
                child: const Text('선택사항', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                ),
                child: const Text('중복선택가능', style: TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '허리밴드에 원하는 문구 또는 무늬를 디자인합니다. 참고이미지를 업로드해 주세요. (선택하지 않아도 됩니다)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // ══ 1) 허리밴드 변경 여부 체크박스 ══
          GestureDetector(
            onTap: () => setState(() {
              _addWaistbandDesign = !_addWaistbandDesign;
              if (!_addWaistbandDesign) {
                _waistbandName = false;
                _waistbandColor = false;
                _waistbandColorName = null;
                _waistbandColor = false;
                _waistbandDesignBase64 = null;
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _addWaistbandDesign
                    ? const Color(0xFF6A1B9A).withValues(alpha: 0.07)
                    : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _addWaistbandDesign ? const Color(0xFF6A1B9A) : AppColors.border,
                  width: _addWaistbandDesign ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _addWaistbandDesign ? const Color(0xFF6A1B9A) : Colors.transparent,
                      border: Border.all(
                        color: _addWaistbandDesign ? const Color(0xFF6A1B9A) : const Color(0xFFCCCCCC),
                        width: 2,
                      ),
                    ),
                    child: _addWaistbandDesign
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('허리밴드 디자인 추가',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                        Text('원하는 문구/무늬를 허리밴드에 추가 (선택사항)',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _addWaistbandDesign
                          ? const Color(0xFF6A1B9A)
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _addWaistbandDesign ? '선택됨' : '선택 안함',
                      style: TextStyle(
                        color: _addWaistbandDesign ? Colors.white : const Color(0xFF888888),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ══ 2) 체크 시 옵션 펼치기 (중복선택 가능) ══
          if (_addWaistbandDesign) ...[
            const SizedBox(height: 16),
            const Text('변경 옵션 선택 (중복선택 가능)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 10),

            // 단체명 변경 옵션 (체크박스 스타일)
            _buildWaistbandCheckTile(
              isChecked: _waistbandName,
              icon: Icons.title_rounded,
              title: '단체명 변경',
              desc: '허리밴드에 단체명/팀명 인쇄',
              price: AppConstants.waistbandNamePrice,
              badgeColor: const Color(0xFF1565C0),
              onToggle: () => setState(() => _waistbandName = !_waistbandName),
            ),
            const SizedBox(height: 8),
            // 색상 변경 옵션 (체크박스 스타일)
            _buildWaistbandCheckTile(
              isChecked: _waistbandColor,
              icon: Icons.palette_rounded,
              title: '색상 변경',
              desc: '허리밴드 색상 변경',
              price: AppConstants.waistbandColorPrice,
              badgeColor: const Color(0xFFFF6B35),
              onToggle: () => setState(() {
                _waistbandColor = !_waistbandColor;
                if (!_waistbandColor) {
                  _waistbandColorName = null;
                }
              }),
            ),

            // 색상 선택기 (색상 변경 선택 시 표시)
            if (_waistbandColor) ...[
              const SizedBox(height: 14),
              ColorSelectButton(
                label: context.watch<LanguageProvider>().loc.groupFormWaistbandColorLabel,
                selectedColorName: _waistbandColorName,
                selectedColor: _waistbandColorName != null ? null : null,
                accentColor: const Color(0xFF6A1B9A),
                onColorSelected: (name, color) {
                  setState(() {
                    _waistbandColorName = name;
                  });
                },
              ),
            ],

            const SizedBox(height: 16),
            // 허리밴드 디자인 참고이미지 업로드
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.upload_file_rounded, size: 16, color: Color(0xFF6A1B9A)),
                      SizedBox(width: 8),
                      Text('허리밴드 디자인 참고이미지',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF6A1B9A))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '원하는 문구 또는 무늬의 참고이미지를 업로드해 주세요\n(AI, PDF, JPG 파일 업로드 가능)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6A1B9A), height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  if (_waistbandDesignBase64 != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            Uri.parse(_waistbandDesignBase64!).data?.contentAsBytes() ??
                                Uri.dataFromString('').data!.contentAsBytes(),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: const Color(0xFFE8D5F5),
                              child: const Center(child: Icon(Icons.file_present_rounded, size: 48, color: Color(0xFF6A1B9A))),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6, right: 6,
                          child: GestureDetector(
                            onTap: () => setState(() => _waistbandDesignBase64 = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickWaistbandDesignImage(),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: Text(_waistbandDesignBase64 != null ? '이미지 변경' : '이미지/파일 선택'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6A1B9A),
                        side: const BorderSide(color: Color(0xFF6A1B9A)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_waistbandExtra > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined, size: 16, color: Color(0xFF7A5000)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '+${_fmt(_waistbandExtra)}원 × $_totalCount명 = +${_fmt(_waistbandExtra * _totalCount)}원 추가',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7A5000)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── 허리밴드 디자인 이미지 선택 ──
  Future<void> _pickWaistbandDesignImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      String mime = 'image/jpeg';
      if (bytes.length >= 4) {
        if (bytes[0] == 0x89 && bytes[1] == 0x50) mime = 'image/png';
        else if (bytes[0] == 0xFF && bytes[1] == 0xD8) mime = 'image/jpeg';
      }
      final base64Str = 'data:$mime;base64,${base64Encode(bytes)}';
      setState(() => _waistbandDesignBase64 = base64Str);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 오류: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── 허리밴드 체크박스 스타일 타일 ──
  Widget _buildWaistbandCheckTile({
    required bool isChecked,
    required IconData icon,
    required String title,
    required String desc,
    required int price,
    required Color badgeColor,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isChecked ? badgeColor.withValues(alpha: 0.07) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isChecked ? badgeColor : AppColors.border, width: isChecked ? 2 : 1),
        ),
        child: Row(
          children: [
            // 체크박스 (사각형 - 중복선택 표시)
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isChecked ? badgeColor : Colors.transparent,
                border: Border.all(color: isChecked ? badgeColor : const Color(0xFFCCCCCC), width: 2),
              ),
              child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: isChecked ? badgeColor : const Color(0xFF888888)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: isChecked ? badgeColor : const Color(0xFF1A1A1A))),
                  Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
              child: Text('+${_fmt(price)}원',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  // ── 직접 주문(상품 없이) 시 디자인 이미지 업로드 카드 ──
  Widget _buildCustomDesignUploadCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🎨 디자인 이미지'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 15, color: Color(0xFF2E7D32)),
                    SizedBox(width: 6),
                    Text('디자인 이미지 업로드 안내',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                  ],
                ),
                SizedBox(height: 6),
                Text('• 원하는 디자인 이미지를 인터넷, 유튜브 등에서 캡처하여 업로드하세요.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.6)),
                Text('• 업로드한 이미지를 참고하여 디자인에 반영합니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.6)),
                Text('• AI, PDF, JPG 파일 모두 지원합니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_customDesignBase64 != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    Uri.parse(_customDesignBase64!).data?.contentAsBytes() ??
                        Uri.dataFromString('').data!.contentAsBytes(),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.file_present_rounded, size: 52, color: Color(0xFF2E7D32)),
                            SizedBox(height: 8),
                            Text('디자인 파일 업로드 완료',
                                style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _customDesignBase64 = null),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickCustomDesignImage(),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(_customDesignBase64 != null ? '이미지 변경' : '디자인 이미지/파일 선택'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (_customDesignBase64 != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Text('디자인 이미지가 업로드되었습니다',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickCustomDesignImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final mime = picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final base64Str = 'data:$mime;base64,${base64Encode(bytes)}';
      setState(() => _customDesignBase64 = base64Str);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── 팀 로고/단체명 이미지 업로드 섹션 (인원별 사이즈 위) ──
  Widget _buildTeamLogoUploadSection() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader('🏷️ 단체명, 로고'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF888888).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('선택사항', style: TextStyle(fontSize: 10, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '팀 로고 또는 단체명 개인 디자인이 있을 경우 이미지/파일을 업로드해 주세요\n(AI, PDF, JPG 파일 지원)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          if (_teamLogoBase64 != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    Uri.parse(_teamLogoBase64!).data?.contentAsBytes() ??
                        Uri.dataFromString('').data!.contentAsBytes(),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.file_present_rounded, size: 48, color: Color(0xFF6A1B9A)),
                            SizedBox(height: 8),
                            Text('파일 업로드 완료', style: TextStyle(fontSize: 12, color: Color(0xFF6A1B9A), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _teamLogoBase64 = null),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickTeamLogoImage(),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(_teamLogoBase64 != null ? '파일 변경' : '단체명, 로고 파일/이미지 선택'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6A1B9A),
                side: const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (_teamLogoBase64 != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D32)),
                  SizedBox(width: 6),
                  Text('단체명/로고 파일이 업로드되었습니다', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 팀 로고 이미지 선택 ──
  Future<void> _pickTeamLogoImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      String mime = 'image/jpeg';
      if (bytes.length >= 4) {
        if (bytes[0] == 0x89 && bytes[1] == 0x50) mime = 'image/png';
        else if (bytes[0] == 0xFF && bytes[1] == 0xD8) mime = 'image/jpeg';
        else if (bytes[0] == 0x25 && bytes[1] == 0x50) mime = 'application/pdf';
      }
      final base64Str = 'data:$mime;base64,${base64Encode(bytes)}';
      setState(() => _teamLogoBase64 = base64Str);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 선택 오류: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── 인원별 사이즈 ──
  Widget _buildPersonListSection() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 사이즈표 ──
          _buildSizeChart(),
          const SizedBox(height: 20),
          // ── 헤더 ──
          Row(
            children: [
              _sectionHeader('👤 ${loc.personInfoTitle}', required: true),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loc.totalPersonCount(_totalCount),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── 활성화 배지 ──
          Row(
            children: [
              _statusBadge(
                  '이름 입력',
                  _nameEnabled && _hasNameChange,
                  _isAdditional ? '1장 이상' : '10장+옵션④',
                  const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              // 사이즈 필수 안내 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF6D00).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.straighten_rounded, size: 11, color: Color(0xFFFF6D00)),
                    SizedBox(width: 4),
                    Text('사이즈 모두 필수', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFF6D00))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── 인원 카드 목록 ──
          ...(_persons.asMap().entries.map((e) {
            return _PersonRow(
              key: ValueKey(e.key),
              entry: e.value,
              index: e.key,
              nameEnabled: _nameEnabled && _hasNameChange,
              measureEnabled: _measureEnabled,
              onRemove: _persons.length > 1
                  ? () => _removePerson(e.key)
                  : null,
              sizes: [...AppConstants.adultSizes, ...AppConstants.juniorSizes],
            );
          }).toList()),
          const SizedBox(height: 12),
          // ── 인원 추가 버튼 ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addPerson,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text(context.watch<LanguageProvider>().loc.groupFormAddPerson,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6A1B9A),
                side: const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
      String label, bool active, String hint, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.1) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.3)
              : const Color(0xFFDDDDDD),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 13,
            color: active ? color : const Color(0xFFAAAAAA),
          ),
          const SizedBox(width: 5),
          Text(
            active ? '$label 활성화' : '$label ($hint)',
            style: TextStyle(
                fontSize: 11,
                color: active ? color : const Color(0xFFAAAAAA),
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── 기본 정보 ──
  Widget _buildBasicInfoSection() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('📝 ${loc.basicInfoTitle}', required: true),
          const SizedBox(height: 14),
          _textField(
              controller: _teamNameCtrl,
              label: context.watch<LanguageProvider>().loc.groupFormTeamNameLabel,
              hint: context.watch<LanguageProvider>().loc.groupFormTeamNameHint,
              required: _hasTeamName),  // 단체명 변경 옵션 선택 시에만 필수
          const SizedBox(height: 10),
          _textField(
              controller: _managerNameCtrl,
              label: context.watch<LanguageProvider>().loc.groupFormManagerNameLabel,
              hint: context.watch<LanguageProvider>().loc.groupFormManagerNameHint,
              required: true),
          const SizedBox(height: 10),
          _textField(
              controller: _phoneCtrl,
              label: context.watch<LanguageProvider>().loc.groupFormPhoneLabel,
              hint: context.watch<LanguageProvider>().loc.groupFormPhoneHint,
              keyboardType: TextInputType.phone,
              required: true),
          const SizedBox(height: 10),
          _textField(
              controller: _emailCtrl,
              label: context.watch<LanguageProvider>().loc.groupFormEmailLabel,
              hint: context.watch<LanguageProvider>().loc.groupFormEmailHint,
              keyboardType: TextInputType.emailAddress),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // ── 하의 길이 안내 + 공통 기본 길이 설정 섹션 ──
  Widget _buildLengthGuideSection() {
    // 기장 선택: 싱글렛, 타이즈, 싱글렛세트 카테고리에만 표시
    final cat = widget.product?.category ?? '';
    final subCat = widget.product?.subCategory ?? '';
    final isSinglet = cat.contains('싱글렛') || subCat.contains('싱글렛');
    final isTights = cat.contains('타이즈') || subCat.contains('타이즈');
    final isSingletSet = cat.contains('싱글렛세트') || subCat.contains('싱글렛세트') ||
        (cat == '세트' && subCat.contains('싱글렛'));
    // product가 null이면(추가제작 등) 항상 표시
    final showLengthSection = widget.product == null || isSinglet || isTights || isSingletSet;
    if (!showLengthSection) return const SizedBox.shrink();

    const lengths = ['9부', '5부', '4부', '3부', '2.5부', '숏쇼트'];
    final lengthDescriptions = {
      '9부':    loc.length9buDesc,
      '5부':    loc.length5buDesc,
      '4부':    loc.length4buDesc,
      '3부':    loc.length3buDesc,
      '2.5부':  loc.length25buDesc,
      '숏쇼트': loc.lengthShortShortDesc,
    };

    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          Row(
            children: [
              _sectionHeader('📐 ${loc.bottomLengthSelect}', required: true),
              const Spacer(),
              // 길이 비교 이미지 팝업 버튼
              GestureDetector(
                onTap: () => _showLengthGuideDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.compare_arrows_rounded,
                          size: 14, color: Color(0xFF6A1B9A)),
                      const SizedBox(width: 5),
                      Text(context.watch<LanguageProvider>().loc.groupFormLengthCompare,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6A1B9A),
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            loc.defaultLengthHint,
            style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),

          // ── 길이 선택 카드 ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lengths.map((len) {
              final isSelected = _defaultLength == len;
              final desc = lengthDescriptions[len] ?? '';
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _defaultLength = len;
                    // 전체 인원에 동일하게 강제 적용
                    for (final p in _persons) {
                      p.selectedLength = len;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6A1B9A)
                        : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6A1B9A)
                          : const Color(0xFFDDDDDD),
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: const Color(0xFF6A1B9A)
                                    .withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        len,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ── 일괄 적용 버튼 ──
          if (_defaultLength != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    for (final p in _persons) {
                      p.selectedLength = _defaultLength;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          loc.defaultLengthApplied),
                      backgroundColor: const Color(0xFF6A1B9A),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text(
                  loc.applyLengthToAll(_defaultLength ?? ''),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6A1B9A),
                  side: const BorderSide(
                      color: Color(0xFF6A1B9A), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

          // ── 안내문구 ──
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    loc.canChangePerPerson,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6A1B9A),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 길이 비교 다이얼로그
  void _showLengthGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.compare_arrows_rounded,
                        color: Color(0xFF6A1B9A), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(context.watch<LanguageProvider>().loc.groupFormBottomLengthCompare,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _lengthGuideItem('9부',   loc.length9buCm,   const Color(0xFF1565C0),  0.92),
                      _lengthGuideItem('5부',   loc.length5buCm,   const Color(0xFF2E7D32),  0.72),
                      _lengthGuideItem('4부',   loc.length4buCm, const Color(0xFF6A1B9A), 0.60),
                      _lengthGuideItem('3부',   loc.length3buCm, const Color(0xFFAD6800), 0.48),
                      _lengthGuideItem('2.5부', loc.length25buCm, const Color(0xFFAD1457), 0.40),
                      _lengthGuideItem('숏쇼트', loc.lengthShortShortCm,      const Color(0xFFB71C1C),  0.32),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                loc.lengthVarianceNote,
                style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lengthGuideItem(
      String name, String desc, Color color, double ratio) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // 길이 바 시각화
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 10,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Container(
                  width: 10,
                  height: 36 * ratio,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF666666))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(ratio * 100).toInt()}%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }

  // 하의 참조 이미지 업로드 (남자 / 여자 각각)
  // ══════════════════════════════════════════════════════════
  Widget _buildBottomRefImageSection() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('📸 ${loc.refImageTitle}'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.uploadImageNotice,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6A1B9A), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── 남자 카드 ──
          _GenderRefImageCard(
            key: const ValueKey('male_ref'),
            gender: loc.maleGenderLabel,
            label: context.watch<LanguageProvider>().loc.groupFormMaleLabel,
            icon: Icons.male_rounded,
            color: const Color(0xFF1565C0),
            bgColor: const Color(0xFFE3F2FD),
            borderColor: const Color(0xFF1565C0),
            base64Image: _maleRefBase64,
            onPick: () => _pickRefImage(isMale: true),
            onRemove: () {
              setState(() => _maleRefBase64 = null);
              _saveImage(isMale: true, base64: null);
            },
          ),
          const SizedBox(height: 14),
          // ── 여자 카드 ──
          _GenderRefImageCard(
            key: const ValueKey('female_ref'),
            gender: loc.femaleGenderLabel,
            label: context.watch<LanguageProvider>().loc.groupFormFemaleLabel,
            icon: Icons.female_rounded,
            color: const Color(0xFFAD1457),
            bgColor: const Color(0xFFFCE4EC),
            borderColor: const Color(0xFFAD1457),
            base64Image: _femaleRefBase64,
            onPick: () => _pickRefImage(isMale: false),
            onRemove: () {
              setState(() => _femaleRefBase64 = null);
              _saveImage(isMale: false, base64: null);
            },
          ),
        ],
      ),
    );
  }


  Future<void> _pickRefImage({required bool isMale}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      // MIME 타입 감지
      String mime = 'image/jpeg';
      if (bytes.length >= 4) {
        if (bytes[0] == 0x89 && bytes[1] == 0x50) {
          mime = 'image/png';
        } else if (bytes[0] == 0x47 && bytes[1] == 0x49) mime = 'image/gif';
        else if (bytes[0] == 0xFF && bytes[1] == 0xD8) mime = 'image/jpeg';
      }
      // Base64 데이터 URI로 변환 — rebuild 후에도 String으로 안전하게 유지
      final base64Str = 'data:$mime;base64,${base64Encode(bytes)}';

      setState(() {
        if (isMale) {
          _maleRefBase64 = base64Str;
        } else {
          _femaleRefBase64 = base64Str;
        }
      });
      // SharedPreferences에 영구 저장 — 앱 재시작 후에도 유지
      await _saveImage(isMale: isMale, base64: base64Str);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.watch<LanguageProvider>().loc.groupFormImageError}: \$e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── 메모 ──
  Widget _buildMemoSection() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('💬 ${loc.memoTitle}'),
          const SizedBox(height: 12),
          _textField(
            controller: _memoCtrl,
            label: context.watch<LanguageProvider>().loc.groupFormMemoLabel,
            hint: context.watch<LanguageProvider>().loc.groupFormMemoHint,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // ── 디자인 독점 사용권 ──
  Widget _buildExclusiveDesignSection() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🔒 ${loc.groupOrderExclusiveTitle}'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCE93D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.groupOrderGuideExclusiveTitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4A148C))),
                const SizedBox(height: 4),
                Text(loc.groupOrderGuideExclusive1,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.5)),
                Text(loc.groupOrderGuideExclusive2,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.5)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _exclusiveDesign = !_exclusiveDesign),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _exclusiveDesign ? const Color(0xFF6A1B9A).withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _exclusiveDesign ? const Color(0xFF6A1B9A) : const Color(0xFFDDDDDD),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _exclusiveDesign ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: _exclusiveDesign ? const Color(0xFF6A1B9A) : const Color(0xFFBBBBBB),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '디자인 독점 사용권 신청 (+₩100,000)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _exclusiveDesign ? const Color(0xFF6A1B9A) : const Color(0xFF333333),
                            ),
                          ),
                        ),
                        if (_exclusiveDesign)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A1B9A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('선택됨',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 최종 금액 요약 ──
  Widget _buildSummarySection() {
    final basePrice = widget.product?.price ?? 0.0;
    final waistbandTotal = _waistbandExtra * _totalCount;
    final fabricTotal = _fabricExtra * _totalCount;
    final subtotal = (basePrice * _totalCount) + waistbandTotal + fabricTotal;
    final total = subtotal.toInt();
    // 5장 이상 무료배송
    final shipping = _totalCount >= 5 ? 0 : 3000;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context.watch<LanguageProvider>().loc.groupFormOrderSummary),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                if (widget.product != null) ...[
                  _summaryRow(loc.groupFormLabelProduct,
                      widget.product!.name,
                      highlight: false),
                  _summaryRow(loc.groupFormLabelBasePrice,
                      '${_fmt(basePrice.toInt())}${loc.wonUnit2} × $_totalCount${loc.groupFormPersons}',
                      highlight: false),
                ],
                // ── 선택된 커스텀 옵션 표시 ──
                _summaryRow(
                  '🎨 커스텀 옵션',
                  [
                    loc.printType1Label,
                    loc.printType2Label,
                    loc.printType3Label,
                    loc.printType4Label,
                  ][_printType],
                  highlight: false,
                  valueColor: [
                    const Color(0xFF1565C0),
                    const Color(0xFF2E7D32),
                    const Color(0xFF6A1B9A),
                    const Color(0xFFC62828),
                  ][_printType],
                ),
                if (_defaultLength != null)
                  _summaryRow(loc.groupFormLabelBottomLength, _defaultLength!, highlight: false,
                      valueColor: const Color(0xFF6A1B9A)),
                if (_fabricExtra > 0)
                  _summaryRow('${loc.groupFormDialogFabric} ($_fabricType)',
                      '+${_fmt(_fabricExtra)}${loc.wonUnit2} × $_totalCount${loc.groupFormPersons}',
                      highlight: false,
                      valueColor: const Color(0xFF1565C0)),
                _summaryRow(loc.groupFormLabelFabricWeight, _fabricWeight, highlight: false),
                // 싱글렛세트: 하의 별도 색상 선택 여부
                if (_useSeparateBottomColor && _bottomColorName != null)
                  _summaryRow(loc.groupFormLabelColor,
                      '${loc.groupFormColorTop}: ${_mainColorName ?? "-"} / ${loc.groupFormColorBottom}: ${_bottomColorName ?? "-"}',
                      highlight: false,
                      valueColor: const Color(0xFF6A1B9A)),
                if (_waistbandExtra > 0)
                  _summaryRow('허리밴드 변경${_waistbandName && _waistbandColor ? " (단체명+색상)" : _waistbandName ? " (단체명)" : " (색상)"}',
                      '+${_fmt(_waistbandExtra)}${loc.wonUnit2} × $_totalCount${loc.groupFormPersons}',
                      highlight: false,
                      valueColor: const Color(0xFFFF6B35)),
                const Divider(height: 20),
                _summaryRow(loc.groupFormShippingLabel,
                    _totalCount >= 5 ? '🚚 무료배송 (5장 이상)' : '${_fmt(shipping)}${loc.wonUnit2}',
                    highlight: false,
                    valueColor: _totalCount >= 5
                        ? const Color(0xFF2E7D32)
                        : null),
                _summaryRow(loc.groupFormLabelTotalPayment,
                    '${_fmt(total + shipping)}${loc.wonUnit2}',
                    highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {required bool highlight, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  // ── 제출 하단바 (최종금액 상시 표시) ──
  Widget _buildSubmitBar() {
    final bool canSubmit = _isAdditional ? _totalCount >= 1 : _totalCount >= 5;

    // 금액 계산 (할인 없음, 5장 이상 무료배송)
    final basePrice   = widget.product?.price ?? 0.0;
    final waistTotal  = _waistbandExtra * _totalCount;
    final fabricTotal = _fabricExtra * _totalCount;
    final subtotal    = (basePrice * _totalCount) + waistTotal + fabricTotal;
    final total       = subtotal.toInt();
    final shipping    = _totalCount >= 5 ? 0 : 3000;
    final finalTotal  = total + shipping;

    return Container(
      padding: EdgeInsets.only(
        left: 0, right: 0,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, -4))
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 최종금액 요약 띠 ──
                if (_totalCount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // 좌측: 인원 & 단가
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text('$_totalCount${context.watch<LanguageProvider>().loc.groupFormPersonUnit}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70,
                                  fontWeight: FontWeight.w600)),
                          if (_totalCount >= 5) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text('무료배송',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.shippingCostLabel(shipping == 0 ? loc.freeShippingLabel : '${_fmt(shipping)}${loc.wonUnit2}'),
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 우측: 최종금액
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(context.watch<LanguageProvider>().loc.finalPaymentLabel,
                          style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmt(finalTotal)}원',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── 최소 인원 미달 안내 ──
          if (!canSubmit && _totalCount > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFCC02).withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 15, color: Color(0xFF7A5000)),
                  const SizedBox(width: 8),
                  Text(
                    _isAdditional
                        ? loc.qtyRequiredToSubmit
                        : loc.minPersonRequired,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF7A5000),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // ── 버튼 행 ──
          if (widget.product != null) ...[
            // 상품이 있는 경우: 장바구니(1) + 바로구매(2) 한 줄 Row
            Row(
              children: [
                // 장바구니 버튼
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: canSubmit ? _addToCart : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6A1B9A),
                        side: BorderSide(
                            color: canSubmit
                                ? const Color(0xFF6A1B9A)
                                : const Color(0xFFCCCCCC),
                            width: 1.5),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 16),
                              const SizedBox(width: 4),
                              Text(context.watch<LanguageProvider>().loc.groupFormCartBtn,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 바로 구매하기 버튼
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: canSubmit ? _buyNow : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canSubmit
                            ? const Color(0xFF6A1B9A)
                            : const Color(0xFFCCCCCC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on_rounded, size: 18),
                              const SizedBox(width: 4),
                              Text(context.watch<LanguageProvider>().loc.groupFormBuyNowFull,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 상품 없는 경우(단체 주문서 전용): 주문서 확인 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canSubmit ? _submitOrder : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canSubmit ? const Color(0xFF6A1B9A) : const Color(0xFFCCCCCC),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          canSubmit
                              ? (_isAdditional ? loc.groupFormCheckAdditional : loc.groupFormCheckOrder)
                              : (_isAdditional ? loc.groupFormNeedQty : loc.groupFormNeedMin5),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addToCart() {
    if (widget.product == null) return;
    // 색상 변경 옵션 선택 시에만 색상 필수 체크
    if (_hasColorChange && _mainColorName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.watch<LanguageProvider>().loc.groupFormColorRequired)),
      );
      return;
    }
    final cart = context.read<CartProvider>();
    cart.addItem(
      widget.product!,
      'TEAM',
      loc.colorDefaultLabel,
      quantity: _totalCount,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.watch<LanguageProvider>().loc.groupFormCartAddedN(_totalCount)),
        action: SnackBarAction(
          label: context.watch<LanguageProvider>().loc.groupFormViewMoreBtn,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  void _buyNow() {
    if (widget.product == null) return;
    // 색상 변경 옵션 선택 시에만 색상 필수 체크
    if (_hasColorChange && _mainColorName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.watch<LanguageProvider>().loc.groupFormColorRequired)),
      );
      return;
    }
    final cart = context.read<CartProvider>();
    cart.addItem(
      widget.product!,
      'TEAM',
      _mainColorName ?? '기본',
      quantity: _totalCount,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(cart: cart),
      ),
    );
  }

  void _submitOrder() {
    // 색상변경 옵션 선택 시에만 색상 필수 검증
    if (_hasColorChange && _mainColorName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.watch<LanguageProvider>().loc.groupFormColorRequired)),
      );
      return;
    }
    // 단체명 변경 옵션 선택 시에만 팀명 필수 검증 (옵션①은 색상만 변경이므로 팀명 불필요)
    if (_hasTeamName && _teamNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.watch<LanguageProvider>().loc.groupFormTeamRequired)),
      );
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.watch<LanguageProvider>().loc.groupFormPhoneRequired)),
      );
      return;
    }
    if (!_isAdditional && _totalCount < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.watch<LanguageProvider>().loc.groupFormMinQtyError)),
      );
      return;
    }
    if (_isAdditional && _totalCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.watch<LanguageProvider>().loc.groupFormAdditionalQtyError)),
      );
      return;
    }

    // ── 성별 미선택 검증 ──
    final noGender = _persons.where((p) => p.gender == null).toList();
    if (noGender.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${noGender.length}명의 성별을 선택해주세요. (인원 ${noGender.map((p) => p.index + 1).join(', ')}번)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ── 사이즈 미입력 검증 (모든 인원 필수) ──
    final noTopSize = _persons.where((p) => p.topCustomCtrl.text.trim().isEmpty).toList();
    if (noTopSize.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${noTopSize.length}명의 상의 사이즈를 입력해주세요. (인원 ${noTopSize.map((p) => p.index + 1).join(', ')}번)'),
          backgroundColor: const Color(0xFFFF6D00),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    final noBottomSize = _persons.where((p) => p.bottomCustomCtrl.text.trim().isEmpty).toList();
    if (noBottomSize.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${noBottomSize.length}명의 하의 사이즈를 입력해주세요. (인원 ${noBottomSize.map((p) => p.index + 1).join(', ')}번)'),
          backgroundColor: const Color(0xFFFF6D00),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    _showAddressAndConfirmDialog();
  }

  // ── 주소 입력 → 주문 확인 다이얼로그 (단순화된 버전) ──
  void _showAddressAndConfirmDialog() {
    final addressCtrl = TextEditingController();
    final detailCtrl  = TextEditingController();

    // 주소 검색 시트 열기 (다이얼로그 컨텍스트 전달받아 상태 갱신)
    void openSheet(StateSetter setDlgState) async {
      final result = await showKakaoAddressSearch(context);
      if (result != null) {
        setDlgState(() => addressCtrl.text = result.address);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  color: Color(0xFF6A1B9A), size: 22),
              const SizedBox(width: 8),
              Text(context.watch<LanguageProvider>().loc.shippingAddressInput,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.orderDeliveryAddrPrompt,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 14),
                // 주소 검색 버튼 + 필드
                GestureDetector(
                  onTap: () => openSheet(setDlgState),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: addressCtrl,
                      readOnly: true,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: context.watch<LanguageProvider>().loc.groupFormAddressHint,
                        hintStyle: const TextStyle(
                            fontSize: 12, color: Color(0xFFBBBBBB)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 13),
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: addressCtrl.text.isNotEmpty
                                  ? const Color(0xFF6A1B9A)
                                  : const Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: addressCtrl.text.isNotEmpty
                                  ? const Color(0xFF6A1B9A)
                                  : const Color(0xFFE0E0E0)),
                        ),
                        isDense: true,
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: addressCtrl.text.isNotEmpty
                              ? const Color(0xFF6A1B9A)
                              : const Color(0xFF999999),
                        ),
                        suffixIcon: TextButton(
                          onPressed: () => openSheet(setDlgState),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(context.watch<LanguageProvider>().loc.searchLabel,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6A1B9A))),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 상세 주소
                TextField(
                  controller: detailCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: context.watch<LanguageProvider>().loc.groupFormDetailAddressHint,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    isDense: true,
                    prefixIcon: const Icon(Icons.apartment_outlined,
                        size: 18, color: Color(0xFF999999)),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(context.watch<LanguageProvider>().loc.cancelLabel,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF666666))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: addressCtrl.text.trim().isEmpty
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _showOrderConfirmDialog(
                                '${addressCtrl.text} ${detailCtrl.text}'
                                    .trim());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFCCCCCC),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(context.watch<LanguageProvider>().loc.nextArrowLabel,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 주문 확인 다이얼로그 ──
  void _showOrderConfirmDialog(String deliveryAddress) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.watch<LanguageProvider>().loc.groupFormOrderConfirmTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 단체명 변경 옵션 선택 시에만 표시
            if (_hasTeamName)
              _dialogRow(loc.groupFormDialogTeamName, _teamNameCtrl.text),
            _dialogRow(loc.groupFormDialogHeadcount, '$_totalCount${loc.groupFormPersons}'),
            Builder(builder: (_) {
              final maleCount =
                  _persons.where((p) => p.gender == '남').length;
              final femaleCount =
                  _persons.where((p) => p.gender == '여').length;
              if (maleCount > 0 || femaleCount > 0) {
                return _dialogRow(loc.groupFormDialogGender, '${loc.groupFormMale} $maleCount${loc.groupFormPersons} / ${loc.groupFormFemale} $femaleCount${loc.groupFormPersons}');
              }
              return const SizedBox.shrink();
            }),
            // 선택된 커스텀 옵션 표시
            _dialogRow('커스텀 옵션', [
              loc.printType1Label,
              loc.printType2Label,
              loc.printType3Label,
              loc.printType4Label,
            ][_printType]),
            if (_hasColorChange)
              _dialogRow(loc.groupFormDialogMainColor, _mainColorName ?? '-'),
            if (_useSeparateBottomColor && _bottomColorName != null)
              _dialogRow(loc.groupFormDialogBottomColor, _bottomColorName ?? '-'),
            if (_defaultLength != null)
              _dialogRow(loc.groupFormLabelBottomLength, _defaultLength!),
            _dialogRow(loc.groupFormDialogFabric, _fabricType),
            _dialogRow(loc.groupFormDialogWeight, _fabricWeight),
            if (_waistbandOption != null)
              _dialogRow(loc.groupFormDialogWaistband,
                  _waistbandOption == 'name'
                      ? loc.waistbandNameOnly
                      : _waistbandOption == 'color'
                          ? '${loc.waistbandColorOnly}(${_waistbandColorName ?? '-'})'
                          : '${loc.waistbandChangeNameColorTitle}(${_waistbandColorName ?? '-'})'),
            _dialogRow(loc.groupFormDialogDelivery, deliveryAddress),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFFCC02)
                        .withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 14, color: Color(0xFF7A5000)),
                      const SizedBox(width: 4),
                      Text(context.watch<LanguageProvider>().loc.orderChangeNoticeTitle,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7A5000))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.modifyDaysNotice(AppConstants.customOrderModifyDays, AppConstants.customOrderAutoConfirmDays),
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A5000),
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.estimateSentNotice,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('수정', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 다이얼로그 닫기
                    _saveGroupOrder(deliveryAddress); // Firestore 저장
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('주문 서식 제출하기',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 단체주문 Firestore 저장 ──
  Future<void> _saveGroupOrder(String deliveryAddress) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6A1B9A)),
              SizedBox(width: 16),
              Text('주문 접수 중...', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );

    try {
      final user = context.read<UserProvider>().user;
      final orderId = 'GROUP-${DateTime.now().millisecondsSinceEpoch}';
      final printTypeLabel = [
        loc.printType1Label, loc.printType2Label,
        loc.printType3Label, loc.printType4Label,
      ][_printType];

      // 팀원 목록을 customOptions에 저장
      final personsList = _persons.map((p) {
        final topS = p.topCustomCtrl.text.trim().isNotEmpty
            ? p.topCustomCtrl.text.trim()
            : (p.topSize ?? '-');
        final botS = p.bottomCustomCtrl.text.trim().isNotEmpty
            ? p.bottomCustomCtrl.text.trim()
            : (p.bottomSize ?? '-');
        final hasCustomMeasure = p.heightCtrl.text.trim().isNotEmpty ||
            p.weightCtrl.text.trim().isNotEmpty;
        return {
          'index': p.index + 1,
          'name': p.nameCtrl.text.trim().isEmpty ? '-' : p.nameCtrl.text.trim(),
          'gender': p.gender ?? '-',
          'topSize': topS,
          'bottomSize': botS,
          'customHeight': p.heightCtrl.text.trim(),
          'customWeight': p.weightCtrl.text.trim(),
          'useCustom': hasCustomMeasure,
        };
      }).toList();

      // 상품 이미지 URL (엑셀 삽입용)
      final productImageUrl = widget.product?.images.isNotEmpty == true
          ? widget.product!.images.first
          : '';
      // 하의 참조 이미지 URL (Firebase Storage 업로드 후 URL 또는 base64)
      final maleRefImageUrl = _maleRefBase64 != null ? 'data:image/jpeg;base64,${_maleRefBase64!.substring(0, _maleRefBase64!.length.clamp(0, 50))}...' : '';
      final femaleRefImageUrl = _femaleRefBase64 != null ? 'data:image/jpeg;base64,${_femaleRefBase64!.substring(0, _femaleRefBase64!.length.clamp(0, 50))}...' : '';

      final customOptions = {
        'printType': _printType,
        'printTypeLabel': printTypeLabel,
        'hasColorChange': _hasColorChange,
        'hasTeamName': _hasTeamName,
        'hasNameChange': _hasNameChange,
        'mainColor': _mainColorName ?? '',
        'mainColorHex': _mainColor != null
            ? '#${_mainColor!.value.toRadixString(16).padLeft(8, '0').substring(2)}'
            : '',
        'bottomColor': _useSeparateBottomColor ? (_bottomColorName ?? '') : '',
        'defaultLength': _defaultLength ?? '',
        'fabricType': _fabricType,
        'fabricWeight': _fabricWeight,
        'waistbandOption': _waistbandOption ?? '',
        'waistbandColor': _waistbandColorName ?? '',
        'exclusiveDesign': _exclusiveDesign,
        'teamName': _teamNameCtrl.text.trim(),
        'managerName': _managerNameCtrl.text.trim(),
        'totalCount': _totalCount,
        'maleCount': _persons.where((p) => p.gender == '남').length,
        'femaleCount': _persons.where((p) => p.gender == '여').length,
        'persons': personsList,
        'memoText': _memoCtrl.text.trim(),
        'isAdditional': _isAdditional,
        'orderType': _isAdditional ? 'additional' : 'group',
        // 이미지 URL (엑셀 내보내기용)
        'productImageUrl': productImageUrl,
        'maleRefImageUrl': maleRefImageUrl,
        'femaleRefImageUrl': femaleRefImageUrl,
        'designFileUrl': '',  // PDF 업로드 시 채워짐
      };

      final basePrice = widget.product?.price ?? 0;
      final fabricExtra = _fabricExtra.toDouble();
      final waistbandExtra = _waistbandExtra.toDouble();
      final exclusiveExtra = _exclusiveDesign ? 100000.0 : 0.0;
      final subtotal = (basePrice + fabricExtra + waistbandExtra) * _totalCount;
      final discount = subtotal * _discountRate;
      final shipping = (_totalCount >= 5 || _isAdditional) ? 0.0 : 4000.0;
      final total = subtotal - discount + exclusiveExtra + shipping;

      final order = OrderModel(
        id: orderId,
        userId: user?.id ?? 'anonymous',
        userName: _managerNameCtrl.text.trim().isNotEmpty
            ? _managerNameCtrl.text.trim()
            : (user?.name ?? '고객'),
        userEmail: _emailCtrl.text.trim().isNotEmpty
            ? _emailCtrl.text.trim()
            : (user?.email ?? ''),
        userPhone: _phoneCtrl.text.trim(),
        userAddress: deliveryAddress,
        items: widget.product != null
            ? [
                OrderItem(
                  productId: widget.product!.id,
                  productName: widget.product!.name,
                  size: 'GROUP',
                  color: _mainColorName ?? '기본',
                  quantity: _totalCount,
                  price: basePrice + fabricExtra + waistbandExtra,
                  customOptions: customOptions,
                ),
              ]
            : [],
        totalAmount: total,
        shippingFee: shipping,
        paymentMethod: '무통장입금',
        orderType: _isAdditional ? 'additional' : 'group',
        customOptions: customOptions,
        groupName: _teamNameCtrl.text.trim().isNotEmpty
            ? _teamNameCtrl.text.trim()
            : null,
        groupCount: _totalCount,
        memo: _memoCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await OrderService.saveOrder(order);

      // ── 알림 전송 ──
      try {
        final notifRef = FirebaseFirestore.instance.collection('admin_notifications').doc();
        final teamNameStr = _teamNameCtrl.text.trim().isNotEmpty ? _teamNameCtrl.text.trim() : '-';
        final orderTypeLabel = _isAdditional ? '추가제작주문' : '단체주문';
        await notifRef.set({
          'id': notifRef.id,
          'title': _isAdditional ? '🔄 추가제작 주문 접수' : '👥 새 단체주문 접수',
          'body': '$orderTypeLabel: $teamNameStr (${_totalCount}명) — ${widget.product?.name ?? '상품'}',
          'type': _isAdditional ? 'additional_order' : 'group_order',
          'orderId': orderId,
          'teamName': teamNameStr,
          'totalCount': _totalCount,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      // 완료 다이얼로그
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 36, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 16),
              const Text('주문 서식이 제출되었습니다!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('주문번호: ${orderId.substring(orderId.length > 12 ? orderId.length - 12 : 0)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.5)),
                ),
                child: const Text(
                  '담당자 확인 후 결제 안내를 드립니다.\n확인 이메일이 발송됩니다.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A5000), height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 완료 다이얼로그 닫기
                  Navigator.pop(context); // 주문 화면 닫기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('확인', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주문 저장 실패: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _dialogRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  // ── 공통 섹션 헤더 ──
  // ── 2FIT 사이즈표 ──
  Widget _buildSizeChart() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('2FIT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 6),
              Text(context.watch<LanguageProvider>().loc.groupFormSizeConditionTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text(context.watch<LanguageProvider>().loc.groupFormSizeStandard, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
            ],
          ),
          const SizedBox(height: 10),
          // 성인 사이즈표
          _buildSizeTableLabel(loc.sizeTableAdultLabel, const Color(0xFF1565C0)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: const Color(0xFFDDDDDD), width: 0.8),
              children: [
                _sizeTableHeaderRow([loc.sizeLabel, 'XS(85)', 'S(90)', 'M(95)', 'L(100)', 'XL(105)', '2XL(110)', '3XL(115)']),
                _sizeTableRow('신장(cm)', ['154~159', '160~165', '166~172', '172~177', '177~182', '182~187', '187~191']),
                _sizeTableRow('몸무게(kg)', ['44~51', '52~60', '61~71', '72~78', '79~85', '86~91', '91~96']),
                _sizeTableRow('가슴둘레(cm)', ['85', '90', '95', '100', '105', '110', '115']),
                _sizeTableRow('허리(inch)', ['26~28', '28~30', '30~32', '32~34', '34~36', '36~38', '38~40']),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 주니어 사이즈표
          _buildSizeTableLabel('주니어', const Color(0xFF2E7D32)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: const Color(0xFFDDDDDD), width: 0.8),
              children: [
                _sizeTableHeaderRow(['사이즈', 'J-S(60)', 'J-M(65)', 'J-L(70)', 'J-XL(75)', 'J-2XL(80)']),
                _sizeTableRow('신장(cm)', ['112~117', '118~122', '123~133', '130~139', '140~153']),
                _sizeTableRow('몸무게(kg)', ['19~21', '22~24', '25~28', '26~34', '35~43']),
                _sizeTableRow('나이', ['6~7세', '7~8세', '8~9세', '10~11세', '-']),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '※ 개인 체형에 따라 정확히 일치하지 않을 수 있으며, 타사 사이즈와 상이할 수 있습니다.',
            style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeTableLabel(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  TableRow _sizeTableHeaderRow(List<String> labels) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
      children: labels.map((l) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center),
      )).toList(),
    );
  }

  TableRow _sizeTableRow(String label, List<String> values) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF444444)), textAlign: TextAlign.center),
        ),
        ...values.map((v) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(v, style: const TextStyle(fontSize: 10, color: Color(0xFF555555)), textAlign: TextAlign.center),
        )),
      ],
    );
  }

  Widget _sectionHeader(String title, {bool required = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800)),
        if (required) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(context.watch<LanguageProvider>().loc.requiredBadgeLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  // ── 공통 텍스트필드 ──
  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333))),
            if (required) ...[
              const SizedBox(width: 4),
              const Text('*',
                  style: TextStyle(
                      color: AppColors.error, fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppColors.textHint, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF6A1B9A), width: 1.5),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ── 주소 검색 시트 ──
// ── 카카오 우편번호 서비스 WebView 주소 검색 시트 ──
class _AddressSearchSheet extends StatefulWidget {
  final ValueChanged<String> onAddressSelected;
  const _AddressSearchSheet({required this.onAddressSelected});

  @override
  State<_AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<_AddressSearchSheet> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  late final WebViewController _webCtrl;
  bool _loading = true;

  // 카카오 우편번호 서비스 HTML
  static const String _kakaoPostHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #fff; }
    #layer { width: 100%; height: 100vh; }
  </style>
</head>
<body>
<div id="layer"></div>
<script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
  new daum.Postcode({
    oncomplete: function(data) {
      var addr = data.userSelectedType === 'R' ? data.roadAddress : data.jibunAddress;
      window.KakaoPostBridge.postMessage(JSON.stringify({
        address: addr,
        zonecode: data.zonecode,
        roadAddress: data.roadAddress,
        jibunAddress: data.jibunAddress
      }));
    },
    width: '100%',
    height: '100%',
    maxSuggestItems: 10
  }).embed(document.getElementById('layer'), { autoClose: false });
</script>
</body>
</html>
  ''';

  @override
  void initState() {
    super.initState();
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'KakaoPostBridge',
        onMessageReceived: (msg) {
          try {
            final data = jsonDecode(msg.message) as Map<String, dynamic>;
            final address = data['address'] as String? ?? '';
            if (address.isNotEmpty) {
              widget.onAddressSelected(address);
            }
          } catch (_) {
            widget.onAddressSelected(msg.message);
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (req) {
          // 외부 링크 차단, 카카오 관련 허용
          if (req.url.contains('daumcdn') ||
              req.url.contains('kakao') ||
              req.url.startsWith('about:')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadHtmlString(_kakaoPostHtml, baseUrl: 'https://t1.daumcdn.net');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Color(0xFF6A1B9A), size: 20),
                const SizedBox(width: 8),
                Text(context.watch<LanguageProvider>().loc.groupFormAddressSearch,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // WebView
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webCtrl),
                if (_loading)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF6A1B9A),
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 12),
                        Text(context.watch<LanguageProvider>().loc.groupFormAddressLoading,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 인원 데이터 모델 ──
class _PersonEntry {
  int index;
  final nameCtrl        = TextEditingController();
  final memoCtrl        = TextEditingController();
  final heightCtrl      = TextEditingController();
  final weightCtrl      = TextEditingController();
  final chestCtrl       = TextEditingController(); // 가슴둘레
  final waistCtrl       = TextEditingController();
  final hipCtrl         = TextEditingController(); // 엉덩이둘레
  final thighCtrl       = TextEditingController();
  // 직접입력 컨트롤러
  final topCustomCtrl    = TextEditingController();
  final bottomCustomCtrl = TextEditingController();
  String? topSize;       // 직접입력 텍스트 저장
  String? bottomSize;    // 직접입력 텍스트 저장
  String? gender;        // null=미선택, '남', '여'
  String? selectedLength;

  _PersonEntry({required this.index});

  void dispose() {
    nameCtrl.dispose();
    memoCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    chestCtrl.dispose();
    waistCtrl.dispose();
    hipCtrl.dispose();
    thighCtrl.dispose();
    topCustomCtrl.dispose();
    bottomCustomCtrl.dispose();
  }
}

// ── 인원 행 위젯 ──
class _PersonRow extends StatefulWidget {
  final _PersonEntry entry;
  final int index;
  final bool nameEnabled;
  final bool measureEnabled;
  final VoidCallback? onRemove;
  final List<String> sizes;

  const _PersonRow({
    super.key,
    required this.entry,
    required this.index,
    required this.nameEnabled,
    required this.measureEnabled,
    this.onRemove,
    required this.sizes,
  });

  @override
  State<_PersonRow> createState() => _PersonRowState();
}

class _PersonRowState extends State<_PersonRow> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final idx = widget.index;
    final entry = widget.entry;
    final genderSelected = entry.gender != null;
    final isFemale = entry.gender == '여';

    // 색상 테마
    final accentColor = !genderSelected
        ? const Color(0xFF757575)
        : isFemale
            ? const Color(0xFFC62828)
            : const Color(0xFF1565C0);
    final bgColor = !genderSelected
        ? Colors.white
        : isFemale
            ? const Color(0xFFFFF5F5)
            : const Color(0xFFF3F7FF);

    // 사이즈 입력 완료 여부 (직접입력 컨트롤러 기준)
    final topDone  = entry.topCustomCtrl.text.trim().isNotEmpty;
    final botDone  = entry.bottomCustomCtrl.text.trim().isNotEmpty;
    final sizeDone = topDone && botDone;

    // 카드 테두리: 사이즈 미완료면 주황, 완료면 accent
    final borderColor = !sizeDone
        ? const Color(0xFFFF6D00).withValues(alpha: 0.6)
        : accentColor.withValues(alpha: 0.25);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 카드 헤더 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: genderSelected
                  ? accentColor.withValues(alpha: 0.07)
                  : const Color(0xFFF5F5F5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(
                  color: borderColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // 번호 뱃지
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 이름 or 상태 표시
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        widget.nameEnabled && entry.nameCtrl.text.isNotEmpty
                            ? entry.nameCtrl.text
                            : '인원 ${idx + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: genderSelected ? accentColor : const Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 사이즈 완료 뱃지
                      if (sizeDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, size: 10, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 2),
                              const Text('사이즈 완료', style: TextStyle(fontSize: 9, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6D00).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFFF6D00)),
                              SizedBox(width: 2),
                              Text('사이즈 필수', style: TextStyle(fontSize: 9, color: Color(0xFFFF6D00), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // ── 성별 선택 ──
                _GenderSelector(
                  value: entry.gender,
                  onChanged: (g) => setState(() => entry.gender = g),
                ),
                const SizedBox(width: 6),
                // 삭제 버튼
                if (widget.onRemove != null)
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),
          // ── 카드 바디 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 이름 입력 (10장 이상 시에만, 성별 선택 후)
                if (widget.nameEnabled && genderSelected) ...[
                  Row(
                    children: [
                      const Text('이름', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('선택', style: TextStyle(fontSize: 9, color: accentColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _buildNameField(entry, accentColor),
                  const SizedBox(height: 10),
                ],
                // 사이즈 행 (상의·하의 나란히 - 크기 축소, 항상 입력 가능)
                Row(
                  children: [
                    // 상의 사이즈
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('상의', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accentColor)),
                              const SizedBox(width: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: topDone
                                      ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                                      : const Color(0xFFFF6D00).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  topDone ? '✓' : '필수',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: topDone ? const Color(0xFF2E7D32) : const Color(0xFFFF6D00),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _buildSizeSection(
                            label: '',
                            value: entry.topSize,
                            customCtrl: entry.topCustomCtrl,
                            accentColor: const Color(0xFF1565C0),
                            enabled: true,
                            onChanged: (v) => setState(() => entry.topSize = v),
                            showLabel: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 하의 사이즈
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('하의', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFC62828))),
                              const SizedBox(width: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: botDone
                                      ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                                      : const Color(0xFFFF6D00).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  botDone ? '✓' : '필수',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: botDone ? const Color(0xFF2E7D32) : const Color(0xFFFF6D00),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _buildSizeSection(
                            label: '',
                            value: entry.bottomSize,
                            customCtrl: entry.bottomCustomCtrl,
                            accentColor: const Color(0xFFC62828),
                            enabled: true,
                            onChanged: (v) => setState(() => entry.bottomSize = v),
                            showLabel: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 실측 입력 (조건부)
                if (widget.measureEnabled) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Row(
                      children: [
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '실측 입력',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '선택',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 10),
                    // 키 / 몸무게
                    Row(
                      children: [
                        Expanded(
                          child: _measureCard(
                              entry.heightCtrl, '키', 'cm', Icons.height_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _measureCard(
                              entry.weightCtrl, '몸무게', 'kg',
                              Icons.monitor_weight_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 허리 / 허벅지 (가슴·엉덩이 제외)
                    Row(
                      children: [
                        Expanded(
                          child: _measureCard(
                              entry.waistCtrl, '허리둘레', 'cm',
                              Icons.straighten_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _measureCard(
                              entry.thighCtrl, '허벅지둘레', 'cm',
                              Icons.accessibility_new_rounded),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF666666),
      ),
    );
  }

  Widget _buildNameField(_PersonEntry entry, Color accentColor) {
    return TextField(
      controller: entry.nameCtrl,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: context.watch<LanguageProvider>().loc.groupFormNameInputHint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        isDense: true,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSizeDropdown(
      String? value, Color accentColor, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: context.watch<LanguageProvider>().loc.groupFormSelectHint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
      items: widget.sizes
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
    );
  }

  // ── 사이즈 섹션: 직접입력 TextField ──
  Widget _buildSizeSection({
    required String label,
    required String? value,
    required TextEditingController customCtrl,
    required Color accentColor,
    bool enabled = true,
    bool showLabel = true,
    required ValueChanged<String?>? onChanged,
  }) {
    final hasValue = customCtrl.text.trim().isNotEmpty;

    return TextField(
      controller: customCtrl,
      enabled: enabled,
      textCapitalization: TextCapitalization.characters,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: hasValue ? accentColor : const Color(0xFF1A1A1A),
        letterSpacing: 0.5,
      ),
      onChanged: (v) {
        // 텍스트를 topSize/bottomSize에 반영
        if (onChanged != null) {
          onChanged(v.trim().isEmpty ? null : v.trim());
        }
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: '예) XL, 95, 32',
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFFBBBBBB),
          fontWeight: FontWeight.normal,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: hasValue
            ? accentColor.withValues(alpha: 0.05)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: hasValue
              ? BorderSide(color: accentColor, width: 1.5)
              : BorderSide(color: accentColor.withValues(alpha: 0.25)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 1.8),
        ),
        isDense: true,
        suffixIcon: hasValue
            ? Icon(Icons.check_circle_rounded,
                size: 14, color: accentColor.withValues(alpha: 0.7))
            : const Icon(Icons.edit_rounded, size: 13, color: Color(0xFFCCCCCC)),
      ),
    );
  }

  Widget _measureCard(
      TextEditingController ctrl, String label, String unit, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: unit,
            hintStyle: const TextStyle(fontSize: 9, color: Color(0xFFBBBBBB)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            filled: true,
            fillColor: const Color(0xFFF0FFF4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF2E7D32), width: 0.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: Color(0xFF2E7D32), width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  // ── 하의 길이 선택 위젯 (인원별) ──
  Widget _buildLengthSection(_PersonEntry entry, Color accentColor, bool enabled) {
    const lengths = ['9부', '5부', '4부', '3부', '2.5부', '숏쇼트'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _fieldLabel('하의 길이'),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(context.watch<LanguageProvider>().loc.requiredBadgeLabel,
                  style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            if (!enabled)
              Text(context.watch<LanguageProvider>().loc.genderSelectFirst,
                  style: const TextStyle(fontSize: 10, color: Color(0xFFBBBBBB))),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: lengths.map((len) {
            final isSelected = entry.selectedLength == len;
            // 성별에 따른 기본 추천 표시
            final isFemaleDefault = len == '2.5부' && entry.gender == '여';
            final isMaleDefault = len == '5부' && entry.gender == '남';
            final isDefault = isFemaleDefault || isMaleDefault;
            return GestureDetector(
              onTap: enabled
                  ? () => setState(() => entry.selectedLength = len)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : enabled
                          ? (isDefault
                              ? accentColor.withValues(alpha: 0.08)
                              : Colors.white)
                          : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : isDefault
                            ? accentColor.withValues(alpha: 0.4)
                            : (enabled
                                ? const Color(0xFFDDDDDD)
                                : const Color(0xFFEEEEEE)),
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      len,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : enabled
                                ? (isDefault ? accentColor : const Color(0xFF444444))
                                : const Color(0xFFBBBBBB),
                      ),
                    ),
                    if (isDefault && !isSelected) ...[
                      const SizedBox(height: 2),
                      Text(
                        '추천',
                        style: TextStyle(
                          fontSize: 9,
                          color: accentColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (enabled && entry.selectedLength == null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 12, color: const Color(0xFFE53935).withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(context.watch<LanguageProvider>().loc.lengthSelectHint,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
    );
  }
}

// ignore: unused_element
class _SizeDropdown extends StatelessWidget {
  final String? value;
  final List<String> sizes;
  final ValueChanged<String?> onChanged;

  const _SizeDropdown({
    required this.value,
    required this.sizes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      isDense: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: context.watch<LanguageProvider>().loc.groupFormSelectHint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
      items: sizes
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
    );
  }
}

// ── 성별 토글 위젯 ──
// ── 성별 선택 위젯 (크고 명확한 버전, null 지원) ──
class _GenderSelector extends StatelessWidget {
  final String? value; // null=미선택, '남', '여'
  final ValueChanged<String> onChanged;

  const _GenderSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final unselected = value == null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn('남', const Color(0xFF1565C0), Icons.male_rounded),
        const SizedBox(width: 5),
        _btn('여', const Color(0xFFB71C1C), Icons.female_rounded),
      ],
    );
  }

  Widget _btn(String label, Color color, IconData icon) {
    final isSelected = value == label;
    final isUnselected = value == null;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : isUnselected
                  ? color.withValues(alpha: 0.08)
                  : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? color
                : isUnselected
                    ? color.withValues(alpha: 0.5)
                    : const Color(0xFFDDDDDD),
            width: isUnselected && !isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : isUnselected
                      ? color
                      : const Color(0xFFBBBBBB),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? Colors.white
                    : isUnselected
                        ? color
                        : const Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 성별 참조 이미지 카드 (StatefulWidget으로 bytes 내부 보존) ──
// ── 성별 참조 이미지 카드 (Base64 String으로 저장 → rebuild 후에도 완전 유지) ──
class _GenderRefImageCard extends StatelessWidget {
  final String gender;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final String? base64Image;   // 'data:image/jpeg;base64,...' 또는 null
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _GenderRefImageCard({
    super.key,
    required this.gender,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.base64Image,
    required this.onPick,
    required this.onRemove,
  });

  // Base64 URI → Uint8List 디코딩
  Uint8List? _decodeBase64() {
    if (base64Image == null) return null;
    try {
      final comma = base64Image!.indexOf(',');
      if (comma == -1) return null;
      return base64Decode(base64Image!.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBase64();
    final hasImage = bytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: hasImage ? 240 : 160,
          decoration: BoxDecoration(
            color: hasImage ? const Color(0xFFF0F0F0) : bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasImage ? borderColor : borderColor.withValues(alpha: 0.4),
              width: hasImage ? 2 : 1.5,
            ),
            boxShadow: hasImage
                ? [BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3))]
                : [],
          ),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: borderColor.withValues(alpha: 0.88),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(label,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            const Spacer(),
                            GestureDetector(
                              onTap: onRemove,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 13, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 40, color: color),
                    ),
                    const SizedBox(height: 10),
                    Text(label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(context.watch<LanguageProvider>().loc.groupFormImageUpload,
                        style: TextStyle(
                            fontSize: 12,
                            color: color.withValues(alpha: 0.6))),
                  ],
                ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: hasImage ? color.withValues(alpha: 0.1) : color,
              borderRadius: BorderRadius.circular(10),
              border: hasImage
                  ? Border.all(color: color.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasImage
                      ? Icons.refresh_rounded
                      : Icons.add_photo_alternate_outlined,
                  size: 15,
                  color: hasImage ? color : Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  hasImage ? '재업로드' : '업로드',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: hasImage ? color : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 다이얼 버튼 위젯 (수량 조절)
// ══════════════════════════════════════════════════════════════
class _DialButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _DialButton({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
    this.onLongPress,
  });
  @override
  State<_DialButton> createState() => _DialButtonState();
}

class _DialButtonState extends State<_DialButton>
    with SingleTickerProviderStateMixin {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _press() async {
    if (!widget.enabled) return;
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? widget.color : const Color(0xFFCCCCCC);
    return GestureDetector(
      onTap: widget.enabled ? _press : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: widget.enabled
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.enabled
                  ? color.withValues(alpha: 0.4)
                  : const Color(0xFFDDDDDD),
              width: 2,
            ),
          ),
          child: Icon(widget.icon, size: 28, color: color),
        ),
      ),
    );
  }
}
