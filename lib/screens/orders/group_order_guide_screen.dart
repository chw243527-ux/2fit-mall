import 'package:flutter/material.dart';
import '../../widgets/net_image.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'group_order_form_screen.dart';
import '../../widgets/pc_layout.dart';
import '../../utils/navigation_helper.dart';

class GroupOrderGuideScreen extends StatefulWidget {
  final ProductModel? product;
  const GroupOrderGuideScreen({super.key, this.product});

  @override
  State<GroupOrderGuideScreen> createState() => _GroupOrderGuideScreenState();
}

class _GroupOrderGuideScreenState extends State<GroupOrderGuideScreen> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  bool _agreed = false;

  // ── 탑텐 스타일 상수 ──
  static const _black = Color(0xFF000000);
  static const _bg = Color(0xFFF8F8F8);
  static const _dividerColor = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return _buildMobileLayout(context);
  }

  // ── 모바일 레이아웃 ──
  Widget _buildMobileLayout(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) goBackOrHome(context);
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(
            context.watch<LanguageProvider>().loc.groupOrderGuideAppBar,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: _black,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 48,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.of(context).size.height - 48,
              child: _buildGuideTab(context),
            );
          },
        ),
      ),
    );
  }

  // ── PC 레이아웃 ──
  Widget _buildPcLayout(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) goBackOrHome(context);
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(
            context.watch<LanguageProvider>().loc.groupOrderGuideAppBar,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: _black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 좌측: 주문 안내 콘텐츠 ──
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white),
                      // Row 안의 SingleChildScrollView는 명시적 높이 필요
                      height: MediaQuery.of(context).size.height - 48 - 48,
                      child: _buildGuideTab(context),
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
      ),
    );
  }

  // ── PC 우측 주문 패널 ──
  Widget _buildPcOrderPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 배너 — 블랙
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  context.watch<LanguageProvider>().loc.groupOrderGuideHeroTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.watch<LanguageProvider>().loc.groupOrderGuideHeroSub,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: _dividerColor),
          const SizedBox(height: 16),

          // 동의 체크
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _agreed ? const Color(0xFFF0F0F0) : const Color(0xFFF8F8F8),
                border: Border.all(
                  color: _agreed ? _black : const Color(0xFFDDDDDD),
                  width: _agreed ? 1.5 : 1,
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
                            ? _black
                            : Colors.transparent),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFF888888)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.watch<LanguageProvider>().loc.groupOrderAgreementCheck,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _agreed ? _black : const Color(0xFF444444),
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
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _agreed
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupOrderFormScreen(product: widget.product),
                      ),
                    )
                  : null,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                context.watch<LanguageProvider>().loc.groupOrderGuideWriteBtn,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _agreed ? _black : const Color(0xFFCCCCCC),
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
            Text(
              context.watch<LanguageProvider>().loc.groupOrderGuideCheckFirst,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _pcBenefitRow(BuildContext context, String emoji, String label, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _black,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF444444))),
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
            const SizedBox(height: 24),
          ],

          // 단체 주문 안내 헤더
          _SectionHeader(title: loc.groupOrderGuideAppBar),
          const SizedBox(height: 14),

          // 최소 수량
          _InfoCard(
            iconData: Icons.group_outlined,
            title: loc.groupOrderMinQtyTitle,
            content: loc.groupOrderMinQtyDesc,
          ),
          const SizedBox(height: 8),

          // 제작 기간
          _InfoCard(
            iconData: Icons.schedule_outlined,
            title: context.watch<LanguageProvider>().loc.groupOrderProductionPeriod,
            content: context.watch<LanguageProvider>().loc.groupOrderProductionPeriodDesc,
          ),
          const SizedBox(height: 8),

          // 배송 안내
          _InfoCard(
            iconData: Icons.local_shipping_outlined,
            title: loc.groupOrderShippingTitle,
            contentWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideShipping1,
                    style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF333333))),
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideShipping2,
                    style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF333333))),
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideShipping3,
                    style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF333333))),
                Text(context.watch<LanguageProvider>().loc.groupOrderGuideShipping4,
                    style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF333333))),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── 커스텀 옵션 ──
          _SectionHeader2(label: 'CUSTOM OPTION', title: '커스텀 옵션'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF0F0F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _customOptionRow(
                  icon: Icons.palette_outlined,
                  text: loc.groupOrderGuideWaistband1,
                  highlight: true,
                ),
                const SizedBox(height: 10),
                _customOptionRow(
                  icon: Icons.attach_file_outlined,
                  text: loc.groupOrderGuideWaistband2,
                ),
                const SizedBox(height: 10),
                _customOptionRow(
                  icon: Icons.checkroom_outlined,
                  text: loc.groupOrderGuideWaistband3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 디자인 독점 사용 옵션
          _SectionHeader2(label: 'EXCLUSIVE DESIGN', title: loc.groupOrderExclusiveTitle),
          const SizedBox(height: 14),
          Builder(builder: (context) {
            return Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF0F0F0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀 행
                  Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF1A1A1A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.groupOrderGuideExclusiveTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: _black,
                        child: const Text(
                          'FREE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(loc.groupOrderGuideExclusive1,
                      style: const TextStyle(fontSize: 12, height: 1.7, color: Color(0xFF444444))),
                  const SizedBox(height: 4),
                  Text(loc.groupOrderGuideExclusive2,
                      style: const TextStyle(fontSize: 12, height: 1.7, color: Color(0xFF444444))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: _black, width: 3)),
                    ),
                    child: Text(
                      loc.groupOrderGuideExclusive3,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 28),

          // 추가 주문 안내
          _SectionHeader2(label: 'ADDITIONAL ORDER', title: loc.groupOrderGuideAdditionalTitle),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF0F0F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.groupOrderGuideAdditional1,
                    style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF333333))),
                Text(loc.groupOrderGuideAdditional2,
                    style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF333333))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(left: BorderSide(color: const Color(0xFFC62828), width: 3)),
                  ),
                  child: Text(
                    loc.groupOrderGuideAdditional3,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 주문 절차
          _SectionHeader2(label: 'ORDER PROCESS', title: '주문 절차'),
          const SizedBox(height: 14),
          _buildOrderSteps(),
          const SizedBox(height: 28),

          // 교환·환불 정책
          _SectionHeader2(
            label: 'EXCHANGE & REFUND',
            title: context.watch<LanguageProvider>().loc.groupOrderGuideExchangeTitle,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF0F0F0),
            child: Builder(builder: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기성품 교환환불
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Color(0xFF1A1A1A), width: 3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: const Color(0xFF1A1A1A),
                          child: const Text('기성품',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loc.groupOrderGuideExchange2,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 커스텀 주문 불가
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Color(0xFFC62828), width: 3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: const Color(0xFFC62828),
                          child: const Text('커스텀',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loc.groupOrderGuideExchange1,
                            style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF444444)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 28),

          // 동의 + 주문 양식 이동
          _AgreementSection(
            agreed: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            onNext: _agreed
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupOrderFormScreen(product: widget.product),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _customOptionRow({required IconData icon, required String text, bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          color: _black,
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              color: highlight ? _black : const Color(0xFF444444),
            ),
          ),
        ),
      ],
    );
  }

  // ── 선택 상품 카드 ──
  Widget _buildProductCard(ProductModel product) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: imageUrl.isNotEmpty
                ? NetImage(imageUrl, width: 72, height: 72, fit: BoxFit.cover)
                : _productPlaceholder(),
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
                  '₩${product.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} / 1개',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    _buildTag(context.watch<LanguageProvider>().loc.setProduct),
                    _buildTag(context.watch<LanguageProvider>().loc.groupOrderOnlyLabel),
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

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: _black),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
    );
  }

  // ── 인쇄 타입 카드 (읽기 전용 안내) ──
  // ignore: unused_element
  Widget _buildPrintTypeCards() {
    final types = [
      {'step': '1', 'title': '색상 변경',             'cond': '5명↑ 무료', 'desc': '원하는 색상으로 변경 제작 (상·하의 동일 색상 적용)'},
      {'step': '2', 'title': '전면 (단체명)',          'cond': '5명↑ 무료', 'desc': '전면에 단체명 인쇄'},
      {'step': '3', 'title': '조합 (전면+색상)',       'cond': '5명↑ 무료', 'desc': '전면 단체명 + 색상 변경'},
      {'step': '4', 'title': '조합 + 후면 이름',      'cond': '10명↑',     'desc': '전면 단체명·색상 + 후면 개인 이름 인쇄'},
    ];

    return Column(
      children: types.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFF8F8F8),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                color: _black,
                child: Center(
                  child: Text(
                    t['step'] as String,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t['title'] as String,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: const Color(0xFF1A1A1A),
                          child: Text(t['cond'] as String,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
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
        );
      }).toList(),
    );
  }

  // ── 주문 절차 5단계 ──
  Widget _buildOrderSteps() {
    final steps = [
      {'num': '1', 'title': '주문 서식 작성', 'desc': '수량·사이즈·색상·로고를 입력하고 양식을 제출'},
      {'num': '2', 'title': '결제 완료', 'desc': '담당자 확인 후 결제 안내 및 입금 확인'},
      {'num': '3', 'title': '디자인 확정', 'desc': '시안 검토 및 최종 디자인 확인'},
      {'num': '4', 'title': '제작 진행', 'desc': '14~21영업일 소요 (디자인 변경 포함 시 추가 기간 가능)'},
      {'num': '5', 'title': '배송', 'desc': '완성 후 일괄 발송, 배송 추적 번호 카카오 알림 발송'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isLast = i == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 번호 + 수직 라인
            Column(
              children: [
                Container(
                  width: 32, height: 32,
                  color: _black,
                  child: Center(
                    child: Text(
                      step['num'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 32, color: const Color(0xFFCCCCCC)),
              ],
            ),
            const SizedBox(width: 14),
            // 내용
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step['desc'] as String,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.4),
                    ),
                    const SizedBox(height: 14),
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
  // ignore: unused_element
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
    return _SizeTable(
      title: '${loc.groupOrderGuideSizeAdult} (XS~XXXL)',
      rows: rows,
      loc: loc,
    );
  }

  // ── 주니어 사이즈표 ──
  // ignore: unused_element
  Widget _buildJuniorSizeTable(BuildContext context) {
    final rows = [
      ['XXS', '68~72', '52~56', '72~76', '120~130'],
      ['XS', '72~76', '56~60', '76~80', '130~140'],
      ['S', '76~80', '60~64', '80~84', '140~150'],
      ['M', '80~84', '64~68', '84~88', '150~155'],
      ['L', '84~88', '68~72', '88~92', '155~165'],
    ];
    return _SizeTable(
      title: '${loc.groupOrderGuideSizeJunior} (XXS~L)',
      rows: rows,
      loc: loc,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Helper Widgets — 탑텐 스타일
// ══════════════════════════════════════════════════════════════

/// 섹션 헤더: 좌측 4px 블랙 보더 + 타이틀
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF000000), width: 4)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1A1A1A),
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

/// 섹션 헤더2: 영문 서브 + 한글 타이틀, 좌측 4px 보더
class _SectionHeader2 extends StatelessWidget {
  final String label;
  final String title;
  const _SectionHeader2({required this.label, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF000000), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 정보 카드: 블랙 아이콘박스 + 내용
class _InfoCard extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String? content;
  final Widget? contentWidget;
  const _InfoCard({
    required this.iconData,
    required this.title,
    this.content,
    this.contentWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E8E8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1A1A1A),
            child: Icon(iconData, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 5),
                if (content != null)
                  Text(content!, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF444444)))
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

/// 동의 + 주문 양식 이동 섹션
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
              color: agreed ? const Color(0xFFF0F0F0) : const Color(0xFFF8F8F8),
              border: Border.all(
                color: agreed ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD),
                width: agreed ? 1.5 : 1,
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
                          ? const Color(0xFF1A1A1A)
                          : Colors.transparent),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Color(0xFF888888)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.watch<LanguageProvider>().loc.groupOrderGuideAgreeAll,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: agreed ? const Color(0xFF1A1A1A) : const Color(0xFF444444),
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
            onPressed: onNext,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              context.watch<LanguageProvider>().loc.groupOrderGuideWriteBtn,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: agreed ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: const RoundedRectangleBorder(),
              elevation: 0,
              disabledBackgroundColor: const Color(0xFFCCCCCC),
              disabledForegroundColor: Colors.white70,
            ),
          ),
        ),
        if (!agreed) ...[
          const SizedBox(height: 8),
          Text(
            context.watch<LanguageProvider>().loc.groupOrderGuideCheckFirst,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// 사이즈 표 (탑텐 스타일)
class _SizeTable extends StatelessWidget {
  final String title;
  final List<List<String>> rows;
  final AppLocalizations? loc;
  const _SizeTable({
    required this.title,
    required this.rows,
    this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final l = loc ?? context.watch<LanguageProvider>().loc;
    final headers = [l.sizeLabel, l.chestLabel, l.waistLabel, l.hipLabel, l.heightLabel];
    const colFlex = [1, 2, 2, 2, 2];

    Widget headerCell(String text, int flex) => Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        color: const Color(0xFF1A1A1A),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );

    Widget dataCell(String text, int flex, bool isEven, bool isSizeCol) => Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: isSizeCol
            ? const Color(0xFFF0F0F0)
            : (isEven ? const Color(0xFFF8F8F8) : Colors.white),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: isSizeCol ? 11 : 10,
            fontWeight: isSizeCol ? FontWeight.w800 : FontWeight.w500,
            color: const Color(0xFF333333),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border.fromBorderSide(BorderSide(color: Color(0xFFE8E8E8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            color: const Color(0xFFF8F8F8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(width: 6),
                const Text('(cm)', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
              ],
            ),
          ),
          // 헤더 행
          Row(children: [
            for (int i = 0; i < headers.length; i++)
              headerCell(headers[i], colFlex[i]),
          ]),
          // 데이터 행
          ...rows.asMap().entries.map((e) {
            final isEven = e.key % 2 == 0;
            return Column(children: [
              Row(children: [
                for (int i = 0; i < e.value.length; i++)
                  dataCell(e.value[i], colFlex[i], isEven, i == 0),
              ]),
              if (e.key < rows.length - 1)
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
            ]);
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
