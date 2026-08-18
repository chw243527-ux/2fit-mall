// admin_coupon_tab.dart — 관리자 쿠폰 관리 탭
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../services/wishlist_coupon_service.dart';
import '../../utils/theme.dart';

class AdminCouponTab extends StatelessWidget {
  const AdminCouponTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminCouponTabBody();
  }
}

class _AdminCouponTabBody extends StatefulWidget {
  const _AdminCouponTabBody();

  @override
  State<_AdminCouponTabBody> createState() => _AdminCouponTabBodyState();
}

class _AdminCouponTabBodyState extends State<_AdminCouponTabBody> {
  String _filter = '전체'; // 전체 / 유효 / 만료

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilterBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── 헤더 ────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_activity_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('쿠폰 관리',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton.icon(
            onPressed: () => _showCouponDialog(context, null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('쿠폰 추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 필터 바 ──────────────────────────────────────────
  Widget _buildFilterBar() {
    final filters = ['전체', '유효', '만료'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final sel = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: sel,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: sel ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              onSelected: (_) => setState(() => _filter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 쿠폰 목록 ────────────────────────────────────────
  Widget _buildList() {
    return StreamBuilder<List<CouponModel>>(
      stream: CouponService.watchAdminCoupons(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data ?? [];
        final filtered = all.where((c) {
          if (_filter == '유효') return c.isValid;
          if (_filter == '만료') return !c.isValid;
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_activity_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  _filter == '전체' ? '등록된 쿠폰이 없습니다.\n쿠폰 추가 버튼으로 첫 쿠폰을 만들어보세요.' : '해당 쿠폰이 없습니다.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) => _CouponCard(
            coupon: filtered[i],
            fmtDate: _fmtDate,
            fmt: _fmt,
            onEdit: () => _showCouponDialog(context, filtered[i]),
            onDelete: () => _confirmDelete(context, filtered[i]),
          ),
        );
      },
    );
  }

  // ── 삭제 확인 ────────────────────────────────────────
  Future<void> _confirmDelete(BuildContext context, CouponModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('쿠폰 삭제'),
        content: Text('「${c.name}」(${c.code}) 쿠폰을 삭제하시겠습니까?\n이미 적용한 사용자의 쿠폰은 영향을 받지 않습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = await CouponService.deleteCoupon(c.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err.isEmpty ? '쿠폰이 삭제되었습니다.' : err),
      backgroundColor: err.isEmpty ? const Color(0xFF43A047) : Colors.red,
    ));
  }

  // ── 쿠폰 추가/수정 다이얼로그 ────────────────────────
  Future<void> _showCouponDialog(BuildContext context, CouponModel? existing) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CouponFormDialog(existing: existing),
    );
  }
}

// ══════════════════════════════════════════════════════
// 쿠폰 카드
// ══════════════════════════════════════════════════════
class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final String Function(DateTime) fmtDate;
  final String Function(double) fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CouponCard({
    required this.coupon,
    required this.fmtDate,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final valid = coupon.isValid;
    final typeColor = coupon.type == CouponType.percent
        ? const Color(0xFF1565C0)
        : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: valid ? const Color(0xFFE8E8E8) : const Color(0xFFEEEEEE),
        ),
        boxShadow: valid
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]
            : [],
      ),
      child: Opacity(
        opacity: valid ? 1.0 : 0.55,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── 타입 배지 ──
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      coupon.type == CouponType.percent
                          ? Icons.percent_rounded
                          : Icons.attach_money_rounded,
                      color: typeColor,
                      size: 22,
                    ),
                    Text(
                      coupon.type == CouponType.percent ? '%' : '₩',
                      style: TextStyle(
                          fontSize: 10, color: typeColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── 정보 ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(coupon.name,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        // 다운로드 쿠폰 배지
                        if (coupon.isDownloadable) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download_rounded,
                                    size: 10, color: Color(0xFF7B1FA2)),
                                const SizedBox(width: 3),
                                Text(
                                  coupon.downloadLimit != null
                                      ? '${coupon.downloadCount}/${coupon.downloadLimit}'
                                      : '다운로드',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF7B1FA2),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: valid
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            valid ? '유효' : '만료',
                            style: TextStyle(
                              fontSize: 11,
                              color: valid
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 코드 + 복사 버튼
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: coupon.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('코드가 복사되었습니다.'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              coupon.code,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded,
                              size: 13, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 할인 정보
                    Text(
                      coupon.type == CouponType.percent
                          ? '${coupon.value.toInt()}% 할인'
                              '${coupon.maxDiscountAmount != null ? ' (최대 ${fmt(coupon.maxDiscountAmount!)}원)' : ''}'
                          : '${fmt(coupon.value)}원 할인',
                      style: TextStyle(
                          fontSize: 13,
                          color: typeColor,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '최소 ${coupon.minOrderAmount > 0 ? '${fmt(coupon.minOrderAmount)}원' : '제한없음'}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 11, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          coupon.startsAt != null
                              ? '${fmtDate(coupon.startsAt!)} ~ ${fmtDate(coupon.expiresAt)}'
                              : '~ ${fmtDate(coupon.expiresAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: valid ? Colors.grey : Colors.red[300],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── 액션 버튼 ──
              Column(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    color: const Color(0xFF1565C0),
                    tooltip: '수정',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: Colors.red,
                    tooltip: '삭제',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// 쿠폰 추가 / 수정 다이얼로그
// ══════════════════════════════════════════════════════
class _CouponFormDialog extends StatefulWidget {
  final CouponModel? existing;
  const _CouponFormDialog({this.existing});

  @override
  State<_CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<_CouponFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _limitCtrl;
  late CouponType _type;
  DateTime? _startsAt;   // null = 즉시 시작
  late DateTime _expiresAt;
  bool _saving = false;
  bool _isDownloadable = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _valueCtrl = TextEditingController(
        text: e != null ? e.value.toInt().toString() : '');
    _minCtrl = TextEditingController(
        text: e != null && e.minOrderAmount > 0
            ? e.minOrderAmount.toInt().toString()
            : '');
    _maxCtrl = TextEditingController(
        text: e?.maxDiscountAmount != null
            ? e!.maxDiscountAmount!.toInt().toString()
            : '');
    _type = e?.type ?? CouponType.fixed;
    _startsAt = e?.startsAt;
    _expiresAt = e?.expiresAt ?? DateTime.now().add(const Duration(days: 30));
    _isDownloadable = e?.isDownloadable ?? false;
    _limitCtrl = TextEditingController(
        text: e?.downloadLimit != null ? e!.downloadLimit.toString() : '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _limitCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: _expiresAt,
    );
    if (picked != null) setState(() => _startsAt = picked);
  }

  Future<void> _pickExpireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: _startsAt ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final value = double.tryParse(_valueCtrl.text.trim()) ?? 0;
    final min = double.tryParse(_minCtrl.text.trim()) ?? 0;
    final max = _type == CouponType.percent && _maxCtrl.text.trim().isNotEmpty
        ? double.tryParse(_maxCtrl.text.trim())
        : null;
    final limit = _isDownloadable && _limitCtrl.text.trim().isNotEmpty
        ? int.tryParse(_limitCtrl.text.trim())
        : null;

    String err;
    if (isEdit) {
      err = await CouponService.updateCoupon(
        couponId: widget.existing!.id,
        name: _nameCtrl.text,
        type: _type,
        value: value,
        minOrderAmount: min,
        maxDiscountAmount: max,
        startsAt: _startsAt,
        expiresAt: _expiresAt,
        isDownloadable: _isDownloadable,
        downloadLimit: limit,
      );
    } else {
      err = await CouponService.createCoupon(
        code: _codeCtrl.text,
        name: _nameCtrl.text,
        type: _type,
        value: value,
        minOrderAmount: min,
        maxDiscountAmount: max,
        startsAt: _startsAt,
        expiresAt: _expiresAt,
        isDownloadable: _isDownloadable,
        downloadLimit: limit,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (err.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit ? '쿠폰이 수정되었습니다.' : '쿠폰이 추가되었습니다.'),
        backgroundColor: const Color(0xFF43A047),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          EdgeInsets.symmetric(horizontal: isWide ? 80 : 16, vertical: 24),
      child: Container(
        width: isWide ? 520 : double.infinity,
        constraints: const BoxConstraints(maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 타이틀 ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_activity_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(isEdit ? '쿠폰 수정' : '쿠폰 추가',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // ── 폼 ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 쿠폰 코드 (수정 시 비활성)
                      _label('쿠폰 코드 *'),
                      TextFormField(
                        controller: _codeCtrl,
                        readOnly: isEdit,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'SUMMER2024',
                          filled: isEdit,
                          fillColor: isEdit ? const Color(0xFFF5F5F5) : null,
                          suffixIcon: isEdit
                              ? const Tooltip(
                                  message: '코드는 수정할 수 없습니다.',
                                  child: Icon(Icons.lock_outline_rounded,
                                      size: 16),
                                )
                              : null,
                        ),
                        validator: (v) {
                          if (!isEdit &&
                              (v == null || v.trim().isEmpty)) {
                            return '코드를 입력하세요';
                          }
                          if (!isEdit &&
                              !RegExp(r'^[A-Z0-9_\-]+$')
                                  .hasMatch(v!.toUpperCase().trim())) {
                            return '영문·숫자·_·- 만 사용 가능합니다';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // 쿠폰 이름
                      _label('쿠폰 이름 *'),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                            hintText: '여름 시즌 10% 할인'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '이름을 입력하세요' : null,
                      ),
                      const SizedBox(height: 14),
                      // 할인 유형 선택
                      _label('할인 유형 *'),
                      Row(
                        children: [
                          _TypeChip(
                            label: '고정 금액',
                            icon: Icons.attach_money_rounded,
                            selected: _type == CouponType.fixed,
                            onTap: () =>
                                setState(() => _type = CouponType.fixed),
                          ),
                          const SizedBox(width: 10),
                          _TypeChip(
                            label: '퍼센트',
                            icon: Icons.percent_rounded,
                            selected: _type == CouponType.percent,
                            onTap: () =>
                                setState(() => _type = CouponType.percent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // 할인 값
                      _label(_type == CouponType.fixed
                          ? '할인 금액 (원) *'
                          : '할인률 (%) *'),
                      TextFormField(
                        controller: _valueCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          hintText: _type == CouponType.fixed
                              ? '예) 3000'
                              : '예) 10',
                          suffixText: _type == CouponType.fixed ? '원' : '%',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '값을 입력하세요';
                          final n = double.tryParse(v.trim());
                          if (n == null || n <= 0) return '0보다 큰 값을 입력하세요';
                          if (_type == CouponType.percent && n > 100) {
                            return '100% 이하로 입력하세요';
                          }
                          return null;
                        },
                      ),
                      // 최대 할인 (퍼센트 전용)
                      if (_type == CouponType.percent) ...[
                        const SizedBox(height: 14),
                        _label('최대 할인 금액 (원, 선택)'),
                        TextFormField(
                          controller: _maxCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            hintText: '예) 5000 (미입력 시 제한 없음)',
                            suffixText: '원',
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // 최소 주문금액
                      _label('최소 주문 금액 (원, 선택)'),
                      TextFormField(
                        controller: _minCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          hintText: '예) 30000 (미입력 시 제한 없음)',
                          suffixText: '원',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── 다운로드 쿠폰 토글 ──
                      Container(
                        decoration: BoxDecoration(
                          color: _isDownloadable
                              ? const Color(0xFFF3E5F5)
                              : const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isDownloadable
                                ? const Color(0xFF9C27B0)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 2),
                          title: Row(
                            children: [
                              Icon(
                                Icons.download_rounded,
                                size: 16,
                                color: _isDownloadable
                                    ? const Color(0xFF9C27B0)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '다운로드 쿠폰',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _isDownloadable
                                      ? const Color(0xFF9C27B0)
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '홈 화면 팝업에서 사용자가 직접 다운로드',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                          value: _isDownloadable,
                          activeColor: const Color(0xFF9C27B0),
                          onChanged: (v) =>
                              setState(() => _isDownloadable = v),
                        ),
                      ),
                      // 다운로드 수 제한
                      if (_isDownloadable) ...[
                        const SizedBox(height: 10),
                        _label('최대 다운로드 수 (선택)'),
                        TextFormField(
                          controller: _limitCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            hintText: '예) 100 (미입력 시 무제한)',
                            suffixText: '명',
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // ── 기간 설정 ──
                      _label('쿠폰 사용 기간 *'),
                      Row(
                        children: [
                          // 시작일
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickStartDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _startsAt != null
                                        ? AppColors.primary
                                        : const Color(0xFFBDBDBD),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('시작일',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500])),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.play_arrow_rounded,
                                            size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          _startsAt != null
                                              ? _fmtDate(_startsAt!)
                                              : '즉시',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _startsAt != null
                                                ? AppColors.primary
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('~',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                          ),
                          // 만료일
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickExpireDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFFBDBDBD)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('만료일',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500])),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.stop_rounded,
                                            size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          _fmtDate(_expiresAt),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 시작일 초기화 버튼
                      if (_startsAt != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _startsAt = null),
                            icon: const Icon(Icons.close_rounded, size: 13),
                            label: const Text('시작일 제거 (즉시 활성)',
                                style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // ── 버튼 ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? '수정 완료' : '쿠폰 추가'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555))),
      );
}

// 할인 유형 선택 칩
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFBDBDBD),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
