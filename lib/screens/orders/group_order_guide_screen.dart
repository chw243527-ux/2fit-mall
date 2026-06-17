import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/net_image.dart';
import '../../widgets/pc_layout.dart';
import '../../utils/navigation_helper.dart';
import 'group_order_form_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GroupOrderGuideScreen
// 상품 상세에서 "단체주문하기" 클릭 시 표시되는 단체주문 안내 페이지
// - 모바일: 전체 화면 스크롤
// - PC: 좌측(안내) + 우측(주문 패널) 2열 레이아웃
// ─────────────────────────────────────────────────────────────────────────────
class GroupOrderGuideScreen extends StatefulWidget {
  final ProductModel? product;
  const GroupOrderGuideScreen({super.key, this.product});

  @override
  State<GroupOrderGuideScreen> createState() => _GroupOrderGuideScreenState();
}

class _GroupOrderGuideScreenState extends State<GroupOrderGuideScreen> {
  bool _agreed = false;

  // ── 탑텐 블랙 스타일 상수 ──────────────────────────────────
  static const _kBlack    = Color(0xFF000000);
  static const _kBg       = Color(0xFFF8F8F8);
  static const _kDivider  = Color(0xFFE8E8E8);
  static const _kGrey1    = Color(0xFF1A1A1A);
  static const _kGrey4    = Color(0xFF444444);
  static const _kGrey6    = Color(0xFF666666);
  static const _kGrey8    = Color(0xFF888888);

  AppLocalizations get _loc => context.read<LanguageProvider>().loc;
  AppLanguage      get _lang => context.read<LanguageProvider>().language;

  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout();
    return _buildMobileLayout();
  }

  // ══════════════════════════════════════════════════════════════
  // 모바일 레이아웃
  // ══════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBackOrHome(context);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(fontSize: 15),
        // ListView를 body 직속으로 — Scaffold가 bounded height를 자동 부여
        body: _buildGuideList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PC 레이아웃
  // ══════════════════════════════════════════════════════════════
  Widget _buildPcLayout() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBackOrHome(context);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(fontSize: 16),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측: 안내 콘텐츠
                  Expanded(
                    flex: 7,
                    child: Container(
                      color: Colors.white,
                      height: MediaQuery.of(context).size.height - 48 - 48,
                      child: _buildGuideList(),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // 우측: 주문 패널
                  SizedBox(width: 300, child: _buildOrderPanel()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar({required double fontSize}) {
    return AppBar(
      backgroundColor: _kBlack,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 48,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
        onPressed: () => goBackOrHome(context),
      ),
      title: Consumer<LanguageProvider>(
        builder: (_, lp, __) => Text(
          lp.loc.groupOrderGuideAppBar,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 안내 콘텐츠 ListView
  // ══════════════════════════════════════════════════════════════
  Widget _buildGuideList() {
    final loc = _loc;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 선택 상품 카드 ───────────────────────────────────────
        if (widget.product != null) ...[
          _productCard(widget.product!),
          const SizedBox(height: 24),
        ],

        // ── 최소 수량 ────────────────────────────────────────────
        _sectionHeader(Icons.groups_outlined, '최소 수량'),
        const SizedBox(height: 8),
        _infoBox('단체 커스텀 제작은 최소 5명부터 가능합니다.'),
        const SizedBox(height: 20),

        // ── 제작 기간 ────────────────────────────────────────────
        _sectionHeader(Icons.schedule_outlined, loc.groupOrderProductionPeriod),
        const SizedBox(height: 8),
        _infoBox(loc.groupOrderProductionPeriodDesc),
        const SizedBox(height: 20),

        // ── 배송 안내 ────────────────────────────────────────────
        _sectionHeader(Icons.local_shipping_outlined, loc.groupOrderGuideShippingTitle),
        const SizedBox(height: 8),
        _infoLines([
          loc.groupOrderGuideShipping1,
          loc.groupOrderGuideShipping2,
          loc.groupOrderGuideShipping3,
          loc.groupOrderGuideShipping4,
        ]),
        const SizedBox(height: 20),

        // ── 커스텀 옵션 ──────────────────────────────────────────
        _sectionHeader(Icons.palette_outlined, loc.groupOrderGuideCustomTitle),
        const SizedBox(height: 8),
        _infoLines([
          loc.groupOrderGuideWaistband1,
          loc.groupOrderGuideWaistband2,
          loc.groupOrderGuideWaistband3,
        ]),
        const SizedBox(height: 20),

        // ── 독점 사용권 ──────────────────────────────────────────
        _sectionHeader(Icons.lock_outline_rounded, loc.groupOrderGuideExclusiveTitle),
        const SizedBox(height: 8),
        _exclusiveBox(loc),
        const SizedBox(height: 20),

        // ── 수량 할인 ────────────────────────────────────────────
        _sectionHeader(Icons.local_offer_outlined, loc.groupOrderGuideDiscountTitle),
        const SizedBox(height: 8),
        _infoLines([
          loc.groupOrderGuideDiscount1,
          loc.groupOrderGuideDiscount2,
          loc.groupOrderGuideDiscount3,
        ]),
        const SizedBox(height: 20),

        // ── 추가 주문 안내 ───────────────────────────────────────
        _sectionHeader(Icons.add_circle_outline, loc.groupOrderGuideAdditionalTitle),
        const SizedBox(height: 8),
        _infoLines([
          loc.groupOrderGuideAdditional1,
          loc.groupOrderGuideAdditional2,
          loc.groupOrderGuideAdditional3,
        ]),
        const SizedBox(height: 20),

        // ── 교환·환불 ────────────────────────────────────────────
        _sectionHeader(Icons.swap_horiz_outlined, loc.groupOrderGuideExchangeTitle),
        const SizedBox(height: 8),
        _infoLines([
          loc.groupOrderExchange1,
          loc.groupOrderExchange2,
        ]),
        const SizedBox(height: 32),

        // ── 동의 + 주문 버튼 (모바일 전용) ──────────────────────
        if (!isPcWeb(context)) _agreementSection(loc),

        const SizedBox(height: 24),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PC 우측 주문 패널
  // ══════════════════════════════════════════════════════════════
  Widget _buildOrderPanel() {
    final loc = _loc;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _kBlack,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Consumer<LanguageProvider>(
                  builder: (_, lp, __) => Text(
                    lp.loc.groupOrderGuideHeroTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<LanguageProvider>(
                  builder: (_, lp, __) => Text(
                    lp.loc.groupOrderGuideHeroSub,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: _kDivider),
          const SizedBox(height: 16),

          // 동의 체크
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _agreed ? const Color(0xFFF0F0F0) : const Color(0xFFF8F8F8),
                border: Border.all(
                  color: _agreed ? _kBlack : const Color(0xFFDDDDDD),
                  width: _agreed ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    checkColor: Colors.white,
                    fillColor: WidgetStateProperty.resolveWith<Color>((s) =>
                        s.contains(WidgetState.selected) ? _kBlack : Colors.transparent),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFF888888)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Consumer<LanguageProvider>(
                      builder: (_, lp, __) => Text(
                        lp.loc.groupOrderGuideAgreeAll,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _agreed ? _kBlack : _kGrey4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 주문 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _agreed
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => GroupOrderFormScreen(product: widget.product)))
                  : null,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Consumer<LanguageProvider>(
                builder: (_, lp, __) => Text(
                  lp.loc.groupOrderGuideWriteBtn,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _agreed ? _kBlack : const Color(0xFFCCCCCC),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                disabledForegroundColor: Colors.white70,
              ),
            ),
          ),
          if (!_agreed) ...[
            const SizedBox(height: 8),
            Consumer<LanguageProvider>(
              builder: (_, lp, __) => Text(
                lp.loc.groupOrderGuideCheckFirst,
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 공용 UI 부품
  // ══════════════════════════════════════════════════════════════

  // 섹션 헤더 (아이콘 + 제목)
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          color: _kBlack,
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kGrey1),
        ),
      ],
    );
  }

  // 단순 텍스트 박스
  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kDivider),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.6, color: _kGrey4)),
    );
  }

  // 목록 라인
  Widget _infoLines(List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l, style: const TextStyle(fontSize: 13, height: 1.6, color: _kGrey4)),
                ))
            .toList(),
      ),
    );
  }

  // 독점 사용권 박스 (강조 스타일)
  Widget _exclusiveBox(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(loc.groupOrderGuideExclusiveTitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kGrey1)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: _kBlack,
                child: const Text('FREE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(loc.groupOrderGuideExclusive1,
              style: const TextStyle(fontSize: 12, height: 1.7, color: _kGrey4)),
          const SizedBox(height: 4),
          Text(loc.groupOrderGuideExclusive2,
              style: const TextStyle(fontSize: 12, height: 1.7, color: _kGrey4)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(left: BorderSide(color: _kBlack, width: 3)),
            ),
            child: Text(loc.groupOrderGuideExclusive3,
                style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF333333), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // 모바일 동의 + 버튼 섹션
  Widget _agreementSection(AppLocalizations loc) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _agreed = !_agreed),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _agreed ? const Color(0xFFF0F0F0) : const Color(0xFFF8F8F8),
              border: Border.all(
                color: _agreed ? _kBlack : const Color(0xFFDDDDDD),
                width: _agreed ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  checkColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith<Color>((s) =>
                      s.contains(WidgetState.selected) ? _kBlack : Colors.transparent),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Color(0xFF888888)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.groupOrderGuideAgreeAll,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _agreed ? _kGrey1 : _kGrey4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _agreed
                ? () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => GroupOrderFormScreen(product: widget.product)))
                : null,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              loc.groupOrderGuideWriteBtn,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _agreed ? _kBlack : const Color(0xFFCCCCCC),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: const RoundedRectangleBorder(),
              elevation: 0,
              disabledBackgroundColor: const Color(0xFFCCCCCC),
              disabledForegroundColor: Colors.white70,
            ),
          ),
        ),
        if (!_agreed) ...[
          const SizedBox(height: 8),
          Text(
            loc.groupOrderGuideCheckFirst,
            style: const TextStyle(fontSize: 12, color: _kGrey8),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // 상품 카드
  Widget _productCard(ProductModel product) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : '';
    final price = product.price.toInt();
    final priceStr = price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? NetImage(imageUrl, width: 72, height: 72, fit: BoxFit.cover)
                : Container(
                    width: 72, height: 72,
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
                  product.localizedName(_lang),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '₩$priceStr / 1개',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kGrey1),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    _tag(_loc.setProduct),
                    _tag(_loc.groupOrderOnlyLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: _kBlack),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: _kBlack, fontWeight: FontWeight.w600)),
    );
  }
}
