// group_order_only_screen.dart
// 단체주문 전용 상품 목록 페이지
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/app_localizations.dart';
import '../../models/models.dart';
import '../../widgets/pc_layout.dart';
import '../products/product_detail_screen.dart';

class GroupOrderOnlyScreen extends StatefulWidget {
  const GroupOrderOnlyScreen({super.key});
  @override
  State<GroupOrderOnlyScreen> createState() => _GroupOrderOnlyScreenState();
}

class _GroupOrderOnlyScreenState extends State<GroupOrderOnlyScreen> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          loc.groupOrderOnlyTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: isPcWeb(context) ? 860 : double.infinity),
          child: Consumer<ProductProvider>(
            builder: (_, pp, __) {
              // isGroupOnly == true 인 상품만 필터
              final list = pp.products
                  .where((p) => p.isGroupOnly && p.isActive)
                  .toList();

              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64, color: Color(0xFFCCCCCC)),
                        const SizedBox(height: 16),
                        Text(
                          loc.groupOrderNoProduct,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF888888),
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildProductCard(list[i]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14)),
              child: p.images.isNotEmpty
                  ? Image.network(
                      p.images.first,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            // 상품 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 배지
                    Row(
                      children: [
                        _badge('단체전용', const Color(0xFF4A148C)),
                        if (p.isNew) ...[
                          const SizedBox(width: 4),
                          _badge('NEW', const Color(0xFF1565C0)),
                        ],
                        if (p.isSale) ...[
                          const SizedBox(width: 4),
                          _badge('SALE', const Color(0xFFC62828)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 상품명
                    Text(
                      p.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.subCategory.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        p.subCategory,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF888888)),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // 가격
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_fmt(p.price)}${loc.wonUnit2}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A2E)),
                        ),
                        if (p.originalPrice != null &&
                            p.originalPrice! > p.price) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${_fmt(p.originalPrice!)}${loc.wonUnit2}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFAAAAAA),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 화살표
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 40),
              child: Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFBBBBBB), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 110,
        height: 110,
        color: const Color(0xFFEEEEEE),
        child: const Icon(Icons.checkroom_rounded,
            color: Color(0xFFAAAAAA), size: 36),
      );
}
