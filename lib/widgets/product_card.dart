import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/products/product_detail_screen.dart';

// ignore: unused_import
import '../utils/app_localizations.dart';

/// 공유 상품 카드 — 홈화면 단체주문 카드와 동일한 스타일
/// · 흰 배경 / radius 10 / 연한 테두리 / 미세 그림자
/// · 이미지 4:5 비율 / BoxFit.contain / 밝은 회색 배경
/// · 좌상단: NEW / SALE / GROUP 배지
/// · 우상단: 할인율 배지 (있을 때만)
/// · 하단: [단체주문 전용 뱃지] → 상품명 → 가격
class ProductCard extends StatelessWidget {
  final ProductModel product;
  /// true = 카드 너비가 외부(ListView)에서 결정됨 (가로 스크롤용)
  /// false = GridView 셀 크기에 맞게 채움 (기본)
  final bool isHorizontal;
  /// false로 넘기면 _buildInfo()의 "단체주문 전용" 텍스트 배지를 숨김
  /// (홈화면 단체주문 전용 섹션 카드에서 중복 표시 방지)
  final bool showGroupBadge;

  const ProductCard({super.key, required this.product, this.isHorizontal = false, this.showGroupBadge = true});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImage(context),
              _buildInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── 이미지 영역 ──────────────────────────────────────────
  Widget _buildImage(BuildContext context) {
    final discount = product.originalPrice != null && product.originalPrice! > product.price
        ? ((1 - product.price / product.originalPrice!) * 100).round()
        : 0;

    // 배지 색상 결정
    Color badgeBg;
    String badgeText;
    if (product.isGroupOnly) {
      badgeBg = const Color(0xFF333333);
      badgeText = 'GROUP';
    } else if (product.isNewActive) {
      badgeBg = const Color(0xFF111111);
      badgeText = 'NEW';
    } else if (product.isSale && discount > 0) {
      badgeBg = const Color(0xFF333333);
      badgeText = 'SALE';
    } else {
      badgeBg = Colors.transparent;
      badgeText = '';
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          children: [
            // ── 상품 이미지 ──
            Container(
              color: const Color(0xFF1E1E1E),
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      filterQuality: FilterQuality.medium,
                      cacheWidth: 400,
                      cacheHeight: 500,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            // ── 좌상단 배지 (GROUP / NEW / SALE) ──
            if (badgeText.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // ── 우상단 할인율 ──
            if (discount > 0 && !product.isGroupOnly)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '-$discount%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

            // ── 단체주문: GROUP일 때 할인율도 표시 ──
            if (discount > 0 && product.isGroupOnly)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '-$discount%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

            // ── 무료배송 (우하단) ──
            if (product.isFreeShipping)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(6)),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.image_not_supported_rounded, color: Color(0xFF444444), size: 28),
    );
  }

  // ── 상품 정보 영역 ──────────────────────────────────────
  Widget _buildInfo(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    final loc  = context.watch<LanguageProvider>().loc;

    final hasDiscount = product.originalPrice != null && product.originalPrice! > product.price;
    final discount = hasDiscount
        ? ((1 - product.price / product.originalPrice!) * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 단체주문 전용 / 기성품 뱃지 (showGroupBadge=false 이면 숨김) ──
          if ((product.isGroupOnly || product.isReadyMade) && showGroupBadge) ...[
            Row(children: [
              if (product.isGroupOnly)
                Container(
                  margin: const EdgeInsets.only(right: 4, bottom: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF888888),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '단체주문 전용',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              if (product.isReadyMade)
                Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '기성품',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
            ]),
          ],

          // ── 상품명 (2줄 고정 높이로 카드 크기 균일화) ──
          SizedBox(
            height: 11 * 1.3 * 2, // fontSize(11) × lineHeight(1.3) × 2줄
            child: Text(
              product.localizedName(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 3),

          // ── 가격 ──
          if (hasDiscount) ...[
            // 정가 (취소선)
            Text(
              '${_fmt(product.originalPrice!)}${loc.productWonUnit}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.35),
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 1),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _fmt(product.price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  loc.productWonUnit,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '$discount%',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 정가만
            Text(
              '${_fmt(product.price)}${loc.productWonUnit}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],

          // ── 별점 ──
          if (product.rating > 0 && product.reviewCount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 10, color: Color(0xFFFFB300)),
                const SizedBox(width: 2),
                Text(
                  '${product.rating} (${product.reviewCount})',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}
