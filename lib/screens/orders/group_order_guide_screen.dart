import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'group_order_form_screen.dart';
import '../../widgets/pc_layout.dart';

class GroupOrderGuideScreen extends StatefulWidget {
  final ProductModel? product;
  const GroupOrderGuideScreen({super.key, this.product});

  @override
  State<GroupOrderGuideScreen> createState() => _GroupOrderGuideScreenState();
}

class _GroupOrderGuideScreenState extends State<GroupOrderGuideScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  late TabController _tab;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return _buildMobileLayout(context);
  }

  // ── 모바일 레이아웃 ──
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.watch<LanguageProvider>().loc.groupOrderGuideAppBar, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: TabBar(
              controller: _tab,
              labelColor: const Color(0xFF6A1B9A),
              unselectedLabelColor: const Color(0xFF888888),
              indicatorColor: const Color(0xFF6A1B9A),
              indicatorWeight: 3,
              tabs: [
                Tab(text: loc.groupOrderGuideTabOrder),
                Tab(text: loc.groupOrderGuideTabForm),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildGuideTab(context),
                _buildFormTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PC 레이아웃 ──
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(context.watch<LanguageProvider>().loc.groupOrderGuideAppBar, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 좌측: 탭 안내 콘텐츠 ──
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                        ),
                        child: TabBar(
                          controller: _tab,
                          labelColor: const Color(0xFF6A1B9A),
                          unselectedLabelColor: const Color(0xFF888888),
                          indicatorColor: const Color(0xFF6A1B9A),
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: '주문 안내'),
                            Tab(text: '주문 양식'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            _buildGuideTab(context),
                            _buildFormTab(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // ── 우측: 주문 패널 ──
                SizedBox(
                  width: 300,
                  child: _buildPcOrderPanel(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── PC 우측 주문 패널 ──
  Widget _buildPcOrderPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideHeroTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideHeroSub,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(context.watch<LanguageProvider>().loc.groupOrderGuideDiscountTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _pcBenefitRow(context, '✅', '5↑', loc.groupOrderGuideQtyRule5, const Color(0xFF1565C0)),
          _pcBenefitRow(context, '🏷️', '10↑', loc.groupOrderGuideQtyRule10, const Color(0xFF2E7D32)),
          _pcBenefitRow(context, '🏆', '30↑', loc.groupOrderBenefit3, const Color(0xFFFF6B35)),
          _pcBenefitRow(context, '🥇', '50↑', loc.groupOrderBenefit4, const Color(0xFF6A1B9A)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // 동의 체크
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _agreed ? const Color(0xFFF3E5F5) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _agreed ? const Color(0xFF6A1B9A).withValues(alpha: 0.4) : const Color(0xFFDDDDDD),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    checkColor: Colors.white,
                    fillColor: WidgetStateProperty.resolveWith<Color>((states) =>
                        states.contains(WidgetState.selected)
                            ? const Color(0xFF6A1B9A)
                            : Colors.transparent),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(context.watch<LanguageProvider>().loc.groupOrderAgreementCheck,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _agreed
                  ? () => _tab.animateTo(1)
                  : null,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(context.watch<LanguageProvider>().loc.groupOrderGuideWriteBtn,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _agreed ? const Color(0xFF6A1B9A) : const Color(0xFFCCCCCC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                disabledForegroundColor: Colors.white70,
              ),
            ),
          ),
          if (!_agreed) ...[
            const SizedBox(height: 8),
            Text(context.watch<LanguageProvider>().loc.groupOrderGuideCheckFirst,
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _pcBenefitRow(BuildContext context, String emoji, String label, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // 탭1: 주문 안내
  // ═══════════════════════════════════════════════════
  Widget _buildGuideTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택된 상품 카드
          if (widget.product != null) ...[
            _buildProductCard(widget.product!),
            const SizedBox(height: 20),
          ],

          // 단체 주문 안내
          _SectionHeader(icon: Icons.info_outline,
              iconColor: const Color(0xFF1565C0),
              iconBg: const Color(0xFFE3F2FD),
              title: loc.groupOrderGuideAppBar),
          const SizedBox(height: 12),

          // 최소 수량
          _InfoCard(
            iconData: Icons.group_outlined,
            iconBg: const Color(0xFFEDE7F6),
            iconColor: const Color(0xFF6A1B9A),
            title: loc.groupOrderMinQtyTitle,
            content: loc.groupOrderMinQtyDesc,
          ),
          const SizedBox(height: 10),

          // 제작 기간
          _InfoCard(
            iconData: Icons.schedule_outlined,
            iconBg: const Color(0xFFF3E5F5),
            iconColor: const Color(0xFF7B1FA2),
            title: context.watch<LanguageProvider>().loc.groupOrderProductionPeriod,
            content: context.watch<LanguageProvider>().loc.groupOrderProductionPeriodDesc,
          ),
          const SizedBox(height: 10),

          // 배송 안내
          _InfoCard(
            iconData: Icons.local_shipping_outlined,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
            title: loc.groupOrderShippingTitle,
            contentWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideShipping1,
                    style: const TextStyle(fontSize: 13, height: 1.6)),
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideShipping2,
                    style: const TextStyle(fontSize: 13, height: 1.6)),
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideShipping3,
                    style: const TextStyle(fontSize: 13, height: 1.6)),
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideShipping4,
                    style: const TextStyle(fontSize: 13, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 커스텀 옵션 (스크린샷 방식: 4가지 카드)
          _SectionHeader2('💰', loc.groupOrderCustomOptionTitle),
          const SizedBox(height: 12),
          _buildCustomOptionCards(),
          const SizedBox(height: 16),

          // 허리밴드 옵션
          _SectionHeader2('⚡', loc.groupOrderGuideWaistbandTitle),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.groupOrderGuideWaistband1,
                    style: const TextStyle(fontSize: 13, height: 1.7)),
                Text(loc.groupOrderGuideWaistband2,
                    style: const TextStyle(fontSize: 13, height: 1.7)),
                const SizedBox(height: 4),
                Text(loc.groupOrderGuideWaistband3,
                    style: const TextStyle(fontSize: 13, height: 1.7, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 디자인 파일 안내
          _SectionHeader2('📎', loc.groupOrderGuideDesignFileTitle),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.groupOrderGuideDesignFile1,
                    style: const TextStyle(fontSize: 13, height: 1.7)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFF1565C0)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(loc.groupOrderGuideDesignFile2,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 인쇄 타입
          _SectionHeader2('🖨️', loc.groupOrderPrintTypeTitle),
          const SizedBox(height: 12),
          _buildPrintTypeCards(),
          const SizedBox(height: 24),

          // 디자인 독점 사용 옵션
          _SectionHeader2('🔒', loc.groupOrderExclusiveTitle),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCE93D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(loc.groupOrderGuideExclusiveTitle,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.6)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(loc.groupOrderGuideExclusive1,
                    style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF555555))),
                Text(loc.groupOrderGuideExclusive2,
                    style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF555555))),
                Text(loc.groupOrderGuideExclusive3,
                    style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF888888))),
              ],
            ),
          );}),
          const SizedBox(height: 24),

          // 수량별 할인 (스크린샷: 30개 10%, 50개 20%, 100개 별도협의)
          _SectionHeader2('🏷️', loc.groupOrderGuideDiscountTitle),
          const SizedBox(height: 12),
          _buildDiscountTable(),
          const SizedBox(height: 16),

          // 추가 주문 안내
          _SectionHeader2('➕', loc.groupOrderGuideAdditionalTitle),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCE93D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.groupOrderGuideAdditional1,
                    style: const TextStyle(fontSize: 13, height: 1.7)),
                Text(loc.groupOrderGuideAdditional2,
                    style: const TextStyle(fontSize: 13, height: 1.7)),
                Text(loc.groupOrderGuideAdditional3,
                    style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF880E4F))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 사이즈 안내
          _SectionHeader2('📏', loc.groupOrderSizeGuideTitle),
          const SizedBox(height: 12),
          _buildAdultSizeTable(context),
          const SizedBox(height: 16),
          _buildJuniorSizeTable(context),
          const SizedBox(height: 16),

          // 원하는 사이즈 없을 경우
          Builder(builder: (context) {
            return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.swap_vert, size: 20, color: Color(0xFF1565C0)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.groupOrderGuideNoSizeHint,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1565C0))),
                      const SizedBox(height: 6),
                      Text(
                        loc.groupOrderGuideNoSizeDesc,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );}),
          const SizedBox(height: 24),

          // 주문 절차 (스크린샷에서 확인된 5단계)
          _SectionHeader2('🔄', '주문 절차'),
          const SizedBox(height: 12),
          _buildOrderSteps(),
          const SizedBox(height: 24),

          // 교환·환불 정책
          _SectionHeader2('⚠️', context.watch<LanguageProvider>().loc.groupOrderGuideExchangeTitle),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDE7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Builder(builder: (context) {
              return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.groupOrderGuideExchange1,
                    style: const TextStyle(fontSize: 13, height: 1.7)),
                Text(loc.groupOrderGuideExchange2,
                    style: const TextStyle(fontSize: 13, height: 1.7)),
              ],
            );}),
          ),
          const SizedBox(height: 24),

          // 동의 + 주문 양식 이동
          _AgreementSection(
            agreed: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            onNext: _agreed ? () => _tab.animateTo(1) : null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // 탭2: 주문 양식
  // ═══════════════════════════════════════════════════
  Widget _buildFormTab(BuildContext context) {
    if (!_agreed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outlined, size: 64, color: Color(0xFFCCCCCC)),
              const SizedBox(height: 16),
              Text(
                context.watch<LanguageProvider>().loc.groupOrderGuideLockedMsg,
                style: const TextStyle(fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tab.animateTo(0),
                icon: const Icon(Icons.info_outline, size: 16),
                label: Text(context.watch<LanguageProvider>().loc.groupOrderGuideViewOrderGuide),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 동의 완료 → 실제 GroupOrderFormScreen으로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupOrderFormScreen(product: widget.product),
          ),
        ).then((_) {
          // 돌아왔을 때 탭을 다시 0으로
          if (mounted) {
            _tab.animateTo(0);
            setState(() => _agreed = false);
          }
        });
      }
    });

    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
    );
  }

  // ── 선택 상품 카드 ──
  Widget _buildProductCard(ProductModel product) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: 72, height: 72, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _productPlaceholder())
                : _productPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.localizedName(_lang),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('₩${product.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} / 1개',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6A1B9A))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildTag(context.watch<LanguageProvider>().loc.setProduct, const Color(0xFF1565C0)),
                    _buildTag(context.watch<LanguageProvider>().loc.groupOrderOnlyLabel, const Color(0xFF6A1B9A)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      width: 72, height: 72,
      color: const Color(0xFFF5F5F5),
      child: const Icon(Icons.checkroom, color: Color(0xFFBBBBBB)),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  // ── 커스텀 옵션 카드 (스크린샷 방식) ──
  Widget _buildCustomOptionCards() {
    final options = [
      {
        'icon': '🎨',
        'title': '팀 로고/마킹 추가 (5장 이상)',
        'desc': '팀 로고 파일 첨부 필수 (AI/PDF/PNG)',
        'badge': '무료',
        'badgeColor': const Color(0xFF1565C0),
        'badgeBg': const Color(0xFFE3F2FD),
      },
      {
        'icon': '🖌️',
        'title': '색상 변경',
        'desc': '원하는 색상으로 제작 가능',
        'badge': '무료',
        'badgeColor': const Color(0xFF2E7D32),
        'badgeBg': const Color(0xFFE8F5E9),
      },
      {
        'icon': '👗',
        'title': '허리밴드 색상 변경',
        'desc': '하의 허리밴드 색상 추가 변경 (형태 변경 불가)',
        'badge': '+5만원',
        'badgeColor': const Color(0xFF6A1B9A),
        'badgeBg': const Color(0xFFF3E5F5),
      },
    ];

    return Column(
      children: options.map((opt) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Text(opt['icon'] as String, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(opt['title'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(opt['desc'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (opt['badgeBg'] as Color),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(opt['badge'] as String,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900,
                      color: opt['badgeColor'] as Color)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // ── 수량별 할인 테이블 ──
  Widget _buildDiscountTable() {
    final rows = [
      {'qty': '30개 이상', 'discount': '10% 할인', 'color': const Color(0xFF1565C0)},
      {'qty': '50개 이상', 'discount': '20% 할인', 'color': const Color(0xFF6A1B9A)},
      {'qty': '100개 이상', 'discount': '별도 협의', 'color': const Color(0xFFC62828)},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.discount_rounded, size: 16, color: Color(0xFFE65100)),
            const SizedBox(width: 6),
            const Text('대량 주문 할인', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFE65100))),
          ]),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: r['color'] as Color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('${r['qty']}: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              Text(r['discount'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: r['color'] as Color)),
            ]),
          )),
        ],
      ),
    );
  }

  // ── 인쇄 타입 카드 (4가지 옵션) ──
  Widget _buildPrintTypeCards() {
    final types = [
      {'step': '①', 'title': '색상변경 (단체명 변경안함)', 'cond': '5장↑ 무료', 'color': const Color(0xFF1565C0), 'desc': '상의·하의 동일 색상으로 변경'},
      {'step': '②', 'title': '단체명변경(전면) (색상변경안함)', 'cond': '5장↑ 무료', 'color': const Color(0xFF2E7D32), 'desc': '앞면 팀/단체명 인쇄'},
      {'step': '③', 'title': '단체명변경(전면) + 색상변경', 'cond': '5장↑ 무료', 'color': const Color(0xFF6A1B9A), 'desc': '단체명 + 상하의 동일 색상 변경'},
      {'step': '④', 'title': '단체명+색상+이름변경(후면)', 'cond': '10장↑', 'color': const Color(0xFFC62828), 'desc': '전면 단체명+색상 + 후면 개인 이름 인쇄'},
    ];

    return Column(
      children: types.map((t) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (t['color'] as Color).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (t['color'] as Color).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: t['color'] as Color, shape: BoxShape.circle),
              child: Center(child: Text(t['step'] as String,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t['title'] as String,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t['color'] as Color)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (t['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(t['cond'] as String,
                            style: TextStyle(fontSize: 10, color: t['color'] as Color, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(t['desc'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // ── 주문 절차 5단계 ──
  Widget _buildOrderSteps() {
    final steps = [
      {'num': '1', 'title': '주문 서식 작성', 'desc': '수량·사이즈·색상·로고를 입력하고 양식을 제출', 'color': const Color(0xFF1565C0)},
      {'num': '2', 'title': '결제 완료', 'desc': '담당자 확인 후 결제 안내 및 입금 확인', 'color': const Color(0xFF1565C0)},
      {'num': '3', 'title': '디자인 확정', 'desc': '시안 검토 및 최종 디자인 확인', 'color': const Color(0xFF1565C0)},
      {'num': '4', 'title': '제작 진행', 'desc': '14~21영업일 소요 (디자인 변경 포함 시 추가 기간 가능)', 'color': const Color(0xFF1565C0)},
      {'num': '5', 'title': '배송', 'desc': '완성 후 일괄 발송, 배송 추적 번호 카카오 알림 발송', 'color': const Color(0xFF1565C0)},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isLast = i == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: step['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(step['num'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 32, color: const Color(0xFFDDDDDD)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step['title'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(step['desc'] as String,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.4)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── 성인 사이즈표 ──
  Widget _buildAdultSizeTable(BuildContext context) {
    final rows = [
      ['XS', '80~84', '60~64', '84~88', '155~160'],
      ['S', '84~88', '64~68', '88~92', '160~165'],
      ['M', '88~92', '68~72', '92~96', '165~170'],
      ['L', '92~96', '72~76', '96~100', '170~175'],
      ['XL', '96~100', '76~80', '100~104', '175~180'],
      ['XXL', '100~104', '80~84', '104~108', '180~185'],
      ['XXXL', '104~108', '84~88', '108~112', '185+'],
    ];
    return _SizeTable(title: '${loc.groupOrderGuideSizeAdult} (XS~XXXL)', emoji: '🧑', rows: rows, loc: loc,
        headerColor: const Color(0xFF1565C0), bgColor: const Color(0xFFE3F2FD));
  }

  // ── 주니어 사이즈표 ──
  Widget _buildJuniorSizeTable(BuildContext context) {
    final rows = [
      ['XXS', '68~72', '52~56', '72~76', '120~130'],
      ['XS', '72~76', '56~60', '76~80', '130~140'],
      ['S', '76~80', '60~64', '80~84', '140~150'],
      ['M', '80~84', '64~68', '84~88', '150~155'],
      ['L', '84~88', '68~72', '88~92', '155~165'],
    ];
    return _SizeTable(title: '${loc.groupOrderGuideSizeJunior} (XXS~L)', emoji: '🧒', rows: rows, loc: loc,
        headerColor: const Color(0xFF6A1B9A), bgColor: const Color(0xFFF3E5F5));
  }
}

// ══════════════════════════════════════════════════════════════
// Helper Widgets
// ══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  const _SectionHeader({required this.icon, required this.iconColor, required this.iconBg, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SectionHeader2 extends StatelessWidget {
  final String emoji;
  final String title;
  const _SectionHeader2(this.emoji, this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData iconData;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? content;
  final Widget? contentWidget;
  const _InfoCard({
    required this.iconData,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.content,
    this.contentWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(iconData, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: iconColor)),
                const SizedBox(height: 4),
                if (content != null)
                  Text(content!, style: const TextStyle(fontSize: 13, height: 1.5))
                else
                  contentWidget ?? const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementSection extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onNext;
  const _AgreementSection({required this.agreed, required this.onChanged, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onChanged(!agreed),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: agreed ? const Color(0xFFF3E5F5) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: agreed ? const Color(0xFF6A1B9A).withValues(alpha: 0.4) : const Color(0xFFDDDDDD),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: agreed,
                  onChanged: onChanged,
                  checkColor: Colors.white,
                  fillColor: WidgetStateProperty.resolveWith<Color>((states) =>
                      states.contains(WidgetState.selected)
                          ? const Color(0xFF6A1B9A)
                          : Colors.transparent),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(context.watch<LanguageProvider>().loc.groupOrderGuideAgreeAll,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(context.watch<LanguageProvider>().loc.groupOrderGuideWriteBtn,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: agreed ? const Color(0xFF6A1B9A) : const Color(0xFFCCCCCC),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: const Color(0xFFCCCCCC),
              disabledForegroundColor: Colors.white70,
            ),
          ),
        ),
        if (!agreed) ...[
          const SizedBox(height: 8),
          Text(context.watch<LanguageProvider>().loc.groupOrderGuideCheckFirst,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _SizeTable extends StatelessWidget {
  final String title;
  final String emoji;
  final List<List<String>> rows;
  final Color headerColor;
  final Color bgColor;
  final AppLocalizations? loc;
  const _SizeTable({
    required this.title,
    required this.emoji,
    required this.rows,
    required this.headerColor,
    required this.bgColor,
    this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final l = loc ?? context.watch<LanguageProvider>().loc;
    final headers = [l.sizeLabel, '${l.chestLabel}(cm)', '${l.waistLabel}(cm)', '${l.hipLabel}(cm)', '${l.heightLabel}(cm)'];
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: headerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: headerColor)),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(headerColor.withValues(alpha: 0.1)),
              headingRowHeight: 36,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 32,
              columnSpacing: 16,
              columns: headers.map((h) => DataColumn(
                label: Text(h, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: headerColor)),
              )).toList(),
              rows: rows.map((r) => DataRow(
                cells: r.map((c) => DataCell(
                  Text(c, style: const TextStyle(fontSize: 12)),
                )).toList(),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
