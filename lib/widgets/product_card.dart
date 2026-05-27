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
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 카드 너비에 비례한 스케일 팩터 (기준: 180px)
          final cardW = constraints.maxWidth;
          final scale = (cardW / 180.0).clamp(0.7, 2.0);

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
            ),
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildImage(context, scale),
                  _buildInfo(context, scale),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(BuildContext context, double scale) {
    final loc = context.watch<LanguageProvider>().loc;
    // 디코딩 크기: 카드가 클수록 더 높은 해상도
    final cacheW = (400 * scale).round().clamp(200, 800);
    final cacheH = (500 * scale).round().clamp(250, 1000);

    return Stack(
      children: [
        // 이미지: 4:5 세로형 비율
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: product.images.isNotEmpty
                ? Image.network(
                    product.images.first,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    filterQuality: FilterQuality.medium,
                    cacheWidth: cacheW,
                    cacheHeight: cacheH,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
        // 배지 (좌상단)
        Positioned(
          top: 0, left: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.isNew)
                _badge('NEW', Colors.white, const Color(0xFF111111), scale),
              if (product.isSale && product.discountPercent > 0)
                _badge('−${product.discountPercent}%',
                    const Color(0xFFFF0000), Colors.white, scale),
            ],
          ),
        ),
        // 무료배송 (우하단)
        if (product.isFreeShipping)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: (6 * scale).clamp(4, 10),
                vertical: (3 * scale).clamp(2, 5),
              ),
              color: const Color(0xFF111111),
              child: Text(
                loc.freeBadge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (8 * scale).clamp(7, 12),
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

  Widget _badge(String text, Color bg, Color fg, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (6 * scale).clamp(4, 10),
        vertical: (3 * scale).clamp(2, 5),
      ),
      color: bg,
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: (9 * scale).clamp(7, 14),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, double scale) {
    final langProvider = context.watch<LanguageProvider>();
    final loc = langProvider.loc;
    final lang = langProvider.language;

    final hPad = (6 * scale).clamp(4.0, 14.0);
    final vPad = (8 * scale).clamp(5.0, 16.0);
    final nameSize = (12 * scale).clamp(10.0, 18.0);
    final labelSize = (9 * scale).clamp(8.0, 13.0);
    final priceSize = (15 * scale).clamp(12.0, 22.0);
    final wonSize = (11 * scale).clamp(9.0, 16.0);
    final starSize = (11 * scale).clamp(9.0, 15.0);
    final reviewSize = (10 * scale).clamp(8.0, 14.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상품명
          Text(
            product.localizedName(lang),
            style: TextStyle(
              fontSize: nameSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111111),
              height: 1.3,
              letterSpacing: 0.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: (5 * scale).clamp(3, 10)),
          // 정가 (취소선)
          if (product.originalPrice != null && product.originalPrice! > product.price) ...[
            Row(
              children: [
                Text('정가 ',
                  style: TextStyle(fontSize: labelSize,
                    color: Colors.black.withValues(alpha: 0.4), fontWeight: FontWeight.w500)),
                Text(
                  '${_formatPrice(product.originalPrice!)}${loc.productWonUnit}',
                  style: TextStyle(
                    fontSize: labelSize + 1,
                    color: Colors.black.withValues(alpha: 0.4),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                SizedBox(width: (4 * scale).clamp(2, 8)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (4 * scale).clamp(3, 7),
                    vertical: (1 * scale).clamp(1, 3),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${(((product.originalPrice! - product.price) / product.originalPrice!) * 100).round()}%',
                    style: TextStyle(
                      fontSize: labelSize,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: (2 * scale).clamp(1, 4)),
          ],
          // 판매가
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (product.originalPrice != null && product.originalPrice! > product.price)
                Text('할인가 ',
                  style: TextStyle(fontSize: labelSize,
                    color: const Color(0xFFE53935), fontWeight: FontWeight.w700)),
              Text(
                _formatPrice(product.price),
                style: TextStyle(
                  fontSize: priceSize,
                  fontWeight: FontWeight.w900,
                  color: (product.originalPrice != null && product.originalPrice! > product.price)
                      ? const Color(0xFFE53935)
                      : const Color(0xFF111111),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(width: (2 * scale).clamp(1, 4)),
              Text(
                loc.productWonUnit,
                style: TextStyle(
                  fontSize: wonSize,
                  fontWeight: FontWeight.w600,
                  color: (product.originalPrice != null && product.originalPrice! > product.price)
                      ? const Color(0xFFE53935)
                      : const Color(0xFF111111),
                ),
              ),
            ],
          ),
          // 별점
          if (product.rating > 0 && product.reviewCount > 0) ...[
            SizedBox(height: (4 * scale).clamp(2, 8)),
            Row(
              children: [
                Icon(Icons.star_rounded, size: starSize, color: const Color(0xFF111111)),
                SizedBox(width: (2 * scale).clamp(1, 4)),
                Text('${product.rating}',
                  style: TextStyle(fontSize: reviewSize,
                    fontWeight: FontWeight.w700, color: const Color(0xFF111111))),
                SizedBox(width: (3 * scale).clamp(2, 6)),
                Text('(${product.reviewCount})',
                  style: TextStyle(fontSize: reviewSize, color: const Color(0xFF888888))),
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
