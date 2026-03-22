import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/app_localizations.dart';
import '../../utils/constants.dart';
import '../../widgets/pc_layout.dart';

// ══════════════════════════════════════════════════════════════
// 단체 커스텀 오더 화면
// - 상품 상세에서 상품을 선택한 후 진입
// - 색상 선택, 하의 길이 선택, 인원별 사이즈 입력 (하의 없을 시 실측)
// ══════════════════════════════════════════════════════════════
class GroupCustomOrderScreen extends StatefulWidget {
  final ProductModel product;
  const GroupCustomOrderScreen({super.key, required this.product});

  @override
  State<GroupCustomOrderScreen> createState() => _GroupCustomOrderScreenState();
}

class _GroupCustomOrderScreenState extends State<GroupCustomOrderScreen> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  // ── 색상 ──
  String? _selectedColor;

  // ── 하의 길이 ──
  String? _selectedBottomLength;

  // ── 인원 목록 ──
  final List<_PersonEntry> _persons = [];

  // ── 팀 정보 ──
  final _teamNameCtrl    = TextEditingController();
  final _managerNameCtrl = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _memoCtrl        = TextEditingController();

  // ── 원단/무게 ──
  String _fabricType   = AppConstants.fabricTypes.first;
  String _fabricWeight = AppConstants.defaultFabricWeight;

  // 스크롤
  final _scrollCtrl = ScrollController();

  // 하의 길이 필요 여부
  bool get _needsBottomLength {
    final p = widget.product;
    return p.category == '하의' ||
        p.subCategory.contains('타이즈') ||
        p.name.contains('타이즈') ||
        p.subCategory.contains('싱글렛') ||
        p.subCategory.contains('세트') ||
        p.category == '세트' ||
        p.isGroupOnly;
  }

  bool get _isBottomProduct {
    final p = widget.product;
    return p.category == '하의' ||
        p.subCategory.contains('타이즈') ||
        p.name.contains('타이즈');
  }

  @override
  void initState() {
    super.initState();
    final colors = widget.product.colors;
    if (colors.isNotEmpty) {
      _selectedColor = colors.first;
    }
    if (_needsBottomLength) {
      _selectedBottomLength = AppConstants.bottomLengths.first['label'];
    }
    _addPerson();
  }

  @override
  void dispose() {
    for (final p in _persons) {
      p.dispose();
    }
    _teamNameCtrl.dispose();
    _managerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _memoCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addPerson() {
    setState(() {
      _persons.add(_PersonEntry(index: _persons.length + 1));
    });
  }

  void _removePerson(int idx) {
    if (_persons.length <= 1) return;
    setState(() {
      _persons[idx].dispose();
      _persons.removeAt(idx);
      for (int i = 0; i < _persons.length; i++) {
        _persons[i].index = i + 1;
      }
    });
  }

  // ── 유효성 검사 ──
  bool _validate() {
    if (_selectedColor == null) {
      _showSnack(loc.selectColorHint);
      return false;
    }
    if (_needsBottomLength && _selectedBottomLength == null) {
      _showSnack(loc.bottomLengthSelectHint);
      return false;
    }
    if (_teamNameCtrl.text.trim().isEmpty) {
      _showSnack(loc.teamNameRequired);
      return false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnack(loc.phoneRequired);
      return false;
    }
    // 10명 이상이면 이름 필수
    if (_persons.length >= 10) {
      final unnamed = _persons.where((p) => p.nameCtrl.text.trim().isEmpty).toList();
      if (unnamed.isNotEmpty) {
        _showSnack(loc.customTenPersonNameRequiredSnackFull(unnamed.length));
        return false;
      }
    }
    return true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF6A1B9A)),
    );
  }

  void _submit() {
    if (!_validate()) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF6A1B9A), size: 24),
            const SizedBox(width: 8),
            Text(loc.orderComplete2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow(loc.productDetail, widget.product.localizedName(_lang)),
            _dialogRow(loc.colorLabel, _selectedColor ?? '-'),
            if (_needsBottomLength)
              _dialogRow(loc.bottomLengthSelect, _selectedBottomLength ?? '-'),
            _dialogRow(loc.personSizeInput, loc.totalPersonCountN(_persons.length)),
            _dialogRow(loc.teamName, _teamNameCtrl.text),
            _dialogRow(loc.managerName, _managerNameCtrl.text.isEmpty ? '-' : _managerNameCtrl.text),
            _dialogRow(loc.contactPhone, _phoneCtrl.text),
            _dialogRow(loc.fabricWeight, _fabricType),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                loc.orderCompleteMsg,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6A1B9A), height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(loc.confirm, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF888888)))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isMobile = !isPcWeb(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(loc.groupOrderFormTitle2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 760),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 선택된 상품 카드 ──
                        _buildSelectedProductCard(),
                        const SizedBox(height: 16),

                        // ── 디자인 이미지 ──
                        _buildDesignImageSection(),

                        // ── 색상 선택 ──
                        _buildSectionCard(
                          title: loc.colorSelect2,
                          child: _buildColorSection(),
                        ),
                        const SizedBox(height: 16),

                        // ── 원단 / 무게 ──
                        _buildSectionCard(
                          title: loc.fabricWeight,
                          child: _buildFabricSection(),
                        ),
                        const SizedBox(height: 16),

                        // ── 하의 길이 선택 ──
                        if (_needsBottomLength) ...[
                          _buildSectionCard(
                            title: loc.bottomLengthSelect,
                            subtitle: loc.bottomLengthNote,
                            child: _buildBottomLengthSection(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── 인원별 사이즈 입력 ──
                        _buildSectionCard(
                          title: loc.personSizeInput,
                          subtitle: loc.personSizeInputNote,
                          child: _buildPersonListSection(),
                        ),
                        const SizedBox(height: 16),

                        // ── 팀 기본 정보 ──
                        _buildSectionCard(
                          title: loc.teamInfoSection,
                          child: _buildTeamInfoSection(),
                        ),
                        const SizedBox(height: 16),

                        // ── 메모 ──
                        _buildSectionCard(
                          title: loc.memoSection,
                          child: _buildMemoSection(),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 하단 제출 바 ──
          _buildSubmitBar(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 선택 상품 카드
  // ══════════════════════════════════════════════════════════════
  Widget _buildSelectedProductCard() {
    final p = widget.product;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: p.images.isNotEmpty
                ? Image.network(
                    p.images.first,
                    width: 80, height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80, height: 80,
                      color: const Color(0xFFF0F0F0),
                      child: const Icon(Icons.checkroom_rounded, color: Color(0xFFCCCCCC), size: 32),
                    ),
                  )
                : Container(
                    width: 80, height: 80,
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(Icons.checkroom_rounded, color: Color(0xFFCCCCCC), size: 32),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 태그
                Row(
                  children: [
                    _tag(loc.groupCustomTag, const Color(0xFF6A1B9A)),
                    const SizedBox(width: 6),
                    if (p.subCategory.isNotEmpty) _tag(p.subCategory, const Color(0xFF1565C0)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(p.price.toInt())}${loc.customPricePerPerson}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6A1B9A)),
                ),
                if (p.material.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(p.material, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: c.withValues(alpha: 0.3))),
    child: Text(t, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w700)),
  );

  // ══════════════════════════════════════════════════════════════
  // 섹션 카드 래퍼
  // ══════════════════════════════════════════════════════════════
  Widget _buildSectionCard({required String title, String? subtitle, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 색상 선택
  // ══════════════════════════════════════════════════════════════
  Widget _buildColorSection() {
    final colors = widget.product.colors;
    if (colors.isEmpty) {
      return Text(loc.customNoColorInfo, style: const TextStyle(color: Color(0xFF888888)));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((c) {
        final selected = _selectedColor == c;
        final colorHex = AppConstants.colorOptions[c];
        final colorVal = colorHex != null ? Color(colorHex) : const Color(0xFF888888);
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF6A1B9A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? const Color(0xFF6A1B9A) : const Color(0xFFDDDDDD),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: colorVal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2)],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  c,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 원단 / 무게
  // ══════════════════════════════════════════════════════════════
  Widget _buildFabricSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.customFabricType, style: const TextStyle(fontSize: 12, color: Color(0xFF555555), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: AppConstants.fabricTypes.map((f) {
            final sel = _fabricType == f;
            final extra = AppConstants.fabricTypePrices[f] ?? 0;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _fabricType = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFF3E5F5) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? const Color(0xFF6A1B9A) : const Color(0xFFDDDDDD), width: sel ? 2 : 1),
                  ),
                  child: Column(
                    children: [
                      Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? const Color(0xFF6A1B9A) : const Color(0xFF333333))),
                      if (extra > 0) Text('+${_fmt(extra)}${loc.wonUnit}', style: const TextStyle(fontSize: 10, color: Color(0xFFE53935))),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text(loc.customFabricWeightLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF555555), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: AppConstants.fabricWeights.map((w) {
            final sel = _fabricWeight == w;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _fabricWeight = w),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFF3E5F5) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? const Color(0xFF6A1B9A) : const Color(0xFFDDDDDD), width: sel ? 2 : 1),
                  ),
                  child: Center(
                    child: Text(w, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? const Color(0xFF6A1B9A) : const Color(0xFF333333))),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 하의 길이 선택
  // ══════════════════════════════════════════════════════════════
  Widget _buildBottomLengthSection() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.bottomLengths.map((bl) {
            final label = bl['label']!;
            final desc  = bl['desc']!;
            final sel   = _selectedBottomLength == label;
            return GestureDetector(
              onTap: () => setState(() => _selectedBottomLength = label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF6A1B9A) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? const Color(0xFF6A1B9A) : const Color(0xFFDDDDDD), width: sel ? 2 : 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                    Text(desc, style: TextStyle(fontSize: 10, color: sel ? Colors.white70 : const Color(0xFF888888))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
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
                  loc.lengthApplyAllDesc,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6A1B9A), height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 인원별 사이즈 입력
  // ══════════════════════════════════════════════════════════════
  Widget _buildPersonListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 하의 길이 안내 배너 (하의 상품일 경우)
        if (_needsBottomLength) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF388E3C).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.customBottomLengthInfo,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 인원 수 요약
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(loc.totalPersonCountN(_persons.length), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addPerson,
              icon: const Icon(Icons.person_add_rounded, size: 16, color: Color(0xFF6A1B9A)),
              label: Text(loc.customAddPerson, style: const TextStyle(color: Color(0xFF6A1B9A), fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 10명 이상 이름 필수 안내
        if (_persons.length >= 10) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFE65100)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.customTenPersonNameRequired,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 사이즈 표 안내
        if (_isBottomProduct) ...[
          _buildSizeReferenceTable(),
          const SizedBox(height: 12),
        ],

        // 인원 카드 목록
        ...List.generate(_persons.length, (i) => _PersonRowWidget(
          key: ValueKey('person_$i'),
          entry: _persons[i],
          onRemove: _persons.length > 1 ? () => _removePerson(i) : null,
          isBottomProduct: _isBottomProduct,
          availableSizes: widget.product.sizes,
          nameRequired: _persons.length >= 10,
          totalCount: _persons.length,
        )),

        const SizedBox(height: 10),
        // 인원 추가 버튼 (하단)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addPerson,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF6A1B9A)),
            label: Text(loc.customAddPersonBtn, style: const TextStyle(color: Color(0xFF6A1B9A), fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6A1B9A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // 하의 사이즈 참고표
  Widget _buildSizeReferenceTable() {
    final headers = [loc.customSizeTableHeader, loc.customSizeTableWaist, loc.customSizeTableHip, loc.customSizeTableThigh];
    const rows = [
      ['XS',  '60~64',  '82~86',  '47~50'],
      ['S',   '64~68',  '86~90',  '50~53'],
      ['M',   '68~72',  '90~94',  '53~56'],
      ['L',   '72~76',  '94~98',  '56~59'],
      ['XL',  '76~80',  '98~102', '59~62'],
      ['XXL', '80~86',  '102~108','62~66'],
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF4A148C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: headers.map((h) => Expanded(
                child: Text(h, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              )).toList(),
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final even = e.key % 2 == 0;
            return Container(
              color: even ? Colors.white : const Color(0xFFFAFAFA),
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: e.value.map((cell) => Expanded(
                  child: Text(cell, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF333333))),
                )).toList(),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF3E5F5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 4),
                Expanded(child: Text(loc.customNoSizeMeasureHint, style: const TextStyle(fontSize: 11, color: Color(0xFF6A1B9A)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 팀 정보
  // ══════════════════════════════════════════════════════════════
  Widget _buildTeamInfoSection() {
    return Column(
      children: [
        _inputField(loc.teamNameFieldLabel, _teamNameCtrl, hint: '예: 서울마라톤클럽'),
        const SizedBox(height: 10),
        _inputField(loc.managerNameFieldLabel, _managerNameCtrl, hint: '예: 홍길동'),
        const SizedBox(height: 10),
        _inputField(loc.phoneFieldLabel, _phoneCtrl, hint: '010-0000-0000', type: TextInputType.phone),
        const SizedBox(height: 10),
        _inputField(loc.emailQuotationLabel, _emailCtrl, hint: 'example@email.com', type: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildMemoSection() {
    return TextField(
      controller: _memoCtrl,
      maxLines: 4,
      decoration: InputDecoration(
         hintText: loc.customOrderMemoHint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2)),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {String? hint, TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF444444))),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 하단 제출 바
  // ══════════════════════════════════════════════════════════════
  Widget _buildSubmitBar() {
    final total = _persons.length;
    final unitPrice = widget.product.price.toInt();
    final subtotal = unitPrice * total;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x15000000), blurRadius: 12, offset: Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$total${loc.groupFormPersonUnit} × ${_fmt(unitPrice)}${loc.wonUnit}', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                Text('${_fmt(subtotal)}${loc.wonUnit}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(loc.customSubmitBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ══════════════════════════════════════════════════════════════
  // 디자인 이미지 섹션 (확대 가능)
  // ══════════════════════════════════════════════════════════════
  Widget _buildDesignImageSection() {
    final imgs = widget.product.sectionImages['design'] ?? [];
    if (imgs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: '디자인 이미지',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '상품 디자인 참고 이미지입니다. 이미지를 탭하면 확대됩니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imgs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    return GestureDetector(
                      onTap: () => _showDesignLightbox(imgs, i),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imgs[i],
                              width: 110, height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 110, height: 110,
                                color: const Color(0xFFEEEEEE),
                                child: const Icon(Icons.broken_image_outlined,
                                    color: Color(0xFFAAAAAA)),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 5, bottom: 5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Icon(Icons.zoom_in_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showDesignLightbox(List<String> imgs, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (_) => _DesignLightboxDialog(images: imgs, initialIndex: initialIndex),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 인원 데이터 모델
// ══════════════════════════════════════════════════════════════
class _PersonEntry {
  int index;
  String? selectedTopSize;      // 상의 사이즈
  String? selectedBottomSize;   // 하의 사이즈
  String gender;                // '남' | '여'
  bool useBodyMeasure;
  final TextEditingController nameCtrl   = TextEditingController();
  final TextEditingController memoCtrl   = TextEditingController(); // 특이사항
  final TextEditingController heightCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController chestCtrl  = TextEditingController(); // 가슴둘레
  final TextEditingController waistCtrl  = TextEditingController();
  final TextEditingController hipCtrl    = TextEditingController(); // 엉덩이둘레
  final TextEditingController thighCtrl  = TextEditingController();

  _PersonEntry({required this.index})
      : gender = '남',
        useBodyMeasure = false;

  void dispose() {
    nameCtrl.dispose();
    memoCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    chestCtrl.dispose();
    waistCtrl.dispose();
    hipCtrl.dispose();
    thighCtrl.dispose();
  }
}

// ══════════════════════════════════════════════════════════════
// 인원 행 위젯 (상세 입력)
// ══════════════════════════════════════════════════════════════
class _PersonRowWidget extends StatefulWidget {
  final _PersonEntry entry;
  final VoidCallback? onRemove;
  final bool isBottomProduct;
  final List<String> availableSizes;
  final bool nameRequired;    // 10명 이상이면 true
  final int totalCount;       // 전체 인원 수

  const _PersonRowWidget({
    super.key,
    required this.entry,
    this.onRemove,
    required this.isBottomProduct,
    required this.availableSizes,
    this.nameRequired = false,
    this.totalCount = 1,
  });

  @override
  State<_PersonRowWidget> createState() => _PersonRowWidgetState();
}

class _PersonRowWidgetState extends State<_PersonRowWidget> {
  // 실측 입력 확장 여부
  bool _showMeasure = false;
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isMale    = e.gender == loc.genderMale;
    final accent    = isMale ? const Color(0xFF1565C0) : const Color(0xFFAD1457);
    final bgLight   = isMale ? const Color(0xFFF0F4FF) : const Color(0xFFFFF0F5);
    final headerBg  = isMale ? const Color(0xFF1565C0) : const Color(0xFFAD1457);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ━━━ 헤더 바 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                // 번호 뱃지
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${e.index}',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                // 이름 필드 (10명 이상이면 필수 표시)
                Expanded(
                  child: TextField(
                    controller: e.nameCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: widget.nameRequired ? loc.customNameRequiredHint : loc.customNameOptionalHint,
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 성별 토글
                _genderToggle(e),
                if (widget.onRemove != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ━━━ 바디 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── 섹션 1: 사이즈 선택 ──────────────────────
                _sectionLabel(Icons.straighten_rounded, loc.customSizeSectionLabel, accent),
                const SizedBox(height: 10),

                if (widget.isBottomProduct) ...[
                  // 하의 상품: 하의 사이즈 칩
                  _sizeChipRow(
                    label: loc.groupFormBottomSizeLabel,
                    sizes: widget.availableSizes,
                    selected: e.selectedBottomSize,
                    accent: accent,
                    onSelect: (s) => setState(() => e.selectedBottomSize = s),
                  ),
                ] else ...[
                  // 상의/세트: 상의 + 하의 사이즈 모두
                  _sizeChipRow(
                    label: loc.groupFormTopSizeLabel,
                    sizes: widget.availableSizes,
                    selected: e.selectedTopSize,
                    accent: accent,
                    onSelect: (s) => setState(() => e.selectedTopSize = s),
                  ),
                  const SizedBox(height: 10),
                  _sizeChipRow(
                    label: loc.groupFormBottomSizeLabel,
                    sizes: widget.availableSizes,
                    selected: e.selectedBottomSize,
                    accent: accent,
                    onSelect: (s) => setState(() => e.selectedBottomSize = s),
                  ),
                ],

                const SizedBox(height: 16),
                Divider(height: 1, color: accent.withValues(alpha: 0.12)),
                const SizedBox(height: 12),

                // ── 섹션 2: 실측 치수 (사이즈표에 없을 경우만) ──
                GestureDetector(
                  onTap: () => setState(() => _showMeasure = !_showMeasure),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _showMeasure ? accent.withValues(alpha: 0.08) : bgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _showMeasure ? accent.withValues(alpha: 0.4) : accent.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.accessibility_new_rounded,
                          size: 16,
                          color: _showMeasure ? accent : accent.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.customMeasureInputTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _showMeasure ? accent : const Color(0xFF555555),
                                ),
                              ),
                              Text(
                                loc.customMeasureInputDesc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _showMeasure ? accent.withValues(alpha: 0.7) : const Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _showMeasure ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 20,
                          color: accent.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showMeasure) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        // 키 / 몸무게
                        Row(
                          children: [
                            Expanded(child: _measureField(loc.customHeightLabel, e.heightCtrl, 'cm', Icons.height_rounded, accent, bgLight)),
                            const SizedBox(width: 8),
                            Expanded(child: _measureField(loc.customWeightLabel, e.weightCtrl, 'kg', Icons.monitor_weight_outlined, accent, bgLight)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 가슴 / 허리
                        Row(
                          children: [
                            Expanded(child: _measureField(loc.chestLabel, e.chestCtrl, 'cm', Icons.favorite_border_rounded, accent, bgLight)),
                            const SizedBox(width: 8),
                            Expanded(child: _measureField(loc.waistLabel, e.waistCtrl, 'cm', Icons.straighten_rounded, accent, bgLight)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 엉덩이 / 허벅지
                        Row(
                          children: [
                            Expanded(child: _measureField(loc.hipLabel, e.hipCtrl, 'cm', Icons.crop_rounded, accent, bgLight)),
                            const SizedBox(width: 8),
                            Expanded(child: _measureField(loc.customThighLabel, e.thighCtrl, 'cm', Icons.accessibility_new_rounded, accent, bgLight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Divider(height: 1, color: accent.withValues(alpha: 0.12)),
                const SizedBox(height: 14),

                // ── 섹션 3: 특이사항 / 요청 ──────────────────────
                _sectionLabel(Icons.edit_note_rounded, loc.specialRequestLabel, accent),
                const SizedBox(height: 8),
                TextField(
                  controller: e.memoCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: loc.customOrderPersonMemoHint,
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                    filled: true,
                    fillColor: bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accent.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accent.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 성별 토글 ──
  Widget _genderToggle(_PersonEntry e) {
    // 내부 데이터 값은 '남'/'여' 고정 (언어 독립적)
    final genderValues = [loc.genderMale, loc.genderFemale];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: genderValues.map((g) {
        final sel = e.gender == g;
        final isMale = g == loc.genderMale;
        final color = isMale ? const Color(0xFF1565C0) : const Color(0xFFAD1457);
        return GestureDetector(
          onTap: () => setState(() => e.gender = g),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isMale ? loc.customMaleLabel : loc.customFemaleLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: sel ? color : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 섹션 라벨 ──
  Widget _sectionLabel(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  // ── 사이즈 칩 행 ──
  Widget _sizeChipRow({
    required String label,
    required List<String> sizes,
    required String? selected,
    required Color accent,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: sizes.map((sz) {
            final sel = selected == sz;
            return GestureDetector(
              onTap: () => onSelect(sz),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? accent : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel ? accent : const Color(0xFFDDDDDD),
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Text(
                  sz,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: sel ? Colors.white : const Color(0xFF444444),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 실측 필드 ──
  Widget _measureField(
    String label,
    TextEditingController ctrl,
    String unit,
    IconData icon,
    Color accent,
    Color bgColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: accent.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent.withValues(alpha: 0.8))),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '-',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
            suffixText: unit,
            suffixStyle: TextStyle(fontSize: 11, color: accent.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
            filled: true,
            fillColor: bgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 디자인 이미지 라이트박스 다이얼로그
// ══════════════════════════════════════════════════════════════
class _DesignLightboxDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _DesignLightboxDialog({required this.images, required this.initialIndex});
  @override
  State<_DesignLightboxDialog> createState() => _DesignLightboxDialogState();
}

class _DesignLightboxDialogState extends State<_DesignLightboxDialog> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: Image.network(
                    widget.images[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54, size: 60),
                  ),
                ),
              ),
            ),
            // 닫기 버튼
            Positioned(
              top: 48, right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
            // 인덱스 표시
            if (widget.images.length > 1)
              Positioned(
                bottom: 32, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _current == i ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _current == i ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
