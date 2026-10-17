import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../utils/theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_notice_card.dart';
import '../products/product_list_screen.dart';

/// 겨울 신상품 메인 배너에서 연결되는 기획전 화면입니다.
class WinterCollectionScreen extends StatelessWidget {
  const WinterCollectionScreen({super.key});

  static const _editorialProducts = <String>[
    '64230',
    '64228',
    '64239',
    '64220',
    '64213',
    '64214',
    '64226',
    '64235',
    '64237',
    '64218',
    '64211',
    '64215',
  ];

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final active = products.where((p) => p.isActive).toList();
    final newProducts = active.where((p) => p.isNewActive).toList();
    final winterProducts =
        active.where((p) => p.category == '아우터' || p.category == '세트').toList();
    final displayProducts = [
      ...newProducts,
      ...winterProducts.where((p) => !newProducts.contains(p)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('겨울 신상품 기획전'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProductProvider>().refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero(context)),
            SliverToBoxAdapter(child: _buildCollectionIntro(context)),
            SliverToBoxAdapter(child: _buildEditorialGrid(context)),
            if (displayProducts.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildSectionTitle('실제 판매 상품')),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 1000
                        ? 4
                        : constraints.crossAxisExtent >= 620
                            ? 3
                            : 2;
                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(
                          product: displayProducts[index],
                        ),
                        childCount: displayProducts.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 20,
                        // 이미지 아래 배지·상품명·가격이 모두 보이도록
                        // 카드 높이를 확보합니다.
                        childAspectRatio: 0.56,
                      ),
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 28),
                child: StoreNoticeCard(compact: true),
              ),
            ),
            SliverToBoxAdapter(child: _buildBottomCta(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/winter/winter_new_arrivals_banner.png',
            // 첨부한 16:9 디자인의 텍스트·상품이 잘리지 않도록
            // 원본 비율을 그대로 표시합니다.
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFF101C2B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionIntro(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WINTER NEW ARRIVALS',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '움직임을 위한 따뜻한 레이어',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '가볍고 따뜻한 패딩부터 데일리 레이어까지, 2FIT의 겨울 신상품을 한곳에서 만나보세요.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorialGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('겨울 컬렉션 미리보기'),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _editorialProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/winter/winter_${_editorialProducts[index]}.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFEDEFF2),
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductListScreen(initialCategory: '전체'),
            ),
          ),
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('신상품 전체 보기'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}
