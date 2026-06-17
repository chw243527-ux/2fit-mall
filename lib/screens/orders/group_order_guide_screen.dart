import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/net_image.dart';
import '../../utils/navigation_helper.dart';
import 'group_order_form_screen.dart';

// ═══════════════════════════════════════════════════════════════
// GroupOrderGuideScreen — 단체주문 안내 화면 (완전 재작성)
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
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── 상품 카드 (있을 때만) ────────────────────────
            if (widget.product != null) ...[
              _buildProductCard(widget.product!),
              const SizedBox(height: 20),
            ],

            // ── 최소 수량 ─────────────────────────────────────
            _buildSectionRow(Icons.groups_outlined, '최소 수량'),
            const SizedBox(height: 8),
            _buildInfoBox('단체 커스텀 제작은 최소 5명부터 가능합니다.'),
            const SizedBox(height: 20),

            // ── 제작 기간 ─────────────────────────────────────
            _buildSectionRow(Icons.schedule_outlined, '제작 기간'),
            const SizedBox(height: 8),
            _buildInfoBox('주문 확정 후 14~21일 소요됩니다.'),
            const SizedBox(height: 20),

            // ── 배송 안내 ─────────────────────────────────────
            _buildSectionRow(Icons.local_shipping_outlined, '배송 안내'),
            const SizedBox(height: 8),
            _buildInfoLines(const [
              '• 30만원 이상 구매 시: 무료배송',
              '• 30만원 미만: 착불',
              '• 단체주문 일괄배송 가능',
              '• 개별 배송 시 추가 요금 발생',
            ]),
            const SizedBox(height: 20),

            // ── 커스텀 옵션 ───────────────────────────────────
            _buildSectionRow(Icons.palette_outlined, '커스텀 옵션'),
            const SizedBox(height: 8),
            _buildInfoLines(const [
              '• 팀명 / 로고 / 번호 마킹 가능',
              '• 원하는 컬러로 제작 가능',
              '• 마킹 방법: 서브리메이션 인쇄',
            ]),
            const SizedBox(height: 20),

            // ── 독점 사용권 ───────────────────────────────────
            _buildSectionRow(Icons.lock_outline_rounded, '독점 사용권'),
            const SizedBox(height: 8),
            _buildExclusiveBox(),
            const SizedBox(height: 20),

            // ── 수량 할인 ─────────────────────────────────────
            _buildSectionRow(Icons.local_offer_outlined, '수량 할인'),
            const SizedBox(height: 8),
            _buildInfoLines(const [
              '• 30인 이상: 5% 할인',
              '• 50인 이상: 10% 할인',
              '• 추가 할인은 별도 문의',
            ]),
            const SizedBox(height: 20),

            // ── 추가 주문 ─────────────────────────────────────
            _buildSectionRow(Icons.add_circle_outline, '추가 주문'),
            const SizedBox(height: 8),
            _buildInfoLines(const [
              '• 기존 주문 후 추가 제작 가능',
              '• 동일 디자인 기준 최소 1명부터 가능',
              '• 추가 주문 시 단가 변동 없음',
            ]),
            const SizedBox(height: 20),

            // ── 교환·환불 ─────────────────────────────────────
            _buildSectionRow(Icons.swap_horiz_outlined, '교환·환불'),
            const SizedBox(height: 8),
            _buildInfoLines(const [
              '• 맞춤 제작 특성상 교환/환불 불가',
              '• 불량품은 전액 교환 처리',
            ]),
            const SizedBox(height: 20),

            // ── 주문서 첨부파일 안내 ────────────────────────────
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
        ),
      ),
    );
  }

  // ── 섹션 제목 행 ──────────────────────────────────────────────
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
            fontSize: 16, fontWeight: FontWeight.w900, color: _kBlack,
          ),
        ),
      ),
    ]);
  }

  // ── 단일 텍스트 박스 ──────────────────────────────────────────
  Widget _buildInfoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF444444)),
      ),
    );
  }

  // ── 복수 줄 박스 ──────────────────────────────────────────────
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
            '단체 커스텀 제작 시 해당 디자인에 대한 1년 독점 사용권을 무료로 제공합니다.',
            style: TextStyle(fontSize: 12, height: 1.7, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 4),
          const Text(
            '동일 디자인을 타 팀에 판매하지 않으며, 귀 팀만을 위한 전용 디자인으로 유지됩니다.',
            style: TextStyle(fontSize: 12, height: 1.7, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              border: Border(left: BorderSide(color: _kBlack, width: 3)),
            ),
            child: const Text(
              '1년 이후 연장 사용권 구매 시 별도 협의 가능합니다.',
              style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF333333), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── 상품 카드 ─────────────────────────────────────────────────
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
            ],
          ),
        ),
      ]),
    );
  }

  // ── 동의 체크박스 ─────────────────────────────────────────────
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
              '위 안내 내용을 모두 확인하였습니다.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF444444)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── 주문서 작성 버튼 ──────────────────────────────────────────
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
