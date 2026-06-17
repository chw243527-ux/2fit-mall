import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/net_image.dart';
import '../../widgets/pc_layout.dart';
import '../../utils/navigation_helper.dart';
import 'group_order_form_screen.dart';

// ═══════════════════════════════════════════════════════════════
// GroupOrderGuideScreen — 단체주문 안내 화면 (탑텐 스타일)
// 단계: 안내 내용 → 동의 체크 → 주문 양식 작성 페이지 이동
// Provider / AppLocalizations 의존성 없음 — 모든 텍스트 하드코딩
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
  static const _kGrey8 = Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return _buildMobileLayout(context);
  }

  // ── 모바일 레이아웃 ──
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

  // ── PC 레이아웃 ──
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
                  // ── 좌측: 주문 안내 콘텐츠 ──
                  Expanded(
                    flex: 7,
                    child: Container(
                      color: Colors.white,
                      child: _buildGuideContent(context),
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
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const Divider(color: Color(0xFFE8E8E8)),
          const SizedBox(height: 12),

          // 동의 체크
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Container(
              padding: const EdgeInsets.all(12),
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
                    fillColor: WidgetStateProperty.resolveWith<Color>((states) =>
                        states.contains(WidgetState.selected)
                            ? _kBlack
                            : Colors.transparent),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFF888888)),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      '안내 내용을 모두 확인하였습니다',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                        builder: (_) => GroupOrderFormScreen(
                          product: widget.product,
                          initialCount: 5,
                        ),
                      ),
                    )
                  : null,
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

  // ═══════════════════════════════════════════════════
  // 안내 콘텐츠
  // ═══════════════════════════════════════════════════
  Widget _buildGuideContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── 선택된 상품 카드 ──────────────────────────────
        if (widget.product != null) ...[
          _buildProductCard(widget.product!),
          const SizedBox(height: 20),
        ],

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

        // ── 최소 수량 ─────────────────────────────────────
        _buildSectionRow(Icons.group_outlined, '최소 수량'),
        const SizedBox(height: 8),
        _buildInfoBox('단체 커스텀 제작은 최소 5명부터 가능합니다.'),
        const SizedBox(height: 20),

        // ── 제작 기간 ─────────────────────────────────────
        _buildSectionRow(Icons.schedule_outlined, '제작 기간'),
        const SizedBox(height: 8),
        _buildInfoLines(const [
          '• 주문 확정 후 14~21일 소요됩니다.',
          '• 디자인 수정: 1회당 3일 이내 수정 요청 없을 시 확정 후 제작 시작',
          '• (시즌/물량에 따라 변동될 수 있습니다)',
        ]),
        const SizedBox(height: 20),

        // ── 배송 안내 ─────────────────────────────────────
        _buildSectionRow(Icons.local_shipping_outlined, '배송 안내'),
        const SizedBox(height: 8),
        _buildInfoLines(const [
          '• 30만원 이상 구매 시: 무료배송',
          '• 30만원 미만: 배송비 별도',
          '• 추가 제작 (5장 미만): 배송비 4,000원 추가',
          '• 단체 주문은 일괄 배송이 원칙입니다.',
        ]),
        const SizedBox(height: 20),

        // ── 커스텀 옵션 (허리밴드·로고·디자인) ───────────
        _buildSectionRow(Icons.palette_outlined, '커스텀 옵션'),
        const SizedBox(height: 8),
        _buildInfoLines(const [
          '• 허리밴드 디자인 색상 변경 전부 무료',
          '• 로고는 AI 원본 파일 첨부 필수 (AI, EPS, SVG 형식)',
          '• 원하는 옷 디자인의 앞·뒤 사진을 첨부하면 원하는 디자인으로 제작 가능',
        ]),
        const SizedBox(height: 20),

        // ── 독점 사용권 ───────────────────────────────────
        _buildSectionRow(Icons.lock_outline_rounded, '디자인 독점 사용 옵션 (선택)'),
        const SizedBox(height: 8),
        _buildExclusiveBox(),
        const SizedBox(height: 20),

        // ── 추가 주문 ─────────────────────────────────────
        _buildSectionRow(Icons.add_circle_outline, '추가 주문 안내'),
        const SizedBox(height: 8),
        _buildInfoLines(const [
          '• 추가 주문 시 기존 주문번호 필수 입력',
          '• 1장부터 추가 가능',
          '• 5장 이하 추가 주문: 배송비 4,000원 별도',
        ]),
        const SizedBox(height: 20),

        // ── 주문 절차 ─────────────────────────────────────
        _buildSectionRow(Icons.assignment_outlined, '주문 절차'),
        const SizedBox(height: 8),
        _buildOrderSteps(),
        const SizedBox(height: 20),

        // ── 교환·환불 정책 ─────────────────────────────────
        _buildSectionRow(Icons.swap_horiz_outlined, '교환·환불 정책'),
        const SizedBox(height: 8),
        _buildExchangeBox(),
        const SizedBox(height: 20),

        // ── 주문서 첨부파일 안내 ──────────────────────────
        _buildSectionRow(Icons.attach_file_outlined, '주문서 첨부파일 안내'),
        const SizedBox(height: 8),
        _buildAttachGuide(),
        const SizedBox(height: 32),

        // ── 동의 체크박스 ──────────────────────────────────
        _buildAgreementRow(),
        const SizedBox(height: 12),

        // ── 주문서 작성 버튼 ───────────────────────────────
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
      ],
    );
  }

  // ── 섹션 제목 행 (탑텐 스타일: 정사각 블랙 아이콘) ──────────
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

  // ── 단일 텍스트 박스 (flat white box) ────────────────────────
  Widget _buildInfoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF444444))),
    );
  }

  // ── 복수 줄 박스 (flat white box) ───────────────────────────
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
          child: Text(l, style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF444444))),
        )).toList(),
      ),
    );
  }

  // ── 독점 사용권 박스 ──────────────────────────────────────────
  Widget _buildExclusiveBox() {
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
            style: TextStyle(fontSize: 12, height: 1.7, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 4),
          const Text(
            '• 별도 이야기 없으면 매년 2월 1일 홈페이지에 업로드 됩니다.',
            style: TextStyle(fontSize: 12, height: 1.7, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 4),
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

  // ── 주문 절차 5단계 ───────────────────────────────────────────
  Widget _buildOrderSteps() {
    final steps = [
      {'num': '1', 'title': '주문 서식 작성', 'desc': '수량·사이즈·색상·로고를 입력하고 양식을 제출'},
      {'num': '2', 'title': '결제 완료',    'desc': '담당자 확인 후 결제 안내 및 입금 확인'},
      {'num': '3', 'title': '디자인 확정',  'desc': '시안 검토 및 최종 디자인 확인'},
      {'num': '4', 'title': '제작 진행',    'desc': '14~21영업일 소요 (디자인 변경 포함 시 추가 기간 가능)'},
      {'num': '5', 'title': '배송',         'desc': '완성 후 일괄 발송, 배송 추적 번호 카카오 알림 발송'},
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
            border: Border.all(color: const Color(0xFFE8E8E8)),
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
                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.5)),
                ],
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  // ── 교환·환불 박스 ────────────────────────────────────────────
  Widget _buildExchangeBox() {
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
          // 기성품 교환환불 (강조 박스)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(left: BorderSide(color: _kBlack, width: 3)),
            ),
            child: const Text(
              '• 의류 자체 불량 외 교환·환불은 불가합니다.',
              style: TextStyle(fontSize: 13, height: 1.6, fontWeight: FontWeight.w700, color: _kBlack),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '• 커스텀 마킹이 포함된 경우 교환·환불이 불가합니다.',
            style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF444444)),
          ),
        ],
      ),
    );
  }

  // ── 첨부파일 안내 박스 ────────────────────────────────────────
  Widget _buildAttachGuide() {
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
          const Text(
            '주문서 작성 시 아래 파일을 첨부해주세요.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kBlack, height: 1.5),
          ),
          const SizedBox(height: 10),
          _buildAttachRow('로고 파일', 'AI, EPS, SVG, PNG (고해상도 권장)'),
          _buildAttachRow('디자인 참고 이미지', '원하는 디자인의 앞·뒤 사진 첨부'),
          _buildAttachRow('색상 코드', 'Pantone 또는 RGB/HEX 코드 기재'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(left: BorderSide(color: _kBlack, width: 2)),
            ),
            child: const Text(
              '파일 첨부가 어려운 경우 카카오톡 채널 @2FIT KOREA로 전송해 주세요.',
              style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF444444)),
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
            child: Text(desc, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF444444))),
          ),
        ],
      ),
    );
  }

  // ── 상품 카드 (탑텐 스타일: flat white box) ───────────────────
  Widget _buildProductCard(ProductModel product) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : '';
    final priceStr = product.price.toInt().toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
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
                _buildTag('세트 상품'),
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
      decoration: BoxDecoration(
        border: Border.all(color: _kBlack),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: _kBlack, fontWeight: FontWeight.w600)),
    );
  }

  // ── 동의 체크박스 (탑텐 스타일) ──────────────────────────────
  Widget _buildAgreementRow() {
    return GestureDetector(
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333), height: 1.5),
            ),
          ),
        ]),
      ),
    );
  }

  // ── 주문서 작성 버튼 (탑텐 스타일) ───────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
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
}
