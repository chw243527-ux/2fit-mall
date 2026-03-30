import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/products/product_detail_screen.dart';

// ignore: unused_import
import '../utils/app_localizations.dart';
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isHorizontal;

  const ProductCard({super.key, required this.product, this.isHorizontal = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          // Nike 스타일 — 완전 평탄, 테두리 없음
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context),
            _buildInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Stack(
      children: [
        // 이미지: 정사각형, 모서리 0
        AspectRatio(
          aspectRatio: 1.0,
          child: product.images.isNotEmpty
              ? Image.network(
                  product.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        // 배지 그룹 (좌상단)
        Positioned(
          top: 0,
          left: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.isNew)
                _badge('NEW', Colors.white, const Color(0xFF111111)),
              if (product.isSale && product.discountPercent > 0)
                _badge('−${product.discountPercent}%', const Color(0xFFFF0000), Colors.white),
            ],
          ),
        ),
        // 무료배송 (우하단)
        if (product.isFreeShipping)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              color: const Color(0xFF111111),
              child: Text(
                loc.freeBadge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Color(0xFFDDDDDD)),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: bg,
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final loc = langProvider.loc;
    final lang = langProvider.language;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상품명 — 2줄까지 허용
          Text(
            product.localizedName(lang),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
              height: 1.3,
              letterSpacing: 0.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
          const SizedBox(height: 5),
          // 가격 행
          if (product.originalPrice != null && product.originalPrice! > product.price) ...[
            // 정가 (취소선)
            Row(
              children: [
                Text(
                  '정가 ',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_formatPrice(product.originalPrice!)}${loc.productWonUnit}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.4),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 4),
                // 할인율 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${(((product.originalPrice! - product.price) / product.originalPrice!) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (product.originalPrice != null && product.originalPrice! > product.price)
                Text(
                  '할인가 ',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                _formatPrice(product.price),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: (product.originalPrice != null && product.originalPrice! > product.price)
                      ? const Color(0xFFE53935)
                      : const Color(0xFF111111),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                loc.productWonUnit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: (product.originalPrice != null && product.originalPrice! > product.price)
                      ? const Color(0xFFE53935)
                      : const Color(0xFF111111),
                ),
              ),
            ],
          ),
          // 별점
          if (product.rating > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 11, color: Color(0xFF111111)),
                const SizedBox(width: 2),
                Text(
                  '${product.rating}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '(${product.reviewCount})',
                  style: const TextStyle(
                    fontSize: 10,
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

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
