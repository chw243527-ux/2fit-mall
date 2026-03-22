import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../providers/providers.dart';
import 'group_order_guide_screen.dart';
import 'group_order_form_screen.dart';
import '../../widgets/pc_layout.dart';

class OrderGuideScreen extends StatefulWidget {
  const OrderGuideScreen({super.key});

  @override
  State<OrderGuideScreen> createState() => _OrderGuideScreenState();
}

class _OrderGuideScreenState extends State<OrderGuideScreen> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return Scaffold(
      backgroundColor: null,
      appBar: AppBar(
        title: Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.orderGuideTitle)),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOrderTypeCards(context),
            _buildOrderFlowSection(),
            _buildOrderFormSection(context),
            _buildPolicySection(),
            _buildShippingSection(),
            _buildFAQSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── PC 2컬럼 레이아웃 ──
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.orderGuideTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        backgroundColor: AppColors.primary,
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
                // ── 좌측: 주문 안내 콘텐츠 ──
                Expanded(
                  flex: 7,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildOrderTypeCards(context),
                        _buildOrderFlowSection(),
                        _buildOrderFormSection(context),
                        _buildPolicySection(),
                        _buildShippingSection(),
                        _buildFAQSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // ── 우측: 빠른 주문 패널 ──
                SizedBox(
                  width: 320,
                  child: _buildPcQuickOrderPanel(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── PC 빠른 주문 패널 ──
  Widget _buildPcQuickOrderPanel(BuildContext context) {
    return Column(
      children: [
        // 단체 주문 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16, offset: const Offset(0, 4),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.groups_rounded, color: Colors.white, size: 32),
              const SizedBox(height: 10),
              Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.groupCustomOrder,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
              const SizedBox(height: 6),
              Text(loc.orderGuide5PlusMake,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              const SizedBox(height: 4),
              Text(loc.orderGuideDiscount,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const GroupOrderGuideScreen())),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 40),
                      ),
                      child: Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.viewGuide, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const GroupOrderFormScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6A1B9A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(0, 40),
                        elevation: 0,
                      ),
                      child: Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.fillOrderForm, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 주문 흐름 요약 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 2),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.orderProcess,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
              const SizedBox(height: 14),
              _pcFlowStep('1', loc.orderGuideStep1, loc.orderGuideStep1Sub, AppColors.primary),
              _pcFlowStep('2', loc.orderGuideStep2, loc.orderGuideStep2Sub, AppColors.accent),
              _pcFlowStep('3', loc.orderGuideStep3, loc.orderGuideStep3Sub, const Color(0xFF2E7D32)),
              _pcFlowStep('4', loc.orderGuideStep4, loc.orderGuideStep4Sub, const Color(0xFFFF6B35)),
              _pcFlowStep('5', loc.orderGuideStep5, loc.orderGuideStep5Sub, const Color(0xFF1565C0)),
              const SizedBox(height: 8),
              // 고객센터 바로가기
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, size: 16, color: Color(0xFF1A1A1A)),
                        const SizedBox(width: 6),
                        Text(loc.orderGuideCustomerService,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.phone_rounded, size: 13, color: Color(0xFF888888)),
                        SizedBox(width: 5),
                        Text('010-2567-9015',
                            style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.chat_rounded, size: 13, color: Color(0xFFFFE500)),
                        const SizedBox(width: 5),
                        Text(loc.orderGuideKakao,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pcFlowStep(String num, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeCards(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.orderGuideTypeTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            loc.orderGuideTypeSub,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // 단체 커스텀
          _buildOrderTypeCardWithButtons(
            context,
            icon: Icons.groups_rounded,
            title: loc.orderGuideGroupTitle,
            subtitle: loc.orderGuideGroupSub,
            description: loc.orderGuideGroupDesc,
            color: AppColors.accent,
            badges: [loc.orderGuideGroupBadge1, loc.orderGuideGroupBadge2, loc.orderGuideGroupBadge3],
            onGuide: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GroupOrderGuideScreen())),
            onForm: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GroupOrderFormScreen())),
          ),

          const SizedBox(height: 12),
          // 추가구매 안내 카드
          _buildAdditionalOrderCard(context),

        ],
      ),
    );
  }

  // ── 추가구매 안내 카드 ──
  Widget _buildAdditionalOrderCard(BuildContext context) {
    const brownColor = Color(0xFF795548);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brownColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brownColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: brownColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_circle_outline_rounded, color: brownColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.additionalPurchase, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: brownColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.addToExistingOrder, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(loc.orderGuideAdditionalNote, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 뱃지
          Wrap(
            spacing: 6,
            children: [loc.orderGuideAdditional1, loc.orderGuideAdditional2, loc.orderGuideAdditional3].map((b) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: brownColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(b, style: const TextStyle(fontSize: 11, color: brownColor, fontWeight: FontWeight.w700)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          // 설명
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brownColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: brownColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: brownColor),
                  const SizedBox(width: 6),
                  Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.additionalPurchaseGuide, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: brownColor))),
                ]),
                const SizedBox(height: 8),
                _additionalGuideRow('✅', loc.orderGuideAdditionalMin, loc.orderGuideAdditionalMinDesc),
                const SizedBox(height: 5),
                _additionalGuideRow('⏰', loc.orderGuideAdditionalDeadline, loc.orderGuideAdditionalDeadlineDesc),
                const SizedBox(height: 5),
                _additionalGuideRow('🎨', loc.orderGuideAdditionalOption, loc.orderGuideAdditionalOptionDesc),
                const SizedBox(height: 5),
                _additionalGuideRow('🚚', '배송', '추가구매 물품은 별도 배송됩니다'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    '⚠️ 추가구매는 마이페이지 > 기존 주문내역에서 신청하실 수 있습니다.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFE65100)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _additionalGuideRow(String emoji, String label, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF795548))),
        ),
        Expanded(child: Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF555555)))),
      ],
    );
  }

  Widget _buildOrderTypeCardWithButtons(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required List<String> badges,
    required VoidCallback onGuide,
    required VoidCallback onForm,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 정보
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(subtitle,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 배지
          Wrap(
            spacing: 6,
            children: badges
                .map((b) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(b,
                          style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // 버튼 2개
          Row(
            children: [
              // 주문 안내 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGuide,
                  icon: Icon(Icons.info_outline_rounded, size: 15, color: color),
                  label: Text(
                    '주문 안내',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 주문서 작성 버튼
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onForm,
                  icon: const Icon(Icons.assignment_rounded, size: 15),
                  label: const Text(
                    '주문서 작성',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFlowSection() {
    final steps = [
      {'icon': Icons.search_rounded, 'title': '상품 선택', 'desc': '원하는 상품과 카테고리 선택'},
      {'icon': Icons.tune_rounded, 'title': '옵션 선택', 'desc': '사이즈, 컬러, 커스텀 옵션 선택'},
      {'icon': Icons.assignment_rounded, 'title': '주문서 작성', 'desc': '주문자 정보 및 배송지 입력'},
      {'icon': Icons.payment_rounded, 'title': '결제', 'desc': '다양한 결제 수단 지원'},
      {'icon': Icons.local_shipping_rounded, 'title': '제작 & 배송', 'desc': '커스텀 14~21일 소요'},
      {'icon': Icons.check_circle_rounded, 'title': '수령', 'desc': '배송 완료 후 검수'},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.orderProcessTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return _buildStepItem(index + 1, step['icon'] as IconData, step['title'] as String, step['desc'] as String, index < steps.length - 1);
          }),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, IconData icon, String title, String desc, bool hasLine) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
            if (hasLine)
              Container(
                width: 2,
                height: 30,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              SizedBox(height: hasLine ? 28 : 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderFormSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.orderFormTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          const SizedBox(height: 12),
          _buildFormCard(
            '단체 주문서',
            Icons.groups_outlined,
            AppColors.accent,
            _groupOrderFields,
            context,
            'group',
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> _groupOrderFields = [
    {'field': '팀/단체명', 'example': '○○ 클럽'},
    {'field': '담당자명', 'example': '홍길동'},
    {'field': '담당자 연락처', 'example': '010-0000-0000'},
    {'field': '총 인원', 'example': '10명'},
    {'field': '상품명', 'example': '2FIT 롱 레깅스'},
    {'field': '공통 컬러', 'example': 'Black'},
    {'field': '개인 사이즈 목록', 'example': 'M×3, L×5, XL×2'},
    {'field': '팀 로고 인쇄', 'example': '있음 (파일 별도 첨부)'},
    {'field': '이름/번호 인쇄', 'example': '별도 명단 첨부'},
    {'field': '배송 주소', 'example': '서울시 강남구 역삼동 000-00'},
  ];

  Widget _buildFormCard(String title, IconData icon, Color color, List<Map<String, String>> fields, BuildContext context, String orderType) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupOrderGuideScreen()));
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.orderGuideTitle, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(100),
                1: FlexColumnWidth(),
              },
              children: fields.map((f) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(f['field']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(f['example']!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.cancelRefundPolicy, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          _buildPolicyItem(Icons.cancel_outlined, '취소', AppColors.error, '결제 후 1시간 이내 취소 가능\n커스텀 제작 시작 후 취소 불가'),
          const SizedBox(height: 12),
          _buildPolicyItem(Icons.swap_horiz_rounded, '교환', AppColors.info, '수령 후 7일 이내 교환 가능\n착용 흔적이 없는 상품에 한함'),
          const SizedBox(height: 12),
          _buildPolicyItem(Icons.replay_rounded, '환불', AppColors.warning, '수령 후 7일 이내 환불 가능\n커스텀 제작 상품은 환불 불가'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.orderGuideNonExchangeable, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Text(loc.orderGuideNonExchangeableList,
                    style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(IconData icon, String title, Color color, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShippingSection() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.shippingGuide, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.local_shipping_rounded, '배송 방법', '택배 (CJ대한통운, 롯데택배)', AppColors.primary),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.attach_money_rounded, '배송비', '3,000원 (30만원 이상 무료배송)', AppColors.success),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time_rounded, '일반 배송', '결제 완료 후 2~3 영업일', AppColors.info),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.design_services_rounded, '커스텀 제작', '주문 확정 후 14~21일', AppColors.warning),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.groups_rounded, '단체 주문', '주문 확인 후 10~21 영업일', AppColors.accent),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: const Text(
              '※ 도서/산간 지역은 추가 배송비가 발생할 수 있습니다.\n※ 배송 관련 문의는 고객센터로 연락해주세요.',
              style: TextStyle(fontSize: 12, height: 1.6, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {'q': '사이즈 변경이 가능한가요?', 'a': '커스텀 제작 시작 전까지 변경 가능합니다. 주문 후 1시간 이내 고객센터로 연락해주세요.'},
      {'q': '커스텀 인쇄 색상 선택이 가능한가요?', 'a': '네, 주문서 작성 시 원하는 인쇄 색상을 기재해주세요. 기본 색상(흰색, 검정)은 무료이며 특수 색상은 추가 비용이 발생합니다.'},
      {'q': '단체 주문 최소 수량은 몇 개인가요?', 'a': '최소 5개부터 단체 주문이 가능합니다.'},
      {'q': '팀 로고 파일은 어떻게 보내나요?', 'a': '주문 완료 후 카카오톡(@2fitkorea)으로 AI/PNG 형식 파일을 전송해주세요.'},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.faqTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _buildFAQItem(faq['q']!, faq['a']!)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          'Q. $question',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'A. $answer',
              style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

