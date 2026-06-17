import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/net_image.dart';
import '../../utils/navigation_helper.dart';
import 'group_order_form_screen.dart';

// ═══════════════════════════════════════════════════════════════
// GroupOrderGuideScreen — 단체주문 안내 화면
// ═══════════════════════════════════════════════════════════════
class GroupOrderGuideScreen extends StatefulWidget {
  final ProductModel? product;
  const GroupOrderGuideScreen({super.key, this.product});

  @override
  State<GroupOrderGuideScreen> createState() => _GroupOrderGuideScreenState();
}

class _GroupOrderGuideScreenState extends State<GroupOrderGuideScreen> {
  bool _agreed = false;

  static const _kBlack = Color(0xFF1A1A1A);
  static const _kBg    = Color(0xFFF8F8F8);

  @override
  Widget build(BuildContext context) {
    final lp   = context.watch<LanguageProvider>();
    final loc  = lp.loc;
    final lang = lp.language;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        title: Text(
          loc.groupOrderGuideAppBar,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: _GuideBody(
        product: widget.product,
        loc: loc,
        lang: lang,
        agreed: _agreed,
        onAgreedChanged: (v) => setState(() => _agreed = v),
        onSubmit: _agreed
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        GroupOrderFormScreen(product: widget.product)))
            : null,
      ),
    );
  }
}

// ─── _GuideBody ───────────────────────────────────────────────
class _GuideBody extends StatelessWidget {
  final ProductModel? product;
  final AppLocalizations loc;
  final AppLanguage lang;
  final bool agreed;
  final ValueChanged<bool> onAgreedChanged;
  final VoidCallback? onSubmit;

  const _GuideBody({
    required this.product,
    required this.loc,
    required this.lang,
    required this.agreed,
    required this.onAgreedChanged,
    required this.onSubmit,
  });

  static const _kBlack = Color(0xFF1A1A1A);
  static const _kBorder = Color(0xFFE8E8E8);
  static const _kGrey4  = Color(0xFF444444);
  static const _kGrey8  = Color(0xFF888888);
  static const _kBg     = Color(0xFFF8F8F8);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: _buildItems(),
    );
  }

  List<Widget> _buildItems() {
    return [
      // ── 상품 카드 ─────────────────────────────────────────
      if (product != null) ...[
        _ProductCard(product: product!, lang: lang, loc: loc),
        const SizedBox(height: 20),
      ],

      // ── 최소 수량 ─────────────────────────────────────────
      _SectionRow(icon: Icons.groups_outlined, title: '최소 수량'),
      const SizedBox(height: 8),
      _InfoBox(text: '단체 커스텀 제작은 최소 5명부터 가능합니다.'),
      const SizedBox(height: 20),

      // ── 제작 기간 ─────────────────────────────────────────
      _SectionRow(icon: Icons.schedule_outlined, title: loc.groupOrderProductionPeriod),
      const SizedBox(height: 8),
      _InfoBox(text: loc.groupOrderProductionPeriodDesc),
      const SizedBox(height: 20),

      // ── 배송 안내 ─────────────────────────────────────────
      _SectionRow(icon: Icons.local_shipping_outlined, title: loc.groupOrderGuideShippingTitle),
      const SizedBox(height: 8),
      _InfoLines(lines: [
        loc.groupOrderGuideShipping1,
        loc.groupOrderGuideShipping2,
        loc.groupOrderGuideShipping3,
        loc.groupOrderGuideShipping4,
      ]),
      const SizedBox(height: 20),

      // ── 커스텀 옵션 ───────────────────────────────────────
      _SectionRow(icon: Icons.palette_outlined, title: loc.groupOrderGuideCustomTitle),
      const SizedBox(height: 8),
      _InfoLines(lines: [
        loc.groupOrderGuideWaistband1,
        loc.groupOrderGuideWaistband2,
        loc.groupOrderGuideWaistband3,
      ]),
      const SizedBox(height: 20),

      // ── 독점 사용권 ───────────────────────────────────────
      _SectionRow(icon: Icons.lock_outline_rounded, title: loc.groupOrderGuideExclusiveTitle),
      const SizedBox(height: 8),
      _ExclusiveBox(loc: loc),
      const SizedBox(height: 20),

      // ── 수량 할인 ─────────────────────────────────────────
      _SectionRow(icon: Icons.local_offer_outlined, title: loc.groupOrderGuideDiscountTitle),
      const SizedBox(height: 8),
      _InfoLines(lines: [
        loc.groupOrderGuideDiscount1,
        loc.groupOrderGuideDiscount2,
        loc.groupOrderGuideDiscount3,
      ]),
      const SizedBox(height: 20),

      // ── 추가 주문 ─────────────────────────────────────────
      _SectionRow(icon: Icons.add_circle_outline, title: loc.groupOrderGuideAdditionalTitle),
      const SizedBox(height: 8),
      _InfoLines(lines: [
        loc.groupOrderGuideAdditional1,
        loc.groupOrderGuideAdditional2,
        loc.groupOrderGuideAdditional3,
      ]),
      const SizedBox(height: 20),

      // ── 교환·환불 ─────────────────────────────────────────
      _SectionRow(icon: Icons.swap_horiz_outlined, title: loc.groupOrderGuideExchangeTitle),
      const SizedBox(height: 8),
      _InfoLines(lines: [loc.groupOrderExchange1, loc.groupOrderExchange2]),
      const SizedBox(height: 32),

      // ── 동의 + 주문 버튼 ──────────────────────────────────
      _AgreementRow(
        agreed: agreed,
        label: loc.groupOrderGuideAgreeAll,
        onChanged: onAgreedChanged,
      ),
      const SizedBox(height: 12),
      _SubmitButton(
        agreed: agreed,
        label: loc.groupOrderGuideWriteBtn,
        onPressed: onSubmit,
      ),
      if (!agreed) ...[
        const SizedBox(height: 8),
        Text(
          loc.groupOrderGuideCheckFirst,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _kGrey8),
        ),
      ],
      const SizedBox(height: 24),
    ];
  }
}

// ─── 개별 UI 컴포넌트 ──────────────────────────────────────────

class _SectionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionRow({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        color: const Color(0xFF1A1A1A),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A)),
        ),
      ),
    ]);
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13, height: 1.6, color: Color(0xFF444444))),
    );
  }
}

class _InfoLines extends StatelessWidget {
  final List<String> lines;
  const _InfoLines({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l,
                      style: const TextStyle(
                          fontSize: 13, height: 1.6, color: Color(0xFF444444))),
                ))
            .toList(),
      ),
    );
  }
}

class _ExclusiveBox extends StatelessWidget {
  final AppLocalizations loc;
  const _ExclusiveBox({required this.loc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(loc.groupOrderGuideExclusiveTitle,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A))),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: const Color(0xFF1A1A1A),
              child: const Text('FREE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(loc.groupOrderGuideExclusive1,
              style: const TextStyle(
                  fontSize: 12, height: 1.7, color: Color(0xFF444444))),
          const SizedBox(height: 4),
          Text(loc.groupOrderGuideExclusive2,
              style: const TextStyle(
                  fontSize: 12, height: 1.7, color: Color(0xFF444444))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(
                  left: BorderSide(color: Color(0xFF1A1A1A), width: 3)),
            ),
            child: Text(loc.groupOrderGuideExclusive3,
                style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  final bool agreed;
  final String label;
  final ValueChanged<bool> onChanged;
  const _AgreementRow(
      {required this.agreed, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!agreed),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: agreed ? const Color(0xFFF0F0F0) : const Color(0xFFF8F8F8),
          border: Border.all(
            color: agreed ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD),
            width: agreed ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Checkbox(
            value: agreed,
            onChanged: (v) => onChanged(v ?? false),
            checkColor: Colors.white,
            fillColor: WidgetStateProperty.resolveWith<Color>((s) =>
                s.contains(WidgetState.selected)
                    ? const Color(0xFF1A1A1A)
                    : Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: const BorderSide(color: Color(0xFF888888)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: agreed
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFF444444))),
          ),
        ]),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool agreed;
  final String label;
  final VoidCallback? onPressed;
  const _SubmitButton(
      {required this.agreed, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              agreed ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC),
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
          elevation: 0,
          disabledBackgroundColor: const Color(0xFFCCCCCC),
          disabledForegroundColor: Colors.white70,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final AppLanguage lang;
  final AppLocalizations loc;
  const _ProductCard(
      {required this.product, required this.lang, required this.loc});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : '';
    final priceStr = product.price
        .toInt()
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isNotEmpty
              ? NetImage(imageUrl, width: 72, height: 72, fit: BoxFit.cover)
              : Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF5F5F5),
                  child: const Icon(Icons.checkroom, color: Color(0xFFBBBBBB)),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.localizedName(lang),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text('₩$priceStr / 1개',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                _tag(loc.setProduct),
                _tag(loc.groupOrderOnlyLabel),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600)),
    );
  }
}
