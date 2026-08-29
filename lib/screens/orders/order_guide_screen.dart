import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../providers/providers.dart';
import 'group_order_landing_screen.dart';
import 'group_order_form_screen.dart';
import '../../widgets/pc_layout.dart';
import '../../utils/navigation_helper.dart';
import '../chat/chat_screen.dart';

class OrderGuideScreen extends StatefulWidget {
  const OrderGuideScreen({super.key});

  @override
  State<OrderGuideScreen> createState() => _OrderGuideScreenState();
}

class _OrderGuideScreenState extends State<OrderGuideScreen> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  // PC 주문안내 확인 체크박스
  bool _guideChecked = false;
  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: null,
      appBar: AppBar(
        title: Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.orderGuideTitle)),
        leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => goBackOrHome(context),
              ),
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
    ));
  }

  // ── PC 2컬럼 레이아웃 ──
  Widget _buildPcLayout(BuildContext context) {
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Consumer<LanguageProvider>(builder: (_, lp, __) => Text(lp.loc.orderGuideTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
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
    ));
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
              // ── 주문안내 확인 체크박스 ──
              GestureDetector(
                onTap: () => setState(() => _guideChecked = !_guideChecked),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _guideChecked
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _guideChecked ? Colors.white : Colors.white38,
                      width: _guideChecked ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      _guideChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: _guideChecked ? Colors.white : Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.loc.t('주문_안내_내용을_모두_확인했습니다', '주문 안내 내용을 모두 확인했습니다.'),
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              // ── 단체주문서 바로가기 (체크 후 활성화) ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guideChecked
                      ? () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const GroupOrderFormScreen(initialCount: 5)))
                      : null,
                  icon: const Icon(Icons.assignment_outlined, size: 18),
                  label: Text(context.loc.t('단체주문서_바로가기', '단체주문서 바로가기'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _guideChecked ? Colors.white : Colors.white38,
                    foregroundColor: const Color(0xFF6A1B9A),
                    disabledBackgroundColor: Colors.white24,
                    disabledForegroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 46),
                    elevation: 0,
                  ),
                ),
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
                    Row(
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
                MaterialPageRoute(builder: (_) => const GroupOrderLandingScreen())),
            onForm: _guideChecked
                ? () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GroupOrderFormScreen(initialCount: 5)))
                : null,
            guideChecked: _guideChecked,
            onGuideCheckChanged: (v) => setState(() => _guideChecked = v),
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
                _additionalGuideRow('🚚', context.loc.t('배송', '배송'), context.loc.t('추가구매_물품은_별도_배송됩니다', '추가구매 물품은 별도 배송됩니다')),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    context.loc.t('추가구매_마이페이지_기존_주문내역_신청', '⚠️ 추가구매는 마이페이지 > 기존 주문내역에서 신청하실 수 있습니다.'),
                    style: const TextStyle(fontSize: 11, color: Color(0xFFE65100)),
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
    required VoidCallback? onForm,
    bool guideChecked = false,
    void Function(bool)? onGuideCheckChanged,
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
          // ── 주문안내 확인 체크박스 (단체주문에만 표시) ──
          if (onGuideCheckChanged != null) ...[
            GestureDetector(
              onTap: () => onGuideCheckChanged(!guideChecked),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: guideChecked ? color.withValues(alpha: 0.06) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: guideChecked ? color.withValues(alpha: 0.4) : const Color(0xFFFFC107).withValues(alpha: 0.6),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    guideChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 20,
                    color: guideChecked ? color : const Color(0xFFFFA000),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(context.loc.t('주문_안내_내용을_모두_확인_899c8d', '주문 안내 내용을 모두 확인했습니다.'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // 버튼 2개
          Row(
            children: [
              // 주문 안내 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGuide,
                  icon: Icon(Icons.info_outline_rounded, size: 15, color: color),
                  label: Text(
                    context.loc.t('주문_안내', '주문 안내'),
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
                  label: Text(
                    onGuideCheckChanged != null && !guideChecked ? context.loc.t('확인_후_작성_가능', '확인 후 작성 가능') : context.loc.t('주문서_작성', '주문서 작성'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onForm != null ? color : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
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
      {'icon': Icons.search_rounded, 'title': context.loc.t('상품_선택', '상품 선택'), 'desc': context.loc.t('원하는_상품과_카테고리_선택', '원하는 상품과 카테고리 선택')},
      {'icon': Icons.tune_rounded, 'title': context.loc.t('옵션_선택', '옵션 선택'), 'desc': context.loc.t('사이즈_컬러_커스텀_옵션_선택', '사이즈, 컬러, 커스텀 옵션 선택')},
      {'icon': Icons.assignment_rounded, 'title': context.loc.t('주문서_작성', '주문서 작성'), 'desc': context.loc.t('주문자_정보_및_배송지_입력', '주문자 정보 및 배송지 입력')},
      {'icon': Icons.payment_rounded, 'title': context.loc.t('결제', '결제'), 'desc': context.loc.t('다양한_결제_수단_지원', '다양한 결제 수단 지원')},
      {'icon': Icons.local_shipping_rounded, 'title': context.loc.t('제작_배송', '제작 & 배송'), 'desc': context.loc.t('커스텀_14_21일_소요', '커스텀 14~21일 소요')},
      {'icon': Icons.check_circle_rounded, 'title': context.loc.t('수령', '수령'), 'desc': context.loc.t('배송_완료_후_검수', '배송 완료 후 검수')},
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
            context.loc.t('단체_주문서', '단체 주문서'),
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupOrderLandingScreen()));
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
                    child: Text(context.loc.t('order_field_${f['field']!.replaceAll(' ', '_').replaceAll('/', '_')}', f['field']!), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
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
          _buildPolicyItem(Icons.cancel_outlined, context.loc.t('취소', '취소'), AppColors.error, context.loc.t('결제_후_1시간_이내_취소_가능_n커스텀_제작_시작_후_취소_불가', '결제 후 1시간 이내 취소 가능\n커스텀 제작 시작 후 취소 불가')),
          const SizedBox(height: 12),
          _buildPolicyItem(Icons.swap_horiz_rounded, context.loc.t('교환', '교환'), AppColors.info, context.loc.t('수령_후_7일_이내_교환_가능_n착용_흔적이_없는_상품에_한함', '수령 후 7일 이내 교환 가능\n착용 흔적이 없는 상품에 한함')),
          const SizedBox(height: 12),
          _buildPolicyItem(Icons.replay_rounded, context.loc.t('환불', '환불'), AppColors.warning, context.loc.t('수령_후_7일_이내_환불_가능_n커스텀_제작_상품은_환불_불가', '수령 후 7일 이내 환불 가능\n커스텀 제작 상품은 환불 불가')),
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
          _buildInfoRow(Icons.local_shipping_rounded, context.loc.t('배송_방법', '배송 방법'), context.loc.t('택배_한진택배', '택배 (한진택배)'), AppColors.primary),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.attach_money_rounded, context.loc.t('배송비', '배송비'), context.loc.t('4_000원_30만원_이상_무료배송', '4,000원 (30만원 이상 무료배송)'), AppColors.success),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.public_rounded, context.loc.t('해외_배송비', '해외 배송비'), context.loc.t('국가_및_무게에_따라_상이', '국가 및 무게에 따라 상이'), const Color(0xFF1565C0)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time_rounded, context.loc.t('일반_배송', '일반 배송'), context.loc.t('결제_완료_후_2_3_영업일', '결제 완료 후 2~3 영업일'), AppColors.info),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.design_services_rounded, context.loc.t('커스텀_제작', '커스텀 제작'), context.loc.t('주문_확정_후_14_21일', '주문 확정 후 14~21일'), AppColors.warning),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.groups_rounded, context.loc.t('단체_주문', '단체 주문'), context.loc.t('주문_확인_후_14_21일', '주문 확정 후 14~21일'), AppColors.accent),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.t('도서_산간_지역_추가_배송비_배송_관련_문의_고객', '※ 도서/산간 지역은 추가 배송비가 발생할 수 있습니다.\n※ 배송 관련 문의는 고객센터로 연락해주세요.'),
                  style: TextStyle(fontSize: 12, height: 1.6, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                // 해외 배송비 채팅상담 연결
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.loc.t('해외_배송비_국가별_상이_채팅안내', '※ 해외 배송비는 국가 및 무게에 따라 상이합니다.'),
                        style: TextStyle(fontSize: 12, height: 1.6, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              context.loc.t('채팅상담', '채팅상담'),
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
      {'q': context.loc.t('사이즈_변경이_가능한가요', '사이즈 변경이 가능한가요?'), 'a': context.loc.t('커스텀_제작_시작_전까지_변경_가능합니다_주문_후_1시간_이내_3fa1fc', '커스텀 제작 시작 전까지 변경 가능합니다. 주문 후 1시간 이내 고객센터로 연락해주세요.')},
      {'q': context.loc.t('커스텀_인쇄_색상_선택이_가능한가요', '커스텀 인쇄 색상 선택이 가능한가요?'), 'a': context.loc.t('네_주문서_작성_시_원하는_인쇄_색상을_기재해주세요_기본_색상_cdf445', '네, 주문서 작성 시 원하는 인쇄 색상을 기재해주세요. 기본 색상(흰색, 검정)은 무료이며 특수 색상은 추가 비용이 발생합니다.')},
      {'q': context.loc.t('단체_주문_최소_수량은_몇_개인가요', '단체 주문 최소 수량은 몇 개인가요?'), 'a': context.loc.t('최소_5개부터_단체_주문이_가능합니다', '최소 5개부터 단체 주문이 가능합니다.')},
      {'q': context.loc.t('팀_로고_파일은_어떻게_보내나요', '팀 로고 파일은 어떻게 보내나요?'), 'a': context.loc.t('주문_완료_후_카카오톡_2fit_mall_으로_AI_PNG_형_2989d6', '주문 완료 후 카카오톡(@2fit-mall)으로 AI/PNG 형식 파일을 전송해주세요.')},
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
