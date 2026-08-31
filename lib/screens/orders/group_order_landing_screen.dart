import 'package:flutter/material.dart';
import '../../widgets/pc_layout.dart';
import '../../utils/navigation_helper.dart';
import '../../models/models.dart';
import 'group_order_form_screen.dart';
import '../../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';

import '../../utils/theme.dart';
// ═══════════════════════════════════════════════════════════════
// GroupOrderLandingScreen — 사이드바 "단체주문방법" 안내 페이지
// • product 파라미터 없음 (사이드바 진입 전용)
// • 단체주문 절차와 조건을 텍스트로 안내
// • 주문서 이동 버튼 없이 문의 중심으로 제공
// • Provider / AppLocalizations 의존성 없음
// • 탑텐 스타일: AppColors.primary, flat black/white, 정사각 블랙 아이콘, sharp border
// ═══════════════════════════════════════════════════════════════

class GroupOrderLandingScreen extends StatefulWidget {
  final ProductModel? product; // 상품 상세에서 진입 시 전달
  const GroupOrderLandingScreen({super.key, this.product});

  @override
  State<GroupOrderLandingScreen> createState() =>
      _GroupOrderLandingScreenState();
}

class _GroupOrderLandingScreenState extends State<GroupOrderLandingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _kBlack = AppColors.primary;
  static const _kBg = AppColors.background;
  static const _kBorder = AppColors.border;
  static const _kGrey4 = AppColors.textSecondary;
  static const _kGrey6 = AppColors.textSecondary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 언어 변경 시 번역 트리거
      context.read<LanguageProvider>().triggerTranslation();
    });
    _tabCtrl = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    if (isPcWeb(context)) return _buildPcLayout();
    return _buildMobileLayout();
  }

  // ════════════════════════════════════════════════════════════
  // 모바일 레이아웃
  // ════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return wrapWithPopScope(
      context,
      Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 56,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
          title: Text(
            context.loc.t('단체주문방법', '단체주문방법'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        body: _buildGuideTab(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // PC 레이아웃
  // ════════════════════════════════════════════════════════════
  Widget _buildPcLayout() {
    return wrapWithPopScope(
      context,
      Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
          title: Text(
            context.loc.t('단체주문방법', '단체주문방법'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                color: Colors.white,
                child: _buildGuideTab(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // product의 하의 여부 판별
  bool get _isBottomOrder {
    final p = widget.product;
    if (p == null) return false;
    return p.category == context.loc.t('하의', '하의') ||
        p.subCategory.contains(context.loc.t('타이즈', '타이즈')) ||
        p.subCategory.contains(context.loc.t('남성_5부', '남성 5부')) ||
        p.subCategory.contains(context.loc.t('여성_25부', '여성 2.5부')) ||
        p.name.contains(context.loc.t('타이즈', '타이즈')) ||
        p.name.contains(context.loc.t('하의', '하의'));
  }

  void _goToForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupOrderFormScreen(
          product: widget.product,
          initialCount: 5,
          isBottomOrder: _isBottomOrder,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 탭1: 단체주문 안내
  // ════════════════════════════════════════════════════════════
  Widget _buildGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 브랜드 히어로
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: Colors.white,
                  child: const Text(
                    'GROUP ORDER',
                    style: TextStyle(
                      color: _kBlack,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.loc.t('단체주문_안내', '단체주문 안내'),
                  style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6),
                ),
                const SizedBox(height: 6),
                Text(
                  context.loc.t('5명_이상_단체_맞춤_제작__a802bf',
                      '5명 이상 단체 맞춤 제작 전문\n최고의 품질로 특별한 유니폼을 만들어드립니다.'),
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          if (widget.product != null) ...[
            const SizedBox(height: 14),
            _buildProductOrderCta(),
          ],
          const SizedBox(height: 20),

          // 주문 절차
          _buildSectionTitle(
              Icons.assignment_outlined, context.loc.t('주문_절차', '주문 절차')),
          const SizedBox(height: 12),
          _buildStepCard(
              '1',
              context.loc.t('상품_선택___주문서_작성', '상품 선택 & 주문서 작성'),
              context.loc.t(
                  '원하는_상품을_선택하고_단체주문서를_작성합니다', '원하는 상품을 선택하고 단체주문서를 작성합니다.')),
          _buildStepCard(
              '2',
              context.loc.t('디자인_협의', '디자인 협의'),
              context.loc.t(
                  '컬러_로고_마킹_등_맞춤_디자인을_협의합니다', '컬러, 로고, 마킹 등 맞춤 디자인을 협의합니다.')),
          _buildStepCard(
              '3',
              context.loc.t('견적_확인___결제', '견적 확인 & 결제'),
              context.loc.t(
                  '수량별_최종_견적을_확인하고_주문을_확정합니다', '수량별 최종 견적을 확인하고 주문을 확정합니다.')),
          _buildStepCard(
              '4',
              context.loc.t('제작___배송', '제작 & 배송'),
              context.loc
                  .t('제작_후_일괄_배송_또는_분_c0067b', '제작 후 일괄 배송 또는 분배 배송을 선택합니다.'),
              isLast: true),
          const SizedBox(height: 20),

          // 주문 조건
          _buildSectionTitle(
              Icons.check_circle_outline, context.loc.t('주문_조건', '주문 조건')),
          const SizedBox(height: 12),
          _buildConditionTable(),
          const SizedBox(height: 20),

          // 커스텀 옵션
          _buildSectionTitle(
              Icons.palette_outlined, context.loc.t('커스텀_옵션', '커스텀 옵션')),
          const SizedBox(height: 12),
          _buildInfoLines([
            context.loc.t('팀명___로고___번호_마킹_ae11e1', '• 팀명 / 로고 / 번호 마킹 가능'),
            context.loc.t('원하는_컬러로_제작_가능', '• 원하는 컬러로 제작 가능'),
            context.loc.t('허리밴드_디자인_색상_변경__141532', '• 허리밴드 디자인·색상 변경 무료'),
            context.loc.t('1년_독점_사용권_무료_제공', '• 1년 독점 사용권 무료 제공'),
          ]),
          const SizedBox(height: 20),

          // 주의사항
          _buildSectionTitle(
              Icons.warning_amber_outlined, context.loc.t('주의사항', '주의사항')),
          const SizedBox(height: 12),
          _buildNoticeBox([
            context.loc.t('주문_확정_후_디자인_변경__628958',
                '주문 확정 후 디자인 변경 시 추가 비용이 발생할 수 있습니다.'),
            context.loc.t('색상은_모니터_환경에_따라__a7b8cd',
                '색상은 모니터 환경에 따라 실제와 다소 차이가 있을 수 있습니다.'),
            context.loc.t('단체주문_상품은_교환_환불이_61f5d0', '단체주문 상품은 교환/환불이 불가합니다.'),
            context.loc
                .t('사이즈_측정은_주문서_작성__0081c8', '사이즈 측정은 주문서 작성 전 반드시 확인해주세요.'),
          ]),
          const SizedBox(height: 20),

          // 문의
          _buildSectionTitle(Icons.phone_outlined, context.loc.t('문의', '문의')),
          const SizedBox(height: 12),
          _buildContactCard(),
          const SizedBox(height: 20),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProductOrderCta() {
    final productName = widget.product?.name ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.checkroom_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.loc.t('선택한_상품으로_주문서_작성', '선택한 상품으로 주문서 작성'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (productName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goToForm,
              icon: const Icon(Icons.edit_note_rounded, size: 19),
              label: Text(context.loc.t('이_상품으로_단체주문서_작성', '이 상품으로 단체주문서 작성')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 탭2: 주문서 바로가기
  // ════════════════════════════════════════════════════════════
  Widget _buildOrderFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
              Icons.edit_note_outlined, context.loc.t('단체주문서_작성', '단체주문서 작성')),
          const SizedBox(height: 12),
          Text(
            context.loc.t('상품을_선택하지_않고_바로__efb285',
                '상품을 선택하지 않고 바로 단체주문서를 작성할 수 있습니다.\n아래 카테고리에서 원하는 상품 유형을 선택해주세요.'),
            style: TextStyle(fontSize: 12, color: _kGrey6, height: 1.6),
          ),
          const SizedBox(height: 20),

          // 상품 유형별 주문서 선택
          _buildOrderTypeCard(
            icon: Icons.sports_rounded,
            title: context.loc.t('싱글렛_A타입_세트', '싱글렛 A타입 세트'),
            subtitle: context.loc
                .t('싱글렛___타이즈_세트____ada1cf', '싱글렛 + 타이즈 세트 / 육상·인라인·마라톤'),
          ),
          const SizedBox(height: 8),
          _buildOrderTypeCard(
            icon: Icons.fitness_center_rounded,
            title: context.loc.t('싱글렛_B타입', '싱글렛 B타입'),
            subtitle:
                context.loc.t('싱글렛_단품___헬스_크로스_1bce31', '싱글렛 단품 / 헬스·크로스핏·복싱'),
          ),
          const SizedBox(height: 8),
          _buildOrderTypeCard(
            icon: Icons.directions_run_rounded,
            title: context.loc.t('스킨슈트', '스킨슈트'),
            subtitle: context.loc
                .t('원피스_전신_경기복___사이_bc1d90', '원피스 전신 경기복 / 사이클·트라이애슬론'),
          ),
          const SizedBox(height: 8),
          _buildOrderTypeCard(
            icon: Icons.dry_cleaning_rounded,
            title: context.loc.t('트레이닝복_세트', '트레이닝복 세트'),
            subtitle: context.loc
                .t('상의___하의_트레이닝_세트_0bebc1', '상의 + 하의 트레이닝 세트 / 팀복·동호회복'),
          ),
          const SizedBox(height: 8),
          _buildOrderTypeCard(
            icon: Icons.list_alt_rounded,
            title: context.loc.t('기타___직접_작성', '기타 / 직접 작성'),
            subtitle:
                context.loc.t('위에_없는_상품이나_복합_주_244706', '위에 없는 상품이나 복합 주문'),
          ),
          const SizedBox(height: 24),

          // 안내 박스
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(left: BorderSide(color: _kBlack, width: 3)),
            ),
            child: Text(
              context.loc.t('상품_상세_페이지에서_단체주_e5e1e7',
                  '상품 상세 페이지에서 단체주문서 작성 시 상품 정보가 자동으로 입력됩니다.\n더 빠른 주문을 원하시면 상품을 먼저 선택해주세요.'),
              style: TextStyle(fontSize: 11, color: _kGrey4, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 공통 UI 컴포넌트 (탑텐 스타일)
  // ════════════════════════════════════════════════════════════

  // 정사각 블랙 아이콘 + 볼드 제목
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: _kBlack),
        ),
      ),
    ]);
  }

  // 번호가 있는 단계 카드
  Widget _buildStepCard(String step, String title, String desc,
      {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x081A1A2E), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: _kBlack)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 11, color: _kGrey6, height: 1.5)),
            ],
          ),
        ),
      ]),
    );
  }

  // 주문 조건 테이블
  Widget _buildConditionTable() {
    final items = [
      {
        'icon': Icons.group_outlined,
        'title': context.loc.t('최소_주문_수량', '최소 주문 수량'),
        'desc': context.loc.t('k_5벌_이상', '5벌 이상')
      },
      {
        'icon': Icons.local_shipping_outlined,
        'title': context.loc.t('배송', '배송'),
        'desc': context.loc.t('k_30만원_이상_무료_미만_별도_해외_국가별',
            '국내: 30만원 이상 무료 (미만 4,000원)\n해외: 국가별 상이')
      },
      {
        'icon': Icons.schedule_outlined,
        'title': context.loc.t('제작_기간', '제작 기간'),
        'desc': context.loc.t('주문_확정_후_1421일', '주문 확정 후 14~21일')
      },
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(item['icon'] as IconData, size: 17, color: _kBlack),
                const SizedBox(width: 12),
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kBlack),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    item['desc'] as String,
                    style: const TextStyle(fontSize: 12, color: _kGrey4),
                    textAlign: TextAlign.right,
                  ),
                ),
              ]),
            ),
            if (!isLast) const Divider(height: 1, color: _kBorder),
          ]);
        }).toList(),
      ),
    );
  }

  // 복수 줄 flat white box
  Widget _buildInfoLines(List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l,
                      style: const TextStyle(
                          fontSize: 12, height: 1.6, color: _kGrey4)),
                ))
            .toList(),
      ),
    );
  }

  // 주의사항 박스 (left black border)
  Widget _buildNoticeBox(List<String> notices) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: AppColors.accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notices
            .map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: _kBlack,
                              fontWeight: FontWeight.w900,
                              fontSize: 13)),
                      Expanded(
                        child: Text(n,
                            style: const TextStyle(
                                fontSize: 11, color: _kGrey4, height: 1.6)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // 연락처 카드 (flat black)
  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.chat_rounded, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              context.loc.t('카카오톡_채널_2fit_mall', '카카오톡 채널: @2fit-mall'),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Icon(Icons.email_rounded, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              context.loc
                  .t('이메일_chw243527_gmail_com', '이메일: chw243527@gmail.com'),
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              context.loc.t('운영시간_평일_10_00_18_00', '운영시간: 평일 10:00 ~ 18:00'),
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ]),
        ],
      ),
    );
  }

  // 상품 유형 선택 카드 (탑텐 flat + 정사각 블랙 아이콘)
  Widget _buildOrderTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: _goToForm,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x081A1A2E), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _kBlack)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: _kGrey6)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _kBlack),
        ]),
      ),
    );
  }
}
