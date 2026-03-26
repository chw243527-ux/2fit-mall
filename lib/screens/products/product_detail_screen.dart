import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/pc_layout.dart';
import '../orders/group_order_form_screen.dart';
import '../orders/group_order_guide_screen.dart';
import '../../widgets/color_picker_widget.dart';
import '../../utils/app_localizations.dart';
import '../../services/analytics_service.dart';

// ══════════════════════════════════════════════════════════════
// ProductDetailScreen
// ══════════════════════════════════════════════════════════════
class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  // ── 이미지 관련 ──
  int _mainImageIndex = 0;
  final PageController _pageCtrl = PageController();
  final ScrollController _scrollCtrl = ScrollController();
  final ValueNotifier<double> _imageOffsetNotifier = ValueNotifier(0); // 패럴랙스 오프셋 (setState 없이)

  // ── 상품 선택 ──
  String? _selectedSize;
  String? _selectedBottomLength;

  // ── 싱글렛/싱글렛세트 전용 ──
  String _singletGender = '남'; // '남' or '여'
  String _singletType = 'A';   // 'A' or 'B' (A타입 레이서백 / B타입 스쿱넥)

  // ── 탭 ──
  late TabController _tabCtrl;

  // ── 로컬 섹션 이미지 캐시 (관리자 업로드 시 즉시 반영) ──
  late Map<String, List<String>> _sectionImages;

  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _sectionImages = Map<String, List<String>>.from(widget.product.sectionImages);
    // 성별 기본값: 남성 → 하의 5부 자동 설정
    _singletGender = '남';
    _selectedBottomLength = '5부';
    _scrollCtrl.addListener(() {
      // ValueNotifier 사용 → setState 없이 패럴랙스만 업데이트 (전체 rebuild 방지)
      _imageOffsetNotifier.value = (_scrollCtrl.offset * 0.4).clamp(0, 120);
    });
    // GA4: 상품 조회 이벤트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.logViewItem(
        itemId: widget.product.id,
        itemName: widget.product.name,
        price: widget.product.price,
        category: widget.product.category,
      );
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _scrollCtrl.dispose();
    _tabCtrl.dispose();
    _imageOffsetNotifier.dispose();
    super.dispose();
  }

  String _fmt(double p) => p
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ═══════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<UserProvider>().isAdmin;

    // ProductProvider를 watch → 관리자가 이미지/정보 수정 시 즉시 반영
    final productProvider = context.watch<ProductProvider>();
    final liveProduct = productProvider.products
        .firstWhere((p) => p.id == widget.product.id, orElse: () => widget.product);
    final product = liveProduct;

    // 로컬 _sectionImages를 최신 product 데이터와 동기화
    // (관리자가 다른 화면에서 수정했을 때 반영)
    for (final key in product.sectionImages.keys) {
      if (!_sectionImages.containsKey(key) ||
          _sectionImages[key] != product.sectionImages[key]) {
        _sectionImages[key] = List<String>.from(product.sectionImages[key]!);
      }
    }
    // 삭제된 섹션 키 제거
    _sectionImages.removeWhere((key, _) => !product.sectionImages.containsKey(key)
        && !_sectionImages.containsKey(key));

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // PC 웹이면 PC 전용 레이아웃 사용
    if (isPcWeb(context)) return _buildPcLayout(product, isAdmin, loc);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            cacheExtent: 1200, // 미리 렌더링 범위 확대
            slivers: [
              _buildSliverHeader(product),
              SliverToBoxAdapter(child: _buildThumbnailBar(product)),
              SliverToBoxAdapter(child: _buildBasicInfo(product)),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection1Banner(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection2Material(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection3Pocket(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection5GoljiColors(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection6SizeChart(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildReviewSection(product))),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomBar(product),
          ),
        ],
      ),
    );
  }

  // ─── PC 전용 레이아웃 ───────────────────────────────────────────
  Widget _buildPcLayout(ProductModel product, bool isAdmin, dynamic loc) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1A1A1A), size: 28),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(product.localizedName(_lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  // ── 상단: 이미지 + 구매 정보 2컬럼 ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 왼쪽: 이미지 갤러리
                      Expanded(
                        flex: 5,
                        child: _buildPcImageGallery(product),
                      ),
                      const SizedBox(width: 32),
                      // 오른쪽: 상품 정보 + 구매
                      Expanded(
                        flex: 5,
                        child: _buildPcProductInfo(product),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // ── 하단: 상세 설명 섹션들 ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            _buildSection1Banner(product, isAdmin),
                            _buildSection2Material(product, isAdmin),
                            _buildSection3Pocket(product, isAdmin),
                            _buildSection5GoljiColors(product, isAdmin),
                            _buildSection6SizeChart(product, isAdmin),
                            _buildReviewSection(product),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // 오른쪽 사이드: 고정 구매 요약
                      SizedBox(
                        width: 300,
                        child: _buildPcStickyOrderCard(product),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPcImageGallery(ProductModel product) {
    final images = product.images.isNotEmpty ? product.images : <String>[];
    return Column(
      children: [
        // 메인 이미지
        Container(
          height: 480,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: images.isNotEmpty
                ? PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _mainImageIndex = i),
                    itemCount: images.length,
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                  ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  _pageCtrl.jumpToPage(i);
                  setState(() => _mainImageIndex = i);
                },
                child: Container(
                  width: 72,
                  height: 72,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _mainImageIndex == i ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
                      width: _mainImageIndex == i ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(images[i], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF0F0F0))),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPcProductInfo(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뱃지
          Row(
            children: [
              if (product.isNew) _pcBadge('NEW', const Color(0xFF1565C0)),
              if (product.isSale) _pcBadge('SALE', const Color(0xFFE53935)),
              if (product.isFreeShipping) _pcBadge(loc.freeShipping, const Color(0xFF2E7D32)),
            ],
          ),
          const SizedBox(height: 12),
          Text(product.localizedName(_lang), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text(product.localizedDescription(_lang), style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.6)),
          const SizedBox(height: 20),
          // 가격
          if (product.originalPrice != null)
            Text('${_formatPricePC(product.originalPrice!)}${loc.wonUnit}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF999999), decoration: TextDecoration.lineThrough)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_formatPricePC(product.price)}${loc.wonUnit}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              // ignore: unnecessary_null_comparison
              if (product.discountPercent != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4)),
                  // ignore: unnecessary_non_null_assertion
                  child: Text('${product.discountPercent!.toInt()}% OFF',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const Divider(height: 32, color: Color(0xFFF0F0F0)),
          // 별점
          Row(
            children: [
              ...List.generate(5, (i) => Icon(Icons.star_rounded,
                  size: 18, color: i < product.rating.floor() ? const Color(0xFFFFD600) : const Color(0xFFEEEEEE))),
              const SizedBox(width: 8),
              Text('${product.rating} ${loc.productReviewCountLabel(product.reviewCount)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
            ],
          ),
          const SizedBox(height: 20),
          // 소재
          _pcInfoRow(loc.materialLabel, product.material),
          _pcInfoRow(loc.sizeLabel, product.sizes.join(', ')),
          _pcInfoRow(loc.colorLabel, product.colors.join(', ')),
          const Divider(height: 32, color: Color(0xFFF0F0F0)),
          // 구매방식 선택 (기성품 / 단체주문) — 해당 상품만 표시
          _buildPurchaseTypeSection(product),
          // 사이즈/수량/구매버튼: 단체주문 전용이 아닐 때만 표시
          if (!product.isGroupOnly) ...[
            const SizedBox(height: 8),
          ],
          // 구매 버튼
          if (product.isGroupOnly) ...[
            // ── 단체주문 전용: 단체주문 버튼만 ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                label: Text(loc.groupOrderBtn,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A148C),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _showGroupOrderGuide(product),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addToCart(product),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(loc.cartLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _showBuyNowSheet(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(loc.buyNow, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPcStickyOrderCard(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 단체주문 전용 배너 (isGroupOnly) ──
          if (product.isGroupOnly) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(loc.groupOrderOnly,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 단체주문 안내
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A148C).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4A148C).withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF4A148C)),
                    const SizedBox(width: 6),
                    Text(loc.groupOrderInfo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4A148C))),
                  ]),
                  const SizedBox(height: 8),
                  _PcInfoLine(icon: Icons.check_circle_outline_rounded, text: loc.groupOrderMin),
                  const SizedBox(height: 4),
                  _PcInfoLine(icon: Icons.check_circle_outline_rounded, text: loc.groupOrderPrint),
                  const SizedBox(height: 4),
                  _PcInfoLine(icon: Icons.check_circle_outline_rounded, text: loc.groupOrderDiscount),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 단체주문 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
                label: Text(loc.groupOrderApply,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A148C),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _showGroupOrderGuide(product),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Divider(height: 24),
          Text(loc.shippingInfo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          // 30만원 무료배송 안내 배너
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 15, color: Color(0xFF1565C0)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: '30만원 이상 구매 시 ',
                          style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
                        ),
                        TextSpan(
                          text: loc.freeShipping,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1565C0)),
                        ),
                        const TextSpan(
                          text: ' 혜택 제공',
                          style: TextStyle(fontSize: 12, color: Color(0xFF555555)),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(loc.productMaxPrice, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          _pcInfoRow(loc.shippingFee, product.isFreeShipping ? loc.freeShippingBadge : loc.shippingFeeValue),
          _pcInfoRow(loc.shippingDays, loc.deliveryDaysValue),
          _pcInfoRow(loc.returnPolicy, loc.returnPolicyValue),
        ],
      ),
    );
  }

  Widget _pcBadge(String label, Color color) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
  );

  Widget _pcInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF888888)))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
      ],
    ),
  );

  String _formatPricePC(double price) => price.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ═══════════════════════════════════════
  // SLIVER HEADER (이미지 + 패럴랙스)
  // ═══════════════════════════════════════
  Widget _buildSliverHeader(ProductModel product) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A1A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<UserProvider>(
          builder: (_, up, __) {
            final isWish = up.isInWishlist(product.id);
            return IconButton(
              icon: Icon(
                isWish ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isWish ? Colors.redAccent : Colors.white,
              ),
              onPressed: () {
                if (up.isLoggedIn) {
                  final wasInWishlist = up.isInWishlist(product.id);
                  up.toggleWishlist(product.id);
                  if (!wasInWishlist) {
                    AnalyticsService.logAddToWishlist(
                      itemId: product.id,
                      itemName: product.name,
                      price: product.price,
                    );
                  }
                } else {
                  final l = context.watch<LanguageProvider>().loc;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.loginRequired)),
                  );
                }
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          onPressed: () => _shareProduct(product),
        ),
        // 라이트박스 열기
        IconButton(
          icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
          onPressed: () => _showLightbox(product, _mainImageIndex),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 패럴랙스: ValueListenableBuilder로 이미지만 분리 빌드 (setState 없이)
            ValueListenableBuilder<double>(
              valueListenable: _imageOffsetNotifier,
              builder: (_, offset, child) => Transform.translate(
                offset: Offset(0, -offset),
                child: child,
              ),
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: product.images.isNotEmpty ? product.images.length : 1,
                onPageChanged: (i) => setState(() => _mainImageIndex = i),
                itemBuilder: (_, i) {
                  final url = product.images.isNotEmpty ? product.images[i] : '';
                  return GestureDetector(
                    onTap: () => _showLightbox(product, i),
                    child: url.isNotEmpty
                        ? Image.network(url,
                            fit: BoxFit.cover,
                            cacheWidth: 600,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) => _imagePlaceholder())
                        : _imagePlaceholder(),
                  );
                },
              ),
            ),
            // 하단 그라디언트
            const Positioned(
              bottom: 0, left: 0, right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x88000000)],
                  ),
                ),
                child: SizedBox(height: 80),
              ),
            ),
            // 페이지 인디케이터
            if (product.images.length > 1)
              Positioned(
                bottom: 14, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(product.images.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: _mainImageIndex == i ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _mainImageIndex == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            // 이미지 번호
            Positioned(
              top: 12, right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_mainImageIndex + 1} / ${product.images.isEmpty ? 1 : product.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFEEEEEE),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 80, color: Color(0xFFCCCCCC)),
        ),
      );

  // ══ 상품 공유 ══
  void _shareProduct(ProductModel product) {
    final productUrl = 'https://2fit-mall.co.kr/#/product/${product.id}';
    final price = product.price > 0
        ? '₩${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원'
        : '';
    final text = '''[2FIT MALL] ${product.name}
$price
$productUrl

2FIT MALL에서 최고의 스포츠웨어를 만나보세요!''';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('공유하기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 링크 복사
                _shareOption(
                  icon: Icons.link_rounded,
                  color: const Color(0xFF6C63FF),
                  label: '링크 복사',
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: productUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('링크가 복사되었습니다 ✓'), backgroundColor: Color(0xFF4CAF50)),
                    );
                  },
                ),
                // 카카오톡 공유 (URL scheme)
                _shareOption(
                  icon: Icons.chat_bubble_rounded,
                  color: const Color(0xFFFFE812),
                  iconColor: const Color(0xFF3A1D1D),
                  label: '카카오톡',
                  onTap: () async {
                    Navigator.pop(context);
                    await _shareViaKakao(product, productUrl);
                  },
                ),
                // 기타 공유
                _shareOption(
                  icon: Icons.share_rounded,
                  color: const Color(0xFF1A1A1A),
                  label: '기타 공유',
                  onTap: () {
                    Navigator.pop(context);
                    SharePlus.instance.share(ShareParams(text: text, subject: product.name));
                  },
                ),
                // 카카오 채널 문의
                _shareOption(
                  icon: Icons.support_agent_rounded,
                  color: const Color(0xFF2DB400),
                  label: '채널 문의',
                  onTap: () {
                    Navigator.pop(context);
                    _openKakaoChannel();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _shareViaKakao(ProductModel product, String url) async {
    // 카카오톡 앱 링크로 공유 (웹 폴백 포함)
    final kakaoShareUrl = Uri.parse(
      'kakaolink://send?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent(product.name)}',
    );
    final webFallbackUrl = Uri.parse('https://story.kakao.com/share?url=${Uri.encodeComponent(url)}');

    if (await canLaunchUrl(kakaoShareUrl)) {
      await launchUrl(kakaoShareUrl);
    } else {
      // 웹 브라우저 폴백 또는 일반 공유
      if (await canLaunchUrl(webFallbackUrl)) {
        await launchUrl(webFallbackUrl, mode: LaunchMode.externalApplication);
      } else {
        // 최후 폴백: 클립보드에 복사
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('링크가 복사되었습니다 (카카오톡에 직접 붙여넣기해 주세요) ✓')),
          );
        }
      }
    }
  }

  Future<void> _openKakaoChannel() async {
    const channelId = '@2fitkorea';
    final kakaoChannelUrl = Uri.parse('kakaoplus://plusfriend/home/$channelId');
    final webUrl = Uri.parse('https://pf.kakao.com/_xjxmxaK'); // 실제 카카오 채널 URL로 변경 필요
    
    if (await canLaunchUrl(kakaoChannelUrl)) {
      await launchUrl(kakaoChannelUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카카오 채널: @2fitkorea')),
        );
      }
    }
  }

  // ══ 라이트박스 ══
  void _showLightbox(ProductModel product, int initialIndex) {
    final images = product.images.isNotEmpty ? product.images : [''];
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (_) => _LightboxDialog(images: images, initialIndex: initialIndex),
    );
  }

  // ══ 썸네일 바 (클릭 → 메인 이미지 교체) ══
  Widget _buildThumbnailBar(ProductModel product) {
    if (product.images.length <= 1) return const SizedBox.shrink();
    return Container(
      height: 80,
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: product.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = _mainImageIndex == i;
          return GestureDetector(
            onTap: () {
              // 썸네일 클릭 → 메인 이미지 교체
              _pageCtrl.animateToPage(i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
              setState(() => _mainImageIndex = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: selected
                    ? [BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8)]
                    : null,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5.5),
                    child: Image.network(
                      product.images[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      cacheWidth: 150,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFEEEEEE),
                        child: const Icon(Icons.image, size: 20, color: Color(0xFFCCCCCC)),
                      ),
                    ),
                  ),
                  // 선택된 썸네일 오버레이
                  if (selected)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5.5),
                      child: Container(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        child: const Center(
                          child: Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // 기본 정보
  // ═══════════════════════════════════════
  Widget _buildBasicInfo(ProductModel product) {
    final discount = product.originalPrice != null && product.originalPrice! > product.price
        ? ((1 - product.price / product.originalPrice!) * 100).round() : 0;
    final isAdmin = context.read<UserProvider>().isAdmin;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 디자인 이미지 셀린 (카테고리 위) ──
          _buildDesignImageSection(product, isAdmin),
          // 카테고리 + 배지
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: Text(product.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
              ),
              // ── 기성품 / 단체주문 전용 구분 배지 ──
              if (!product.isGroupOnly) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag_rounded, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(loc.readyMadeLabel,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_rounded, size: 10, color: Color(0xFF1565C0)),
                      const SizedBox(width: 3),
                      const Text('2~3일 배송',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_rounded, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(loc.groupOrderLabel,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ],
              if (product.isNew) ...[const SizedBox(width: 6), _tag('NEW', AppColors.primary)],
              if (product.isSale) ...[const SizedBox(width: 6), _tag('SALE', AppColors.accent)],
              if (product.isFreeShipping) ...[const SizedBox(width: 6), _tag(loc.freeShipping, const Color(0xFF43A047))],
            ],
          ),
          const SizedBox(height: 10),
          // 브랜드
          const Text('2FIT KOREA', style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          // 상품명
          Text(product.localizedName(_lang),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), height: 1.2)),
          const SizedBox(height: 10),

          // ── 기성품 타이즈/싱글렛세트: 하의 색상 선택 안내 배너 (해당 카테고리만 표시) ──
          if (!product.isGroupOnly && _showBottomColorBadge(product)) ...[
            _buildColorInfoBadge(product),
            const SizedBox(height: 12),
          ],

          // 가격 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.originalPrice != null) ...[
                    Row(
                      children: [
                        Text('${_fmt(product.originalPrice!)}${loc.wonUnit}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA), decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 8),
                        if (discount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4)),
                            child: Text(loc.productDiscountLabel(discount), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text('${_fmt(product.price)}${loc.wonUnit}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 별점
          Row(
            children: [
              Row(
                children: List.generate(5, (i) => Icon(Icons.star_rounded,
                    size: 16,
                    color: i < product.rating.floor() ? const Color(0xFFFFD600) : const Color(0xFFE0E0E0))),
              ),
              const SizedBox(width: 6),
              Text('${product.rating}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF333333))),
              const SizedBox(width: 4),
              Text(loc.productReviewCountLabel(product.reviewCount), style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            ],
          ),
          const SizedBox(height: 14),
          // 배송/혜택 정보
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                _infoRow(Icons.local_shipping_outlined, loc.shippingLabel,
                    product.isFreeShipping ? loc.freeShipping : loc.basicShippingFeeInfo),
                const SizedBox(height: 8),
                _infoRow(Icons.access_time_rounded, loc.dispatchLabel,
                    loc.dispatchDaysInfo),
                const SizedBox(height: 8),
                _infoRow(Icons.stars_rounded, loc.pointLabel,
                    loc.pointAccumulateInfo),
                const SizedBox(height: 8),
                _infoRow(Icons.swap_horiz_rounded, loc.exchangeReturnLabel,
                    loc.exchangeReturnInfo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF888888)),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // 상의 색상 안내 배너용 행 위젯
  Widget _colorNoticeRow(IconData icon, String label, String desc, {required bool highlight}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: highlight ? const Color(0xFFFFD54F) : Colors.white70,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: highlight ? const Color(0xFFFFD54F) : Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? Colors.white : Colors.white70,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  /// 타이즈 또는 싱글렛세트만 하의 색상 선택 배너 표시
  bool _showBottomColorBadge(ProductModel p) {
    final isTaiz = p.category == '하의' ||
        p.subCategory.contains('타이즈') ||
        p.name.contains('타이즈');
    final isSingletSet = p.category == '세트' ||
        p.subCategory.contains('싱글렛세트') ||
        p.subCategory.contains('싱글렛 A타입세트');
    return isTaiz || isSingletSet;
  }

  /// 상품명 아래 기성품 색상 안내 뱃지 (싱글렛세트 / 상의 구분)
  Widget _buildColorInfoBadge(ProductModel product) {
    // 타이즈와 싱글렛세트 모두 "하의 색상 선택" 표시
    final isTaiz = product.category == '하의' ||
        product.subCategory.contains('타이즈') ||
        product.name.contains('타이즈');
    final label = isTaiz ? '타이즈' : '기성품';
    final subtitle = isTaiz
        ? '색상을 선택하세요 (19가지)'
        : '상의는 디자인 색상 그대로 제작, 하의 색상은 선택 가능합니다.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.palette_rounded, size: 16, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(label,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(width: 6),
                    const Text('하의 색상 선택',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF555555), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      );

  // ═══════════════════════════════════════
  // ═══════════════════════════════════════
  // 하의 길이 선택 (인라인)
  // ═══════════════════════════════════════
  // ignore: unused_element
  Widget _buildInlineLengthSection() {
    const lengths = AppConstants.bottomLengths;
    final product = widget.product;
    final isSingletSet = (product.category == '세트' &&
            (product.subCategory.contains('싱글렛세트') ||
             product.subCategory.contains('싱글렛 A타입세트'))) ||
        product.category.contains('싱글렛세트') ||
        product.subCategory.contains('싱글렛세트') ||
        product.subCategory.contains('싱글렛 A타입세트') ||
        (product.category == '세트' && product.name.contains('싱글렛'));

    // 싱글렛세트: 남/여 선택 → 5부/2.5부 자동고정 UI
    if (isSingletSet) {
      // 성별에 따라 하의길이 자동반영
      final autoLength = _singletGender == '남' ? '5부' : '2.5부';
      // 상태가 아직 반영 안 됐으면 반영
      if (_selectedBottomLength != autoLength) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedBottomLength = autoLength);
        });
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 10),
            // 제목 + 안내
            Row(
              children: [
                Text(loc.bottomLengthTitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A148C).withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.3)),
                  ),
                  child: Text(loc.genderAutoFix,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF6A1B9A), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 남/여 선택 버튼
            Row(
              children: [
                _inlineGenderBtn('남', loc.male, loc.maleBottomSub),
                const SizedBox(width: 8),
                _inlineGenderBtn('여', loc.female, loc.femaleBottomSub),
              ],
            ),
            const SizedBox(height: 8),

            // 확정된 길이 표시
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF6A1B9A)),
                  const SizedBox(width: 6),
                  Text(
                    '하의 기장 ${_singletGender == "남" ? "5부 (~55cm)" : "2.5부 (~30cm)"} 확정',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A148C)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 일반 상품: 기존 하의길이 선택 UI
    List<String>? allowedLengths;
    for (final entry in AppConstants.productLengthRestrictions.entries) {
      if (product.name.contains(entry.key)) {
        allowedLengths = entry.value;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(loc.bottomLengthSelectTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              if (allowedLengths != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                  ),
                  child: Text(loc.restrictedLabel,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: lengths.map((l) {
              final label = l['label']!;
              final isAllowed = allowedLengths == null || allowedLengths.contains(label);
              final sel = _selectedBottomLength == label;
              return GestureDetector(
                onTap: isAllowed
                    ? () => setState(() => _selectedBottomLength = label)
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.restrictedLengthNote.replaceAll('%s', allowedLengths!.join('·'))),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: !isAllowed
                        ? const Color(0xFFF0F0F0)
                        : sel
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !isAllowed
                          ? const Color(0xFFDDDDDD)
                          : sel
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFE0E0E0),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: !isAllowed
                                  ? const Color(0xFFBBBBBB)
                                  : sel
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (allowedLengths != null) ...[
            const SizedBox(height: 6),
            Text('* ${loc.productAllowedLengthNote}: ${allowedLengths.join("·")}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0))),
          ],
        ],
      ),
    );
  }

  // 성별 선택 버튼 (모든 제품에 표시)
  Widget _inlineGenderBtn(String code, String label, String subLabel, {bool autoLength = false}) {
    final isSel = _singletGender == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _singletGender = code;
          // 성별 선택 시 하의길이 자동 선택 (싱글렛세트: 남=5부, 여=2.5부)
          _selectedBottomLength = code == '남' ? '5부' : '2.5부';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: subLabel.isEmpty ? 14 : 12),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF111111) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? const Color(0xFF111111) : const Color(0xFFDDDDDD),
              width: isSel ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                code == '남' ? Icons.male_rounded : Icons.female_rounded,
                size: 20,
                color: isSel ? Colors.white : const Color(0xFF888888),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSel ? Colors.white : const Color(0xFF333333))),
              if (subLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: isSel
                            ? Colors.white.withValues(alpha: 0.8)
                            : const Color(0xFF888888))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 사이즈 선택
  // ═══════════════════════════════════════

  // 싱글렛세트 전용: 단일 하의길이 버튼 (선택된 것만 표시)
  Widget _singletLengthOnlyBtn({required String label, required String desc}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF111111), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.straighten_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 6),
          Text(desc,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(loc.confirmLabel,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // 구매 방식 선택 (인라인 섹션)
  // ═══════════════════════════════════════
  Widget _buildPurchaseTypeSection(ProductModel product) {

    // ── 카테고리 판별 ──────────────────────────────────────────────
    // 싱글렛 A타입세트: 세트 카테고리 + subCategory/name에 싱글렛+A타입 포함
    final isSingletATypeSet =
        (product.category == '세트' && product.subCategory.contains('싱글렛 A타입세트')) ||
        product.subCategory.contains('싱글렛 A타입세트') ||
        (product.category == '세트' && product.name.contains('싱글렛') && product.name.contains('A타입'));

    // 타이즈 / 하의 전체 (싱글렛세트 제외)
    final isTaiz = !isSingletATypeSet && (
        product.category == '하의' ||
        product.subCategory.contains('타이즈') ||
        product.name.contains('타이즈'));

    // 트레이닝세트: 세트 카테고리 + 트레이닝 포함
    final isTrainingSet = !isSingletATypeSet && (
        (product.category == '세트' && product.subCategory.contains('트레이닝세트')) ||
        (product.category == '세트' && product.name.contains('트레이닝')));

    // 하의 길이 선택 표시 여부: 타이즈 or 싱글렛 A타입세트
    final showLengthPicker = isTaiz || isSingletATypeSet;
    // 9부 고정 표시 여부: 트레이닝세트
    final showFixedLength9 = isTrainingSet;

    // 타이즈/싱글렛세트: 하의 색상 선택 안내 표시 여부
    final isSingletTop = !product.isGroupOnly && _showBottomColorBadge(product);

    // 싱글렛세트 여부: 상의+하의 세트라서 "하의 색상 선택"으로 표기
    final isSingletSet = product.category == '세트' ||
        product.subCategory.contains('싱글렛세트') ||
        product.subCategory.contains('싱글렛 A타입세트');

    // 싱글렛세트 초기 길이 자동 설정 (남=5부, 여=2.5부)
    if (isSingletATypeSet) {
      final autoLength = _singletGender == '남' ? '5부' : '2.5부';
      if (_selectedBottomLength != '5부' && _selectedBottomLength != '2.5부') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedBottomLength = autoLength);
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── 기성품 싱글렛(상의): 상의 색상 고정 안내 배너 (강조형) ──
          if (isSingletTop) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    // 헤더
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1A6ED4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSingletSet ? '하의 색상 선택 안내' : '기성품 색상 안내',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('기성품',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    // 상의 색상 고정 행
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: const Color(0xFFFFF3E0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFE65100)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('상의 색상 — 변경 불가',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFBF360C))),
                                const SizedBox(height: 2),
                                Text('디자인 색상 그대로 제작됩니다',
                                  style: TextStyle(fontSize: 11, color: const Color(0xFFBF360C).withValues(alpha: 0.8), height: 1.3)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('고정',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    // 구분선
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    // 하의 색상 선택 가능 행
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: const Color(0xFFE8F5E9),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('하의 색상 — 선택 가능',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
                                const SizedBox(height: 2),
                                Text(
                                  isSingletSet
                                      ? '19가지 색상 중 하의 색상을 선택하세요'
                                      : '19가지 색상 중 자유롭게 선택하세요',
                                  style: TextStyle(fontSize: 11, color: const Color(0xFF1B5E20).withValues(alpha: 0.8), height: 1.3)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('선택',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    // 하단 안내
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      color: const Color(0xFFF5F5F5),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFF888888)),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              '하의 색상 선택은 장바구니 / 바로구매 버튼을 눌러 진행하세요',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF666666), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── 싱글렛 A타입세트: 하의 기장 자동적용 안내 배너 ──
          if (isSingletATypeSet) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4A148C).withValues(alpha: 0.08),
                    const Color(0xFF6A1B9A).withValues(alpha: 0.04),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_fix_high_rounded, size: 14, color: Color(0xFF6A1B9A)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.bottomAutoApplyTitle,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4A148C))),
                        const SizedBox(height: 2),
                        Text(loc.bottomAutoApplyDesc,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6A1B9A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── 트레이닝세트: 9부 고정 안내 배너 ──
          if (showFixedLength9) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF6A1B9A)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.bottomFixedTitle,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4A148C))),
                        const SizedBox(height: 2),
                        Text(loc.bottomFixedDesc,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6A1B9A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (!product.isGroupOnly) ...[
            Text(loc.purchaseType,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
          ],

          // ── 구매방식 버튼 (기성품 / 단체주문) ──
          Builder(builder: (context) {
            final showGroupBtn = product.isGroupOnly || _showGroupOrderBtn(product);
            return Row(
              children: [
                if (!product.isGroupOnly) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showBuyNowSheet(product),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                            const SizedBox(height: 4),
                            Text(loc.readyMadeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                )),
                            Text(loc.buyNow,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (showGroupBtn) ...[
                  if (!product.isGroupOnly) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showGroupOrderGuide(product),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
                            const SizedBox(height: 4),
                            Text(loc.groupOrderLabel,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                            Text(loc.groupOrderSubLabel,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),

          // ── 성별 선택 (단체주문 전용 상품 제외) ──
          if (!product.isGroupOnly) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          Text(loc.gender,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Row(children: [
            _inlineGenderBtn('남', loc.male, isSingletATypeSet ? loc.maleBottomSub : '', autoLength: isSingletATypeSet),
            const SizedBox(width: 8),
            _inlineGenderBtn('여', loc.female, isSingletATypeSet ? loc.femaleBottomSub : '', autoLength: isSingletATypeSet),
          ]),

          // ── 싱글렛 A타입세트: 성별에 따라 하의 길이 1개만 표시 ──
          if (isSingletATypeSet) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            Text(loc.bottomLengthTitle,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            if (_singletGender == '남') ...[
              _singletLengthOnlyBtn(label: '5부', desc: '~55 cm'),
            ] else ...[
              _singletLengthOnlyBtn(label: '2.5부', desc: '~30 cm'),
            ],
          ],

          // ── 타이즈: 하의 길이 선택 (전체 옵션) ──
          if (isTaiz) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            Text(loc.bottomLengthTitle,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: AppConstants.bottomLengths.map((l) {
                final label = l['label']!;
                final desc  = l['desc']!;
                final sel   = _selectedBottomLength == label;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBottomLength = label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF111111) : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel ? const Color(0xFF111111) : const Color(0xFFDDDDDD),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                        const SizedBox(height: 2),
                        Text(desc,
                            style: TextStyle(
                                fontSize: 10,
                                color: sel
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : const Color(0xFF999999))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // ── 트레이닝세트: 9부 고정 표시 칩 ──
          if (showFixedLength9) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            Text(loc.bottomLengthTitle,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF111111), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.productShorter9,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(loc.fixedLabel,
                      style: const TextStyle(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
          ],
          ], // end if (!product.isGroupOnly)
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 관리자 전용: 섹션 이미지 업로드 위젯
  // ═══════════════════════════════════════════════════════════
  // 하의길이 참조 이미지 — 남자 / 여자 분리 업로드 섹션
  // ═══════════════════════════════════════════════════════════
  Widget _buildGenderLengthImageSection(bool isAdmin) {
    // 기존 통합키 s2_length 이미지도 표시 (하위호환)
    final legacyImgs = _sectionImages['s2_length'] ?? [];
    final maleImgs   = _sectionImages['s2_length_male'] ?? [];
    final femaleImgs = _sectionImages['s2_length_female'] ?? [];

    // 표시 여부: 관리자이거나 이미지 있을 때
    final showMale   = isAdmin || maleImgs.isNotEmpty || legacyImgs.isNotEmpty;
    final showFemale = isAdmin || femaleImgs.isNotEmpty;

    if (!showMale && !showFemale) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 섹션 헤더 ──
        if (isAdmin)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.photo_library_rounded, size: 14, color: Color(0xFF7B1FA2)),
                const SizedBox(width: 6),
                Text(loc.productLengthRefImg,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF7B1FA2))),
              ],
            ),
          ),

        if (isAdmin) const SizedBox(height: 10),

        // ── 남자 섹션 ──
        if (showMale) ...[
          _buildGenderImageHeader(
            icon: Icons.male_rounded,
            label: loc.maleLengthRef,
            color: const Color(0xFF1565C0),
            bgColor: const Color(0xFFE3F2FD),
          ),
          const SizedBox(height: 6),
          // 기존 s2_length 이미지가 있으면 하위호환으로 표시
          if (legacyImgs.isNotEmpty && maleImgs.isEmpty)
            _buildAdminImageSection('s2_length', '남자 하의길이 참조 이미지', isAdmin)
          else
            _buildAdminImageSection('s2_length_male', '남자 하의길이 참조 이미지', isAdmin),
        ],

        // ── 여자 섹션 ──
        if (showFemale) ...[
          const SizedBox(height: 12),
          _buildGenderImageHeader(
            icon: Icons.female_rounded,
            label: loc.femaleLengthRef,
            color: const Color(0xFFAD1457),
            bgColor: const Color(0xFFFCE4EC),
          ),
          const SizedBox(height: 6),
          _buildAdminImageSection('s2_length_female', '여자 하의길이 참조 이미지', isAdmin),
        ],
      ],
    );
  }

  Widget _buildGenderImageHeader({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════

  /// 관리자용 섹션 이미지 표시 + 업로드 버튼
  Widget _buildAdminImageSection(
    String sectionKey,
    String sectionLabel,
    bool isAdmin,
  ) {
    final imgs = _sectionImages[sectionKey] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 관리자 업로드 버튼
        if (isAdmin)
          _buildAdminUploadButton(sectionKey, sectionLabel, imgs),

        // 이미지 목록 (관리자: 드래그 순서변경 가능)
        if (imgs.isNotEmpty) ...[
          if (isAdmin) ...[
            // 관리자용 안내 텍스트
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Row(children: [
                const Icon(Icons.drag_indicator_rounded, size: 14, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(loc.dragToReorder,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
              ]),
            ),
            // ReorderableListView — 드래그 순서 변경
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final newList = List<String>.from(imgs);
                final item = newList.removeAt(oldIndex);
                newList.insert(newIndex, item);
                setState(() => _sectionImages[sectionKey] = newList);
                await context.read<ProductProvider>().updateSectionImages(
                    widget.product.id, sectionKey, newList);
              },
              children: imgs.asMap().entries.map((e) {
                final i = e.key;
                final url = e.value;
                return _buildReorderableImageItem(
                    key: ValueKey('$sectionKey-$i-$url'),
                    url: url,
                    index: i,
                    sectionKey: sectionKey,
                    imgs: imgs,
                    isAdmin: isAdmin);
              }).toList(),
            ),
          ] else ...[
            // 일반 사용자: 일반 표시
            ...imgs.asMap().entries.map((e) {
              final url = e.value;
              return _buildImageItem(url: url);
            }),
          ],
        ],
      ],
    );
  }

  // 드래그 가능한 이미지 아이템 (관리자)
  Widget _buildReorderableImageItem({
    required Key key,
    required String url,
    required int index,
    required String sectionKey,
    required List<String> imgs,
    required bool isAdmin,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // 이미지
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 드래그 핸들
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 6),
                child: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator_rounded,
                      size: 22, color: Color(0xFFBBBBBB)),
                ),
              ),
              // 이미지 본체
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: url.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(url.split(',').last),
                          width: double.infinity,
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          url,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          cacheWidth: 800,
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : Container(
                                  height: 200,
                                  color: const Color(0xFFF5F5F5),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Color(0xFF888888)),
                                    ),
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            color: const Color(0xFFEEEEEE),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  size: 36, color: Color(0xFFCCCCCC)),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          // 삭제 버튼 (관리자)
          if (isAdmin)
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () async {
                  final newList = List<String>.from(imgs)..removeAt(index);
                  await context.read<ProductProvider>().updateSectionImages(
                      widget.product.id, sectionKey, newList);
                  setState(() {
                    if (newList.isEmpty) {
                      _sectionImages.remove(sectionKey);
                    } else {
                      _sectionImages[sectionKey] = newList;
                    }
                  });
                },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 일반 이미지 아이템 (비관리자)
  Widget _buildImageItem({required String url}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url.startsWith('data:image')
            ? Image.memory(
                base64Decode(url.split(',').last),
                width: double.infinity,
                fit: BoxFit.contain,
              )
            : Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.contain,
                cacheWidth: 800,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 200,
                        color: const Color(0xFFF5F5F5),
                        child: const Center(
                          child: SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF888888)),
                          ),
                        ),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: const Color(0xFFEEEEEE),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 36, color: Color(0xFFCCCCCC)),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAdminUploadButton(
      String sectionKey, String sectionLabel, List<String> existingImgs) {
    return GestureDetector(
      onTap: () => _pickAndUploadImages(sectionKey, sectionLabel, existingImgs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                size: 20, color: Color(0xFF1A1A2E)),
            const SizedBox(width: 8),
            Text(
              existingImgs.isEmpty
                  ? '[관리자] $sectionLabel 이미지 업로드'
                  : '[관리자] $sectionLabel 이미지 추가 (현재 ${existingImgs.length}장)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 파일 선택 → Base64 변환 → 저장 ──
  Future<void> _pickAndUploadImages(
      String sectionKey, String sectionLabel, List<String> existingImgs) async {
    final picker = ImagePicker();

    // 로딩 스낵바
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 12),
          Text(loc.fileSelecting),
        ]),
        duration: const Duration(seconds: 30),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );

    try {
      // 여러 장 선택
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (pickedFiles.isEmpty) return;

      // 선택된 이미지들 미리보기 다이얼로그
      _showPickedImagesPreview(
          sectionKey, sectionLabel, existingImgs, pickedFiles);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.imageSelectFailed}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── 선택된 이미지 미리보기 + 최종 저장 다이얼로그 ──
  void _showPickedImagesPreview(
    String sectionKey,
    String sectionLabel,
    List<String> existingImgs,
    List<XFile> pickedFiles,
  ) {
    // 선택된 파일 정보 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PickedImagesSheet(
        sectionKey: sectionKey,
        sectionLabel: sectionLabel,
        existingImgs: existingImgs,
        pickedFiles: pickedFiles,
        onSave: (finalUrls) async {
          await context.read<ProductProvider>().updateSectionImages(
              widget.product.id, sectionKey, finalUrls);
          setState(() {
            if (finalUrls.isEmpty) {
              _sectionImages.remove(sectionKey);
            } else {
              _sectionImages[sectionKey] = finalUrls;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '$sectionLabel 이미지 ${finalUrls.length}장이 저장되었습니다'),
              backgroundColor: const Color(0xFF1A1A2E),
            ),
          );
        },
        onDeleteAll: () async {
          await context.read<ProductProvider>().updateSectionImages(
              widget.product.id, sectionKey, []);
          setState(() => _sectionImages.remove(sectionKey));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.productSectionDeleted(sectionLabel)),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 0: 디자인 이미지 (관리자 업로드)
  // ═══════════════════════════════════════════════════════════
  // 디자인 이미지 셀린 (카테고리 위 인라인, 확대 가능)
  // ═══════════════════════════════════════════════════════════
  Widget _buildDesignImageSection(ProductModel product, bool isAdmin) {
    final imgs = _sectionImages['design'] ?? [];
    if (!isAdmin && imgs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 헤더 행 (라벨 + 관리자 업로드 버튼) ──
        Row(
          children: [
            Container(
              width: 3, height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF4A148C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '디자인 이미지',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A), letterSpacing: -0.2),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A148C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('관리자', style: TextStyle(fontSize: 9, color: Color(0xFF4A148C), fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              // 업로드 버튼
              GestureDetector(
                onTap: () => _pickAndUploadImages('design', '디자인 이미지', imgs),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A148C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        imgs.isEmpty ? '이미지 업로드' : '이미지 추가 (${imgs.length}장)',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),

        // ── 이미지가 있을 때: 가로 스크롤 썸네일 ──
        if (imgs.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imgs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                return GestureDetector(
                  onTap: () => _showDesignLightbox(imgs, i),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imgs[i],
                          width: 100, height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100, height: 100,
                            color: const Color(0xFFEEEEEE),
                            child: const Icon(Icons.broken_image_outlined, color: Color(0xFFAAAAAA)),
                          ),
                        ),
                      ),
                      // 확대 아이콘 오버레이
                      Positioned(
                        right: 4, bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                        ),
                      ),
                      // 관리자: 삭제 버튼
                      if (isAdmin)
                        Positioned(
                          right: 4, top: 4,
                          child: GestureDetector(
                            onTap: () async {
                              final newList = List<String>.from(imgs)..removeAt(i);
                              setState(() => _sectionImages['design'] = newList);
                              await context.read<ProductProvider>()
                                  .updateSectionImages(product.id, 'design', newList);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

        // ── 이미지 없을 때 관리자 안내 ──
        if (imgs.isEmpty && isAdmin)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A148C).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF4A148C).withValues(alpha: 0.2),
                  style: BorderStyle.solid),
            ),
            child: const Column(
              children: [
                Icon(Icons.image_outlined, size: 28, color: Color(0xFF9E9E9E)),
                SizedBox(height: 6),
                Text('디자인 이미지를 업로드하세요',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),

        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 14),
      ],
    );
  }

  /// 디자인이미지 전용 라이트박스
  void _showDesignLightbox(List<String> imgs, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (_) => _LightboxDialog(images: imgs, initialIndex: initialIndex),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 1: 메인 배너 (2FIT 싱글렛 특화)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection1Banner(ProductModel product, bool isAdmin) {
    final isSinglet = product.name.contains('싱글렛') || product.category == '상의';

    // 4가지 핵심 특징 - 큰 텍스트 + 통일된 이모지
    final features = [
      {
        'emoji': '⚡',
        'title': loc.feat1Title,
        'desc': loc.feat1Desc,
        'tag': 'ULTRA LIGHT',
      },
      {
        'emoji': '🧵',
        'title': loc.feat2Title,
        'desc': loc.feat2Desc,
        'tag': 'SEAMLESS',
      },
      {
        'emoji': '🏃',
        'title': loc.feat3Title,
        'desc': loc.feat3Desc,
        'tag': 'A-TYPE RACERBACK',
      },
      {
        'emoji': '🥇',
        'title': loc.feat4Title,
        'desc': loc.feat4Desc,
        'tag': 'ELITE WEAR',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 섹션1 이미지 업로드 (카드 위) ──
        if (isAdmin || (_sectionImages['s1'] ?? []).isNotEmpty)
          Container(
            color: const Color(0xFFF5F7FF),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildAdminImageSection('s1', '섹션1 메인 배너', isAdmin),
          ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          color: const Color(0xFFF5F7FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더 배경 이미지 영역
              Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE3EAFF), Color(0xFFCDD8FF)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 섹션 라벨
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('SECTION 01',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 9, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 5),
                // 메인 타이틀
                Text(
                  isSinglet ? '2FIT 싱글렛' : product.localizedName(_lang),
                  style: const TextStyle(
                      color: Color(0xFF1A1A3E),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.15),
                ),
                const SizedBox(height: 6),
                // 서브타이틀
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB0BEFF)),
                  ),
                  child: Text(
                    isSinglet
                        ? '경기력을 극대화하는 퍼포먼스 싱글렛 · No.1 엘리트 스포츠웨어'
                        : product.localizedDescription(_lang),
                    style: const TextStyle(
                        color: Color(0xFF3A3A6E), fontSize: 11, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          // 핵심 특징 4가지 카드
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Column(
              children: features.asMap().entries.map((entry) {
                final idx = entry.key;
                final f = entry.value;
                return Container(
                  margin: EdgeInsets.only(top: idx == 0 ? 0 : 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCDD5FF)),
                  ),
                  child: Row(
                    children: [
                      // 이모지 아이콘
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF1FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(f['emoji']!,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 태그 + 제목
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(f['title']!,
                                  style: const TextStyle(
                                      color: Color(0xFF1A1A3E),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(f['tag']!,
                                  style: const TextStyle(
                                      color: Color(0xFF2962FF),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 2: 소재 및 기술 + 섬유 혼용율 표
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection2Material(ProductModel product, bool isAdmin) {
    final badges = [
      {'icon': '🧬', 'label': loc.badgeSeamless},
      {'icon': '💧', 'label': loc.badgeFastAbsorb},
      {'icon': '🌬️', 'label': loc.badgeFastDry},
      {'icon': '🪶', 'label': loc.badgeUltraLight},
      {'icon': '🏅', 'label': loc.badgeElite},
    ];

    // 기능별 상세 설명
    final techDetails = [
      {
        'icon': '💧',
        'title': loc.techAbsorbTitle,
        'desc': loc.techAbsorbDesc,
      },
      {
        'icon': '🌬️',
        'title': loc.techDryTitle,
        'desc': loc.techDryDesc,
      },
    ];

    // 섬유 혼용율 테이블
    final fiberTable = loc.fiberTableData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 섹션2 이미지 업로드 (카드 위) ──
        if (isAdmin || (_sectionImages['s2'] ?? []).isNotEmpty)
          Container(
            color: const Color(0xFFF7F8FA),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildAdminImageSection('s2', '섹션2 소재 및 기술', isAdmin),
          ),
        Container(
          color: const Color(0xFFF7F8FA),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('02', loc.section02Title, loc.section02Sub),
          const SizedBox(height: 10),

          // 뱃지 행
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: badges.map((b) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(b['icon']!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(b['label']!,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            )).toList(),
          ),

          const SizedBox(height: 10),

          // 흡수/건조 기술 상세 설명
          ...techDetails.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8EAF6)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(t['icon']!, style: const TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['title']!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 2),
                      Text(t['desc']!,
                          style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF666666),
                              height: 1.45)),
                    ],
                  ),
                ),
              ],
            ),
          )),

          const SizedBox(height: 10),

          // ── 하의길이 참조 이미지 — 하의(타이즈 포함) 또는 싱글렛세트 상품에만 표시 ──
          if (_isBottomOrSingletSetProduct(product)) ...[
            if (isAdmin || (_sectionImages['s2_length_male'] ?? []).isNotEmpty ||
                (_sectionImages['s2_length_female'] ?? []).isNotEmpty ||
                (_sectionImages['s2_length'] ?? []).isNotEmpty) ...[
              _buildGenderLengthImageSection(isAdmin),
              const SizedBox(height: 10),
            ],
          ],

          // ── 소재혼용율 위 이미지 업로드 ──
          if (isAdmin || (_sectionImages['s2_fiber'] ?? []).isNotEmpty) ...[
            _buildAdminImageSection('s2_fiber', '소재혼용율 이미지', isAdmin),
            const SizedBox(height: 10),
          ],

          // ── 섬유 혼용율 표 ──
          Text(loc.fiberMixRatio,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          Text(loc.productFabricCompositionNote,
              style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA))),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                // 테이블 헤더
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 5,
                          child: Text(loc.fiberCategory,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11))),
                      Expanded(
                          flex: 4,
                          child: Text(loc.fiberMainMaterial,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                              textAlign: TextAlign.center)),
                      Expanded(
                          flex: 3,
                          child: Text(loc.fiberMix,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                              textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                // 테이블 행
                ...fiberTable.asMap().entries.map((e) {
                  final row = e.value;
                  final even = e.key % 2 == 0;
                  final isLast = e.key == fiberTable.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                    decoration: BoxDecoration(
                      color: even ? Colors.white : const Color(0xFFF9FAFB),
                      borderRadius: isLast
                          ? const BorderRadius.vertical(bottom: Radius.circular(10))
                          : BorderRadius.zero,
                      border: const Border(
                        top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 5,
                            child: Text(row[0],
                                style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.5,
                                    color: Color(0xFF333333)))),
                        Expanded(
                            flex: 4,
                            child: Text(row[1],
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center)),
                        Expanded(
                            flex: 3,
                            child: Text(row[2],
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF888888)),
                                textAlign: TextAlign.center)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          // ── 시선표 ──
          if (isAdmin || (_sectionImages['s2'] ?? []).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: _buildAdminImageSection('s2', '섹션2 소재 및 기술', isAdmin),
            ),
        ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 3: 포켓 특성 (소재 설명 아래 배치)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection3Pocket(ProductModel product, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin || (_sectionImages['s3'] ?? []).isNotEmpty)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildAdminImageSection('s3', '섹션3 포켓 특성', isAdmin),
          ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('03', loc.section03Title, loc.section03Sub),
              const SizedBox(height: 10),

          // 4가지 포켓 특성
          _buildPocketFeatureTile(
            icon: Icons.location_on_rounded,
            color: const Color(0xFF1565C0),
            title: loc.pocketTile1Title,
            desc: loc.pocketTile1Desc,
          ),
          _buildPocketFeatureTile(
            icon: Icons.rotate_right_rounded,
            color: const Color(0xFF6A1B9A),
            title: loc.pocketTile2Title,
            desc: loc.pocketTile2Desc,
          ),
          _buildPocketFeatureTile(
            icon: Icons.smartphone_rounded,
            color: const Color(0xFF1B5E20),
            title: loc.pocketTile3Title,
            desc: loc.pocketTile3Desc,
          ),
          _buildPocketFeatureTile(
            icon: Icons.water_drop_rounded,
            color: const Color(0xFFE65100),
            title: loc.pocketTile4Title,
            desc: loc.pocketTile4Desc,
          ),
        ],
          ),
        ),
      ],
    );
  }

  Widget _buildPocketFeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 5),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF666666), height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════
  // 섹션 5: 골지 원단 색상 안내 (사이즈 차트 위)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection5GoljiColors(ProductModel product, bool isAdmin) {
    // 이미지 기준 골지 원단 색상 전체 목록 (코드 + 색상명 + hex)
    final goljiColors = [
      {'code': 'K',  'name': '블랙',         'hex': 0xFF1A1A1A},
      {'code': 'N',  'name': '네이비',        'hex': 0xFF0D1B4F},
      {'code': 'W',  'name': '화이트',        'hex': 0xFFF5F5F5},
      {'code': 'G',  'name': '그레이',        'hex': 0xFF9E9E9E},
      {'code': 'DG', 'name': '다크그레이',    'hex': 0xFF424242},
      {'code': 'SB', 'name': '스카이블루',    'hex': 0xFF90CAF9},
      {'code': 'B',  'name': '블루',          'hex': 0xFF1A4DB3},
      {'code': 'DB', 'name': '다크블루',      'hex': 0xFF2C3D6E},
      {'code': 'SP', 'name': '스킨핑크',      'hex': 0xFFE8C8C0},
      {'code': 'LP', 'name': '라이트핑크',    'hex': 0xFFE8A8B0},
      {'code': 'IO', 'name': '아이보리',      'hex': 0xFFD4CFC4},
      {'code': 'LG', 'name': '라이트그레이',  'hex': 0xFFBDBDBD},
      {'code': 'R',  'name': '레드',          'hex': 0xFFCC1111},
      {'code': 'PP', 'name': '퍼플네이비',    'hex': 0xFF1B1B3A},
      {'code': 'ND', 'name': '올리브그린',    'hex': 0xFF4A5240},
      {'code': 'BB', 'name': '틸블루',        'hex': 0xFF0F6B7A},
      {'code': 'FP', 'name': '형광핑크',      'hex': 0xFFFF1493},
      {'code': 'FO', 'name': '형광오렌지',    'hex': 0xFFFF6600},
      {'code': 'FG', 'name': '형광그린',      'hex': 0xFF88EE00},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin || (_sectionImages['s5'] ?? []).isNotEmpty)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildAdminImageSection('s5', '섹션5 골지 원단 색상', isAdmin),
          ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('05', loc.section05Title, loc.section05Sub),
          const SizedBox(height: 4),
          Text(
            loc.section05Desc,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF666666), height: 1.5),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 6,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: goljiColors.length,
            itemBuilder: (_, i) {
              final c = goljiColors[i];
              final hexVal = c['hex'] as int;
              final swatchColor = Color(hexVal);
              final isLight = swatchColor.computeLuminance() > 0.5;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RibColorSwatch(color: swatchColor, size: 42, isLight: isLight),
                  const SizedBox(height: 3),
                  Text(
                    c['code'] as String,
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF222222)),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 6: 사이즈 차트 (성인 / 주니어 탭)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection6SizeChart(ProductModel product, [bool isAdmin = false]) {
    // ── 성인 차트 (투핏 사이즈 조건표 기준) ──
    const adultHeaders = ['SIZE', 'HEIGHT\n(cm)', 'WEIGHT\n(kg)', 'CHEST\n(cm)', 'WAIST\n(inch)'];
    const adultRows = [
      ['XS(85)',   '154~159', '44~51', '85',  '26~28'],
      ['S(90)',    '160~165', '52~60', '90',  '28~30'],
      ['M(95)',    '166~172', '61~71', '95',  '30~32'],
      ['L(100)',   '172~177', '72~78', '100', '32~34'],
      ['XL(105)',  '177~182', '79~85', '105', '34~36'],
      ['2XL(110)', '182~187', '86~91', '110', '36~38'],
      ['3XL(115)', '187~191', '91~96', '115', '38~40'],
    ];
    // ── 주니어 차트 ──
    const juniorHeaders = ['SIZE', 'HEIGHT\n(cm)', 'WEIGHT\n(kg)', 'AGE'];
    const juniorRows = [
      ['J-S(60)',   '112~117', '19~21', '6~7'],
      ['J-M(65)',   '118~122', '22~24', '7~8'],
      ['J-L(70)',   '123~133', '25~28', '8~9'],
      ['J-XL(75)',  '130~139', '26~34', '10~11'],
      ['J-2XL(80)', '140~153', '35~43', '-'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin || (_sectionImages['s6'] ?? []).isNotEmpty)
          Container(
            color: const Color(0xFF111111),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildAdminImageSection('s6', '섹션6 사이즈 차트', isAdmin),
          ),

        // ── 메인 사이즈 차트 컨테이너 ──
        Container(
          color: const Color(0xFF111111),
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 타이틀 영역
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 섹션 넘버
                      Text(
                        '06',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.3),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 메인 타이틀
                      const Text(
                        'SIZE\nCHART',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 브랜드 로고 영역
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '2FiT KOREA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '투핏 사이즈 조건표 기준',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 구분선
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
              ),

              // ── 탭 + 테이블 ──
              _SizeChartTabs(
                adultHeaders: adultHeaders,
                adultRows: adultRows,
                juniorHeaders: juniorHeaders,
                juniorRows: juniorRows,
                loc: loc,
              ),

              const SizedBox(height: 24),

              // ── 안내 문구 ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            loc.sizeChartDesc1,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            loc.sizeChartDesc2,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (isAdmin || (_sectionImages['s6'] ?? []).isNotEmpty)
          Container(
            color: const Color(0xFF111111),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildAdminImageSection('s6', '섹션6 사이즈 차트', isAdmin),
          ),
      ],
    );
  }

  // 사이즈 테이블 공통 빌더 (골지 질감 다크 테마)
  // ignore: unused_element
  Widget _buildSizeTable(List<String> headers, List<List<String>> rows) {
    return _buildRibSizeTable(headers, rows);
  }

  Widget _buildRibSizeTable(List<String> headers, List<List<String>> rows) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          // 헤더 행
          _RibTableHeader(headers: headers),
          // 데이터 행
          ...rows.asMap().entries.map((e) => _RibTableRow(
            values: e.value,
            isEven: e.key.isEven,
            isLast: e.key == rows.length - 1,
            isSizeCol: true,
          )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 리뷰 섹션
  // ═══════════════════════════════════════════════════════════
  Widget _buildReviewSection(ProductModel product) {
    return Consumer<ReviewProvider>(
      builder: (_, reviewProv, __) {
        final reviews = reviewProv.getProductReviews(product.id);
        final avg = reviewProv.getProductRating(product.id);

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(loc.productReviewLabel,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        '${reviews.isNotEmpty ? reviews.length : product.reviewCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              if (avg > 0 || product.rating > 0) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      (avg > 0 ? avg : product.rating).toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                              5,
                              (i) => Icon(Icons.star_rounded,
                                  size: 20,
                                  color: i < (avg > 0 ? avg : product.rating).floor()
                                      ? const Color(0xFFFFD600)
                                      : const Color(0xFFE0E0E0))),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '${reviews.isNotEmpty ? reviews.length : product.reviewCount}개 리뷰',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              ..._buildSampleReviews(product),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final reviews = context.read<ReviewProvider>().getProductReviews(product.id);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _AllReviewsSheet(product: product, reviews: reviews),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Consumer<LanguageProvider>(builder: (_,lp,__) => Text(lp.loc.moreReviews,
                      style: const TextStyle(
                          color: Color(0xFF555555), fontWeight: FontWeight.w600))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSampleReviews(ProductModel product) {
    final list = [
      {
        'name': '김*지', 'rating': 5, 'size': 'M', 'color': 'Black',
        'content': '착용감이 너무 좋아요! 신축성이 뛰어나고 땀 흡수도 잘 됩니다. 운동할 때 불편함이 전혀 없어요.',
        'date': '2024.03.10'
      },
      {
        'name': '이*수', 'rating': 4, 'size': 'S', 'color': 'Navy',
        'content': '품질은 정말 좋습니다. 사이즈가 약간 작게 나오는 것 같아 한 사이즈 업 추천드려요.',
        'date': '2024.03.05'
      },
      {
        'name': '박*준', 'rating': 5, 'size': 'L', 'color': 'Black',
        'content': '2FIT 제품 믿고 삽니다. 이번에도 역시나 만족스럽고 빠른 배송도 좋았어요!',
        'date': '2024.02.28'
      },
    ];
    return list
        .map((r) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(r['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(width: 8),
                      Row(
                          children: List.generate(
                              5,
                              (i) => Icon(Icons.star_rounded,
                                  size: 13,
                                  color: i < (r['rating'] as int)
                                      ? const Color(0xFFFFD600)
                                      : const Color(0xFFE0E0E0)))),
                      const Spacer(),
                      Text(r['date'] as String,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFAAAAAA))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _reviewChip('사이즈: ${r['size']}'),
                      const SizedBox(width: 6),
                      _reviewChip('컬러: ${r['color']}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(r['content'] as String,
                      style: const TextStyle(
                          fontSize: 13, height: 1.6, color: Color(0xFF555555))),
                ],
              ),
            ))
        .toList();
  }

  Widget _reviewChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
      );

  // ═══════════════════════════════════════════════════════════
  // 하단 바
  // ═══════════════════════════════════════════════════════════
  Widget _buildBottomBar(ProductModel product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (product.isGroupOnly) ...[
            // ── 단체주문 전용: 단체주문 버튼만 ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                label: Text(loc.groupOrderBtn,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A148C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _showGroupOrderGuide(product),
              ),
            ),
          ] else ...[
            Row(
              children: [
                // 찜 버튼
                Consumer<UserProvider>(
                  builder: (_, up, __) {
                    final isWish = up.isInWishlist(product.id);
                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isWish ? Colors.redAccent : const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isWish ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isWish ? Colors.redAccent : const Color(0xFF888888),
                        ),
                        onPressed: () {
                          if (up.isLoggedIn) {
                            up.toggleWishlist(product.id);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.loginRequired)),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                // 장바구니 담기
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
                        foregroundColor: const Color(0xFF1A1A1A),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _addToCart(product),
                      child: Text(loc.addToCart,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 바로 구매
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => _showBuyNowSheet(product),
                      child: Text(loc.buyNow,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── 포켓 인포 박스 ───────────────────────────────────────────
  // ignore: unused_element
  Widget _pocketInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 기장 설명 텍스트 ─────────────────────────────────────────
  // ignore: unused_element
  String _getLengthDesc(String label) {
    switch (label) {
      case '9부': return '발목 바로 위까지 오는 풀 레깅스 스타일';
      case '5부': return '무릎 약간 위, 가장 범용적인 기장';
      case '4부': return '무릎 바로 위, 활동적인 스타일';
      case '3부': return '허벅지 중간, 경쾌한 움직임';
      case '2.5부': return '허벅지 상단, 스피드 특화';
      case '숏쇼츠': return '2.5부보다 짧은 초단 디자인, 스피드 경기용';
      default: return '';
    }
  }

  // ─── 주문 유형 선택 모달 ────────────────────────────────────────
  /// 단체주문 버튼 표시 여부
  /// 허용: 타이즈(하의 전체) / 싱글렛 A타입 / 싱글렛 B타입 / 라운드티 / 싱글렛 A타입세트 / 트레이닝세트
  bool _showGroupOrderBtn(ProductModel p) {
    // 1) 타이즈 / 하의 카테고리 전체
    final isTights =
        p.category == '하의' ||
        p.subCategory.contains('타이즈') ||
        p.name.contains('타이즈');

    // 2) 싱글렛 A타입세트 (세트 카테고리)
    final isSingletATypeSet =
        (p.category == '세트' && p.subCategory.contains('싱글렛 A타입세트')) ||
        p.subCategory.contains('싱글렛 A타입세트') ||
        (p.category == '세트' && p.name.contains('싱글렛') && p.name.contains('A타입'));

    // 3) 트레이닝세트 (세트 카테고리)
    final isTrainingSet =
        (p.category == '세트' && p.subCategory.contains('트레이닝세트')) ||
        p.subCategory.contains('트레이닝세트') ||
        (p.category == '세트' && p.name.contains('트레이닝'));

    // 4) 싱글렛 A타입 (상의 카테고리)
    final isSingletA =
        (p.category == '상의' && p.subCategory.contains('싱글렛 A타입')) ||
        (p.category == '상의' && p.name.contains('싱글렛') && p.name.contains('A타입'));

    // 5) 싱글렛 B타입 (상의 카테고리)
    final isSingletB =
        (p.category == '상의' && p.subCategory.contains('싱글렛 B타입')) ||
        (p.category == '상의' && p.name.contains('싱글렛') && p.name.contains('B타입'));

    // 6) 라운드티 (상의 카테고리)
    final isRoundTee =
        (p.category == '상의' && p.subCategory.contains('라운드')) ||
        (p.category == '상의' && p.name.contains('라운드') && p.name.contains('티'));

    return isTights || isSingletATypeSet || isTrainingSet ||
           isSingletA || isSingletB || isRoundTee;
  }

  // ignore: unused_element
  void _showOrderModal(ProductModel product) {
    final isSingletProduct = product.name.contains('싱글렛');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(loc.purchaseTypeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 6),
            Text(loc.purchaseTypeSubtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),

            // ── 싱글렛 전용: 성별·타입 선택 ──
            if (isSingletProduct) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.accessibility_new_rounded, size: 16, color: Color(0xFF6A1B9A)),
                        const SizedBox(width: 6),
                        Text(loc.singletOptionLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF6A1B9A))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 성별 선택
                    Text(context.watch<LanguageProvider>().loc.gender, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                    const SizedBox(height: 8),
                    Row(
                      children: ['남성', '여성'].map((g) {
                        final isSelected = _singletGender == (g == '남성' ? '남' : '여');
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() {
                              setState(() => _singletGender = g == '남성' ? '남' : '여');
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF6A1B9A) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF6A1B9A) : const Color(0xFFDDDDDD),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    g == '남성' ? Icons.male_rounded : Icons.female_rounded,
                                    size: 16,
                                    color: isSelected ? Colors.white : const Color(0xFF888888),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    g,
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : const Color(0xFF555555),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    // 타입 선택
                    Text(loc.styleTypeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        {'type': 'A', 'label': loc.singletTypeA, 'desc': loc.singletTypeADesc},
                        {'type': 'B', 'label': loc.singletTypeB, 'desc': loc.singletTypeBDesc},
                      ].map((t) {
                        final isSelected = _singletType == t['type'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() {
                              setState(() => _singletType = t['type']!);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1A1A2E) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    t['label']!,
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : const Color(0xFF333333),
                                    ),
                                  ),
                                  Text(
                                    t['desc']!,
                                    style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white70 : const Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            _orderTypeBtn(
              emoji: '🛍️',
              title: loc.orderTypeReadyMadeTitle,
              description: loc.orderTypeReadyMadeDesc,
              tags: [loc.orderTypeReadyMadeTag1, loc.orderTypeReadyMadeTag2],
              color: const Color(0xFF1A1A1A),
              onTap: () {
                Navigator.pop(context);
                _directProceedToCheckout(product);
              },
            ),
            // 단체주문 버튼: 라운드티, 싱글렛세트, 싱글렛, 타이즈 카테고리만 표시
            if (_showGroupOrderBtn(product)) ...[
              const SizedBox(height: 12),
              _orderTypeBtn(
                emoji: '👥',
                title: loc.orderTypeGroupCustomTitle,
                description: loc.orderTypeGroupCustomDesc,
                tags: [loc.orderTypeGroupCustomTag1, loc.orderTypeGroupCustomTag2],
                color: const Color(0xFFE53935),
                onTap: () {
                  Navigator.pop(context);
                  _showGroupOrderGuide(product);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
      ),
    );
  }

  Widget _orderTypeBtn({
    required String emoji,
    required String title,
    required String description,
    required List<String> tags,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 3),
                  Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(t, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  // ─── 기성품 직접 결제 진행 ─────────────────────────────────────
  void _directProceedToCheckout(ProductModel product) {
    _showBuyNowSheet(product);
  }

  // ─── 단체주문 안내 시트 표시 ───
  void _showGroupOrderGuide(ProductModel product) {
    // 단체주문 전용 상품: 바로 단체주문 안내 페이지로 이동
    if (product.isGroupOnly) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupOrderGuideScreen(product: product),
        ),
      );
      return;
    }
    // 일반 상품: 바텀시트로 안내
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _GroupOrderGuideSheet(product: product),
      ),
    );
  }

  // ─── 기성품 옵션 선택 + 다중담기 시트 (장바구니/바로구매 공통) ───
  void _showBuyNowSheet(ProductModel product) {
    // 바로구매는 로그인 필수
    final user = context.read<UserProvider>().user;
    if (user == null) {
      final l = context.read<LanguageProvider>().loc;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.loginRequired),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: l.login,
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ),
      );
      return;
    }
    _showReadyMadeOptionSheet(product, isBuyNow: true);
  }

  void _showBottomLengthSheet(ProductModel product) {
    _showReadyMadeOptionSheet(product, isBuyNow: false);
  }

  void _addToCart(ProductModel product) {
    _showReadyMadeOptionSheet(product, isBuyNow: false);
  }

  void _showReadyMadeOptionSheet(ProductModel product, {required bool isBuyNow}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReadyMadeOptionSheet(
        product: product,
        isBuyNow: isBuyNow,
        calcExtraForColor: _calcExtraForColor,
        onCartUpdated: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  // 현재 선택된 색상의 추가금액 계산
  double _calcExtraForColor(String color) =>
      AppConstants.freeColors.contains(color) ? 0.0 : AppConstants.extraColorPrice.toDouble();

  // 실제 장바구니 추가 처리
  void _doAddToCart(
    ProductModel product,
    String size,
    String color,
    String? bottomLength,
    int qty,
  ) {
    // ignore: unused_local_variable
    final extra = _calcExtraForColor(color);
    context.read<CartProvider>().addItem(
      product,
      size,
      color,
      quantity: qty,
      extraPrice: extra,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.addedToCartMsg(bottomLength),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: loc.viewCartLabel,
          textColor: const Color(0xFFFFD600),
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  // ─── 공통 섹션 헤더 ───
  Widget _sectionHeader(String num, String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SECTION $num',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFAAAAAA),
                  letterSpacing: 2)),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
        ],
      );

  // ─── 사이즈 가이드 ───
  // ignore: unused_element
  void _showSizeGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(context.watch<LanguageProvider>().loc.sizeGuideTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(child: SingleChildScrollView(
              child: _buildSection6SizeChart(widget.product),
            )),
          ],
        ),
      ),
    );
  }

  /// 하의길이 비교 섹션 표시 여부: 하의 카테고리 또는 싱글렛세트만 표시
  bool _isBottomOrSingletSetProduct(ProductModel p) {
    final isSingletSet =
        (p.category == '세트' &&
            (p.subCategory.contains('싱글렛세트') ||
             p.subCategory.contains('싱글렛 A타입세트'))) ||
        p.category.contains('싱글렛세트') ||
        p.subCategory.contains('싱글렛세트') ||
        p.subCategory.contains('싱글렛 A타입세트') ||
        (p.category == '세트' && p.name.contains('싱글렛'));

    final isBottom =
        p.category == '하의' ||
        p.subCategory == '타이즈' ||
        p.name.contains('타이즈') ||
        p.subCategory.contains('레깅스') ||
        p.subCategory.contains('팬츠') ||
        p.subCategory.contains('반바지') ||
        p.subCategory.contains('숏츠') ||
        p.subCategory.contains('트레이닝');

    return isSingletSet || isBottom;
  }
}

// ══════════════════════════════════════════════════════════════
// 라이트박스 다이얼로그 (크게 보기 + 좌우 스와이프)
// ══════════════════════════════════════════════════════════════
class _LightboxDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _LightboxDialog({required this.images, required this.initialIndex});

  @override
  State<_LightboxDialog> createState() => _LightboxDialogState();
}

class _LightboxDialogState extends State<_LightboxDialog> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  late int _idx;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _ctrl = PageController(initialPage: _idx);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 이미지 페이지뷰 (핀치 줌 가능)
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _idx = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  widget.images[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 80),
                ),
              ),
            ),
          ),
          // 닫기 버튼
          Positioned(
            top: 48, right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          // 인디케이터
          if (widget.images.length > 1)
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Column(
                children: [
                  Text('${_idx + 1} / ${widget.images.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.images.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _idx == i ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _idx == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          // 이전/다음 버튼 (이미지 2장 이상일 때)
          if (widget.images.length > 1) ...[
            Positioned(
              left: 8,
              top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_idx > 0) {
                      _ctrl.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }
                  },
                  child: AnimatedOpacity(
                    opacity: _idx > 0 ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0, bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_idx < widget.images.length - 1) {
                      _ctrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }
                  },
                  child: AnimatedOpacity(
                    opacity: _idx < widget.images.length - 1 ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 측정 방법 행 (const 위젯)
// ══════════════════════════════════════════════════════════════
// ignore: unused_element
class _MeasureRow extends StatelessWidget {
  final String label;
  final String desc;
  const _MeasureRow({required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555555))),
          ),
          Expanded(
            child: Text(desc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 관리자 이미지 선택 시트 (파일 선택 → 미리보기 → 저장)
// ══════════════════════════════════════════════════════════════
class _PickedImagesSheet extends StatefulWidget {
  final String sectionKey;
  final String sectionLabel;
  final List<String> existingImgs;
  final List<XFile> pickedFiles;
  final void Function(List<String>) onSave;
  final VoidCallback onDeleteAll;

  const _PickedImagesSheet({
    required this.sectionKey,
    required this.sectionLabel,
    required this.existingImgs,
    required this.pickedFiles,
    required this.onSave,
    required this.onDeleteAll,
  });

  @override
  State<_PickedImagesSheet> createState() => _PickedImagesSheetState();
}

class _PickedImagesSheetState extends State<_PickedImagesSheet> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  // 최종 이미지 목록: 기존 이미지 + 새로 선택한 Base64 이미지
  late List<String> _allImages;
  // 새로 선택된 파일들 (Base64 변환 전)
  late List<XFile> _pendingFiles;
  bool _isConverting = false;
  // 변환된 Base64 목록
  final List<String> _convertedBase64 = [];

  @override
  void initState() {
    super.initState();
    // 기존 이미지를 먼저 로드
    _allImages = List<String>.from(widget.existingImgs);
    _pendingFiles = List<XFile>.from(widget.pickedFiles);
    // 새로 선택한 파일들을 자동 변환 시작
    _convertPendingFiles();
  }

  Future<void> _convertPendingFiles() async {
    if (_pendingFiles.isEmpty) return;
    setState(() => _isConverting = true);

    for (final file in _pendingFiles) {
      try {
        final bytes = await file.readAsBytes();
        final ext = file.name.toLowerCase();
        final mime = ext.endsWith('.png')
            ? 'image/png'
            : ext.endsWith('.gif')
                ? 'image/gif'
                : ext.endsWith('.webp')
                    ? 'image/webp'
                    : 'image/jpeg';
        final b64 = 'data:$mime;base64,${base64Encode(bytes)}';
        _convertedBase64.add(b64);
        if (mounted) setState(() {});
      } catch (_) {
        // 변환 실패 시 스킵
      }
    }

    if (mounted) {
      setState(() {
        _allImages.addAll(_convertedBase64);
        _pendingFiles.clear();
        _isConverting = false;
      });
    }
  }

  // 더 추가 선택
  Future<void> _addMoreImages() async {
    final picker = ImagePicker();
    final more = await picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (more.isEmpty || !mounted) return;
    setState(() {
      _pendingFiles = more;
      _isConverting = true;
    });
    await _convertPendingFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── 헤더 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          size: 18, color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.imageUploadLabel,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(widget.sectionLabel,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF888888))),
                        ],
                      ),
                    ),
                    // 이미지 수 배지
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_allImages.length}장',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 변환 중 진행 표시 ──
          if (_isConverting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '이미지 변환 중... (${_convertedBase64.length}/${_pendingFiles.length + _convertedBase64.length})',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),

          // ── 이미지 그리드 ──
          Expanded(
            child: _allImages.isEmpty && !_isConverting
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined,
                            size: 48,
                            color: Colors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(context.watch<LanguageProvider>().loc.noImageSelected,
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 14)),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _allImages.length,
                      itemBuilder: (_, i) {
                        final url = _allImages[i];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: url.startsWith('data:image')
                                  ? Image.memory(
                                      base64Decode(url.split(',').last),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      url,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFFEEEEEE),
                                        child: const Icon(
                                            Icons.broken_image_outlined,
                                            color: Color(0xFFCCCCCC)),
                                      ),
                                    ),
                            ),
                            // 순서 번호
                            Positioned(
                              top: 4, left: 4,
                              child: Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ),
                            // 삭제 버튼
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _allImages.removeAt(i));
                                },
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.85),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),

          // ── 하단 버튼 영역 ──
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
            child: Column(
              children: [
                // 이미지 추가 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 18),
                    label: Text(context.watch<LanguageProvider>().loc.addMoreImages),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A2E),
                      side: const BorderSide(
                          color: Color(0xFF1A1A2E), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isConverting ? null : _addMoreImages,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // 전체 삭제
                    if (widget.existingImgs.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: Text(loc.deleteAllLabel),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDeleteAll();
                          },
                        ),
                      ),
                    if (widget.existingImgs.isNotEmpty)
                      const SizedBox(width: 8),
                    // 저장
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _allImages.isEmpty
                              ? '저장 (이미지 없음)'
                              : '${_allImages.length}장 저장하기',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _allImages.isEmpty
                              ? Colors.grey
                              : const Color(0xFF1A1A2E),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isConverting
                            ? null
                            : () {
                                Navigator.pop(context);
                                widget.onSave(_allImages);
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// 기성품 구매 2단계 시트 (STEP1: 하의길이 → STEP2: 사이즈·컬러·수량)
// ══════════════════════════════════════════════════════════════
class _ReadyMadePurchaseSheet extends StatefulWidget {
  final ProductModel product;
  final void Function(String length, String size, String color, int qty) onConfirm;
  final String? initialSize;
  final String? initialColor;

  const _ReadyMadePurchaseSheet({
    required this.product,
    required this.onConfirm,
    // ignore: unused_element_parameter
    this.initialSize,
    // ignore: unused_element_parameter
    this.initialColor,
  });

  @override
  State<_ReadyMadePurchaseSheet> createState() => _ReadyMadePurchaseSheetState();
}

class _ReadyMadePurchaseSheetState extends State<_ReadyMadePurchaseSheet> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  // step 0 = 성별선택(싱글렛A세트만) / step 1 = 사이즈·컬러·수량
  int _step = 0;
  String? _gender;        // 싱글렛A세트 성별
  String? _autoLength;    // 성별로 확정된 하의길이 (싱글렛A세트)
  String? _selectedSize;
  String? _selectedColor;
  String  _selectedWeight = AppConstants.defaultFabricWeight;
  int     _quantity = 1;

  // ── 싱글렛 A타입 세트만 성별선택 스텝 ──
  bool get _isSingletASet =>
      (widget.product.category == '세트' &&
          (widget.product.subCategory.contains('싱글렛세트') ||
           widget.product.subCategory.contains('싱글렛 A타입세트'))) ||
      widget.product.subCategory.contains('싱글렛세트') ||
      widget.product.subCategory.contains('싱글렛 A타입세트') ||
      (widget.product.category == '세트' && widget.product.name.contains('싱글렛'));

  String _lengthForGender(String g) => g == '남' ? '5부' : '2.5부';

  @override
  void initState() {
    super.initState();
    _selectedSize  = widget.initialSize;
    _selectedColor = widget.initialColor;
    // 싱글렛A세트가 아니면 성별 스텝 건너뜀
    if (!_isSingletASet) {
      _step = 1;
    }
  }

  bool get _canConfirm => _selectedSize != null && _selectedColor != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _step == 0 ? _buildGenderStep() : _buildOptionStep(),
    );
  }

  // ━━━ STEP 0 : 성별 선택 (싱글렛 A타입 세트 전용) ━━━
  Widget _buildGenderStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width:40, height:4,
            decoration: BoxDecoration(color:const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('성별 선택',
            style: TextStyle(fontSize:16, fontWeight:FontWeight.w900, color:Color(0xFF1A1A1A))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color:const Color(0xFFFFCC02).withValues(alpha:0.5)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size:14, color:Color(0xFF7A5000)),
            SizedBox(width:6),
            Expanded(child: Text(
              '남성 → 하의 5부 자동 적용\n여성 → 하의 2.5부 자동 적용',
              style: TextStyle(fontSize:12, color:Color(0xFF7A5000), height:1.5),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _gBtn('남', '하의 5부'),
          const SizedBox(width: 12),
          _gBtn('여', '하의 2.5부'),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _gender == null ? null : () {
              setState(() {
                _autoLength = _lengthForGender(_gender!);
                _step = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              disabledBackgroundColor: const Color(0xFFCCCCCC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              _gender == null ? '성별을 선택해주세요'
                  : '다음  ·  하의 ${_lengthForGender(_gender!)} 확정',
              style: const TextStyle(fontSize:15, fontWeight:FontWeight.w800, color:Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gBtn(String gender, String sub) {
    final sel = _gender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF1A1A2E) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0E0),
              width: sel ? 2 : 1,
            ),
          ),
          child: Column(children: [
            Icon(gender == '남' ? Icons.male_rounded : Icons.female_rounded,
                size: 32, color: sel ? Colors.white : const Color(0xFF888888)),
            const SizedBox(height: 6),
            Text(gender == '남' ? '남성' : '여성',
                style: TextStyle(fontSize:16, fontWeight:FontWeight.w800,
                    color: sel ? Colors.white : const Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize:11,
                color: sel ? Colors.white70 : const Color(0xFF888888))),
          ]),
        ),
      ),
    );
  }

  // ━━━ STEP 1 : 사이즈 → 색상 → 무게 → 수량 ━━━
  Widget _buildOptionStep() {
    // 사이즈 목록: 상품에 사이즈가 있으면 그대로, 없으면 기본 성인 사이즈
    final rawSizes = widget.product.sizes;
    final isJunior = rawSizes.any((s) => RegExp(r'^\d{3}$').hasMatch(s));
    final sizes = rawSizes.isNotEmpty ? rawSizes
        : (isJunior ? AppConstants.juniorSizes : AppConstants.adultSizes);

    final isBottom = _isSingletASet ||
        widget.product.category == '하의' ||
        widget.product.subCategory == '타이즈' ||
        widget.product.name.contains('타이즈');

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그 핸들 + 헤더
          Center(child: Container(width:40, height:4,
              decoration: BoxDecoration(color:const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(children: [
            if (_isSingletASet) ...[
              GestureDetector(
                onTap: () => setState(() => _step = 0),
                child: const Icon(Icons.chevron_left_rounded, size: 24),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSingletASet
                      ? '사이즈 · 색상 선택  (${_gender == "남" ? "남성" : "여성"} · 하의 ${_autoLength ?? ""})'
                      : '사이즈 · 색상 · 수량 선택',
                  style: const TextStyle(fontSize:15, fontWeight:FontWeight.w900, color:Color(0xFF1A1A1A)),
                ),
              ],
            )),
          ]),
          const SizedBox(height: 12),

          // 안내 배지
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF43A047).withValues(alpha:0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.check_circle_rounded, size:14, color:Color(0xFF2E7D32)),
              SizedBox(width:5),
              Expanded(child: Text('기성품 · 2~3일 이내 배송',
                  style: TextStyle(fontSize:12, fontWeight:FontWeight.w700, color:Color(0xFF2E7D32)))),
            ]),
          ),
          const SizedBox(height: 16),

          // ── 사이즈 ──
          const Text('사이즈', style: TextStyle(fontSize:13, fontWeight:FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: sizes.map((s) {
              final sel = _selectedSize == s;
              return GestureDetector(
                onTap: () => setState(() => _selectedSize = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal:16, vertical:8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0)),
                  ),
                  child: Text(s, style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── 색상 ──
          _ColorSelectionWidget(
            isBottomCategory: isBottom,
            selectedColor: _selectedColor,
            onColorChanged: (c) => setState(() => _selectedColor = c),
          ),
          const SizedBox(height: 16),

          // ── 무게 ──
          const Text('원단 무게', style: TextStyle(fontSize:13, fontWeight:FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: AppConstants.fabricWeights.map((w) {
              final sel = _selectedWeight == w;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedWeight = w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    margin: EdgeInsets.only(right: w == AppConstants.fabricWeights.first ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0)),
                    ),
                    child: Column(children: [
                      Text(w, style: TextStyle(fontSize:16, fontWeight:FontWeight.w800,
                          color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                      const SizedBox(height: 2),
                      Text(w == '80g' ? '가볍고 시원함' : '두툼하고 탄탄함',
                          style: TextStyle(fontSize:10,
                              color: sel ? Colors.white70 : const Color(0xFF888888))),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── 수량 ──
          Row(children: [
            const Text('수량', style: TextStyle(fontSize:13, fontWeight:FontWeight.w700)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            ),
            Text('$_quantity', style: const TextStyle(fontSize:16, fontWeight:FontWeight.w800)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _quantity++),
            ),
          ]),
          const SizedBox(height: 16),

          // ── 확인 버튼 ──
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _canConfirm ? () => widget.onConfirm(
                _autoLength ?? '-',
                _selectedSize!,
                _selectedColor!,
                _quantity,
              ) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _canConfirm ? '확인' : '사이즈와 색상을 선택해주세요',
                style: const TextStyle(fontSize:15, fontWeight:FontWeight.w800, color:Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 빠른 사이즈 선택 시트 (바로 구매 - 컬러 선택 없음)
// ══════════════════════════════════════════════════════════════
class _QuickSizeSelectSheet extends StatefulWidget {
  final ProductModel product;
  final void Function(String size, int qty) onConfirm;
  final bool isBuyNow;

  const _QuickSizeSelectSheet({
    required this.product,
    required this.onConfirm,
    this.isBuyNow = false,
  });

  @override
  State<_QuickSizeSelectSheet> createState() => _QuickSizeSelectSheetState();
}

class _QuickSizeSelectSheetState extends State<_QuickSizeSelectSheet> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  String? _selectedSize;
  int _quantity = 1;

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final sizes = widget.product.sizes;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 타이틀
          Row(
            children: [
              Text(loc.sizeSelectTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.product.localizedName(_lang),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.isBuyNow
                ? '사이즈를 선택하고 바로 결제로 이동합니다'
                : '사이즈를 선택하고 장바구니에 담습니다',
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 18),

          // 사이즈 선택 그리드
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((s) {
              final sel = _selectedSize == s;
              return GestureDetector(
                onTap: () => setState(() => _selectedSize = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  width: 64,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(s,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 수량 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.quantitySelectTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () { if (_quantity > 1) setState(() => _quantity--); },
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove_rounded, size: 16),
                    ),
                  ),
                  Container(
                    width: 44,
                    alignment: Alignment.center,
                    child: Text('$_quantity',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _quantity++),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 금액 요약
          if (_selectedSize != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.product.localizedName(_lang)} · $_selectedSize',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                  Text(
                    '${_fmt((widget.product.price * _quantity).toInt())}원',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                  ),
                ],
              ),
            ),

          // 결제하기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedSize != null
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFCCCCCC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _selectedSize == null
                  ? null
                  : () => widget.onConfirm(_selectedSize!, _quantity),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.isBuyNow
                      ? Icons.payment_rounded
                      : Icons.shopping_bag_outlined,
                      size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _selectedSize == null
                        ? '사이즈를 선택해주세요'
                        : (widget.isBuyNow ? '바로 결제하기' : '장바구니에 담기'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 기성품 옵션선택 + 다중담기 시트 (장바구니/바로구매 공통)
// ══════════════════════════════════════════════════════════════
class _ReadyMadeOptionSheet extends StatefulWidget {
  final ProductModel product;
  final bool isBuyNow;
  final double Function(String color) calcExtraForColor;
  final VoidCallback onCartUpdated;

  const _ReadyMadeOptionSheet({
    required this.product,
    required this.isBuyNow,
    required this.calcExtraForColor,
    required this.onCartUpdated,
  });

  @override
  State<_ReadyMadeOptionSheet> createState() => _ReadyMadeOptionSheetState();
}

class _ReadyMadeOptionSheetState extends State<_ReadyMadeOptionSheet> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  // ─────────────────────────────────────────────
  // 현재 선택 중인 옵션
  // ─────────────────────────────────────────────
  String? _gender;       // '남' / '여'
  String? _length;       // 하의 기장
  String? _topSize;      // 상의 사이즈 (세트 상품)
  String? _bottomSize;   // 하의 사이즈 (세트 상품)
  String? _size;         // 단품 사이즈
  String? _color;        // 하의/단품 색상
  int _qty = 1;

  // 장바구니에 담을 옵션 목록
  final List<Map<String, dynamic>> _items = [];

  // ─────────────────────────────────────────────
  // 상품 타입 판별 getter
  // ─────────────────────────────────────────────

  /// 싱글렛 A타입 세트: 성별 선택 → 하의기장 고정(남=5부, 여=2.5부, 변경불가)
  bool get _isSingletATypeSet =>
      (widget.product.category == '세트' &&
          ((widget.product.subCategory ?? '').contains('싱글렛 A타입세트') ||
           (widget.product.subCategory ?? '').contains('싱글렛세트'))) ||
      (widget.product.subCategory ?? '').contains('싱글렛 A타입세트') ||
      (widget.product.subCategory ?? '').contains('싱글렛세트') ||
      (widget.product.category == '세트' && widget.product.name.contains('싱글렛 A타입'));

  /// 타이즈 카테고리: 하의길이 모두 선택 가능
  bool get _isTaiz =>
      (widget.product.subCategory ?? '').contains('타이즈') ||
      widget.product.name.contains('타이즈');

  /// 세트 상품 여부 (상의/하의 사이즈 각각 선택)
  bool get _isSetProduct =>
      widget.product.category == '세트' ||
      (widget.product.subCategory ?? '').contains('세트') ||
      widget.product.name.contains('세트');

  /// 기성품 싱글렛 (상의 색상 고정, 하의만 색상 선택 가능)
  bool get _isSingletReadyMade =>
      (widget.product.category == '상의' ||
          (widget.product.subCategory ?? '').contains('싱글렛')) &&
      !_isSetProduct;

  /// 하의류: 색상 선택 시 하의 색상 탭 먼저
  bool get _isBottomItem =>
      widget.product.category == '하의' ||
      (widget.product.subCategory ?? '').contains('타이즈') ||
      (widget.product.subCategory ?? '').contains('레깅스') ||
      (widget.product.subCategory ?? '').contains('팬츠') ||
      (widget.product.subCategory ?? '').contains('반바지') ||
      (widget.product.subCategory ?? '').contains('숏츠') ||
      widget.product.name.contains('타이즈');

  /// 하의길이 선택이 필요한지: 타이즈이거나 싱글렛 A타입 세트
  bool get _needsLength => _isTaiz || _isSingletATypeSet;

  /// 성별 선택이 필요한지: 싱글렛 A타입 세트만
  bool get _needsGender => _isSingletATypeSet;

  // ─────────────────────────────────────────────
  // 사이즈 목록
  // ─────────────────────────────────────────────
  /// 공통 기본 사이즈: 상품에 등록된 사이즈 우선, 없으면 성인/주니어 자동 판별
  List<String> get _defaultSizes {
    final raw = widget.product.sizes;
    if (raw.isNotEmpty) return raw;
    final isJunior = widget.product.name.contains('주니어') ||
        widget.product.name.contains('Jr') ||
        (widget.product.subCategory ?? '').contains('주니어');
    // 성인 S~XL / 주니어 S~XL (요구사항)
    return isJunior ? AppConstants.juniorSizes : AppConstants.adultSizes;
  }

  // ─────────────────────────────────────────────
  // 헬퍼
  // ─────────────────────────────────────────────
  String _autoLength(String gender) => gender == '남' ? '5부' : '2.5부';

  /// 현재 선택 가능 여부
  bool get _canAddItem {
    // 색상 선택이 필요한지: 싱글렛 A타입 세트 또는 타이즈만
    final needsColor = _isSingletATypeSet || _isTaiz;

    // 세트 상품: 상의+하의 사이즈 모두 선택
    if (_isSetProduct) {
      final sizeOk = _topSize != null && _bottomSize != null;
      final colorOk = needsColor ? _color != null : true;
      final lengthOk = _needsLength ? _length != null : true;
      return sizeOk && colorOk && lengthOk;
    }
    // 단품
    final sizeOk = _size != null;
    final colorOk = needsColor ? _color != null : true;
    final lengthOk = _needsLength ? _length != null : true;
    return sizeOk && colorOk && lengthOk;
  }

  int _totalQty() => _items.fold(0, (s, e) => s + (e['qty'] as int));
  int _totalPrice() => _items.fold(0, (s, e) {
    final base = (widget.product.price as num).toInt();
    final extra = (e['extra'] as num).toInt();
    return s + (base + extra) * (e['qty'] as int);
  });

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _addCurrentOption() {
    if (!_canAddItem) return;
    final needsColor = _isSingletATypeSet || _isTaiz;
    final colorValue = needsColor ? (_color ?? '-') : '-';
    setState(() {
      final sizeLabel = _isSetProduct
          ? '상의 $_topSize / 하의 $_bottomSize'
          : _size!;
      _items.add({
        'size': sizeLabel,
        'topSize': _topSize,
        'bottomSize': _bottomSize,
        'singleSize': _size,
        'color': colorValue,
        'qty': _qty,
        'length': _length ?? '-',
        'gender': _gender ?? '-',
        'extra': needsColor ? widget.calcExtraForColor(colorValue) : 0,
      });
      // 옵션 초기화 (새 옵션 선택)
      _topSize = null;
      _bottomSize = null;
      _size = null;
      _color = null;
      _qty = 1;
      // 성별/기장은 유지
    });
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  void _proceedToCart() {
    final cart = context.read<CartProvider>();
    for (final item in _items) {
      cart.addItem(
        widget.product,
        item['size'] as String,
        item['color'] as String,
        quantity: item['qty'] as int,
        extraPrice: (item['extra'] as num).toDouble(),
      );
    }
    widget.onCartUpdated();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('${_items.length}가지 옵션 · 총 ${_totalQty()}개 장바구니에 담겼습니다'),
        ]),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: '장바구니 보기',
          textColor: const Color(0xFFFFD600),
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  void _proceedToBuyNow() {
    final cart = context.read<CartProvider>();
    for (final item in _items) {
      cart.addItem(
        widget.product,
        item['size'] as String,
        item['color'] as String,
        quantity: item['qty'] as int,
        extraPrice: (item['extra'] as num).toDouble(),
      );
    }
    widget.onCartUpdated();
    Navigator.pop(context);
    Navigator.pushNamed(context, '/checkout');
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lengths = AppConstants.bottomLengths
        .map((m) => m['label'] as String)
        .where((s) => s.isNotEmpty)
        .toList();
    final sizes = _defaultSizes;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── 핸들 + 헤더 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isBuyNow ? '바로구매 옵션 선택' : '장바구니 옵션 선택',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '옵션을 선택하고 추가하면 한 번에 담을 수 있어요',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 20, color: Color(0xFFF0F0F0)),

            // ── 스크롤 영역 ──
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [

                  // ══════════════════════════════
                  // [1] 싱글렛 A타입 세트: 성별 선택 → 기장 고정
                  // ══════════════════════════════
                  if (_needsGender) ...[
                    _sectionTitle('성별 선택', required: true),
                    const SizedBox(height: 8),
                    // 안내 배지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF7A5000)),
                        const SizedBox(width: 5),
                        const Text(
                          '남성 → 5부 자동선택  •  여성 → 2.5부 자동선택',
                          style: TextStyle(fontSize: 11, color: Color(0xFF7A5000), fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                    Row(
                      children: ['남', '여'].map((g) {
                        final isSel = _gender == g;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _gender = g;
                              _length = _autoLength(g); // 고정
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 130),
                              margin: EdgeInsets.only(right: g == '남' ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF1A1A2E) : const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0E0),
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    g == '남' ? Icons.male_rounded : Icons.female_rounded,
                                    size: 26,
                                    color: isSel ? Colors.white : const Color(0xFF888888),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    g == '남' ? '남성' : '여성',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isSel ? Colors.white : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : const Color(0xFF1A1A2E).withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_autoLength(g)} 자동선택',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSel ? Colors.white : const Color(0xFF1A1A2E),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // 기장 고정 표시 (변경 불가)
                    if (_gender != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 6),
                          Text(
                            '하의 기장: ${_length!} (고정 · 변경 불가)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],

                  // ══════════════════════════════
                  // [2] 타이즈: 하의길이 모두 선택 가능 (성별 선택 없음)
                  // ══════════════════════════════
                  if (_isTaiz && !_needsGender) ...[
                    _sectionTitle('하의 기장 선택', required: true),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: lengths.map((len) {
                        final isSel = _length == len;
                        return GestureDetector(
                          onTap: () => setState(() => _length = len),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF1A1A2E) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Text(
                              len,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ══════════════════════════════
                  // [3] 사이즈 선택
                  //   - 세트 상품: 상의/하의 각각
                  //   - 단품: 공통 사이즈
                  // ══════════════════════════════
                  if (_isSetProduct) ...[
                    // 상의 사이즈
                    _sectionTitle('상의 사이즈', required: true),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: sizes.map((s) {
                        final isSel = _topSize == s;
                        return GestureDetector(
                          onTap: () => setState(() => _topSize = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF1A1A2E) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // 하의 사이즈
                    _sectionTitle('하의 사이즈', required: true),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: sizes.map((s) {
                        final isSel = _bottomSize == s;
                        return GestureDetector(
                          onTap: () => setState(() => _bottomSize = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF5C6BC0) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? const Color(0xFF5C6BC0) : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // 단품 사이즈
                    _sectionTitle('사이즈', required: true),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: sizes.map((s) {
                        final isSel = _size == s;
                        return GestureDetector(
                          onTap: () => setState(() => _size = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF1A1A2E) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ══════════════════════════════
                  // [4] 색상 선택
                  //   - 싱글렛 A타입 세트 / 타이즈만 색상 선택 표시
                  //   - 상의, 그 외 카테고리는 색상 선택 없음
                  // ══════════════════════════════
                  if (_isSingletATypeSet || _isTaiz) ...[
                    _sectionTitle('하의 색상', required: true),
                    const SizedBox(height: 6),
                    _ColorSelectionWidget(
                      isBottomCategory: true,
                      selectedColor: _color,
                      onColorChanged: (c) => setState(() => _color = c),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ══════════════════════════════
                  // [5] 수량
                  // ══════════════════════════════
                  Row(
                    children: [
                      _sectionTitle('수량', required: false),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: _qty > 1 ? () => setState(() => _qty--) : null,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                              child: Container(
                                width: 36, height: 36,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: _qty > 1 ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC),
                                ),
                              ),
                            ),
                            Container(
                              width: 40, height: 36,
                              alignment: Alignment.center,
                              child: Text(
                                '$_qty',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _qty++),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                              child: Container(
                                width: 36, height: 36,
                                alignment: Alignment.center,
                                child: const Icon(Icons.add, size: 16, color: Color(0xFF1A1A1A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ══════════════════════════════
                  // [6] 옵션 추가 버튼
                  // ══════════════════════════════
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _canAddItem ? _addCurrentOption : null,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(
                        _canAddItem
                            ? _buildAddBtnLabel()
                            : _buildAddBtnHint(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _canAddItem ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
                          width: 1.5,
                        ),
                        foregroundColor: _canAddItem ? const Color(0xFF1A1A2E) : const Color(0xFFAAAAAA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  // ══════════════════════════════
                  // [7] 선택된 옵션 목록
                  // ══════════════════════════════
                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 16, color: Color(0xFF1A1A2E)),
                        const SizedBox(width: 6),
                        Text(
                          '선택된 옵션 ${_items.length}가지',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '총 ${_totalQty()}개 · ${_fmt(_totalPrice())}원',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._items.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      final base = (widget.product.price as num).toInt();
                      final extra = (item['extra'] as num).toInt();
                      final itemTotal = (base + extra) * (item['qty'] as int);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6, runSpacing: 4,
                                    children: [
                                      _optionChip(item['size'] as String, const Color(0xFF1A1A2E)),
                                      _optionChip(item['color'] as String, const Color(0xFF43A047)),
                                      if ((item['length'] as String) != '-')
                                        _optionChip(item['length'] as String, const Color(0xFF1565C0)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        '수량 ${item['qty']}개',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                                      ),
                                      if (extra > 0) ...[
                                        const Text(' · ', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                                        Text(
                                          '색상 추가금 +${_fmt(extra)}원',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFFE53935)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_fmt(itemTotal)}원',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _removeItem(idx),
                                  child: const Icon(Icons.close, size: 16, color: Color(0xFFAAAAAA)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            // ── 하단 버튼 ──
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: _items.isEmpty
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCCCCCC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          '위에서 옵션을 선택하고 추가해주세요',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        if (!widget.isBuyNow) ...[
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _proceedToCart,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  '장바구니 담기\n(${_totalQty()}개)',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E),
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: widget.isBuyNow ? 1 : 2,
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _proceedToBuyNow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A2E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.isBuyNow
                                    ? '바로구매 (${_fmt(_totalPrice())}원)'
                                    : '바로구매',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 추가 버튼 라벨/힌트 빌더
  // ─────────────────────────────────────────────
  String _buildAddBtnLabel() {
    final parts = <String>[];
    if (_isSetProduct) {
      if (_topSize != null) parts.add('상의 $_topSize');
      if (_bottomSize != null) parts.add('하의 $_bottomSize');
    } else if (_size != null) {
      parts.add(_size!);
    }
    if (_color != null) parts.add(_color!);
    if (_length != null && _length != '-') parts.add(_length!);
    parts.add('${_qty}개');
    return '이 옵션 추가 · ${parts.join(' · ')}';
  }

  String _buildAddBtnHint() {
    if (_isSetProduct) {
      if (_topSize == null) return '상의 사이즈를 선택해주세요';
      if (_bottomSize == null) return '하의 사이즈를 선택해주세요';
    } else if (_size == null) {
      return '사이즈를 선택해주세요';
    }
    // 색상 선택은 싱글렛 A타입 세트 / 타이즈만 필요
    if ((_isSingletATypeSet || _isTaiz) && _color == null) return '하의 색상을 선택해주세요';
    if (_needsLength && _length == null) return '하의 기장을 선택해주세요';
    return '옵션을 선택해주세요';
  }

  // ─────────────────────────────────────────────
  // UI 헬퍼
  // ─────────────────────────────────────────────
  Widget _sectionTitle(String title, {bool required = false}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Color(0xFFE53935), fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ],
    );
  }

  Widget _optionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 사이즈 + 컬러 선택 시트 (바로 구매)
// ══════════════════════════════════════════════════════════════
class _QuickSizeColorSelectSheet extends StatefulWidget {
  final ProductModel product;
  final String? initialSize;
  final String? initialColor;
  final void Function(String size, String color, int qty) onConfirm;

  const _QuickSizeColorSelectSheet({
    required this.product,
    // ignore: unused_element_parameter
    this.initialSize,
    // ignore: unused_element_parameter
    this.initialColor,
    required this.onConfirm,
  });

  @override
  State<_QuickSizeColorSelectSheet> createState() =>
      _QuickSizeColorSelectSheetState();
}

class _QuickSizeColorSelectSheetState
    extends State<_QuickSizeColorSelectSheet> {
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;

  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;

  // 색상 추가금액
  double get _extraPrice =>
      AppConstants.freeColors.contains(_selectedColor) ? 0.0 : AppConstants.extraColorPrice.toDouble();

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.initialSize;
    _selectedColor = widget.initialColor ??
        (widget.product.colors.isNotEmpty ? widget.product.colors.first : null);
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  bool get _canConfirm => _selectedSize != null && _selectedColor != null;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final bottom = MediaQuery.of(context).padding.bottom;
    final sizes = widget.product.sizes;
    // 골지 텍스처: 싱글렛세트 또는 타이즈(하의) 상품에만 적용
    final p = widget.product;
    final isSingletSetHere =
        (p.category == '세트' && (p.subCategory.contains('싱글렛세트') || p.subCategory.contains('싱글렛 A타입세트'))) ||
        p.category.contains('싱글렛세트') ||
        p.subCategory.contains('싱글렛세트') ||
        p.subCategory.contains('싱글렛 A타입세트') ||
        (p.category == '세트' && p.name.contains('싱글렛'));
    final isBottom = isSingletSetHere ||
        p.category == '하의' ||
        p.subCategory == '타이즈' ||
        p.name.contains('타이즈');

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Text(loc.optionSelectTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.product.localizedName(_lang),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(loc.buyNowCheckoutDesc,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            const SizedBox(height: 20),
            Text(loc.sizeLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes.map((s) {
                final sel = _selectedSize == s;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    width: 64,
                    height: 48,
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // 컬러 섹션 (하의: 19가지 + 팔레트, 기타: 검정/남색)
            _ColorSelectionWidget(
              isBottomCategory: isBottom,
              selectedColor: _selectedColor,
              onColorChanged: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.quantityLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () { if (_quantity > 1) setState(() => _quantity--); },
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.remove_rounded, size: 16),
                      ),
                    ),
                    Container(
                      width: 44,
                      alignment: Alignment.center,
                      child: Text('$_quantity',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _quantity++),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_rounded, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_canConfirm)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                          '${widget.product.localizedName(_lang)} · $_selectedSize · $_selectedColor',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                          softWrap: true),
                    ),
                    Text(
                      '${_fmt(((widget.product.price + _extraPrice) * _quantity).toInt())}원',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canConfirm ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _canConfirm
                    ? () => widget.onConfirm(_selectedSize!, _selectedColor!, _quantity)
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _canConfirm ? '바로 결제하기' : '사이즈와 컬러를 선택해주세요',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 색상 선택 위젯 (하의: 19가지 InlineColorChart + 팔레트/직접입력, 기타: 검정/남색)
// - 하의(category == '하의'): 19가지 표준 색상 + 팔레트에서 색상코드 직접입력
//   - 블랙, 퍼플(PP) 계열: 추가비용 없음
//   - 그 외 색상: +20,000원 추가비용 안내
// - 기타 카테고리: 기본 검정/남색만 표시
// ══════════════════════════════════════════════════════════════
class _ColorSelectionWidget extends StatefulWidget {
  final bool isBottomCategory;
  final String? selectedColor;
  final void Function(String color) onColorChanged;

  const _ColorSelectionWidget({
    required this.isBottomCategory,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  State<_ColorSelectionWidget> createState() => _ColorSelectionWidgetState();
}

class _ColorSelectionWidgetState extends State<_ColorSelectionWidget> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  @override
  Widget build(BuildContext context) {
    // 상세 페이지 _buildColorSection과 완전히 동일한 팔레트 사용
    const palette = AppColorPalette.registeredColors;
    final freeColors = AppConstants.freeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 헤더 ──
        Row(
          children: [
            Text(loc.colorLabel2,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
              ),
              child: Text(loc.productColorExtraNote,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── 선택된 색상 표시 ──
        if (widget.selectedColor != null) ...[
          Builder(builder: (_) {
            final col = widget.selectedColor!;
            final found = palette.firstWhere(
              (c) => c['name'] == col,
              orElse: () => <String, dynamic>{},
            );
            if (found.isEmpty) return const SizedBox.shrink();
            final isFree = freeColors.contains(col);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text(loc.selectedLabel,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(found['hex'] as int),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFCCCCCC), width: 0.8),
                  ),
                ),
                const SizedBox(width: 6),
                Text(col,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text(
                  isFree ? '기본색상' : '+20,000원',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isFree
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFCC0000),
                  ),
                ),
              ]),
            );
          }),
        ],

        // ── 색상 팔레트 그리드 (상세 페이지와 동일) ──
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: palette.map((c) {
            final name = c['name'] as String;
            final hex = c['hex'] as int;
            final code = c['code'] as String;
            final sel = widget.selectedColor == name;
            final isFree = freeColors.contains(name);
            return GestureDetector(
              onTap: () => widget.onColorChanged(name),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RibColorSwatch(
                    color: Color(hex),
                    size: 40,
                    isSelected: sel,
                    accentColor: const Color(0xFF1A1A1A),
                    isLight: Color(hex).computeLuminance() > 0.5,
                    child: sel
                        ? Icon(Icons.check_rounded,
                            size: 18,
                            color: Color(hex).computeLuminance() > 0.5
                                ? const Color(0xFF333333)
                                : Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w400,
                      color: sel
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF666666),
                    ),
                  ),
                  if (!isFree)
                    const Text('+₩',
                        style: TextStyle(
                            fontSize: 8, color: Color(0xFFCC0000))),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(loc.productColorExtraFull,
            style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 사이즈 차트 탭 (성인/주니어) - StatefulWidget으로 분리하여 스크롤 충돌 방지
// ══════════════════════════════════════════════════════════════
class _SizeChartTabs extends StatefulWidget {
  final List<String> adultHeaders;
  final List<List<String>> adultRows;
  final List<String> juniorHeaders;
  final List<List<String>> juniorRows;
  final dynamic loc;

  const _SizeChartTabs({
    required this.adultHeaders,
    required this.adultRows,
    required this.juniorHeaders,
    required this.juniorRows,
    required this.loc,
  });

  @override
  State<_SizeChartTabs> createState() => _SizeChartTabsState();
}

class _SizeChartTabsState extends State<_SizeChartTabs> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  int _tab = 0; // 0=성인, 1=주니어

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 탭 버튼 ──
        Row(
          children: [
            _tabBtn(0, 'ADULT', '성인'),
            const SizedBox(width: 8),
            _tabBtn(1, 'JUNIOR', '주니어'),
          ],
        ),
        const SizedBox(height: 16),
        // ── 테이블 ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _tab == 0
              ? _buildTable(widget.adultHeaders, widget.adultRows, key: const ValueKey('adult'))
              : _buildTable(widget.juniorHeaders, widget.juniorRows, key: const ValueKey('junior')),
        ),
      ],
    );
  }

  Widget _tabBtn(int idx, String label, String sublabel) {
    final sel = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: sel ? Colors.white : Colors.white.withValues(alpha: 0.2),
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: sel ? const Color(0xFF111111) : Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: sel ? const Color(0xFF555555) : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<String> headers, List<List<String>> rows, {Key? key}) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          // 헤더
          _RibTableHeader(headers: headers),
          // 데이터 행
          ...rows.asMap().entries.map((e) => _RibTableRow(
            values: e.value,
            isEven: e.key.isEven,
            isLast: e.key == rows.length - 1,
            isSizeCol: true,
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 전체 리뷰 목록 바텀시트
// ═══════════════════════════════════════════════════════════
class _AllReviewsSheet extends StatefulWidget {
  final ProductModel product;
  final List<ReviewModel> reviews;
  const _AllReviewsSheet({required this.product, required this.reviews});
  @override
  State<_AllReviewsSheet> createState() => _AllReviewsSheetState();
}

class _AllReviewsSheetState extends State<_AllReviewsSheet> {
  String _sort = 'latest'; // latest, highest, lowest
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  List<ReviewModel> get _sorted {
    final list = List<ReviewModel>.from(widget.reviews);
    if (_sort == 'highest') list.sort((a, b) => b.rating.compareTo(a.rating));
    if (_sort == 'lowest')  list.sort((a, b) => a.rating.compareTo(b.rating));
    return list;
  }

  void _showWriteReviewDialog({ReviewModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(
        product: widget.product,
        existing: existing,
        onSubmitted: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _deleteReview(ReviewModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('리뷰 삭제'),
        content: const Text('이 리뷰를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<ReviewProvider>().deleteReview(r.id, r.productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰가 삭제되었습니다'), backgroundColor: Color(0xFF1A1A1A)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.watch<UserProvider>().user?.id;
    return Consumer<ReviewProvider>(
      builder: (_, reviewProv, __) {
        final reviews = List<ReviewModel>.from(reviewProv.getProductReviews(widget.product.id).isNotEmpty
            ? reviewProv.getProductReviews(widget.product.id)
            : widget.reviews);
        if (_sort == 'highest') reviews.sort((a, b) => b.rating.compareTo(a.rating));
        if (_sort == 'lowest') reviews.sort((a, b) => a.rating.compareTo(b.rating));
        final avg = reviews.isEmpty ? 0.0 : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        final myReview = currentUid != null ? reviews.where((r) => r.userId == currentUid).firstOrNull : null;

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('리뷰 ${reviews.length}개', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(Icons.star_rounded,
                                size: 16, color: i < avg.round() ? const Color(0xFFFFD600) : const Color(0xFFEEEEEE))),
                            const SizedBox(width: 6),
                            Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(),
              // 정렬 버튼 + 리뷰 작성 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _sortBtn('최신순', 'latest'),
                    const SizedBox(width: 8),
                    _sortBtn('평점 높은순', 'highest'),
                    const SizedBox(width: 8),
                    _sortBtn('평점 낮은순', 'lowest'),
                    const Spacer(),
                    if (currentUid != null)
                      GestureDetector(
                        onTap: () => _showWriteReviewDialog(existing: myReview),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(myReview != null ? Icons.edit : Icons.rate_review,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(myReview != null ? '내 리뷰 수정' : '리뷰 작성',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 리뷰 목록
              Expanded(
                child: reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFFCCCCCC)),
                            const SizedBox(height: 12),
                            Text(loc.noReviewYet, style: const TextStyle(color: Color(0xFF999999))),
                            if (currentUid != null) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showWriteReviewDialog(),
                                icon: const Icon(Icons.rate_review, size: 16),
                                label: const Text('첫 번째 리뷰를 작성해보세요'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = reviews[i];
                          final isMyReview = currentUid != null && r.userId == currentUid;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isMyReview ? const Color(0xFF6C63FF) : const Color(0xFF1A1A1A),
                                      child: Text(r.userName.isNotEmpty ? r.userName[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                            if (isMyReview) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('내 리뷰', style: TextStyle(fontSize: 10, color: Color(0xFF6C63FF), fontWeight: FontWeight.w700)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Row(
                                          children: List.generate(5, (j) => Icon(Icons.star_rounded,
                                              size: 13, color: j < r.rating ? const Color(0xFFFFD600) : const Color(0xFFEEEEEE))),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text('${r.createdAt.year}.${r.createdAt.month.toString().padLeft(2,'0')}.${r.createdAt.day.toString().padLeft(2,'0')}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                                    if (isMyReview) ...[
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF999999)),
                                        onSelected: (v) {
                                          if (v == 'edit') _showWriteReviewDialog(existing: r);
                                          if (v == 'delete') _deleteReview(r);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('수정')])),
                                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('삭제', style: TextStyle(color: Colors.red))])),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (r.size.isNotEmpty || r.color.isNotEmpty)
                                  Row(
                                    children: [
                                      if (r.size.isNotEmpty) _chip('사이즈: ${r.size}'),
                                      if (r.color.isNotEmpty) ...[const SizedBox(width: 6), _chip('색상: ${r.color}')],
                                    ],
                                  ),
                                const SizedBox(height: 6),
                                Text(r.content, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF333333))),
                                if (r.images.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 60,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: r.images.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                                      itemBuilder: (_, j) => ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(r.images[j], width: 60, height: 60, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: const Color(0xFFF0F0F0))),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sortBtn(String label, String value) {
    final sel = _sort == value;
    return GestureDetector(
      onTap: () => setState(() => _sort = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF555555))),
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
  );
}

// ═══════════════════════════════════════════════════════════
// 리뷰 작성/수정 시트
// ═══════════════════════════════════════════════════════════
class _WriteReviewSheet extends StatefulWidget {
  final ProductModel product;
  final ReviewModel? existing;
  final VoidCallback? onSubmitted;
  const _WriteReviewSheet({required this.product, this.existing, this.onSubmitted});
  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  double _rating = 5.0;
  final _contentCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _rating = widget.existing!.rating;
      _contentCtrl.text = widget.existing!.content;
      _sizeCtrl.text = widget.existing!.size;
      _colorCtrl.text = widget.existing!.color;
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _sizeCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 내용을 입력해주세요'), backgroundColor: Colors.red),
      );
      return;
    }
    final user = context.read<UserProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final reviewProv = context.read<ReviewProvider>();
      if (widget.existing != null) {
        // 수정
        final updated = ReviewModel(
          id: widget.existing!.id,
          userId: widget.existing!.userId,
          userName: widget.existing!.userName,
          productId: widget.existing!.productId,
          rating: _rating,
          content: _contentCtrl.text.trim(),
          images: widget.existing!.images,
          size: _sizeCtrl.text.trim(),
          color: _colorCtrl.text.trim(),
          createdAt: widget.existing!.createdAt,
        );
        await reviewProv.updateReview(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리뷰가 수정되었습니다 ✓'), backgroundColor: Color(0xFF4CAF50)),
          );
        }
      } else {
        // 신규
        final review = ReviewModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.id,
          userName: user.name.isNotEmpty ? user.name : user.email.split('@').first,
          productId: widget.product.id,
          rating: _rating,
          content: _contentCtrl.text.trim(),
          images: [],
          size: _sizeCtrl.text.trim(),
          color: _colorCtrl.text.trim(),
          createdAt: DateTime.now(),
        );
        await reviewProv.addReview(review);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리뷰가 등록되었습니다 ✓'), backgroundColor: Color(0xFF4CAF50)),
          );
        }
      }
      widget.onSubmitted?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 + 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(widget.existing != null ? '리뷰 수정' : '리뷰 작성',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상품명
                    Text(widget.product.name,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 20),
                    // 별점
                    const Text('별점', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(5, (i) => GestureDetector(
                          onTap: () => setState(() => _rating = (i + 1).toDouble()),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.star_rounded, size: 36,
                                color: i < _rating ? const Color(0xFFFFD600) : const Color(0xFFDDDDDD)),
                          ),
                        )),
                        const SizedBox(width: 8),
                        Text('${_rating.toInt()}점', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 리뷰 내용
                    const Text('리뷰 내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: '상품에 대한 솔직한 후기를 남겨주세요 (최소 10자)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 사이즈 / 색상 (선택)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('구매 사이즈 (선택)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _sizeCtrl,
                                decoration: InputDecoration(
                                  hintText: 'ex) M, 55',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('구매 색상 (선택)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _colorCtrl,
                                decoration: InputDecoration(
                                  hintText: 'ex) 블랙, 화이트',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 제출 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(widget.existing != null ? '리뷰 수정 완료' : '리뷰 등록',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 골지(Rib) 질감 사이즈 테이블 위젯들
// ═══════════════════════════════════════════════════════════

/// 골지 패턴을 CustomPainter로 그리는 위젯
class _RibPatternPainter extends CustomPainter {
  final Color lineColor;
  final double spacing;
  final double lineWidth;

  const _RibPatternPainter({
    required this.lineColor,
    this.spacing = 6.0,
    // ignore: unused_element_parameter
    this.lineWidth = 0.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RibPatternPainter old) =>
      old.lineColor != lineColor || old.spacing != spacing;
}

/// 테이블 헤더 행 – 짙은 배경 + 골지 라인
class _RibTableHeader extends StatelessWidget {
  final List<String> headers;
  const _RibTableHeader({required this.headers});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 기본 배경 (단색 – 그라디언트 제거)
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
          ),
          child: Row(
            children: headers.asMap().entries.map((e) {
              final isFirst = e.key == 0;
              return Expanded(
                flex: isFirst ? 2 : 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      right: e.key < headers.length - 1
                          ? BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1)
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.8,
                      height: 1.3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 골지 라인 오버레이 (주기 축소)
        Positioned.fill(
          child: CustomPaint(
            painter: _RibPatternPainter(
              lineColor: Colors.white.withValues(alpha: 0.06),
              spacing: 4,
            ),
          ),
        ),
      ],
    );
  }
}

/// 테이블 데이터 행 – 교차 배경 + 골지 라인
class _RibTableRow extends StatelessWidget {
  final List<String> values;
  final bool isEven;
  final bool isLast;
  final bool isSizeCol;

  const _RibTableRow({
    required this.values,
    required this.isEven,
    required this.isLast,
    this.isSizeCol = true,
  });

  @override
  Widget build(BuildContext context) {
    // 짝수 행: 살짝 밝은 톤, 홀수 행: 약간 어두운 톤
    final bg = isEven
        ? const Color(0xFF1E1E1E)
        : const Color(0xFF242424);
    final ribColor = isEven
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.04);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
            ),
          ),
          child: Row(
            children: values.asMap().entries.map((e) {
              final isFirst = e.key == 0;
              final isSize = isFirst && isSizeCol;
              return Expanded(
                flex: isFirst ? 2 : 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSize
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.transparent,
                    border: Border(
                      right: e.key < values.length - 1
                          ? BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1)
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSize ? 11 : 11.5,
                      fontWeight: isSize ? FontWeight.w800 : FontWeight.w400,
                      color: isSize
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.75),
                      letterSpacing: isSize ? 0.3 : 0,
                      height: 1.2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 골지 라인
        Positioned.fill(
          child: CustomPaint(
            painter: _RibPatternPainter(
              lineColor: ribColor,
              spacing: 4,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PC 단체주문 안내 라인 위젯
// ══════════════════════════════════════════════════════════════
class _PcInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PcInfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF6A1B9A)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 섹션5 골지 텍스처 사각 스와치 - RibColorSwatch 래퍼
// ══════════════════════════════════════════════════════════════
// ignore: unused_element
class _GoljiSwatch extends StatelessWidget {
  final Color color;
  final double size;
  final bool isLight;

  const _GoljiSwatch({
    required this.color,
    required this.size,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return RibColorSwatch(
      color: color,
      size: size,
      isLight: isLight,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 단체주문 안내 바텀시트 (백업 기반 전면 재설계)
// ══════════════════════════════════════════════════════════════
class _GroupOrderGuideSheet extends StatefulWidget {
  final ProductModel product;
  const _GroupOrderGuideSheet({required this.product});

  @override
  State<_GroupOrderGuideSheet> createState() => _GroupOrderGuideSheetState();
}

class _GroupOrderGuideSheetState extends State<_GroupOrderGuideSheet> {
  bool _checked = false;
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;

  static const Color _purple = Color(0xFF4A148C);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.groups_rounded, color: _purple, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.groupOrderGuideAppBar,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                    Text(loc.groupOrderGuideHeroTitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // 스크롤 가능 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ─── 1. 기본 안내 ───────────────────────────────
                  _sheetSectionTitle(Icons.info_outline_rounded, loc.groupOrderGuideAppBar, const Color(0xFF1565C0)),
                  const SizedBox(height: 10),
                  _infoCard(
                    icon: Icons.people_outline_rounded,
                    iconBg: const Color(0xFFE8EAF6),
                    iconColor: _purple,
                    title: loc.groupOrderMinQty,
                    content: loc.groupOrderMinQtyDesc,
                  ),
                  const SizedBox(height: 8),
                  _infoCard(
                    icon: Icons.schedule_outlined,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF6A1B9A),
                    title: loc.groupOrderProductionPeriod,
                    content: loc.groupOrderProductionPeriodDesc,
                  ),
                  const SizedBox(height: 8),
                  _infoCardWidget(
                    icon: Icons.local_shipping_outlined,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    title: loc.groupOrderGuideShippingTitle,
                    contentWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.groupOrderGuideShipping1, style: const TextStyle(fontSize: 13, height: 1.6)),
                        Text(loc.groupOrderGuideShipping2, style: const TextStyle(fontSize: 13, height: 1.6)),
                        Text(loc.groupOrderGuideShipping3, style: const TextStyle(fontSize: 13, height: 1.6)),
                        Text(loc.groupOrderGuideShipping4, style: const TextStyle(fontSize: 13, height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 2. 커스텀 옵션 ──────────────────────────────
                  _sheetSectionTitle(null, loc.groupOrderGuideCustomTitle, const Color(0xFFE65100), emoji: '🎨'),
                  const SizedBox(height: 10),
                  _optionCard(
                    bg: const Color(0xFFE8F5E9),
                    border: const Color(0xFFA5D6A7),
                    titleColor: const Color(0xFF2E7D32),
                    title: loc.groupOrderGuideCustomTitle,
                    items: [
                      loc.groupOrderGuideCustom1.replaceAll('• ', ''),
                      loc.groupOrderGuideCustom2.replaceAll('• ', ''),
                      loc.groupOrderGuideCustom3.replaceAll('• ', ''),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _optionCard(
                    bg: const Color(0xFFFFF8E1),
                    border: const Color(0xFFFFCC80),
                    titleColor: const Color(0xFFE65100),
                    title: loc.groupOrderGuideDiscountTitle,
                    items: [
                      loc.groupOrderGuideShipping1.replaceAll('• ', ''),
                      loc.groupOrderGuideDiscount1.replaceAll('• ', ''),
                      loc.groupOrderGuideDiscount2.replaceAll('• ', ''),
                      loc.groupOrderGuideDiscount3.replaceAll('• ', ''),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── 3. 사이즈 안내 ──────────────────────────────
                  _sheetSectionTitle(null, loc.groupOrderGuideSizeTitle, const Color(0xFF1A1A1A), emoji: '📏'),
                  const SizedBox(height: 10),
                  _sizeTable(
                    title: '${loc.groupOrderGuideSizeAdult} (XS~XXXL)',
                    emoji: '🧑',
                    headerColor: const Color(0xFF1565C0),
                    headerBg: const Color(0xFFE3F2FD),
                    rows: const [
                      ['XS',   '80~84',   '60~64',   '84~88',   '155~160'],
                      ['S',    '84~88',   '64~68',   '88~92',   '160~165'],
                      ['M',    '88~92',   '68~72',   '92~96',   '165~170'],
                      ['L',    '92~96',   '72~76',   '96~100',  '170~175'],
                      ['XL',   '96~100',  '76~80',   '100~104', '175~180'],
                      ['XXL',  '100~104', '80~84',   '104~108', '180~185'],
                      ['XXXL', '104~108', '84~88',   '108~112', '185+'],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sizeTable(
                    title: '${loc.groupOrderGuideSizeJunior} (XXS~L)',
                    emoji: '🧒',
                    headerColor: const Color(0xFF6A1B9A),
                    headerBg: const Color(0xFFF3E5F5),
                    rows: const [
                      ['XXS', '68~72', '52~56', '72~76', '120~130'],
                      ['XS',  '72~76', '56~60', '76~80', '130~140'],
                      ['S',   '76~80', '60~64', '80~84', '140~150'],
                      ['M',   '80~84', '64~68', '84~88', '150~155'],
                      ['L',   '84~88', '68~72', '88~92', '155~165'],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('↕', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.groupOrderGuideNoSizeHint,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                loc.groupOrderGuideNoSizeDesc,
                                style: const TextStyle(fontSize: 13, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── 4. 교환·환불 정책 ───────────────────────────
                  _sheetSectionTitle(null, loc.groupOrderGuideExchangeTitle, const Color(0xFFE65100), emoji: '⚠️'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.groupOrderGuideExchange1,
                            style: const TextStyle(fontSize: 13, height: 1.7)),
                        Text(loc.groupOrderGuideExchange2,
                            style: const TextStyle(fontSize: 13, height: 1.7)),
                        Text(loc.groupOrderSheetCancelNote,
                            style: const TextStyle(fontSize: 13, height: 1.7)),
                        Text(loc.groupOrderSheetColorNote,
                            style: const TextStyle(fontSize: 13, height: 1.7)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── 동의 체크박스 ────────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _checked = !_checked),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _checked ? _purple.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _checked ? _purple.withValues(alpha: 0.4) : const Color(0xFFDDDDDD),
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: _checked ? _purple : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _checked ? _purple : const Color(0xFFBBBBBB),
                                width: 1.5,
                              ),
                            ),
                            child: _checked
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loc.groupOrderSheetAgreeBtn,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── 서식 작성 버튼 ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                      label: Text(loc.groupOrderSheetFillForm,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _checked ? _purple : const Color(0xFFBBBBBB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _checked
                          ? () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => GroupOrderFormScreen(product: widget.product)),
                              );
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 섹션 타이틀 ──────────────────────────────────────────────
  Widget _sheetSectionTitle(IconData? icon, String title, Color color, {String? emoji}) {
    return Row(
      children: [
        if (emoji != null) ...[
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
        ] else if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
        ],
        Text(title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  // ── 정보 카드 (텍스트) ────────────────────────────────────────
  Widget _infoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(content, style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 정보 카드 (위젯) ─────────────────────────────────────────
  Widget _infoCardWidget({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required Widget contentWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                contentWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 옵션 카드 ─────────────────────────────────────────────────
  Widget _optionCard({
    required Color bg,
    required Color border,
    required Color titleColor,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: titleColor)),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $item', style: const TextStyle(fontSize: 13, height: 1.6)),
              )),
        ],
      ),
    );
  }

  // ── 사이즈 표 ─────────────────────────────────────────────────
  Widget _sizeTable({
    required String title,
    required String emoji,
    required Color headerColor,
    required Color headerBg,
    required List<List<String>> rows,
  }) {
    final headers = [loc.sheetSizeTableSize, loc.sheetSizeTableChest, loc.sheetSizeTableWaist, loc.sheetSizeTableHip, loc.sheetSizeTableHeight];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
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
                  flex: e.key == 0 ? 2 : 3,
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
            final rowBg = entry.key.isEven ? Colors.white : headerBg.withValues(alpha: 0.3);
            return Container(
              color: rowBg,
              child: Row(
                children: entry.value.asMap().entries.map((cell) {
                  return Expanded(
                    flex: cell.key == 0 ? 2 : 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                      child: Text(
                        cell.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
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
}
