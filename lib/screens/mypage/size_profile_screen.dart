import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/size_profile_service.dart';

const Color _purple = Color(0xFF6A1B9A);
const Color _purpleLight = Color(0xFFF3E5F5);

// ── 성인 사이즈 옵션 ─────────────────────────────────────
const List<String> _adultSizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
const List<String> _juniorSizes = ['XXS(80)', 'XS(90)', 'S(100)', 'M(110)', 'L(120)', 'XL(130)'];

// ── 성인 사이즈표 데이터 ─────────────────────────────────
const List<List<String>> _adultSizeRows = [
  ['XS',  '154~159', '44~51',  '85', '68'],
  ['S',   '160~165', '52~60',  '90', '72'],
  ['M',   '166~172', '61~71',  '95', '76'],
  ['L',   '172~177', '72~78',  '100','80'],
  ['XL',  '177~182', '79~85',  '105','84'],
  ['2XL', '182~187', '86~91',  '110','88'],
  ['3XL', '187~191', '91~96',  '115','92'],
];
const List<List<String>> _juniorSizeRows = [
  ['XXS(80)', '104~116', '16~20', '58', '55'],
  ['XS(90)',  '116~128', '20~25', '63', '58'],
  ['S(100)',  '128~140', '25~32', '68', '62'],
  ['M(110)',  '140~152', '32~40', '73', '65'],
  ['L(120)',  '152~158', '40~48', '78', '68'],
  ['XL(130)', '158~165', '48~55', '83', '72'],
];

class SizeProfileScreen extends StatelessWidget {
  const SizeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FB),
      appBar: AppBar(
        title: const Text('내 사이즈 관리',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _SizeProfileBody(user: user),
      floatingActionButton: Consumer<SizeProfileProvider>(
        builder: (ctx, prov, _) {
          final canAdd = prov.profiles.length < SizeProfileService.maxProfiles;
          return FloatingActionButton.extended(
            onPressed: canAdd
                ? () => _openEditSheet(ctx, user, null)
                : () => ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('최대 ${SizeProfileService.maxProfiles}개까지 저장 가능합니다.')),
                    ),
            backgroundColor: canAdd ? _purple : Colors.grey,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('새 사이즈 추가',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          );
        },
      ),
    );
  }
}

class _SizeProfileBody extends StatelessWidget {
  final UserModel user;
  const _SizeProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return Consumer<SizeProfileProvider>(
      builder: (ctx, prov, _) {
        if (prov.loading) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        if (prov.profiles.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.straighten_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('저장된 사이즈 프로필이 없습니다.',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('+ 버튼을 눌러 나의 사이즈를 저장해 보세요.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: prov.profiles.length,
          itemBuilder: (ctx, i) => _ProfileCard(profile: prov.profiles[i], user: user),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final SizeProfile profile;
  final UserModel user;
  const _ProfileCard({required this.profile, required this.user});

  @override
  Widget build(BuildContext context) {
    final isMale = profile.gender == 'male';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: isMale ? Colors.blue.shade50 : Colors.pink.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: isMale ? Colors.blue : Colors.pink, borderRadius: BorderRadius.circular(20)),
              child: Text(profile.genderLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(profile.profileName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: _purple, size: 20),
              onPressed: () => _openEditSheet(context, user, profile),
              tooltip: '수정', padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
              onPressed: () => _confirmDelete(context),
              tooltip: '삭제', padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _infoRow('사이즈 구분', profile.sizeType),
            _infoRow('상의 사이즈', profile.topSize),
            _infoRow('하의 사이즈', profile.bottomSize),
            if (profile.height.isNotEmpty) _infoRow('키', '${profile.height} cm'),
            if (profile.weight.isNotEmpty) _infoRow('몸무게', '${profile.weight} kg'),
            if (profile.waist.isNotEmpty) _infoRow('허리', '${profile.waist} cm'),
            if (profile.thigh.isNotEmpty) _infoRow('허벅지', '${profile.thigh} cm'),
          ]),
        ),
      ]),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 80,
        child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
    ]),
  );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로필 삭제', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('"${profile.profileName}" 프로필을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await context.read<SizeProfileProvider>().deleteProfile(user.id, profile.id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── 편집 바텀시트 ────────────────────────────────────────
void _openEditSheet(BuildContext context, UserModel user, SizeProfile? existing) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditSheet(user: user, existing: existing),
  );
}

class _EditSheet extends StatefulWidget {
  final UserModel user;
  final SizeProfile? existing;
  const _EditSheet({required this.user, this.existing});
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  final _nameCtrl   = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _waistCtrl  = TextEditingController();
  final _thighCtrl  = TextEditingController();

  String  _gender     = 'male';
  String  _sizeType   = '성인';
  String? _topSize;
  String? _bottomSize;
  bool    _saving     = false;
  bool    _tableExpanded = false;

  List<String> get _sizeOptions => _sizeType == '성인' ? _adultSizes : _juniorSizes;
  List<List<String>> get _tableRows => _sizeType == '성인' ? _adultSizeRows : _juniorSizeRows;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameCtrl.text   = e.profileName;
      _heightCtrl.text = e.height;
      _weightCtrl.text = e.weight;
      _waistCtrl.text  = e.waist;
      _thighCtrl.text  = e.thigh;
      _gender   = e.gender;
      _sizeType = e.sizeType;
      _topSize    = e.topSize.isNotEmpty ? e.topSize : null;
      _bottomSize = e.bottomSize.isNotEmpty ? e.bottomSize : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _heightCtrl.dispose();
    _weightCtrl.dispose(); _waistCtrl.dispose(); _thighCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 핸들
            Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(widget.existing == null ? '새 사이즈 프로필 추가' : '사이즈 프로필 수정',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 16),

            // 프로필 이름
            _field('프로필 이름', '예) 내 기본 사이즈, 겨울 오버핏', _nameCtrl),
            const SizedBox(height: 12),

            // 성별
            _label('성별'),
            Row(children: [
              _genderBtn('남성', 'male', Colors.blue),
              const SizedBox(width: 8),
              _genderBtn('여성', 'female', Colors.pink),
            ]),
            const SizedBox(height: 12),

            // 사이즈 구분
            _label('사이즈 구분'),
            Row(children: [
              _typeBtn('성인'),
              const SizedBox(width: 8),
              _typeBtn('주니어'),
            ]),
            const SizedBox(height: 14),

            // ── 사이즈표 (접기/펴기) ──
            _buildSizeTableToggle(),
            const SizedBox(height: 14),

            // 상의 사이즈 선택
            _label('상의 사이즈 *'),
            _buildSizeSelector(_topSize, (v) => setState(() => _topSize = v)),
            const SizedBox(height: 12),

            // 하의 사이즈 선택
            _label('하의 사이즈 *'),
            _buildSizeSelector(_bottomSize, (v) => setState(() => _bottomSize = v)),
            const SizedBox(height: 14),

            // 상세 치수 (선택 - 하의 기준)
            Container(
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
                  Text('상세 치수 (선택)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange.shade800)),
                  const SizedBox(width: 4),
                  Text('사이즈 미해당 시 입력',
                      style: TextStyle(fontSize: 10, color: Colors.orange.shade500)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _compactField('키 (cm)', _heightCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _compactField('몸무게 (kg)', _weightCtrl)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _compactField('허리 (cm)', _waistCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _compactField('허벅지 (cm)', _thighCtrl)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('저장하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── 사이즈표 토글 ────────────────────────────────────
  Widget _buildSizeTableToggle() {
    final headers = ['사이즈', '키(cm)', '몸무게(kg)', '가슴(cm)', '허리(cm)'];
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _tableExpanded = !_tableExpanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _tableExpanded ? _purple.withValues(alpha: 0.07) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _tableExpanded ? _purple.withValues(alpha: 0.3) : Colors.grey.shade200),
          ),
          child: Row(children: [
            Icon(Icons.table_chart_outlined, size: 15,
                color: _tableExpanded ? _purple : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text('사이즈 참고표',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _tableExpanded ? _purple : Colors.grey.shade600)),
            const Spacer(),
            Icon(_tableExpanded ? Icons.expand_less : Icons.expand_more, size: 18,
                color: _tableExpanded ? _purple : Colors.grey.shade400),
          ]),
        ),
      ),
      if (_tableExpanded) ...[
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
                    child: Text(h, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _purple)),
                  )).toList(),
                ),
                ..._tableRows.map((r) => TableRow(
                  children: r.map((cell) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(cell, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                  )).toList(),
                )),
              ],
            ),
          ),
        ),
      ],
    ]);
  }

  // ── 사이즈 선택 버튼 그리드 ────────────────────────────
  Widget _buildSizeSelector(String? selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _sizeOptions.map((size) {
        final isSelected = selected == size;
        return GestureDetector(
          onTap: () => onSelect(size),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _purple : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? _purple : Colors.grey.shade300, width: isSelected ? 2 : 1),
            ),
            child: Text(size,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.grey.shade600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
  );

  Widget _field(String label, String hint, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true, fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _purple, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _compactField(String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _purple, width: 1.5)),
      ),
    );
  }

  Widget _genderBtn(String label, String value, Color color) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey.shade500)),
      ),
    );
  }

  Widget _typeBtn(String label) {
    final selected = _sizeType == label;
    return GestureDetector(
      onTap: () => setState(() {
        _sizeType = label;
        _topSize = null;
        _bottomSize = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _purple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _purple : Colors.grey.shade300, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey.shade500)),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 이름을 입력해 주세요.')));
      return;
    }
    if (_topSize == null || _bottomSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('상의/하의 사이즈를 선택해 주세요.')));
      return;
    }
    setState(() => _saving = true);
    final profile = SizeProfile(
      id: widget.existing?.id ?? '',
      userId: widget.user.id,
      profileName: name,
      gender: _gender,
      sizeType: _sizeType,
      topSize: _topSize!,
      bottomSize: _bottomSize!,
      height: _heightCtrl.text.trim(),
      weight: _weightCtrl.text.trim(),
      waist: _waistCtrl.text.trim(),
      thigh: _thighCtrl.text.trim(),
    );
    final err = await context.read<SizeProfileProvider>().saveProfile(widget.user.id, profile);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('사이즈 프로필이 저장되었습니다.'),
        backgroundColor: _purple,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
