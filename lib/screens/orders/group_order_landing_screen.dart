import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../widgets/pc_layout.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/constants.dart';
import 'group_order_form_screen.dart';

// ═══════════════════════════════════════════════════════════════
// GroupOrderLandingScreen — 단체주문 통합 화면 (탑텐 스타일)
// 탭1: 단체주문 안내 (내용 + 동의 체크박스 + 주문서 이동 버튼)
// 탭2: 주문서 작성 (상품 있으면 카드, 없으면 유형 선택)
// Provider / AppLocalizations 의존성 없음 — 모든 텍스트 하드코딩
// 탑텐 스타일: 블랙/화이트, sharp border, 정사각 아이콘 헤더
// ═══════════════════════════════════════════════════════════════
class GroupOrderLandingScreen extends StatefulWidget {
  final ProductModel? product;
  const GroupOrderLandingScreen({super.key, this.product});

  @override
  State<GroupOrderLandingScreen> createState() => _GroupOrderLandingScreenState();
}

class _GroupOrderLandingScreenState extends State<GroupOrderLandingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _agreed = false;

  static const _kBlack = Color(0xFF1A1A1A);
  static const _kBg    = Color(0xFFF8F8F8);
  static const _kGrey8 = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout();
    return _buildMobileLayout();
  }

  // ══════════════════════════════════════════════════════════
  // 모바일 레이아웃
  // ══════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return wrapWithPopScope(
      context,
      Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          title: const Text(
            '단체주문하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          backgroundColor: _kBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 48,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: Colors.white,
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: '단체주문 안내'),
              Tab(text: '주문서 작성'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildGuideTab(),
            _buildFormTab(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PC 레이아웃
  // ══════════════════════════════════════════════════════════
  Widget _buildPcLayout() {
    return wrapWithPopScope(
      context,
      Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          title: const Text(
            '단체주문하기',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          backgroundColor: _kBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: Colors.white,
                      child: _buildGuideTab(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: Container(
                      color: Colors.white,
                      child: _buildFormTab(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 탭1: 단체주문 안내 (탑텐 스타일)
  // ══════════════════════════════════════════════════════════
  Widget _buildGuideTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 블록 (flat black) ────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: _kBlack,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: Colors.white,
                  child: const Text(
                    'GROUP ORDER',
                    style: TextStyle(
                      color: _kBlack,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '단체주문 안내',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '5명 이상 단체 맞춤 제작 전문\n최고의 품질로 특별한 유니폼을 만들어드립니다.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 주문 절차 ─────────────────────────────────────
          _buildSectionRow(Icons.assignment_outlined, '주문 절차'),
          const SizedBox(height: 10),
          _buildStepRow('1', '상품 선택', '원하는 상품을 선택하고 단체주문서를 작성합니다.'),
          _buildStepRow('2', '디자인 협의', '컬러, 로고, 마킹 등 맞춤 디자인을 협의합니다.'),
          _buildStepRow('3', '견적 확인', '수량별 최종 견적을 확인하고 주문을 확정합니다.'),
          _buildStepRow('4', '제작 & 배송', '제작 후 일괄 배송 또는 분배 배송을 선택합니다.', isLast: true),
          const SizedBox(height: 20),

          // ── 주문 조건 ─────────────────────────────────────
          _buildSectionRow(Icons.check_circle_outline, '주문 조건'),
          const SizedBox(height: 10),
          _buildConditionBox(),
          const SizedBox(height: 20),

          // ── 커스텀 옵션 ───────────────────────────────────
          _buildSectionRow(Icons.palette_outlined, '커스텀 옵션'),
          const SizedBox(height: 10),
          _buildInfoLines(const [
            '• 팀명 / 로고 / 번호 마킹 가능',
            '• 원하는 컬러로 제작 가능',
            '• 마킹 방법: 서브리메이션 인쇄',
            '• 허리밴드 디자인·색상 변경 무료',
            '• 1년 독점 사용권 무료 제공',
          ]),
          const SizedBox(height: 20),

          // ── 주의사항 ──────────────────────────────────────
          _buildSectionRow(Icons.warning_amber_outlined, '주의사항'),
          const SizedBox(height: 10),
          _buildNoticeBox(const [
            '주문 확정 후 디자인 변경 시 추가 비용이 발생할 수 있습니다.',
            '색상은 모니터 환경에 따라 실제와 다소 차이가 있을 수 있습니다.',
            '단체주문 상품은 교환/환불이 불가합니다.',
            '사이즈 측정은 주문서 작성 전 반드시 확인해주세요.',
          ]),
          const SizedBox(height: 20),

          // ── 문의 ─────────────────────────────────────────
          _buildSectionRow(Icons.phone_outlined, '문의'),
          const SizedBox(height: 10),
          _buildContactBox(),
          const SizedBox(height: 28),

          // ── 동의 체크박스 ─────────────────────────────────
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
              child: Row(children: [
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
                const Expanded(
                  child: Text(
                    '위 단체주문 안내 내용을 모두 확인하였으며,\n주문 조건 및 유의사항에 동의합니다.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                      height: 1.5,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // ── 주문서 작성 버튼 ──────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _agreed
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupOrderFormScreen(product: widget.product, initialCount: 5),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                '주문서 작성하기',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlack,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                disabledForegroundColor: Colors.white70,
                shape: const RoundedRectangleBorder(),
                elevation: 0,
              ),
            ),
          ),

          if (!_agreed) ...[
            const SizedBox(height: 8),
            const Text(
              '안내 동의 체크 후 주문서 작성이 가능합니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _kGrey8),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 탭2: 주문서 작성
  // ══════════════════════════════════════════════════════════
  Widget _buildFormTab() {
    if (widget.product != null) return _buildProductFormTab(widget.product!);
    return _buildCategoryFormTab();
  }

  // 상품이 있을 때: 해당 상품으로 바로 연결
  Widget _buildProductFormTab(ProductModel product) {
    final priceStr = product.price.toInt().toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionRow(Icons.edit_note_outlined, '단체주문서 작성'),
          const SizedBox(height: 12),

          // 선택된 상품 카드 (flat white box)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Row(children: [
              product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: _kBlack,
                      child: const Text(
                        '선택된 상품',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₩$priceStr / 1개',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // 안내 확인 후 작성 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _tabCtrl.animateTo(0),
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: const Text(
                '단체주문 안내 확인 후 서식 작성',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 바로 서식 작성 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupOrderFormScreen(product: product, initialCount: 5),
                ),
              ),
              icon: const Icon(Icons.edit_note_outlined, size: 18),
              label: const Text(
                '바로 서식 작성하기',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kBlack,
                side: const BorderSide(color: _kBlack, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 안내 박스
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(left: BorderSide(color: _kBlack, width: 3)),
            ),
            child: const Text(
              '단체주문 안내를 먼저 확인하시면 주문 절차와 유의사항을 숙지할 수 있습니다.',
              style: TextStyle(fontSize: 11, color: Color(0xFF444444), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // 상품 미선택 시: 카테고리 유형 선택 카드
  Widget _buildCategoryFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionRow(Icons.edit_note_outlined, '단체주문서 작성'),
          const SizedBox(height: 12),
          const Text(
            '상품을 선택하지 않고 바로 단체주문서를 작성할 수 있습니다.\n아래 카테고리에서 원하는 상품 유형을 선택해주세요.',
            style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.6),
          ),
          const SizedBox(height: 20),

          _buildTypeCard(Icons.sports_rounded,         '싱글렛 A타입 세트',  '싱글렛 + 타이즈 세트 / 육상·인라인·마라톤'),
          const SizedBox(height: 8),
          _buildTypeCard(Icons.fitness_center_rounded,  '싱글렛 B타입',       '싱글렛 단품 / 헬스·크로스핏·복싱'),
          const SizedBox(height: 8),
          _buildTypeCard(Icons.directions_run_rounded,  '스킨슈트',           '원피스 전신 경기복 / 사이클·트라이애슬론'),
          const SizedBox(height: 8),
          _buildTypeCard(Icons.dry_cleaning_rounded,    '트레이닝복 세트',     '상의 + 하의 트레이닝 세트 / 팀복·동호회복'),
          const SizedBox(height: 8),
          _buildTypeCard(Icons.list_alt_rounded,        '기타 / 직접 작성',    '위에 없는 상품이나 복합 주문'),
          const SizedBox(height: 24),

          // 안내 박스
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(left: BorderSide(color: _kBlack, width: 3)),
            ),
            child: const Text(
              '상품 상세 페이지에서 단체주문서 작성 시 상품 정보가 자동으로 입력됩니다.\n더 빠른 주문을 원하시면 상품을 먼저 선택해주세요.',
              style: TextStyle(fontSize: 11, color: Color(0xFF444444), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 공통 UI 컴포넌트 (탑텐 스타일)
  // ══════════════════════════════════════════════════════════

  // 정사각 블랙 아이콘 + 볼드 제목
  Widget _buildSectionRow(IconData icon, String title) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        color: _kBlack,
        child: Icon(icon, size: 16, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _kBlack,
          ),
        ),
      ),
    ]);
  }

  // flat numbered step row (탑텐 스타일 — 정사각 번호 + flat white box)
  Widget _buildStepRow(String step, String title, String desc, {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          color: _kBlack,
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _kBlack)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.5)),
            ],
          ),
        ),
      ]),
    );
  }

  // flat white box — 주문 조건 테이블
  Widget _buildConditionBox() {
    final items = [
      {'icon': Icons.group_outlined,          'title': '최소 주문 수량', 'desc': '10벌 이상'},
      {'icon': Icons.local_shipping_outlined,  'title': '배송',         'desc': '무료 배송 (단체주문 전용)'},
      {'icon': Icons.schedule_outlined,        'title': '제작 기간',    'desc': '주문 확정 후 14~21일'},
      {'icon': Icons.local_offer_outlined,     'title': '단체 할인',    'desc': '30인 이상 5% / 50인 이상 10%'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
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
                    color: _kBlack,
                  ),
                ),
                const Spacer(),
                Text(
                  item['desc'] as String,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
                ),
              ]),
            ),
            if (!isLast) const Divider(height: 1, color: Color(0xFFE8E8E8), indent: 0, endIndent: 0),
          ]);
        }).toList(),
      ),
    );
  }

  // flat white box — 복수 줄
  Widget _buildInfoLines(List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(l,
              style: const TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF444444))),
        )).toList(),
      ),
    );
  }

  // flat notice box (left black border)
  Widget _buildNoticeBox(List<String> notices) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        border: Border(left: BorderSide(color: _kBlack, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notices.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ',
                  style: TextStyle(color: _kBlack, fontWeight: FontWeight.w900, fontSize: 13)),
              Expanded(
                child: Text(n,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF444444), height: 1.6)),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // flat contact box (탑텐 스타일)
  Widget _buildContactBox() {
    return Column(children: [
      // 엘리트 선수 전화 (flat black)
      GestureDetector(
        onTap: () async {
          final uri = Uri(scheme: 'tel', path: AppConstants.eliteAthletePhone.replaceAll('-', ''));
          if (await canLaunchUrl(uri)) launchUrl(uri);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          color: _kBlack,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              color: Colors.white,
              child: const Icon(Icons.emoji_events_outlined, color: _kBlack, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '엘리트 선수 주문 — 전담 상담사 직통',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.eliteAthletePhone,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: Colors.white,
              child: const Text(
                '전화',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _kBlack),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 1),
      // 일반 문의 (flat white)
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.chat_outlined, size: 15, color: _kBlack),
              SizedBox(width: 8),
              Text(
                '카카오톡 채널: @2FIT KOREA',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kBlack),
              ),
            ]),
            SizedBox(height: 8),
            Row(children: [
              Icon(Icons.email_outlined, size: 15, color: _kBlack),
              SizedBox(width: 8),
              Text(
                '이메일: tbrk2435@kakao.com',
                style: TextStyle(fontSize: 12, color: Color(0xFF444444)),
              ),
            ]),
            SizedBox(height: 8),
            Row(children: [
              Icon(Icons.schedule_outlined, size: 15, color: _kBlack),
              SizedBox(width: 8),
              Text(
                '운영시간: 평일 10:00 ~ 18:00',
                style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
            ]),
          ],
        ),
      ),
    ]);
  }

  // flat type card (탑텐 스타일 — 정사각 블랙 아이콘)
  Widget _buildTypeCard(IconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: () => _tabCtrl.animateTo(0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            color: _kBlack,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _kBlack)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _kBlack),
        ]),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFF0F0F0),
      child: const Icon(Icons.checkroom, color: Color(0xFFBBBBBB)),
    );
  }
}
