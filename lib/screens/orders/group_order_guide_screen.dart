import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/net_image.dart';
import '../../widgets/pc_layout.dart';
import '../../utils/navigation_helper.dart';
import 'group_order_form_screen.dart';

// ═══════════════════════════════════════════════════════════════
// GroupOrderGuideScreen — 단체주문 안내 화면 (탑텐 스타일)
// • Provider / AppLocalizations 의존성 없음
// • 탑텐 스타일: Color(0xFF1A1A1A), flat black/white, 정사각 블랙 아이콘, sharp border
// • 진입: 상품 상세 "단체주문하기" 버튼 → GroupOrderGuideScreen(product: p)
// • 이동: 동의 체크 후 "주문 양식 작성하기" → GroupOrderFormScreen(initialCount: 5)
// ═══════════════════════════════════════════════════════════════

class GroupOrderGuideScreen extends StatefulWidget {
  final ProductModel? product;
  const GroupOrderGuideScreen({super.key, this.product});

  @override
  State<GroupOrderGuideScreen> createState() => _GroupOrderGuideScreenState();
}

class _GroupOrderGuideScreenState extends State<GroupOrderGuideScreen> {
  bool _agreed = false;

  static const _kBlack  = Color(0xFF1A1A1A);
  static const _kBg     = Color(0xFFF8F8F8);
  static const _kBorder = Color(0xFFE8E8E8);
  static const _kGrey4  = Color(0xFF444444);
  static const _kGrey6  = Color(0xFF666666);
  static const _kGrey8  = Color(0xFF888888);

  // ── isBottomOrder 판별 (하의 계열) ──────────────────────────
  bool get _isBottomOrder {
    final p = widget.product;
    if (p == null) return false;
    return p.category == '하의' ||
        p.subCategory.contains('타이즈') ||
        p.subCategory.contains('남성 5부') ||
        p.subCategory.contains('여성 2.5부') ||
        p.name.contains('타이즈') ||
        p.name.contains('하의');
  }

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return _buildMobileLayout(context);
  }

  // ════════════════════════════════════════════════════════════
  // 모바일 레이아웃
  // ════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBackOrHome(context);
      },
      child: Scaffold(
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
          title: const Text(
            '단체주문 안내',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        body: _buildGuideContent(context),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // PC 레이아웃
  // ════════════════════════════════════════════════════════════
  Widget _buildPcLayout(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBackOrHome(context);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
          title: const Text(
            '단체주문 안내',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
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
                  // 좌측: 안내 콘텐츠
                  Expanded(
                    flex: 7,
                    child: Container(
                      color: Colors.white,
                      child: _buildGuideContentPc(context),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // 우측: 주문 패널
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

  // ── PC 우측 주문 패널 ────────────────────────────────────────
  Widget _buildPcOrderPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 블랙 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                      color: _kBlack, fontSize: 9,
                      fontWeight: FontWeight.w900, letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '단체 맞춤 제작',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  '5인 이상 단체 주문',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: _kBorder),
          const SizedBox(height: 12),
          // 동의 체크
          _buildAgreementRow(compact: true),
          const SizedBox(height: 12),
          // 주문 양식 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _agreed ? _navigateToForm : null,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text(
                '주문 양식 작성하기',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
            const Text(
              '안내를 확인 체크 후 양식 작성이 가능합니다',
              style: TextStyle(fontSize: 11, color: _kGrey8),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 안내 콘텐츠 (공통)
  // ════════════════════════════════════════════════════════════
  // PC용: SingleChildScrollView > Column (Row 안에서 높이 무한대 없음)
  Widget _buildGuideContentPc(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _guideItems(context),
      ),
    );
  }

  // 모바일용: ListView (Scaffold body 직접 배치 — 정상 스크롤)
  Widget _buildGuideContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: _guideItems(context),
    );
  }

  // 공통 안내 아이템 목록
  List<Widget> _guideItems(BuildContext context) {
    return [

        // ── 선택된 상품 카드 ──────────────────────────────────
        if (widget.product != null) ...[
          _buildProductCard(widget.product!),
          const SizedBox(height: 20),
        ],

        // ── 헤더 블록 ─────────────────────────────────────────
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
                    color: _kBlack, fontSize: 10,
                    fontWeight: FontWeight.w900, letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '단체주문 안내',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
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

        // ── 최소 수량 ──────────────────────────────────────────
        _buildSectionRow(Icons.group_outlined, '최소 수량'),
        const SizedBox(height: 8),
        _buildInfoBox('단체 커스텀 제작은 최소 5명부터 가능합니다.'),
        const SizedBox(height: 20),

        // ── 제작 기간 ──────────────────────────────────────────
        _buildSectionRow(Icons.schedule_outlined, '제작 기간'),
        const SizedBox(height: 8),
        _buildInfoLines(const [
          '• 주문 확정 후 14~21일 소요됩니다.',
          '• 디자인 수정: 1회당 3일 이내 수정 요청 없을 시 확정 후 제작 시작',
          '• 시즌/물량에 따라 변동될 수 있습니다.',
        ]),
        const SizedBox(height: 20),

        // ── 배송 안내 ──────────────────────────────────────────
        _buildSectionRow(Icons.local_shipping_outlined, '배송 안내'),
        const SizedBox(height: 8),
        _buildInfoLines(const [
          '• 30만원 이상 구매 시: 무료배송',
          '• 30만원 미만: 배송비 별도',
          '• 추가 제작 (5장 미만): 배송비 4,000원 추가',
          '• 단체 주문은 일괄 배송이 원칙입니다.',
        ]),
        const SizedBox(height: 20),

        // ── 커스텀 옵션 ────────────────────────────────────────
        _buildSectionRow(Icons.palette_outlined, '커스텀 옵션'),
        const SizedBox(height: 8),
        _buildInfoLines(const [
          '• 허리밴드 디자인 색상 변경 전부 무료',
          '• 로고는 AI 원본 파일 첨부 필수 (AI, EPS, SVG 형식)',
          '• 원하는 옷 디자인의 앞·뒤 사진을 첨부하면 원하는 디자인으로 제작 가능',
        ]),
        const SizedBox(height: 20),

        // ── 독점 사용권 ────────────────────────────────────────
        _buildSectionRow(Icons.lock_outline_rounded, '디자인 독점 사용 옵션 (선택)'),
        const SizedBox(height: 8),
        _buildExclusiveBox(),
        const SizedBox(height: 20),

        // ── 추가 주문 안내 ─────────────────────────────────────
        _buildSectionRow(Icons.add_circle_outline, '추가 주문 안내'),
        const SizedBox(height: 8),
        _buildInfoLines(const [
          '• 추가 주문 시 기존 주문번호 필수 입력',
          '• 1장부터 추가 가능',
          '• 5장 이하 추가 주문: 배송비 4,000원 별도',
        ]),
        const SizedBox(height: 20),

        // ── 주문 절차 ──────────────────────────────────────────
        _buildSectionRow(Icons.assignment_outlined, '주문 절차'),
        const SizedBox(height: 8),
        _buildOrderSteps(),
        const SizedBox(height: 20),

        // ── 사이즈 안내 ────────────────────────────────────────
        _buildSectionRow(Icons.straighten_outlined, '사이즈 안내'),
        const SizedBox(height: 8),
        _buildSizeTable(
          title: '성인 사이즈 (XS~XXXL)',
          emoji: '🧑',
          headerColor: const Color(0xFF1565C0),
          headerBg: const Color(0xFFE3F2FD),
          headers: const ['사이즈', '키(cm)', '체중(kg)', '가슴', '허리'],
          rows: const [
            ['XS',   '154~159', '44~51',  '85', '68'],
            ['S',    '160~165', '52~60',  '90', '72'],
            ['M',    '166~172', '61~71',  '95', '76'],
            ['L',    '172~177', '72~78',  '100', '80'],
            ['XL',   '177~182', '79~85',  '105', '84'],
            ['2XL',  '182~187', '86~91',  '110', '88'],
            ['3XL',  '187~191', '91~96',  '115', '92'],
          ],
        ),
        const SizedBox(height: 10),
        _buildSizeTable(
          title: '주니어 사이즈 (XXS~XL)',
          emoji: '🧒',
          headerColor: const Color(0xFF6A1B9A),
          headerBg: const Color(0xFFF3E5F5),
          headers: const ['사이즈', '신장(cm)', '체중(kg)', '가슴', '허리'],
          rows: const [
            ['XXS(80)', '104~116', '16~20', '58', '55'],
            ['XS(90)',  '116~128', '20~25', '63', '58'],
            ['S(100)',  '128~140', '25~32', '68', '62'],
            ['M(110)',  '140~152', '32~40', '73', '65'],
            ['L(120)',  '152~158', '40~48', '78', '68'],
            ['XL(130)', '158~165', '48~55', '83', '72'],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFE3F2FD),
            border: Border(left: BorderSide(color: Color(0xFF1565C0), width: 3)),
          ),
          child: const Text(
            '원하는 사이즈가 없을 경우 주문 양식에 키와 체중을 입력해주세요.',
            style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF333333)),
          ),
        ),
        const SizedBox(height: 20),

        // ── 교환·환불 정책 ─────────────────────────────────────
        _buildSectionRow(Icons.swap_horiz_outlined, '교환·환불 정책'),
        const SizedBox(height: 8),
        _buildExchangeBox(),
        const SizedBox(height: 20),

        // ── 첨부파일 안내 ──────────────────────────────────────
        _buildSectionRow(Icons.attach_file_outlined, '주문서 첨부파일 안내'),
        const SizedBox(height: 8),
        _buildAttachGuide(),
        const SizedBox(height: 32),

        // ── 동의 체크박스 ──────────────────────────────────────
        _buildAgreementRow(),
        const SizedBox(height: 12),

        // ── 주문서 작성 버튼 ───────────────────────────────────
        _buildSubmitButton(),

        if (!_agreed) ...[
          const SizedBox(height: 8),
          const Text(
            '안내를 확인 체크 후 양식 작성이 가능합니다',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _kGrey8),
          ),
        ],
        const SizedBox(height: 24),
      ];
  }

  // ════════════════════════════════════════════════════════════
  // UI 컴포넌트 (탑텐 스타일)
  // ════════════════════════════════════════════════════════════

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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kBlack),
        ),
      ),
    ]);
  }

  // 단일 텍스트 flat white box
  Widget _buildInfoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.6, color: _kGrey4)),
    );
  }

  // 복수 줄 flat white box
  Widget _buildInfoLines(List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(l, style: const TextStyle(fontSize: 13, height: 1.6, color: _kGrey4)),
        )).toList(),
      ),
    );
  }

  // 독점 사용권 박스
  Widget _buildExclusiveBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(
              child: Text(
                '1년 독점 사용권',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kBlack),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: _kBlack,
              child: const Text('FREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 10),
          const Text(
            '• 1년 독점 사용권 무료 제공 — 해당 디자인을 1년간 타인에게 배포하지 않습니다.',
            style: TextStyle(fontSize: 12, height: 1.7, color: _kGrey4),
          ),
          const SizedBox(height: 4),
          const Text(
            '• 별도 이야기 없으면 매년 2월 1일 홈페이지에 업로드 됩니다.',
            style: TextStyle(fontSize: 12, height: 1.7, color: _kGrey4),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(left: BorderSide(color: _kBlack, width: 3)),
            ),
            child: const Text(
              '• 같은 디자인을 원할 경우 색상만 변경 가능하며, 같은 색상으로는 제작 불가합니다.',
              style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF333333), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // 주문 절차 5단계
  Widget _buildOrderSteps() {
    final steps = [
      {'num': '1', 'title': '주문 서식 작성',  'desc': '수량·사이즈·색상·로고를 입력하고 양식을 제출'},
      {'num': '2', 'title': '결제 완료',       'desc': '담당자 확인 후 결제 안내 및 입금 확인'},
      {'num': '3', 'title': '디자인 확정',     'desc': '시안 검토 및 최종 디자인 확인'},
      {'num': '4', 'title': '제작 진행',       'desc': '14~21영업일 소요 (디자인 변경 포함 시 추가 기간 가능)'},
      {'num': '5', 'title': '배송',            'desc': '완성 후 일괄 발송, 배송 추적 번호 카카오 알림 발송'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isLast = i == steps.length - 1;
        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
          ),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              color: _kBlack,
              child: Center(
                child: Text(
                  step['num']!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step['title']!,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _kBlack)),
                  const SizedBox(height: 2),
                  Text(step['desc']!,
                      style: const TextStyle(fontSize: 11, color: _kGrey6, height: 1.5)),
                ],
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  // 사이즈 표
  Widget _buildSizeTable({
    required String title,
    required String emoji,
    required Color headerColor,
    required Color headerBg,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: headerBg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 테이블 제목
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: headerColor)),
              ],
            ),
          ),
          // 헤더 행
          Container(
            color: headerColor,
            child: Row(
              children: headers.asMap().entries.map((e) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text(
                      e.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // 데이터 행
          ...rows.asMap().entries.map((entry) {
            final rowBg = entry.key.isEven ? Colors.white : headerBg.withOpacity(0.3);
            return Container(
              color: rowBg,
              child: Row(
                children: entry.value.asMap().entries.map((cell) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                      child: Text(
                        cell.value,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: cell.key == 0 ? 10 : 11,
                          fontWeight: cell.key == 0 ? FontWeight.w700 : FontWeight.w400,
                          color: cell.key == 0 ? headerColor : const Color(0xFF333333),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  // 교환·환불 박스
  Widget _buildExchangeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(left: BorderSide(color: _kBlack, width: 3)),
            ),
            child: const Text(
              '• 커스텀(단체) 주문: 의류 자체 불량 외 교환·환불은 불가합니다.',
              style: TextStyle(fontSize: 13, height: 1.6, fontWeight: FontWeight.w700, color: _kBlack),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '• 기성품: 제품 수령 후 3일 이내 교환·환불 가능합니다.',
            style: TextStyle(fontSize: 13, height: 1.6, color: _kGrey4),
          ),
          const SizedBox(height: 4),
          const Text(
            '• 주문 확정 후 제작 착수 전까지만 취소 가능합니다.',
            style: TextStyle(fontSize: 13, height: 1.6, color: _kGrey4),
          ),
          const SizedBox(height: 4),
          const Text(
            '• 색상은 모니터 환경에 따라 실제와 다소 다를 수 있습니다.',
            style: TextStyle(fontSize: 13, height: 1.6, color: _kGrey4),
          ),
        ],
      ),
    );
  }

  // 첨부파일 안내 박스
  Widget _buildAttachGuide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주문서 작성 시 아래 파일을 첨부해주세요.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kBlack, height: 1.5),
          ),
          const SizedBox(height: 10),
          _buildAttachRow('로고 파일',       'AI, EPS, SVG, PNG (고해상도 권장)'),
          _buildAttachRow('디자인 참고 이미지', '원하는 디자인의 앞·뒤 사진 첨부'),
          _buildAttachRow('색상 코드',       'Pantone 또는 RGB/HEX 코드 기재'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(left: BorderSide(color: _kBlack, width: 2)),
            ),
            child: const Text(
              '파일 첨부가 어려운 경우 카카오톡 채널 @2FIT KOREA로 전송해 주세요.',
              style: TextStyle(fontSize: 12, height: 1.6, color: _kGrey4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachRow(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: _kBlack,
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(desc, style: const TextStyle(fontSize: 12, height: 1.5, color: _kGrey4)),
          ),
        ],
      ),
    );
  }

  // 상품 카드 (탑텐 flat white box)
  Widget _buildProductCard(ProductModel product) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : '';
    final priceStr = product.price.toInt().toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        imageUrl.isNotEmpty
            ? NetImage(imageUrl, width: 72, height: 72, fit: BoxFit.cover)
            : Container(
                width: 72, height: 72,
                color: const Color(0xFFF5F5F5),
                child: const Icon(Icons.checkroom, color: Color(0xFFBBBBBB)),
              ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: _kBlack,
                child: const Text(
                  '선택된 상품',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '₩$priceStr / 1개',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kBlack),
              ),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                _buildTag('5인 이상'),
                _buildTag('단체 전용'),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: _kBlack)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: _kBlack, fontWeight: FontWeight.w600)),
    );
  }

  // 동의 체크박스 (탑텐 스타일)
  Widget _buildAgreementRow({bool compact = false}) {
    return GestureDetector(
      onTap: () => setState(() => _agreed = !_agreed),
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 14),
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
          Expanded(
            child: Text(
              compact
                  ? '안내 내용을 모두 확인하였습니다'
                  : '위 단체주문 안내 내용을 모두 확인하였으며,\n주문 조건 및 유의사항에 동의합니다.',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
                height: 1.5,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // 주문서 작성 버튼 (탑텐 flat black 버튼)
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _agreed ? _navigateToForm : null,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text(
          '주문 양식 작성하기',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
    );
  }

  // 폼 화면으로 이동
  void _navigateToForm() {
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
}
