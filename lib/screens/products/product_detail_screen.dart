import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/pc_layout.dart';
import '../orders/group_order_form_screen.dart';
import '../orders/group_order_guide_screen.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/image_lightbox.dart';
import '../../utils/app_localizations.dart';
import '../../services/analytics_service.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../utils/navigation_helper.dart';
import '../main_screen.dart';
import '../../utils/responsive.dart';

/// 주니어 사이즈 판별 (J- 접두어 또는 2~3자리 숫자)
/// 예: J-S, J-M, J-L, J-XL, J-2XL, 060, 065, 070 등
bool _isJuniorSizeLabel(String s) =>
    s.startsWith('J-') || RegExp(r'^\d{2,3}$').hasMatch(s);

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
  // ignore: unused_field
  String? _selectedSize;
  String? _selectedBottomLength;

  // ── 싱글렛/싱글렛세트 전용 ──
  String _singletGender = '남'; // '남' or '여'
  String _singletType = 'A';   // 'A' or 'B' (A타입 레이서백 / B타입 스쿱넥)

  // ── 기성품 원단 선택 (일반원단 / 심리스) ──
  String _selectedFabricType = '일반원단'; // '일반원단' or '심리스'

  // ── 탭 ──
  late TabController _tabCtrl;
  int _selectedTabIndex = 0;

  // ── 섹션 스크롤 키 ──
  final GlobalKey _keyInfo     = GlobalKey();
  final GlobalKey _keySize     = GlobalKey();
  final GlobalKey _keyReview   = GlobalKey();
  final GlobalKey _keyWashing  = GlobalKey();
  final GlobalKey _keyDesign   = GlobalKey(); // 디자인 이미지 섹션 스크롤 대상

  // ── 로컬 섹션 이미지 캐시 (관리자 업로드 시 즉시 반영) ──
  late Map<String, List<String>> _sectionImages;
  // ── 메인 상품 이미지 캐시 (Firestore fresh 로드 후 갱신) ──
  late List<String> _mainImages;
  // Firestore 최신 로드 완료 여부 (중복 로드 방지)
  bool _sectionImagesLoaded = false;

  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  // ignore: unused_element
  AppLanguage get _lang => context.watch<LanguageProvider>().language;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _sectionImages = Map<String, List<String>>.from(widget.product.sectionImages);
    _mainImages = List<String>.from(widget.product.images);
    // 성별 기본값: 남성 → 하의 5부 자동 설정
    _singletGender = '남';
    _selectedBottomLength = '5부';
    // 패럴랙스 비활성화: 이미지 잘림 방지를 위해 오프셋 항상 0 유지
    _imageOffsetNotifier.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // GA4: 상품 조회 이벤트
      AnalyticsService.logViewItem(
        itemId: widget.product.id,
        itemName: widget.product.name,
        price: widget.product.price,
        category: widget.product.category,
      );
      // Firestore 최신 sectionImages 강제 로드
      _refreshSectionImagesFromFirestore();
    });
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Provider에서 product가 업데이트됐을 때 sectionImages 동기화
    // (관리자가 이미지 업로드 후 notifyListeners → 여기서 반영)
    if (oldWidget.product.id != widget.product.id) {
      // 다른 상품으로 교체된 경우 전체 초기화
      _sectionImages = Map<String, List<String>>.from(widget.product.sectionImages);
      _mainImages = List<String>.from(widget.product.images);
      _sectionImagesLoaded = false;
      _refreshSectionImagesFromFirestore();
    } else if (!_sectionImagesLoaded) {
      // 아직 Firestore 로드가 완료되지 않은 경우, 새 product 데이터로 임시 업데이트
      final incoming = widget.product.sectionImages;
      if (incoming.isNotEmpty) {
        bool changed = false;
        for (final key in incoming.keys) {
          if (_sectionImages[key] != incoming[key]) {
            _sectionImages[key] = List<String>.from(incoming[key]!);
            changed = true;
          }
        }
        if (changed) setState(() {});
      }
    }
  }

  /// Firestore에서 최신 상품 데이터를 직접 가져와 sectionImages 및 메인 이미지를 갱신
  /// (앱 첫 진입 시 1회만 실행 – 관리자가 업로드한 이미지를 일반 사용자에게 즉시 반영)
  Future<void> _refreshSectionImagesFromFirestore() async {
    if (_sectionImagesLoaded) return;
    try {
      final fresh = await ProductService.getProductByIdFresh(widget.product.id);
      if (!mounted) return;
      _sectionImagesLoaded = true;

      // Firestore 로드 실패(null)여도 Provider 캐시의 최신값으로 폴백
      final freshImages = fresh?.sectionImages ?? widget.product.sectionImages;

      bool changed = false;

      // ── 메인 상품 이미지 갱신 (Firestore fresh 우선, picsum/placeholder 제거)
      if (fresh != null) {
        final freshMain = fresh.images
            .where((u) => u.startsWith('http') && !u.contains('picsum.photos'))
            .toList();
        if (freshMain.isNotEmpty && _mainImages.join() != freshMain.join()) {
          _mainImages = freshMain;
          changed = true;
        }
      }

      // ── 섹션 이미지 갱신
      // 새로 받은 키 반영
      for (final key in freshImages.keys) {
        final newList = List<String>.from(freshImages[key]!);
        if (_sectionImages[key]?.join() != newList.join()) {
          _sectionImages[key] = newList;
          changed = true;
        }
      }
      // Firestore에서 삭제된 키 제거 (fresh가 null이면 건너뜀)
      if (fresh != null) {
        for (final key in _sectionImages.keys.toList()) {
          if (!freshImages.containsKey(key)) {
            _sectionImages.remove(key);
            changed = true;
          }
        }
      }
      if (changed && mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ sectionImages Firestore 로드 실패: $e');
      _sectionImagesLoaded = true;
      // 실패 시 widget.product의 sectionImages로 폴백
      if (mounted && widget.product.sectionImages.isNotEmpty) {
        setState(() {
          for (final key in widget.product.sectionImages.keys) {
            _sectionImages[key] = List<String>.from(widget.product.sectionImages[key]!);
          }
        });
      }
    }
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
    final r = Responsive.of(context);
    final isAdmin = context.watch<UserProvider>().isAdmin;
    final productProvider = context.watch<ProductProvider>();
    final liveProduct = productProvider.products
        .firstWhere((p) => p.id == widget.product.id, orElse: () => widget.product);
    final product = liveProduct;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final screenW = MediaQuery.of(context).size.width;
    final isPc     = screenW >= 900;
    final isTablet = screenW >= 600 && screenW < 900;

    if (isPc) return _buildPcDetailLayout(context, product, isAdmin);
    if (isTablet) return _buildTabletDetailLayout(context, product, isAdmin);
    return _buildMobileDetailLayout(context, product, isAdmin);
  }

  // ── 모바일 상세 (<600px) — 기존 레이아웃 그대로 ──
  Widget _buildMobileDetailLayout(BuildContext context, ProductModel product, bool isAdmin) {
    final r = Responsive.of(context);
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            cacheExtent: 1200,
            slivers: [
              _buildSliverAppBarOnly(product),
              SliverToBoxAdapter(child: _buildImageSlider(product)),
              SliverToBoxAdapter(child: _buildThumbnailBar(product)),
              SliverToBoxAdapter(child: _buildAiImageNoticeBanner()),
              SliverToBoxAdapter(child: KeyedSubtree(key: _keyDesign, child: _buildBasicInfo(product))),
              SliverToBoxAdapter(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Divider(height: 8, color: Color(0xFFF5F5F5), thickness: 8),
                  _buildToptenBrandSection(product),
                  const Divider(height: 8, color: Color(0xFFF5F5F5), thickness: 8),
                ]),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ToptenTabBarDelegate(_buildToptenTabBar()),
              ),
              SliverToBoxAdapter(child: _buildMobileDesignImageBanner(product)),
              SliverToBoxAdapter(child: KeyedSubtree(key: _keyInfo, child: _buildToptenInfoSection(product))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection1Banner(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection2Material(product, isAdmin))),
              if (_showPocketSection(product))
                SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection3Pocket(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection5GoljiColors(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(key: _keySize, child: _buildSection6SizeChart(product, isAdmin))),
              SliverToBoxAdapter(child: KeyedSubtree(key: _keyWashing, child: _buildWashingTipSection(product))),
              SliverToBoxAdapter(child: RepaintBoundary(key: _keyReview, child: _buildReviewSection(product))),
              SliverToBoxAdapter(child: SizedBox(height: r.h(120))),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomBar(product),
          ),
        ],
      ),
    ));
  }

  // ── 태블릿 상세 (600~899px) — 중앙 정렬 + 최대폭 720 ──
  Widget _buildTabletDetailLayout(BuildContext context, ProductModel product, bool isAdmin) {
    final r = Responsive.of(context);
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            cacheExtent: 1200,
            slivers: [
              _buildSliverAppBarOnly(product),
              // 콘텐츠 영역 maxWidth 720 중앙 정렬
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildImageSlider(product),
                          _buildThumbnailBar(product),
                          _buildAiImageNoticeBanner(),
                          KeyedSubtree(key: _keyDesign, child: _buildBasicInfo(product)),
                          const Divider(height: 8, color: Color(0xFFF5F5F5), thickness: 8),
                          _buildToptenBrandSection(product),
                          const Divider(height: 8, color: Color(0xFFF5F5F5), thickness: 8),
                          _buildMobileDesignImageBanner(product),
                          KeyedSubtree(key: _keyInfo, child: _buildToptenInfoSection(product)),
                          RepaintBoundary(child: _buildSection1Banner(product, isAdmin)),
                          RepaintBoundary(child: _buildSection2Material(product, isAdmin)),
                          if (_showPocketSection(product))
                            RepaintBoundary(child: _buildSection3Pocket(product, isAdmin)),
                          RepaintBoundary(child: _buildSection5GoljiColors(product, isAdmin)),
                          RepaintBoundary(key: _keySize, child: _buildSection6SizeChart(product, isAdmin)),
                          KeyedSubtree(key: _keyWashing, child: _buildWashingTipSection(product)),
                          RepaintBoundary(key: _keyReview, child: _buildReviewSection(product)),
                          SizedBox(height: r.h(120)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _buildBottomBar(product),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  // ── PC 상세 (≥900px) — 2컬럼: 좌 이미지 고정 / 우 정보+스크롤 ──
  Widget _buildPcDetailLayout(BuildContext context, ProductModel product, bool isAdmin) {
    final r = Responsive.of(context);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    // 전체 최대 1280, 좌우 나눔: 이미지 45% / 정보 55%
    final contentW = screenW.clamp(900.0, 1280.0);
    final imgColW  = contentW * 0.45;
    final infoColW = contentW * 0.55;

    return wrapWithPopScope(context, Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── 상단 앱바 (전체 너비) ──
          Material(
            color: Colors.white,
            elevation: 0.5,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    // 뒤로가기
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: Color(0xFF1A1A1A)),
                      onPressed: () => goBackOrHome(context),
                    ),
                    // 홈
                    _appBarIconBtn(
                      icon: Icons.home_outlined,
                      onTap: () => Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
                        (r) => false),
                    ),
                    _appBarIconBtn(
                      icon: Icons.search_rounded,
                      onTap: () => Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                        (r) => false),
                    ),
                    _appBarIconBtn(
                      icon: Icons.shopping_bag_outlined,
                      onTap: () => Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                        (r) => false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── 본문: 2컬럼 ──
          Expanded(
            child: Center(
              child: SizedBox(
                width: contentW,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 좌: 이미지 슬라이더 (스크롤해도 고정) ──
                    SizedBox(
                      width: imgColW,
                      height: screenH - 56,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildImageSlider(product),
                            _buildThumbnailBar(product),
                            _buildAiImageNoticeBanner(),
                          ],
                        ),
                      ),
                    ),
                    // 세로 구분선
                    Container(width: 1, color: const Color(0xFFEEEEEE)),
                    // ── 우: 상품 정보 + 스크롤 ──
                    SizedBox(
                      width: infoColW - 1,
                      height: screenH - 56,
                      child: Stack(
                        children: [
                          CustomScrollView(
                            controller: _scrollCtrl,
                            cacheExtent: 1200,
                            slivers: [
                              SliverToBoxAdapter(child: Container(
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 기본 정보
                                    KeyedSubtree(key: _keyDesign, child: _buildBasicInfo(product)),
                                    const Divider(height: 8, color: Color(0xFFF5F5F5), thickness: 8),
                                    _buildToptenBrandSection(product),
                                    const Divider(height: 8, color: Color(0xFFF5F5F5), thickness: 8),
                                  ],
                                ),
                              )),
                              // 탭바 sticky
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _ToptenTabBarDelegate(_buildToptenTabBar()),
                              ),
                              SliverToBoxAdapter(child: Container(
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    _buildMobileDesignImageBanner(product),
                                    KeyedSubtree(key: _keyInfo, child: _buildToptenInfoSection(product)),
                                    RepaintBoundary(child: _buildSection1Banner(product, isAdmin)),
                                    RepaintBoundary(child: _buildSection2Material(product, isAdmin)),
                                    if (_showPocketSection(product))
                                      RepaintBoundary(child: _buildSection3Pocket(product, isAdmin)),
                                    RepaintBoundary(child: _buildSection5GoljiColors(product, isAdmin)),
                                    RepaintBoundary(key: _keySize, child: _buildSection6SizeChart(product, isAdmin)),
                                    KeyedSubtree(key: _keyWashing, child: _buildWashingTipSection(product)),
                                    RepaintBoundary(key: _keyReview, child: _buildReviewSection(product)),
                                    SizedBox(height: r.h(120)),
                                  ],
                                ),
                              )),
                            ],
                          ),
                          // 구매 버튼 (우측 컬럼 하단 고정)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildBottomBar(product),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  // ═══════════════════════════════════════
  // SLIVER HEADER (이미지 + 패럴랙스)
  // ═══════════════════════════════════════
  // ── 탑텐 스타일: 상단 앱바 (투명 → 스크롤 시 흰색) ──
  Widget _buildSliverAppBarOnly(ProductModel product) {
    final r = Responsive.of(context);
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      leading: Container(
        margin: EdgeInsets.all(r.w(8)),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A1A), size: 18),
          onPressed: () => goBackOrHome(context),
          padding: EdgeInsets.zero,
        ),
      ),
      actions: [
        // 홈 버튼 (탑텐 스타일)
        _appBarIconBtn(
          icon: Icons.home_outlined,
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
            (route) => false,
          ),
        ),
        // 검색 버튼
        _appBarIconBtn(
          icon: Icons.search_rounded,
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
            (route) => false,
          ),
        ),
        // 장바구니 버튼
        _appBarIconBtn(
          icon: Icons.shopping_bag_outlined,
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
            (route) => false,
          ),
          margin: EdgeInsets.only(right: r.w(8), top: r.h(8), bottom: r.h(8)),
        ),
      ],
    );
  }

  // 앱바 원형 아이콘 버튼 헬퍼
  Widget _appBarIconBtn({required IconData icon, required VoidCallback onTap, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin ?? EdgeInsets.only(right: r.w(2), top: r.h(8), bottom: r.h(8)),
      decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF1A1A1A), size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ── 이미지 슬라이더 (탑텐 스타일: 전체화면형, 하단 바 인디케이터) ──
  Widget _buildImageSlider(ProductModel product) {
    // _mainImages: Firestore fresh 로드 후 갱신된 메인 이미지 (배포 후에도 유지)
    final imgs = _mainImages.isNotEmpty ? _mainImages : product.images;
    final imgCount = imgs.isNotEmpty ? imgs.length : 1;

    // LayoutBuilder로 실제 부모 너비 기준 → PC/태블릿/모바일 모두 자동 대응
    return LayoutBuilder(
      builder: (_, constraints) {
        final r = Responsive.of(context);

        final w = constraints.maxWidth;
        final imgH = w * (5 / 4); // 4:5 비율 고정

    return Container(
      width: w,
      height: imgH,
      color: Colors.white,
      child: Stack(
        children: [
          // 메인 PageView
          PageView.builder(
            controller: _pageCtrl,
            itemCount: imgCount,
            onPageChanged: (i) => setState(() => _mainImageIndex = i),
            itemBuilder: (_, i) {
              final url = imgs.isNotEmpty ? imgs[i] : '';
              return GestureDetector(
                onTap: () => _showLightbox(product, i),
                child: url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.contain,
                        width: w,
                        height: imgH,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              );
            },
          ),
          // ── 탑텐 스타일: 하단 가득 채운 얇은 바 인디케이터 ──
          if (imgCount > 1)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Row(
                children: List.generate(imgCount, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: _mainImageIndex == i ? 3.0 : 2.0,
                      margin: EdgeInsets.only(right: i < imgCount - 1 ? 2 : 0),
                      decoration: BoxDecoration(
                        color: _mainImageIndex == i
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFCCCCCC),
                      ),
                    ),
                  );
                }),
              ),
            ),
          // ── 탑텐 스타일: 우하단 이미지 카운터 (작고 심플) ──
          Positioned(
            bottom: 12, right: 14,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(4)),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_mainImageIndex + 1} / $imgCount',
                style: TextStyle(color: Colors.white, fontSize: r.sp(11), fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // ── 좌상단 AI 생성 고지 텍스트 ──
          Positioned(
            top: 12, left: 14,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: r.w(9), vertical: r.h(6)),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '※ 모든 착상 이미지는 AI 생성 이미지입니다',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: r.sp(10),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: r.h(3)),
                  Text(
                    '▶ 디자인 이미지를 반드시 확인해주세요 [확인 필수]',
                    style: TextStyle(
                      color: Color(0xFFFFD966),
                      fontSize: r.sp(10),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],       // end Stack children
      ),         // end Stack
    );           // end Container return
        },       // LayoutBuilder builder
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
    final r = Responsive.of(context);

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
        padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), r.h(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
            SizedBox(height: r.h(16)),
            Text('공유하기', style: TextStyle(fontSize: r.sp(17), fontWeight: FontWeight.w800)),
            SizedBox(height: r.h(20)),
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
    final r = Responsive.of(context);
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
          SizedBox(height: r.h(8)),
          Text(label, style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w600)),
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
    // _mainImages: Firestore fresh 로드 후 갱신된 메인 이미지 사용
    final images = _mainImages.isNotEmpty
        ? _mainImages
        : (product.images.isNotEmpty ? product.images : ['']);
    showImageLightbox(context, images, initialIndex: initialIndex);
  }

  // ══ AI 생성 이미지 고지 배너 (제거됨 — 메인 이미지에 직접 표시) ══
  Widget _buildAiImageNoticeBanner() {
    return const SizedBox.shrink();
  }

  // ══ 모바일: 메인이미지 아래 디자인 이미지 배너 ══
  Widget _buildMobileDesignImageBanner(ProductModel product) {
    // 디자인 이미지는 풀사이즈 배너로 표시하지 않음
    // → 상품정보 탭의 '디자인 이미지' 섹션(_buildDesignImageSection)에서만 표시
    return const SizedBox.shrink();
  }

  // ══ 탑텐 스타일: 썸네일 바 (심플 정사각형, 선택 시 검정 테두리) ══
  Widget _buildThumbnailBar(ProductModel product) {
    final r = Responsive.of(context);
    // _mainImages: Firestore fresh 로드 후 갱신된 메인 이미지 사용
    final imgs = _mainImages.isNotEmpty ? _mainImages : product.images;
    if (imgs.length <= 1) return const SizedBox.shrink();
    return Container(
      height: 78,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(8)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imgs.length,
        separatorBuilder: (_, __) => SizedBox(width: r.w(6)),
        itemBuilder: (_, i) {
          final selected = _mainImageIndex == i;
          return GestureDetector(
            onTap: () {
              _pageCtrl.animateToPage(i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
              setState(() => _mainImageIndex = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
                  width: selected ? 2.0 : 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imgs[i],
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
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // 섬유 혼용율 인라인 (상품명 아래)
  // ═══════════════════════════════════════
  Widget _buildFiberRatioInline(ProductModel product) {
    final r = Responsive.of(context);
    final table = loc.fiberTableData;
    final name = product.localizedName(_lang).toLowerCase();
    final cat  = product.category.toLowerCase();
    final sub  = product.subCategory.toLowerCase();

    // 상품 카테고리/이름으로 해당 혼용율 행 매칭
    List<String>? matched;
    if (name.contains('타이즈') || sub.contains('타이즈') || cat.contains('하의')) {
      matched = table.firstWhere((r) => r[0].contains('골지') || r[0].contains('Golgi') || r[0].contains('タイツ'), orElse: () => table.isNotEmpty ? table[1] : []);
    } else if (name.contains('크롭') || name.contains('crop') || name.contains('삼각') || name.contains('원피스')) {
      // 에어로브라이트 또는 브라이트
      matched = table.length >= 4 ? table[2] : null;
    } else {
      // 싱글렛, 라운드티 기본
      matched = table.isNotEmpty ? table[0] : null;
    }
    if (matched == null || matched.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(3)),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F8FF),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
          ),
          child: Text(
            matched[1],
            style: TextStyle(fontSize: r.sp(11), color: Color(0xFF1565C0), fontWeight: FontWeight.w600),
          ),
        ),
        if (matched.length > 2)
          Container(
            padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(3)),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
            ),
            child: Text(
              matched[2],
              style: TextStyle(fontSize: r.sp(11), color: Color(0xFF1565C0), fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // 기본 정보 (탑텐 스타일)
  // ═══════════════════════════════════════
  Widget _buildBasicInfo(ProductModel product) {
    final r = Responsive.of(context);
    final discount = product.originalPrice != null && product.originalPrice! > product.price
        ? ((1 - product.price / product.originalPrice!) * 100).round() : 0;
    final isAdmin = context.read<UserProvider>().isAdmin;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 디자인 이미지 섹션 ──
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(16), r.w(16), r.h(0)),
            child: _buildDesignImageSection(product, isAdmin),
          ),

          // ═══════════════════════════════════════════════
          // 상품 속성 뱃지 (단체전용 / 기성품)
          // ═══════════════════════════════════════════════
          if (!product.isGroupOnly && product.isReadyMade)
            Padding(
              padding: EdgeInsets.fromLTRB(r.w(16), r.h(14), r.w(16), r.h(0)),
              child: Row(children: [
                _toptenTabChip('기성품', true, activeColor: Colors.teal),
              ]),
            ),
          if (product.isGroupOnly)
            Padding(
              padding: EdgeInsets.fromLTRB(r.w(16), r.h(14), r.w(16), r.h(0)),
              child: Row(children: [
                _toptenTabChip('단체전용', true, activeColor: const Color(0xFF6A1B9A)),
                if (product.isReadyMade) ...[
                  SizedBox(width: r.w(8)),
                  _toptenTabChip('기성품', true, activeColor: Colors.teal),
                ],
              ]),
            ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 브랜드명 > + 공유 버튼
          // ═══════════════════════════════════════════════
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(16), r.w(16), r.h(0)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Text(
                        '2FIT KOREA',
                        style: TextStyle(
                          fontSize: r.sp(13),
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: r.w(2)),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF888888)),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _shareProduct(product),
                  child: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 상품명 (영문 소제목 + 한국어 대제목)
          // ═══════════════════════════════════════════════
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(6), r.w(16), r.h(0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 소제목
                Text(
                  product.category,
                  style: TextStyle(
                    fontSize: r.sp(12),
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: r.h(4)),
                // 상품명 대제목
                Text(
                  product.localizedName(_lang),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: r.sp(20),
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    height: 1.35,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 별점 + 리뷰건수 >
          // ═══════════════════════════════════════════════
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(8), r.w(16), r.h(0)),
            child: GestureDetector(
              onTap: () {},
              child: Row(children: [
                const Icon(Icons.star_rounded, size: 15, color: Color(0xFF1A1A1A)),
                SizedBox(width: r.w(3)),
                Text(
                  product.rating > 0 ? product.rating.toStringAsFixed(1) : '4.8',
                  style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                SizedBox(width: r.w(4)),
                Text(
                  '리뷰 ${product.reviewCount > 0 ? product.reviewCount : 0}건',
                  style: TextStyle(fontSize: r.sp(13), color: Color(0xFF888888), fontWeight: FontWeight.w500),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF888888)),
              ]),
            ),
          ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 가격 영역 (파란 할인율 + 현재가 + 취소선)
          // ═══════════════════════════════════════════════
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(14), r.w(16), r.h(0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // 파란색 할인율 (탑텐 시그니처: 배경 없는 텍스트)
                      Text(
                        '$discount%',
                        style: TextStyle(
                          fontSize: r.sp(22),
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1976D2),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(width: r.w(8)),
                      // 현재가
                      Text(
                        '${_fmt(product.price)}${loc.wonUnit}',
                        style: TextStyle(
                          fontSize: r.sp(22),
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(width: r.w(8)),
                      // 취소선 원가
                      Text(
                        '${_fmt(product.originalPrice!)}',
                        style: TextStyle(
                          fontSize: r.sp(14),
                          color: Color(0xFFBBBBBB),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Color(0xFFBBBBBB),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '${_fmt(product.price)}${loc.wonUnit}',
                    style: TextStyle(
                      fontSize: r.sp(22),
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 색상 선택 원형 그리드 (단체주문 상품은 색상 선택 UI 없음)
          // ═══════════════════════════════════════════════
          if (product.colors.isNotEmpty && !product.isGroupOnly) ...[
            SizedBox(height: r.h(18)),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            _buildToptenColorSection(product),
          ],

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 시즌 | 상품번호
          // ═══════════════════════════════════════════════
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(10), r.w(16), r.h(10)),
            child: Text(
              '시즌 : SS26  |  상품번호 : ${product.productCode.isNotEmpty ? product.productCode.toUpperCase() : product.id.toUpperCase()}',
              style: TextStyle(fontSize: r.sp(11), color: Color(0xFFAAAAAA), fontWeight: FontWeight.w400),
            ),
          ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 해시태그 칩
          // ═══════════════════════════════════════════════
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(0), r.w(16), r.h(14)),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              _hashtagChip('#2fit'),
              _hashtagChip('#스포츠웨어'),
              if (product.isFreeShipping) _hashtagChip('#무료배송'),
              if (product.isNewActive) _hashtagChip('#신상품'),
              if (product.isSale) _hashtagChip('#세일'),
              _hashtagChip('#${product.category}'),
            ]),
          ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 배송비 + 포인트 섹션
          // ═══════════════════════════════════════════════
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _buildToptenShippingSection(product),
        ],
      ),
    );
  }

  // ── 탑텐 스타일: PAYBACK/특별사이즈 탭 칩 ──
  Widget _toptenTabChip(String label, bool selected, {Color? activeColor}) {
    final r = Responsive.of(context);
    final ac = activeColor ?? const Color(0xFF1A1A1A);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(5)),
      decoration: BoxDecoration(
        color: selected ? ac : Colors.white,
        border: Border.all(color: selected ? ac : const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: r.sp(12),
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF888888),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ── 탑텐 스타일: 색상 원형 그리드 선택 UI ──
  Widget _buildToptenColorSection(ProductModel product) {
    String _selectedColor = product.colors.isNotEmpty ? product.colors.first : '';
    // 골지 텍스처 적용 대상: 타이즈, 단체주문 하의, 5부, 2.5부
    final sub  = product.subCategory;
    final name = product.name;
    final showRib = product.isGroupOnly && product.category == '하의'
        || sub.contains('타이즈') || name.contains('타이즈')
        || sub.contains('5부')    || name.contains('5부')
        || sub.contains('2.5부')  || name.contains('2.5부');

    return StatefulBuilder(builder: (ctx, setSt) {
      final r = Responsive.of(context);

      return Padding(
        padding: EdgeInsets.fromLTRB(r.w(16), r.h(14), r.w(16), r.h(0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 색상 라벨 + 선택된 색상명
            Row(children: [
              Text('색상', style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              SizedBox(width: r.w(10)),
              Text(
                _selectedColor,
                style: TextStyle(fontSize: r.sp(13), color: Color(0xFF888888), fontWeight: FontWeight.w400),
              ),
            ]),
            SizedBox(height: r.h(12)),
            // 원형 색상 버튼 그리드
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: product.colors.map((colorName) {
                final isSelected = _selectedColor == colorName;
                final dotColor = _goljiColorMap[colorName] ?? const Color(0xFFCCCCCC);
                final isLight = dotColor.computeLuminance() > 0.5;
                return GestureDetector(
                  onTap: () => setSt(() => _selectedColor = colorName),
                  child: RibColorSwatch(
                    color: dotColor,
                    size: 36,
                    isSelected: isSelected,
                    accentColor: const Color(0xFF1A1A1A),
                    isLight: isLight,
                    borderRadius: 18,
                    showRib: showRib,
                    child: isSelected
                        ? Icon(Icons.check_rounded, size: 16,
                            color: isLight ? Colors.black87 : Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: r.h(8)),
            // 색상 안내 disclaimer
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 11, color: Color(0xFFBBBBBB)),
                SizedBox(width: r.w(4)),
                Expanded(
                  child: Text(
                    '화면에 표시된 색상은 모니터 환경에 따라 실제 제품과 약간의 차이가 있을 수 있습니다.',
                    style: TextStyle(fontSize: r.sp(10), color: Color(0xFFBBBBBB), height: 1.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── 탑텐 스타일: 해시태그 칩 ──
  Widget _hashtagChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: r.sp(12), color: Color(0xFF555555), fontWeight: FontWeight.w400),
      ),
    );
  }

  // ── 탑텐 스타일: 배송비 + 포인트 구조형 섹션 ──
  Widget _buildToptenShippingSection(ProductModel product) {
    final r = Responsive.of(context);
    return Column(children: [
      // 배송비 행
      Padding(
        padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(13)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Text('배송비', style: TextStyle(fontSize: r.sp(13), color: Color(0xFF888888), fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.isFreeShipping
                        ? '무료배송'
                        : '4,000원 (300,000원 이상 구매시 무료)',
                    style: TextStyle(
                      fontSize: r.sp(13),
                      color: product.isFreeShipping ? const Color(0xFF2E7D32) : const Color(0xFF1A1A1A),
                      fontWeight: product.isFreeShipping ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  if (!product.isFreeShipping)
                    Text(
                      '(도서산간 배송시 3,000원 추가)',
                      style: TextStyle(fontSize: r.sp(11), color: Color(0xFFAAAAAA)),
                    ),
                  // 포인트 섹션 제거됨 (요청 반영)
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ── 탑텐 스타일: 브랜드 로고 박스 섹션 ──
  Widget _buildToptenBrandSection(ProductModel product) {
    return Consumer<UserProvider>(builder: (_, up, __) {
      final r = Responsive.of(context);

      final isWish = up.isInWishlist(product.id);
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(14)),
        child: Row(children: [
          // 브랜드 로고 — logo_2fit_text.png 이미지
          SizedBox(
            width: 90,
            height: 40,
            child: Image.asset(
              'assets/images/logo_2fit_text.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, __, ___) => Text(
                '2FIT',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: r.sp(18),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SizedBox(width: r.w(10)),
          // 브랜드명 텍스트
          GestureDetector(
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2FIT', style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), letterSpacing: -0.3)),
                Text('2FIT KOREA', style: TextStyle(fontSize: r.sp(11), color: Color(0xFF888888), fontWeight: FontWeight.w400, letterSpacing: 0.5)),
              ],
            ),
          ),
          const Spacer(),
          // 찜하기 하트 + 카운트
          GestureDetector(
            onTap: () {
              if (up.isLoggedIn) {
                up.toggleWishlist(product.id);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.loginRequired)),
                );
              }
            },
            child: Column(children: [
              Icon(
                isWish ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isWish ? Colors.redAccent : const Color(0xFF888888),
                size: 26,
              ),
              Text(
                (up.user?.wishlist.length ?? 0).toString(),
                style: TextStyle(fontSize: r.sp(11), color: Color(0xFF888888), fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ]),
      );
    });
  }

  // ── 탑텐 스타일: 상품정보 탭바 (상품정보/사이즈/리뷰/추천/문의) ──
  // 탭 클릭 → 해당 섹션으로 즉시 스크롤
  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.0,
    );
  }

  Widget _buildToptenTabBar() {
    final tabs = [
      ('상품정보', 0, _keyInfo),
      ('사이즈',   1, _keySize),
      ('세탁',     2, _keyWashing),
      ('리뷰',     3, _keyReview),
    ];
    return Container(
      color: Colors.white,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: tabs.map((t) {
          final r = Responsive.of(context);

          final label = t.$1;
          final idx   = t.$2;
          final key   = t.$3;
          final sel   = _selectedTabIndex == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTabIndex = idx);
                _scrollToSection(key);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: r.h(13)),
                child: Column(children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: r.sp(13),
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: r.h(10)),
                  Container(height: 2, color: sel ? const Color(0xFF1A1A1A) : Colors.transparent),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 탑텐 스타일: 상품 상세 정보 (INFO/PRODUCT/MATERIAL/COLOR/WASHING TIP) ──
  Widget _buildToptenInfoSection(ProductModel product) {
    final r = Responsive.of(context);
    final productCode = product.productCode.isNotEmpty
        ? product.productCode.toUpperCase()
        : product.id.toUpperCase();

    final cat = product.category;
    final sub = product.subCategory;
    final name = product.name;

    // ── 카테고리 판별 헬퍼 ──────────────────────────────────────
    final isSingletSet =
        cat == '세트' ||
        sub.contains('싱글렛세트') ||
        name.contains('싱글렛세트') ||
        name.contains('싱글렛 세트');
    final isSingletTop =
        !isSingletSet &&
        (cat == '상의' || sub.contains('싱글렛') || name.contains('싱글렛'));
    final isTaiz =
        sub.contains('타이즈') || name.contains('타이즈') || cat == '하의';
    final isGroupOnly = product.isGroupOnly;

    // ── 1) MATERIAL: 카테고리별 소재 텍스트 ─────────────────────
    // 우선순위: ① 관리자 직접 입력값(material) → ② 카테고리 기본값
    String materialText;
    // 기본값('78% Nylon...')이 아닌 실제 입력값이 있으면 최우선 사용
    final hasCustomMaterial = product.material.isNotEmpty &&
        product.material != '78% Nylon, 22% Spandex / 4-way Stretch' &&
        product.material != '78% Nylon, 22% Spandex';
    if (hasCustomMaterial) {
      materialText = product.material;
    } else if (isSingletSet) {
      materialText = '상의: 폴리에스터 92% / 라이크라 8%\n하의: 나일론 75% / 라이크라 25%';
    } else if (isSingletTop) {
      materialText = '폴리에스터 92% / 라이크라 8%';
    } else if (isTaiz) {
      materialText = '나일론 75% / 라이크라 25%';
    } else if (product.material.isNotEmpty) {
      materialText = product.material;
    } else {
      materialText = '78% Nylon, 22% Spandex / 4-way Stretch';
    }

    // ── 2) COLOR: 카테고리/구매방식별 표시 ──────────────────────
    // 단체주문: 골지 19색 모두 선택 가능
    // 기성품 싱글렛세트: 상의=디자인 색상 고정, 하의=K/PP 선택
    // 기성품 싱글렛(상의 단품): 제품 디자인 색상 그대로
    // 하의 타이즈: K 또는 PP 선택
    // 기타: 등록된 색상만
    Widget colorContent;
    if (isGroupOnly && (isSingletSet || isTaiz)) {
      final r = Responsive.of(context);

      // 단체주문 싱글렛세트·하의: 골지 19색 전체 안내
      colorContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoColorBadge(
            label: '단체주문 전용',
            labelColor: const Color(0xFF4A148C),
            text: '골지원단 19가지 기본 색상 중 원하는 색상으로 자유롭게 제작 가능',
          ),
          SizedBox(height: r.h(10)),
          _infoColorChipRow(['K','N','W','G','DG','SB','B','DB','SP','LP','IO','LG','R','PP','ND','BB','FP','FO','FG'], useRib: true),
          SizedBox(height: r.h(12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: r.w(13), vertical: r.h(10)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFF7B1FA2).withOpacity(0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFF6A1B9A)),
                ),
                SizedBox(width: r.w(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '19가지 기본 색상 외에도 제작 가능',
                        style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w700, color: Color(0xFF4A148C), height: 1.3),
                      ),
                      SizedBox(height: r.h(2)),
                      Text(
                        '원하시는 색상이 있다면 주문 시 별도로 알려주세요.',
                        style: TextStyle(fontSize: r.sp(10.5), color: Color(0xFF6A1B9A), height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // 기성품: 타이즈·5부·2.5부는 골지, 그 외(숏츠 등)는 단색
      final isRibBottom =
          sub.contains('타이즈') || name.contains('타이즈') ||
          sub.contains('5부')    || name.contains('5부')    ||
          sub.contains('2.5부')  || name.contains('2.5부');
      final useRib = isRibBottom;
      colorContent = product.colors.isNotEmpty
          ? _infoColorChipRow(product.colors, useRib: useRib)
          : Text('등록된 색상 정보가 없습니다.',
              style: TextStyle(fontSize: r.sp(12), color: Color(0xFF888888)));
    }

    // ── 3) PRODUCT 테이블 행: 하의길이 행 추가 ──────────────────
    // 우선순위: ① 관리자 직접 입력값(bottomLength) → ② 카테고리 기본값
    String? bottomLengthValue;
    if (product.bottomLength.isNotEmpty) {
      // 관리자가 직접 입력한 값 최우선 사용
      bottomLengthValue = product.bottomLength;
    } else if (!isGroupOnly && isSingletSet) {
      // 싱글렛세트 기성품 기본값
      bottomLengthValue = '남성: 5부 고정  /  여성: 2.5부 고정';
    } else if (!isGroupOnly && isTaiz) {
      // 하의 타이즈 기성품: subCategory에 길이 정보 있으면 사용
      final lengthLabel = sub.contains('9부') ? '9부'
          : sub.contains('5부') ? '5부'
          : sub.contains('4부') ? '4부'
          : sub.contains('3부') ? '3부'
          : sub.contains('2.5부') ? '2.5부'
          : sub.contains('숏쇼츠') ? '숏쇼츠'
          : null;
      if (lengthLabel != null) bottomLengthValue = lengthLabel;
    }

    // 블록 번호 동적 계산
    int blockNum = 2;
    final int productBlockNum = ++blockNum; // 02 PRODUCT (항상)
    final int materialBlockNum = ++blockNum; // 03 MATERIAL (항상)
    final int colorBlockNum = ++blockNum;   // 04 COLOR (항상)

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: const Color(0xFFE8E8E8)),
          SizedBox(height: r.h(8)),

          // ── 01 INFO: 제품 설명
          _toptenInfoBlock(
            num: '01',
            label: 'INFO',
            labelSub: '제품 설명',
            content: Text(
              product.localizedDescription(_lang),
              style: TextStyle(
                fontSize: r.sp(13),
                color: Color(0xFF444444),
                height: 1.85,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ),

          // ── 02 PRODUCT: 제품 기본 정보 테이블
          _toptenInfoBlock(
            num: productBlockNum.toString().padLeft(2, '0'),
            label: 'PRODUCT',
            labelSub: '제품 기본 정보',
            content: _toptenInfoTable([
              ('제품명', product.localizedName(_lang)),
              if (product.subCategory.isNotEmpty) ('분류', product.subCategory),
              ('상품코드', productCode),
              ('시즌', 'SS26'),
              // 하의길이 행: 해당 카테고리만
              if (bottomLengthValue != null) ('하의길이', bottomLengthValue),
            ]),
          ),

          // ── 03 MATERIAL: 카테고리별 소재 텍스트
          _toptenInfoBlock(
            num: materialBlockNum.toString().padLeft(2, '0'),
            label: 'MATERIAL',
            labelSub: '소재 정보',
            content: Text(
              materialText,
              style: TextStyle(
                fontSize: r.sp(13),
                color: Color(0xFF444444),
                height: 1.85,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // ── 04 COLOR: 카테고리/구매방식별 색상 안내
          _toptenInfoBlock(
            num: colorBlockNum.toString().padLeft(2, '0'),
            label: 'COLOR',
            labelSub: '색상 안내',
            content: colorContent,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── 색상 안내 배지 (라벨 + 설명 텍스트) ──
  Widget _infoColorBadge({
    required String label,
    required Color labelColor,
    required String text,
  }) {
    final r = Responsive.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(3)),
          decoration: BoxDecoration(
            color: labelColor,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(label,
              style: TextStyle(color: Colors.white, fontSize: r.sp(10), fontWeight: FontWeight.w800)),
        ),
        SizedBox(width: r.w(8)),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: r.sp(12), color: Color(0xFF444444), height: 1.5)),
        ),
      ],
    );
  }

  // ── 골지 19색 + 일반 색상 공통 맵
  // 실물 촬영 이미지 픽셀 직접 추출 — median sampling (2026-05-28)
  static const Map<String, Color> _goljiColorMap = {
    // ── 골지 19색 (코드 기준) ──────────────────────────────
    'K':  Color(0xFF3A3A3A),  // 블랙
    'N':  Color(0xFF2A3668),  // 네이비
    'W':  Color(0xFFF2F2F2),  // 화이트
    'G':  Color(0xFF9E9E9E),  // 그레이
    'DG': Color(0xFF424242),  // 다크그레이
    'SB': Color(0xFF92C9F8),  // 스카이블루
    'B':  Color(0xFF3A6ACD),  // 블루
    'DB': Color(0xFF485685),  // 다크블루
    'SP': Color(0xFFE7C6BF),  // 스킨핑크
    'LP': Color(0xFFE6A8B1),  // 라이트핑크
    'IO': Color(0xFFD2CEC3),  // 아이보리
    'LG': Color(0xFFBDBDBD),  // 라이트그레이
    'R':  Color(0xFFE03430),  // 레드
    'PP': Color(0xFF363752),  // 퍼플네이비
    'ND': Color(0xFF4B5441),  // 올리브그린
    'BB': Color(0xFF116977),  // 틸블루
    'FP': Color(0xFFFD1691),  // 형광핑크
    'FO': Color(0xFFFE6502),  // 형광오렌지
    'FG': Color(0xFF7FD905),  // 형광그린
    // ── 영문 색상명 매핑 ──────────────────────────────────
    'Black':    Color(0xFF3A3A3A),
    'White':    Color(0xFFF2F2F2),
    'Navy':     Color(0xFF2A3668),
    'Gray':     Color(0xFF9E9E9E),
    'Red':      Color(0xFFE03430),
    'Blue':     Color(0xFF3A6ACD),
    'Pink':     Color(0xFFE6A8B1),
    'Purple':   Color(0xFF363752),
    'Sky Blue': Color(0xFF92C9F8),
    'Green':    Color(0xFF4B5441),
    'Yellow':   Color(0xFFFFD600),
    'Brown':    Color(0xFF795548),
    'Beige':    Color(0xFFD2CEC3),
    'Orange':   Color(0xFFFE6502),
    'Mint':     Color(0xFF26C9A0),
    // ── 한글 색상명 매핑 ──────────────────────────────────
    '블랙':       Color(0xFF3A3A3A),
    '화이트':     Color(0xFFF2F2F2),
    '네이비':     Color(0xFF2A3668),
    '그레이':     Color(0xFF9E9E9E),
    '다크그레이':  Color(0xFF424242),
    '스카이블루':  Color(0xFF92C9F8),
    '블루':       Color(0xFF3A6ACD),
    '다크블루':   Color(0xFF485685),
    '스킨핑크':   Color(0xFFE7C6BF),
    '라이트핑크':  Color(0xFFE6A8B1),
    '아이보리':   Color(0xFFD2CEC3),
    '라이트그레이': Color(0xFFBDBDBD),
    '레드':       Color(0xFFE03430),
    '퍼플네이비':  Color(0xFF363752),
    '올리브그린':  Color(0xFF4B5441),
    '틸블루':     Color(0xFF116977),
    '형광핑크':   Color(0xFFFD1691),
    '형광오렌지':  Color(0xFFFE6502),
    '형광그린':   Color(0xFF7FD905),
    '퍼플':       Color(0xFF363752),
    '핑크':       Color(0xFFE6A8B1),
    '그린':       Color(0xFF4B5441),
    '옐로우':     Color(0xFFFFD600),
    '브라운':     Color(0xFF795548),
    '베이지':     Color(0xFFD2CEC3),
    '민트':       Color(0xFF26C9A0),
  };

  // ── 색상 칩: 원형 스와치 (useRib=true 이면 골지 텍스처, false 이면 단색)
  Widget _infoColorChipRow(List<String> codes, {bool useRib = true}) {
    return Wrap(
      spacing: 10,
      runSpacing: 14,
      children: codes.map((c) {
        final r = Responsive.of(context);

        final dotColor = _goljiColorMap[c] ?? _goljiColorMap[c.toUpperCase()] ?? const Color(0xFFCCCCCC);
        final isLight = dotColor.computeLuminance() > 0.5;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            useRib
                // 골지 텍스처 원형 스와치 (borderRadius=18 → 완전 원형)
                ? RibColorSwatch(
                    color: dotColor,
                    size: 36,
                    isLight: isLight,
                    borderRadius: 18,
                    showRib: true,
                  )
                // 단색 원형 스와치 (숏츠 등 골지 없는 원단)
                : Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLight
                            ? Colors.black.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.30),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
            SizedBox(height: r.h(5)),
            // 코드명
            Text(
              c.toUpperCase(),
              style: TextStyle(
                fontSize: r.sp(9),
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
                letterSpacing: 0.3,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── 탑텐 스타일: 번호+라벨+컨텐츠 블록
  Widget _toptenInfoBlock({
    required String num,
    required String label,
    required String labelSub,
    required Widget content,
    bool isLast = false,
  }) {
    final r = Responsive.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 분리선
        Container(
          margin: EdgeInsets.symmetric(horizontal: r.w(20)),
          height: 1,
          color: const Color(0xFFE0E0E0),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), r.h(16)),
          child: content,
        ),
        if (isLast) SizedBox(height: r.h(8)),
      ],
    );
  }

  // ── 탑텐 스타일: 키-값 테이블
  Widget _toptenInfoTable(List<(String, String)> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        color: Colors.white,
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final r = Responsive.of(context);

          final i = entry.key;
          final row = entry.value;
          final isLast = i == rows.length - 1;
          return Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              color: i.isEven ? Colors.white : const Color(0xFFFAFAFA),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 라벨 셀
                Container(
                  width: 80,
                  padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(11)),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
                    color: Color(0xFFF5F5F5),
                  ),
                  child: Text(
                    row.$1,
                    style: TextStyle(
                      fontSize: r.sp(11),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                // 값 셀
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(11)),
                    child: Text(
                      row.$2,
                      style: TextStyle(
                        fontSize: r.sp(11),
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF222222),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 세탁 주의사항 리스트
  static const List<String> _washingTips = [
    '세제를 풀어 놓은 물에 담가 두지 마시고 세탁 시 수축 및 변형 방지를 위해 찬물 세탁을 권장합니다.',
    '땀과 물에 젖었을 경우 즉시 세탁하십시오.',
    '세탁 시 지퍼나 단추를 잠근 상태에서 세탁하여 주십시오.',
    '흰색 제품과 유색 제품은 반드시 구분하여 별도 세탁하십시오.',
    '이염 방지를 위해 색상이 있는 옷은 단독 세탁 권장 드리며, 염소, xs백 제품은 사용하지 않는 것을 권장 드립니다.',
    '탈수 시 약하게 짜시고 탈수 후 뭉친 상태로 두시면 이염이 될 수 있으니 바로 건조하여 주십시오.',
    '열풍 건조는 제품 수축의 원인이 될 수 있으므로 열풍 건조를 하지 마십시오.',
  ];

  // ── 최하단 WASHING TIP 독립 섹션 (탑텐 스타일) ──
  Widget _buildWashingTipSection(ProductModel product) {
    final r = Responsive.of(context);
    // 아이콘+설명 세탁 가이드 항목
    final washGuide = [
      (Icons.water_drop_outlined,      '찬물 세탁',    '30°C 이하 찬물 사용 권장'),
      (Icons.front_hand_outlined,      '손세탁 권장',  '세탁기 사용 시 단독 세탁'),
      (Icons.air_outlined,             '자연 건조',    '열풍 건조 금지 — 수축 원인'),
      (Icons.lock_outline_rounded,     '지퍼/단추 잠금', '세탁 전 지퍼·단추를 잠근 후 세탁'),
      (Icons.color_lens_outlined,      '색상 분리',    '흰색·유색 제품 반드시 분리 세탁'),
      (Icons.timer_outlined,           '즉시 세탁',    '땀·물에 젖은 즉시 세탁'),
    ];

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 상단 굵은 구분선
          Container(height: 2, color: const Color(0xFF1A1A1A)),

          SizedBox(height: r.h(8)),

          // ── 세탁 가이드 아이콘 그리드
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(20)),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
              childAspectRatio: 1.15,
              children: washGuide.map((g) => Container(
                color: const Color(0xFFF2F2F2),
                padding: EdgeInsets.all(r.w(14)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(g.$1, size: 22, color: const Color(0xFF333333)),
                    SizedBox(height: r.h(8)),
                    Text(
                      g.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: r.sp(10),
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: r.h(3)),
                    Text(
                      g.$3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: r.sp(9),
                        color: Color(0xFF888888),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          SizedBox(height: r.h(24)),

          // ── WASHING TIP 상세 리스트
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 팁 리스트
                ..._washingTips.asMap().entries.map((entry) {
                  final r = Responsive.of(context);

                  final tip = entry.value;
                  final isLast = entry.key == _washingTips.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: r.h(12)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('·', style: TextStyle(
                              fontSize: r.sp(14),
                              color: Color(0xFFBBBBBB),
                              height: 1.2,
                            )),
                            SizedBox(width: r.w(10)),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: r.sp(12),
                                  color: Color(0xFF555555),
                                  height: 1.65,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                    ],
                  );
                }),

                SizedBox(height: r.h(20)),

                // ── 하단 주의사항 박스 (탑텐 스타일: 검정 좌측 라인)
                Container(
                  padding: EdgeInsets.fromLTRB(r.w(16), r.h(14), r.w(16), r.h(14)),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    border: Border(
                      left: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                    ),
                  ),
                  child: Text(
                    '재고는 조기 소진될 수 있으며, 소비자 부주의로 인한 제품 손상은 보상이 되지 않으므로 위의 세탁 방법을 반드시 준수 바랍니다.',
                    style: TextStyle(fontSize: r.sp(11), color: Color(0xFF666666), height: 1.65),
                  ),
                ),

                SizedBox(height: r.h(40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 탑텐 스타일: 섹션 내 소타이틀 (기존 _infoBlockTitle 대체)
  Widget _infoBlockTitle(String title) {
    final r = Responsive.of(context);
    return Row(
      children: [
        Container(width: 12, height: 1.5, color: const Color(0xFF1A1A1A)),
        SizedBox(width: r.w(7)),
        Text(
          title,
          style: TextStyle(
            fontSize: r.sp(11),
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // 탑텐 스타일: 키-값 한 줄 (기존 _infoLabelRow 대체)
  Widget _infoLabelRow(String label, String value) {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.h(7)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: r.sp(12), color: Color(0xFF999999), fontWeight: FontWeight.w500, letterSpacing: 0.1),
            ),
          ),
          Container(width: 1, height: 14, color: Color(0xFFDDDDDD), margin: EdgeInsets.only(top: r.h(1), right: r.w(12))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: r.sp(12), color: Color(0xFF222222), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── 탑텐 스타일: 태그 위젯 ──
  Widget _toptenTag(IconData icon, String label, Color color) {
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(9), vertical: r.h(5)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: r.w(4)),
          Text(
            label,
            style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // ── 탑텐 스타일: 배송/혜택 정보 심플 라인형 ──
  Widget _buildToptenShippingInfo(ProductModel product) {
    final r = Responsive.of(context);
    final items = [
      {
        'icon': Icons.local_shipping_outlined,
        'label': loc.shippingLabel,
        'value': product.isFreeShipping ? loc.freeShipping : loc.basicShippingFeeInfo,
        'highlight': product.isFreeShipping,
      },
      {
        'icon': Icons.access_time_rounded,
        'label': loc.dispatchLabel,
        'value': loc.dispatchDaysInfo,
        'highlight': false,
      },
      {
        'icon': Icons.stars_rounded,
        'label': loc.pointLabel,
        'value': loc.pointAccumulateInfo,
        'highlight': false,
      },
      {
        'icon': Icons.swap_horiz_rounded,
        'label': loc.exchangeReturnLabel,
        'value': loc.exchangeReturnInfo,
        'highlight': false,
      },
    ];
    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        final isHighlight = item['highlight'] as bool;
        final isLast = entry.key == items.length - 1;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(13)),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isLast ? Colors.transparent : const Color(0xFFF0F0F0),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item['icon'] as IconData, size: 15, color: isHighlight ? const Color(0xFF2E7D32) : const Color(0xFF999999)),
              SizedBox(width: r.w(10)),
              SizedBox(
                width: 52,
                child: Text(
                  item['label'] as String,
                  style: TextStyle(fontSize: r.sp(12), color: Color(0xFF999999), fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Text(
                  item['value'] as String,
                  style: TextStyle(
                    fontSize: r.sp(12),
                    color: isHighlight ? const Color(0xFF2E7D32) : const Color(0xFF333333),
                    fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final r = Responsive.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF888888)),
        SizedBox(width: r.w(8)),
        SizedBox(
          width: 48,
          child: Text(label, style: TextStyle(fontSize: r.sp(12), color: Color(0xFF888888), fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: r.sp(12), color: Color(0xFF333333), fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // 상의 색상 안내 배너용 행 위젯
  // ignore: unused_element
  Widget _colorNoticeRow(IconData icon, String label, String desc, {required bool highlight}) {
    final r = Responsive.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: highlight ? const Color(0xFFFFD54F) : Colors.white70,
        ),
        SizedBox(width: r.w(8)),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontSize: r.sp(12),
              fontWeight: FontWeight.w800,
              color: highlight ? const Color(0xFFFFD54F) : Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: TextStyle(
              fontSize: r.sp(12),
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
    final r = Responsive.of(context);
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
      padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(r.w(7)),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.palette_rounded, size: 16, color: Color(0xFF1565C0)),
          ),
          SizedBox(width: r.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(2)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(label,
                        style: TextStyle(fontSize: r.sp(10), fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    SizedBox(width: r.w(6)),
                    Text('하의 색상 선택',
                      style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
                  ],
                ),
                SizedBox(height: r.h(3)),
                Text(subtitle,
                  style: TextStyle(fontSize: r.sp(11), color: Color(0xFF555555), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(3)),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: TextStyle(color: Colors.white, fontSize: r.sp(10), fontWeight: FontWeight.w700)),
      );
  }

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
      final r = Responsive.of(context);

      // 성별에 따라 하의길이 자동반영
      final autoLength = _singletGender == '남' ? '5부' : '2.5부';
      // 상태가 아직 반영 안 됐으면 반영
      if (_selectedBottomLength != autoLength) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedBottomLength = autoLength);
        });
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(r.w(16), r.h(10), r.w(16), r.h(0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            SizedBox(height: r.h(10)),
            // 제목 + 안내
            Row(
              children: [
                Text(loc.bottomLengthTitle,
                    style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700)),
                SizedBox(width: r.w(6)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.w(6), vertical: r.h(2)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A148C).withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.3)),
                  ),
                  child: Text(loc.genderAutoFix,
                      style: TextStyle(fontSize: r.sp(10), color: Color(0xFF6A1B9A), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            SizedBox(height: r.h(8)),

            // 남/여 선택 버튼
            Row(
              children: [
                _inlineGenderBtn('남', loc.male, loc.maleBottomSub),
                SizedBox(width: r.w(8)),
                _inlineGenderBtn('여', loc.female, loc.femaleBottomSub),
              ],
            ),
            SizedBox(height: r.h(8)),

            // 확정된 길이 표시
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(9)),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF6A1B9A)),
                  SizedBox(width: r.w(6)),
                  Text(
                    '하의 기장 ${_singletGender == "남" ? "5부 (~55cm)" : "2.5부 (~30cm)"} 확정',
                    style: TextStyle(
                        fontSize: r.sp(12),
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
      padding: EdgeInsets.fromLTRB(r.w(16), r.h(10), r.w(16), r.h(0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          SizedBox(height: r.h(10)),
          Row(
            children: [
              Text(loc.bottomLengthSelectTitle,
                  style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700)),
              if (allowedLengths != null) ...[
                SizedBox(width: r.w(6)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.w(6), vertical: r.h(2)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                  ),
                  child: Text(loc.restrictedLabel,
                      style: TextStyle(fontSize: r.sp(10), color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          SizedBox(height: r.h(8)),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: lengths.map((l) {
              final r = Responsive.of(context);

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
                  padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(6)),
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
                              fontSize: r.sp(12),
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
            SizedBox(height: r.h(6)),
            Text('* ${loc.productAllowedLengthNote}: ${allowedLengths.join("·")}',
                style: TextStyle(fontSize: r.sp(10), color: Color(0xFF1565C0))),
          ],
        ],
      ),
    );
  }

  // 성별 선택 버튼 (모든 제품에 표시)
  Widget _inlineGenderBtn(String code, String label, String subLabel, {bool autoLength = false}) {
    final r = Responsive.of(context);
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
              SizedBox(height: r.h(4)),
              Text(label,
                  style: TextStyle(
                      fontSize: r.sp(13),
                      fontWeight: FontWeight.w800,
                      color: isSel ? Colors.white : const Color(0xFF333333))),
              if (subLabel.isNotEmpty) ...[
                SizedBox(height: r.h(2)),
                Text(subLabel,
                    style: TextStyle(
                        fontSize: r.sp(11),
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
    final r = Responsive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: r.h(14), horizontal: r.w(20)),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF111111), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.straighten_rounded, color: Colors.white, size: 16),
          SizedBox(width: r.w(8)),
          Text(label,
              style: TextStyle(
                  fontSize: r.sp(15), fontWeight: FontWeight.w800, color: Colors.white)),
          SizedBox(width: r.w(6)),
          Text(desc,
              style: TextStyle(
                  fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.75))),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(3)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(loc.confirmLabel,
                style: TextStyle(color: Colors.white, fontSize: r.sp(10), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── 원단 타입 선택 버튼 (일반원단 / 심리스) ──
  Widget _fabricTypeBtn(String type, String subLabel, IconData icon) {
    final r = Responsive.of(context);
    final sel = _selectedFabricType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFabricType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: r.h(12), horizontal: r.w(10)),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD),
              width: sel ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: sel ? Colors.white : const Color(0xFF555555)),
              SizedBox(height: r.h(6)),
              Text(
                type,
                style: TextStyle(
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w800,
                  color: sel ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: r.h(2)),
              Text(
                subLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.sp(10),
                  color: sel ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF999999),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // 구매 방식 선택 (인라인 섹션)
  // ═══════════════════════════════════════
  Widget _buildPurchaseTypeSection(ProductModel product) {
 final r = Responsive.of(context);

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
    // ignore: unused_local_variable
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
      padding: EdgeInsets.fromLTRB(r.w(16), r.h(8), r.w(16), r.h(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          SizedBox(height: r.h(10)),

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
                      padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(11)),
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
                          SizedBox(width: r.w(8)),
                          Expanded(
                            child: Text(
                              isSingletSet ? '하의 색상 선택 안내' : '기성품 색상 안내',
                              style: TextStyle(
                                fontSize: r.sp(14),
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(3)),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('기성품',
                              style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    // 상의 색상 고정 행
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
                      color: const Color(0xFFFFF3E0),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(r.w(6)),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_rounded, size: 16, color: Color(0xFFE65100)),
                          ),
                          SizedBox(width: r.w(10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('상의 색상 — 변경 불가',
                                  style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w900, color: Color(0xFFBF360C))),
                                SizedBox(height: r.h(2)),
                                Text('디자인 색상 그대로 제작됩니다',
                                  style: TextStyle(fontSize: r.sp(11), color: Color(0xFFBF360C).withValues(alpha: 0.8), height: 1.3)),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: r.w(9), vertical: r.h(4)),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('고정',
                              style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    // 구분선
                    const Divider(height: 1, color: Color(0xFFE0E0E0)),
                    // 하의 색상 선택 가능 행
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
                      color: const Color(0xFFE8F5E9),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(r.w(6)),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E7D32)),
                          ),
                          SizedBox(width: r.w(10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('하의 색상 — 선택 가능',
                                  style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))),
                                SizedBox(height: r.h(2)),
                                Text(
                                  isSingletSet
                                      ? '19가지 색상 중 하의 색상을 선택하세요'
                                      : '19가지 색상 중 자유롭게 선택하세요',
                                  style: TextStyle(fontSize: r.sp(11), color: Color(0xFF1B5E20).withValues(alpha: 0.8), height: 1.3)),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: r.w(9), vertical: r.h(4)),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('선택',
                              style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    // 하단 안내
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(9)),
                      color: const Color(0xFFF5F5F5),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFF888888)),
                          SizedBox(width: r.w(6)),
                          Expanded(
                            child: Text(
                              '하의 색상 선택은 장바구니 / 바로구매 버튼을 눌러 진행하세요',
                              style: TextStyle(fontSize: r.sp(10.5), color: Color(0xFF666666), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: r.h(14)),
          ],

          // ── 싱글렛 A타입세트: 하의 기장 자동적용 안내 배너 ──
          if (isSingletATypeSet) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(10)),
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
                    padding: EdgeInsets.all(r.w(6)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_fix_high_rounded, size: 14, color: Color(0xFF6A1B9A)),
                  ),
                  SizedBox(width: r.w(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.bottomAutoApplyTitle,
                            style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w800, color: Color(0xFF4A148C))),
                        SizedBox(height: r.h(2)),
                        Text(loc.bottomAutoApplyDesc,
                            style: TextStyle(fontSize: r.sp(11), color: Color(0xFF6A1B9A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.h(10)),
          ],

          // ── 트레이닝세트: 9부 고정 안내 배너 ──
          if (showFixedLength9) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(10)),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(r.w(6)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF6A1B9A)),
                  ),
                  SizedBox(width: r.w(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.bottomFixedTitle,
                            style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w800, color: Color(0xFF4A148C))),
                        SizedBox(height: r.h(2)),
                        Text(loc.bottomFixedDesc,
                            style: TextStyle(fontSize: r.sp(11), color: Color(0xFF6A1B9A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.h(10)),
          ],

          if (!product.isGroupOnly) ...[
            Text(loc.purchaseType,
                style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            SizedBox(height: r.h(8)),
          ],

          // ── 기성품 원단 선택 버튼 (일반원단 / 심리스) ──
          if (!product.isGroupOnly) ...[
            SizedBox(height: r.h(4)),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            SizedBox(height: r.h(10)),
            Text('원단 선택',
                style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            SizedBox(height: r.h(8)),
            Row(children: [
              _fabricTypeBtn('일반원단', '기본 기능성 원단', Icons.layers_outlined),
              SizedBox(width: r.w(8)),
              _fabricTypeBtn('심리스', '봉제선 없는 심리스', Icons.auto_awesome_outlined),
            ]),
            SizedBox(height: r.h(10)),
          ],

          // ── 구매방식 버튼: 단체주문 전용 → 단체주문 1개, 기성품 → 기성품 1개 ──
          if (product.isGroupOnly) ...[
            GestureDetector(
              onTap: () => _showGroupOrderGuide(product),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: r.h(12)),
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
                    SizedBox(height: r.h(4)),
                    Text(loc.groupOrderLabel,
                        style: TextStyle(color: Colors.white, fontSize: r.sp(13), fontWeight: FontWeight.w800)),
                    Text(loc.groupOrderSubLabel,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: r.sp(10))),
                  ],
                ),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => _showBuyNowSheet(product),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: r.h(12)),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                    SizedBox(height: r.h(4)),
                    Text(loc.readyMadeLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(13),
                          fontWeight: FontWeight.w800,
                        )),
                    Text(loc.buyNow,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: r.sp(10))),
                  ],
                ),
              ),
            ),
          ],

          // ── 성별 선택 (단체주문 전용 상품 제외) ──
          if (!product.isGroupOnly) ...[
          SizedBox(height: r.h(12)),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          SizedBox(height: r.h(10)),
          Text(loc.gender,
              style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          SizedBox(height: r.h(8)),
          Row(children: [
            _inlineGenderBtn('남', loc.male, isSingletATypeSet ? loc.maleBottomSub : '', autoLength: isSingletATypeSet),
            SizedBox(width: r.w(8)),
            _inlineGenderBtn('여', loc.female, isSingletATypeSet ? loc.femaleBottomSub : '', autoLength: isSingletATypeSet),
          ]),

          // ── 싱글렛 A타입세트: 성별에 따라 하의 길이 1개만 표시 ──
          if (isSingletATypeSet) ...[
            SizedBox(height: r.h(12)),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            SizedBox(height: r.h(10)),
            Text(loc.bottomLengthTitle,
                style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            SizedBox(height: r.h(8)),
            if (_singletGender == '남') ...[
              _singletLengthOnlyBtn(label: '5부', desc: '~55 cm'),
            ] else ...[
              _singletLengthOnlyBtn(label: '2.5부', desc: '~30 cm'),
            ],
          ],

          // ── 타이즈: 하의 길이 선택 (전체 옵션) ──
          if (isTaiz) ...[
            SizedBox(height: r.h(12)),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            SizedBox(height: r.h(10)),
            Text(loc.bottomLengthTitle,
                style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            SizedBox(height: r.h(8)),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: AppConstants.bottomLengths.map((l) {
                final r = Responsive.of(context);

                final label = l['label']!;
                final desc  = l['desc']!;
                final sel   = _selectedBottomLength == label;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBottomLength = label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(10)),
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
                                fontSize: r.sp(13),
                                fontWeight: FontWeight.w800,
                                color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                        SizedBox(height: r.h(2)),
                        Text(desc,
                            style: TextStyle(
                                fontSize: r.sp(10),
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
            SizedBox(height: r.h(12)),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            SizedBox(height: r.h(10)),
            Text(loc.bottomLengthTitle,
                style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            SizedBox(height: r.h(8)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: r.w(18), vertical: r.h(10)),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF111111), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.productShorter9,
                      style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w800, color: Colors.white)),
                  SizedBox(height: r.h(2)),
                  Text(loc.fixedLabel,
                      style: TextStyle(fontSize: r.sp(10), color: Colors.white70)),
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
  // ── 기본 하의길이 참조 이미지 (이미지 미등록 시 fallback) ──
  static const String _defaultMaleLengthImg =
      'https://firebasestorage.googleapis.com/v0/b/fit-mall.firebasestorage.app/o/section_images%2Flength_male_default.jpg?alt=media';
  static const String _defaultFemaleLengthImg =
      'https://firebasestorage.googleapis.com/v0/b/fit-mall.firebasestorage.app/o/section_images%2Flength_female_default.jpg?alt=media';

  Widget _buildGenderLengthImageSection(bool isAdmin) {
    final r = Responsive.of(context);
    // 통합 키 's2_length' 하나로 관리 (남녀 구분 없음)
    final imgs = _sectionImages['s2_length'] ?? [];
    // 기존 남자키 데이터도 폴백으로 사용
    final legacyMale = _sectionImages['s2_length_male'] ?? [];

    // ── 실제 업로드된 이미지 여부 (default fallback 제외)
    final hasUploadedImgs = imgs.isNotEmpty || legacyMale.isNotEmpty;

    final effectiveImgs = imgs.isNotEmpty
        ? imgs
        : (legacyMale.isNotEmpty ? legacyMale : [_defaultMaleLengthImg]);

    // 일반 유저이고 업로드된 이미지가 없으면 섹션 전체 숨김
    if (!isAdmin && !hasUploadedImgs) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin) ...[
          // 관리자: 단일 업로드 섹션
          Container(
            padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(8)),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.photo_library_rounded, size: 14, color: Color(0xFF7B1FA2)),
                SizedBox(width: r.w(6)),
                Text(loc.productLengthRefImg,
                    style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w800, color: Color(0xFF7B1FA2))),
              ],
            ),
          ),
          SizedBox(height: r.h(10)),
          _buildAdminImageSection('s2_length', '하의길이 참조 이미지', isAdmin),
        ] else ...[
          // 일반 유저: 업로드된 이미지 표시
          _buildStaticImageList(effectiveImgs),
        ],
        // ── 하의길이 순서 및 성별 적용 범위 안내 (업로드된 이미지가 있을 때만)
        if (hasUploadedImgs) Container(
          margin: EdgeInsets.fromLTRB(r.w(16), r.h(12), r.w(16), r.h(0)),
          padding: EdgeInsets.fromLTRB(r.w(14), r.h(12), r.w(14), r.h(12)),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 길이 순서 안내
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.straighten_rounded, size: 14, color: Color(0xFF555555)),
                  SizedBox(width: r.w(6)),
                  Text(
                    '왼쪽부터',
                    style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: Color(0xFF555555)),
                  ),
                  SizedBox(width: r.w(8)),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final label in ['9부', '5부', '4부', '3부', '2.5부', '숏사각'])
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(2)),
                            decoration: BoxDecoration(
                              color: label == '숏사각' ? const Color(0xFFFFF3E0) : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: label == '숏사각' ? const Color(0xFFFF8F00) : const Color(0xFFCCCCCC),
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: r.sp(11),
                                fontWeight: FontWeight.w600,
                                color: label == '숏사각' ? const Color(0xFFE65100) : const Color(0xFF333333),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.h(10)),
              const Divider(height: 1, color: Color(0xFFE8E8E8)),
              SizedBox(height: r.h(10)),
              // 숏사각 주머니 불가 안내
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(3)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFF8F00).withValues(alpha: 0.5)),
                    ),
                    child: Text('숏사각', style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w800, color: Color(0xFFE65100))),
                  ),
                  SizedBox(width: r.w(8)),
                  Expanded(
                    child: Text(
                      '주머니 추가 불가',
                      style: TextStyle(fontSize: r.sp(12), color: Color(0xFFE65100), height: 1.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.h(10)),
              const Divider(height: 1, color: Color(0xFFE8E8E8)),
              SizedBox(height: r.h(10)),
              // 남성 적용 범위
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(3)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('남성', style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
                  ),
                  SizedBox(width: r.w(8)),
                  Expanded(
                    child: Text(
                      '9부 · 5부 · 4부 · 3부까지 적용 가능',
                      style: TextStyle(fontSize: r.sp(12), color: Color(0xFF444444), height: 1.5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.h(8)),
              // 여성 적용 범위
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(3)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('여성', style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w800, color: Color(0xFFC62828))),
                  ),
                  SizedBox(width: r.w(8)),
                  Expanded(
                    child: Text(
                      '9부 · 5부 · 4부 · 3부 · 2.5부 · 숏사각까지 적용 가능',
                      style: TextStyle(fontSize: r.sp(12), color: Color(0xFF444444), height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 정적 이미지 리스트 (fallback 포함) ──
  Widget _buildStaticImageList(List<String> imgs) {
    final r = Responsive.of(context);
    if (imgs.isEmpty) return const SizedBox.shrink();
    return Column(
      children: imgs.map((url) => Padding(
        padding: EdgeInsets.only(bottom: r.h(6)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildGenderImageHeader({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(7)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: r.w(6)),
          Text(label,
              style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════

  /// 섹션 이미지 가로 슬라이더 (비로그인/일반 사용자용)
  /// - 이미지 1장: 풀너비 세로 표시, 탭 → 라이트박스
  /// - 이미지 2장+: 가로 PageView 슬라이더 + 하단 pill-dot 인디케이터, 탭 → 라이트박스
  Widget _buildSectionImageSlider(String sectionKey) {
    final imgs = _sectionImages[sectionKey] ?? [];
    if (imgs.isEmpty) return const SizedBox.shrink();

    // 이미지 1장 → 풀너비, 탭으로 라이트박스 오픈
    if (imgs.length == 1) {
      return GestureDetector(
        onTap: () => _openLightbox(imgs, 0),
        child: Image.network(
          imgs.first,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    // 이미지 2장 이상 → 가로 슬라이더 + 인디케이터
    return _SectionImageSliderWidget(
      imgs: imgs,
      onTap: (index) => _openLightbox(imgs, index),
    );
  }

  /// 공통 라이트박스 오픈 (섹션 이미지용)
  void _openLightbox(List<String> imgs, int initialIndex) {
    showImageLightbox(context, imgs, initialIndex: initialIndex);
  }

  // ═══════════════════════════════════════════════════════════

  /// 관리자용 섹션 이미지 표시 + 업로드 버튼
  Widget _buildAdminImageSection(
    String sectionKey,
    String sectionLabel,
    bool isAdmin,
  ) {
    final r = Responsive.of(context);
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
              padding: EdgeInsets.only(top: r.h(6), bottom: r.h(4)),
              child: Row(children: [
                const Icon(Icons.drag_indicator_rounded, size: 14, color: Color(0xFF999999)),
                SizedBox(width: r.w(4)),
                Text(loc.dragToReorder,
                    style: TextStyle(fontSize: r.sp(11), color: Color(0xFF999999))),
              ]),
            ),
            // ReorderableListView — 드래그 순서 변경
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final newList = List<String>.from(imgs);
                final item = newList.removeAt(oldIndex);
                newList.insert(newIndex, item);
                // UI 즉시 반영 (먼저)
                setState(() => _sectionImages[sectionKey] = newList);
                // 백그라운드 저장 (나중에)
                context.read<ProductProvider>().updateSectionImages(
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
                    isAdmin: isAdmin,
                    onTap: () => _openLightbox(imgs, i));
              }).toList(),
            ),
          ] else ...[
            // 일반 사용자: 일반 표시 (탭 → 라이트박스)
            ...imgs.asMap().entries.map((e) {
              final i = e.key;
              final url = e.value;
              return _buildImageItem(
                url: url,
                onTap: () => _openLightbox(imgs, i),
              );
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
    VoidCallback? onTap,
  }) {
    final r = Responsive.of(context);
    return Padding(
      key: key,
      padding: EdgeInsets.only(bottom: r.h(8)),
      child: Stack(
        children: [
          // 이미지
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 드래그 핸들
              Padding(
                padding: EdgeInsets.only(top: r.h(4), right: r.w(6)),
                child: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator_rounded,
                      size: 22, color: Color(0xFFBBBBBB)),
                ),
              ),
              // 이미지 본체 (탭 → 라이트박스)
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
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
              ),
            ],
          ),
          // 삭제 버튼 (관리자)
          if (isAdmin)
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () async {
                  final deletedUrl = imgs[index];
                  final newList = List<String>.from(imgs)..removeAt(index);
                  // UI 즉시 반영 (먼저)
                  setState(() {
                    if (newList.isEmpty) {
                      _sectionImages.remove(sectionKey);
                    } else {
                      _sectionImages[sectionKey] = newList;
                    }
                  });
                  // 백그라운드 저장 (나중에)
                  context.read<ProductProvider>().updateSectionImages(
                      widget.product.id, sectionKey, newList);
                  // Firebase Storage URL이면 Storage에서도 삭제
                  if (deletedUrl.startsWith('https://firebasestorage.googleapis.com') ||
                      deletedUrl.startsWith('https://storage.googleapis.com')) {
                    StorageService.deleteFile(deletedUrl);
                  }
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

  // 일반 이미지 아이템 (비관리자, 탭 → 라이트박스)
  Widget _buildImageItem({required String url, VoidCallback? onTap}) {
    final r = Responsive.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: r.h(8)),
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
    );
  }

  Widget _buildAdminUploadButton(
      String sectionKey, String sectionLabel, List<String> existingImgs) {
    final r = Responsive.of(context);
    return GestureDetector(
      onTap: () => _pickAndUploadImages(sectionKey, sectionLabel, existingImgs),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: r.h(14)),
        margin: EdgeInsets.only(top: r.h(8)),
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
            SizedBox(width: r.w(8)),
            Text(
              existingImgs.isEmpty
                  ? '[관리자] $sectionLabel 이미지 업로드'
                  : '[관리자] $sectionLabel 이미지 추가 (현재 ${existingImgs.length}장)',
              style: TextStyle(
                fontSize: r.sp(13),
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 파일 선택 → Base64 변환 → 자동 저장 ──
  Future<void> _pickAndUploadImages(
      String sectionKey, String sectionLabel, List<String> existingImgs) async {
    final r = Responsive.of(context);

    final picker = ImagePicker();

    // 1) 이미지 선택
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          SizedBox(width: r.w(20), height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: r.w(12)),
          Text(loc.fileSelecting),
        ]),
        duration: const Duration(seconds: 60),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );

    List<XFile> pickedFiles = [];
    try {
      pickedFiles = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (pickedFiles.isEmpty) return;

    // 2) 업로드 중 스낵바
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          SizedBox(width: r.w(20), height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: r.w(12)),
          Text('${pickedFiles.length}장 업로드 중... (잠시 기다려 주세요)'),
        ]),
        duration: const Duration(seconds: 120),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );

    try {
      final r = Responsive.of(context);

      // 3) Firebase Storage 업로드 → 다운로드 URL 획득
      final productId = widget.product.id;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final newUrls = <String>[];

      for (int i = 0; i < pickedFiles.length; i++) {
        final file = pickedFiles[i];
        try {
          final bytes = await file.readAsBytes();
          final ext = file.name.toLowerCase().split('.').last;
          final fileName = '${ts}_$i.$ext';
          final url = await StorageService.uploadSectionImage(
            productId: productId,
            sectionKey: sectionKey,
            bytes: bytes,
            fileName: fileName,
          );
          if (url.isNotEmpty) newUrls.add(url);
        } catch (_) { /* 개별 파일 실패 시 스킵 */ }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (newUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('업로드 실패: Firebase Storage 저장에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 4) 기존 이미지(URL)에 새 URL 추가
      // _sectionImages에서 최신값 참조 (함수 호출 시점 스냅샷 대신 현재 상태 사용)
      final currentImgs = _sectionImages[sectionKey] ?? [];
      final finalUrls = [...currentImgs, ...newUrls];

      // 5) Firestore 저장 중 스낵바
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            SizedBox(width: r.w(20), height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: r.w(12)),
            Text('$sectionLabel Firestore 저장 중...'),
          ]),
          duration: const Duration(seconds: 30),
          backgroundColor: const Color(0xFF1A1A2E),
        ),
      );

      // 6) Firestore 자동 저장
      final ok = await context.read<ProductProvider>()
          .updateSectionImages(productId, sectionKey, finalUrls);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firestore 저장 실패. 잠시 후 다시 시도해 주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 7) UI 즉시 반영
      setState(() => _sectionImages[sectionKey] = List<String>.from(finalUrls));

      // 8) 완료 스낵바
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: r.w(10)),
            Text('$sectionLabel 이미지 ${newUrls.length}장 저장 완료'),
          ]),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── 선택된 이미지 미리보기 + 최종 저장 다이얼로그 (레거시 - 더 이상 사용 안함) ──
  void _showPickedImagesPreview(
    String sectionKey,
    String sectionLabel,
    List<String> existingImgs,
    List<XFile> pickedFiles,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PickedImagesSheet(
        productId: widget.product.id,
        sectionKey: sectionKey,
        sectionLabel: sectionLabel,
        existingImgs: existingImgs,
        pickedFiles: pickedFiles,
        onSave: (finalUrls) async {
          await context.read<ProductProvider>().updateSectionImages(
              widget.product.id, sectionKey, finalUrls);
          if (!mounted) return;
          setState(() {
            if (finalUrls.isEmpty) {
              _sectionImages.remove(sectionKey);
            } else {
              _sectionImages[sectionKey] = finalUrls;
            }
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$sectionLabel 이미지 ${finalUrls.length}장이 저장되었습니다'),
              backgroundColor: const Color(0xFF1A1A2E),
            ),
          );
        },
        onDeleteAll: () async {
          await context.read<ProductProvider>().updateSectionImages(
              widget.product.id, sectionKey, []);
          if (!mounted) return;
          setState(() => _sectionImages.remove(sectionKey));
          if (!mounted) return;
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
    final r = Responsive.of(context);
    final imgs = _sectionImages['design'] ?? [];
    // 이미지가 없고 관리자도 아니면 숨김
    if (!isAdmin && imgs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 헤더 행 (라벨 + AI 배지 + 관리자 업로드 버튼) ──
        Row(
          children: [
            Container(
              width: 3, height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF4A148C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: r.w(8)),
            Text(
              '디자인 이미지',
              style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A), letterSpacing: -0.2),
            ),
            if (isAdmin) ...[
              SizedBox(width: r.w(8)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: r.w(6), vertical: r.h(2)),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A148C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('관리자', style: TextStyle(fontSize: r.sp(9), color: Color(0xFF4A148C), fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              // 업로드 버튼
              GestureDetector(
                onTap: () => _pickAndUploadImages('design', '디자인 이미지', imgs),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(5)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A148C),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 14),
                      SizedBox(width: r.w(4)),
                      Text(
                        imgs.isEmpty ? '이미지 업로드' : '이미지 추가 (${imgs.length}장)',
                        style: TextStyle(color: Colors.white, fontSize: r.sp(11), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: r.h(10)),

        // ── 이미지가 있을 때: 가로 스크롤 썸네일 ──
        if (imgs.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imgs.length,
              separatorBuilder: (_, __) => SizedBox(width: r.w(8)),
              itemBuilder: (_, i) {
                final r = Responsive.of(context);

                return GestureDetector(
                  onTap: () => _showDesignLightbox(imgs, i),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imgs[i].startsWith('data:image')
                            ? Image.memory(
                                base64Decode(imgs[i].split(',').last),
                                width: 100, height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100, height: 100,
                                  color: const Color(0xFFEEEEEE),
                                  child: const Icon(Icons.broken_image_outlined, color: Color(0xFFAAAAAA)),
                                ),
                              )
                            : Image.network(
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
                          padding: EdgeInsets.all(r.w(3)),
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
                              final deletedUrl = imgs[i];
                              final newList = List<String>.from(imgs)..removeAt(i);
                              // UI 즉시 반영 (먼저)
                              setState(() {
                                if (newList.isEmpty) {
                                  _sectionImages.remove('design');
                                } else {
                                  _sectionImages['design'] = newList;
                                }
                              });
                              // 백그라운드 저장 (나중에)
                              context.read<ProductProvider>()
                                  .updateSectionImages(product.id, 'design', newList);
                              if (deletedUrl.startsWith('https://firebasestorage.googleapis.com') ||
                                  deletedUrl.startsWith('https://storage.googleapis.com')) {
                                StorageService.deleteFile(deletedUrl);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(r.w(3)),
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
            padding: EdgeInsets.symmetric(vertical: r.h(16)),
            decoration: BoxDecoration(
              color: const Color(0xFF4A148C).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF4A148C).withValues(alpha: 0.2),
                  style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.image_outlined, size: 28, color: Color(0xFF9E9E9E)),
                SizedBox(height: r.h(6)),
                Text('디자인 이미지를 업로드하세요',
                    style: TextStyle(fontSize: r.sp(12), color: Color(0xFF9E9E9E))),
              ],
            ),
          ),

        SizedBox(height: r.h(14)),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        SizedBox(height: r.h(14)),
      ],
    );
  }

  /// 디자인이미지 전용 라이트박스
  void _showDesignLightbox(List<String> imgs, int initialIndex) {
    showImageLightbox(context, imgs, initialIndex: initialIndex);
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 1: PERFORMANCE — 탑텐 스타일 모노크롬 특징 리스트
  // ═══════════════════════════════════════════════════════════
  // ── 골지 타이즈 소재 행 반환 (나일론 75% / 라이크라 25%) ──
  List<String>? _getGoljiTaizFiberRow() {
    switch (loc.language) {
      case AppLanguage.english:
        return ['Golgi Tights (Bottom)', 'Nylon 75%', 'Lycra 25%'];
      case AppLanguage.japanese:
        return ['ゴルジタイツ (下)', 'ナイロン 75%', 'ライクラ 25%'];
      case AppLanguage.chinese:
        return ['罗纹紧身裤 (下衣)', '尼龙 75%', '莱卡 25%'];
      case AppLanguage.mongolian:
        return ['Голжи хачиг (Доод)', 'Нейлон 75%', 'Лайкра 25%'];
      default:
        return ['골지 타이즈 (하의)', '나일론 75%', '라이크라 25%'];
    }
  }

  // ── 싱글렛 상의 소재 행 반환 (폴리에스터 92% / 라이크라 8%) ──
  List<String>? _getSingletTopFiberRow() {
    // 언어별로 싱글렛 상의 소재 행 반환
    switch (loc.language) {
      case AppLanguage.english:
        return ['Singlet (Top)', 'Polyester 92%', 'Lycra 8%'];
      case AppLanguage.japanese:
        return ['シングレット (上)', 'ポリエステル 92%', 'ライクラ 8%'];
      case AppLanguage.chinese:
        return ['背心 (上衣)', '聚酯纤维 92%', '莱卡 8%'];
      case AppLanguage.mongolian:
        return ['Сингэлет (Дээд)', 'Полиэстер 92%', 'Лайкра 8%'];
      default:
        return ['싱글렛 상의', '폴리에스터 92%', '라이크라 8%'];
    }
  }

  // ── 공통: 섹션 헤더 배너 (검정 배경 + 영문 대제목 + 한글 서브) ──
  Widget _sectionHeaderBanner({
    required String engTitle,
    required String engSub,
    required String korSub,
    Color bgColor = const Color(0xFF1A1A1A),
    Color textColor = Colors.white,
    Widget? trailingIcon,
  }) {
    final r = Responsive.of(context);
    return Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.fromLTRB(r.w(20), r.h(22), r.w(20), r.h(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 영문 대제목
                Text(
                  engTitle,
                  style: TextStyle(
                    fontSize: r.sp(26),
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: r.h(6)),
                // 한글 설명
                Text(
                  korSub,
                  style: TextStyle(
                    fontSize: r.sp(11),
                    color: textColor.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailingIcon != null) trailingIcon,
        ],
      ),
    );
  }

  Widget _buildSection1Banner(ProductModel product, bool isAdmin) {
    final r = Responsive.of(context);
    final features = [
      {'tag': 'ULTRA LIGHT',      'title': loc.feat1Title, 'desc': loc.feat1Desc},
      {'tag': 'SEAMLESS',         'title': loc.feat2Title, 'desc': loc.feat2Desc},
      {'tag': 'ELITE WEAR',       'title': loc.feat4Title, 'desc': loc.feat4Desc},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 섹션1 헤더 배너
        _sectionHeaderBanner(
          engTitle: 'PERFORMANCE',
          engSub: 'SECTION 01',
          korSub: '고성능 스포츠 소재와 기술이 만든\n최상위 퍼포먼스 웨어',
          trailingIcon: const Icon(Icons.bolt_rounded, size: 36, color: Color(0x55FFFFFF)),
        ),
        const Divider(height: 8, thickness: 8, color: Color(0xFFF5F5F5)),
        // ── 섹션1 어드민 이미지 (관리자: 업로드 UI / 일반: 가로 슬라이더)
        if (isAdmin || (_sectionImages['s1'] ?? []).isNotEmpty)
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(r.w(0), isAdmin ? 12 : 0, r.w(0), r.h(0)),
            child: isAdmin
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.w(16)),
                    child: _buildAdminImageSection('s1', '섹션1 메인 배너', isAdmin),
                  )
                : _buildSectionImageSlider('s1'),
          ),
        // ── 특징 리스트 제거됨 (ULTRA LIGHT / SEAMLESS / ELITE WEAR)
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 2: MATERIAL — 탑텐 스타일 소재/기술
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection2Material(ProductModel product, bool isAdmin) {
    final r = Responsive.of(context);
    final techRows = [
      {'label': 'SEAMLESS', 'desc': loc.feat2Title, 'sub': loc.feat2Desc},
      {'label': 'FAST DRY',  'desc': loc.techDryTitle,  'sub': loc.techDryDesc},
      {'label': 'MOISTURE',  'desc': loc.techAbsorbTitle,'sub': loc.techAbsorbDesc},
    ];

    final generalImgs  = _sectionImages['s2_general']  ?? [];
    final seamlessImgs = _sectionImages['s2_seamless'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 섹션2 헤더 배너
        _sectionHeaderBanner(
          engTitle: 'MATERIAL',
          engSub: 'SECTION 02',
          korSub: '고급 원단과 기능성 소재로 완성한\n쾌적하고 지속 가능한 착용감',
          bgColor: const Color(0xFF212121),
          trailingIcon: const Icon(Icons.layers_rounded, size: 36, color: Color(0x55FFFFFF)),
        ),
        const Divider(height: 8, thickness: 8, color: Color(0xFFF5F5F5)),

        // ── 일반봉제 / 심리스 이미지 섹션 ──────────────────────────
        // 하의 카테고리일 때는 숨김
        // 관리자: 두 슬롯 각각 업로드 버튼 표시
        // 일반 사용자: 이미지가 하나라도 있으면 탭 UI로 표시
        if (product.category != '하의') ...[
          if (isAdmin)
            _buildSection2FabricAdmin(generalImgs, seamlessImgs, isAdmin)
          else if (generalImgs.isNotEmpty || seamlessImgs.isNotEmpty)
            _buildSection2FabricTabs(generalImgs, seamlessImgs),

          // ── 일반봉제/심리스 이미지 아래 추가 이미지 (관리자: 업로드 UI / 일반: 가로 슬라이더)
          if (isAdmin || (_sectionImages['s2_fabric_extra'] ?? []).isNotEmpty)
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(r.w(0), isAdmin ? 12 : 0, r.w(0), r.h(0)),
              child: isAdmin
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: r.w(16)),
                      child: _buildAdminImageSection('s2_fabric_extra', '원단 추가 이미지', isAdmin),
                    )
                  : _buildSectionImageSlider('s2_fabric_extra'),
            ),
        ],

        // ── 기술 특징 리스트 (SEAMLESS / FAST DRY / MOISTURE)
        // 하의 카테고리: SEAMLESS 숨김, FAST DRY / MOISTURE 표시
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(r.w(20), r.h(8), r.w(20), r.h(0)),
          child: Column(
            children: techRows
                .where((t) => product.category != '하의' || t['label'] != 'SEAMLESS')
                .toList()
                .asMap().entries.map((entry) {
                final r = Responsive.of(context);

                final i = entry.key;
                final t = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i > 0) const Divider(height: 1, color: Color(0xFFE8E8E8)),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: r.h(18)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text('0${i + 1}',
                              style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w900,
                                  color: Color(0xFFCCCCCC), letterSpacing: 1)),
                          ),
                          SizedBox(width: r.w(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(3)),
                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF555555))),
                                  child: Text(t['label']!,
                                    style: TextStyle(fontSize: r.sp(9), fontWeight: FontWeight.w800,
                                        color: Color(0xFF555555), letterSpacing: 1.2)),
                                ),
                                SizedBox(height: r.h(8)),
                                Text(t['desc']!,
                                  style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A1A), height: 1.3)),
                                SizedBox(height: r.h(5)),
                                Text(t['sub']!,
                                  style: TextStyle(fontSize: r.sp(12), color: Color(0xFF777777),
                                      height: 1.6, fontWeight: FontWeight.w400)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

        // ── 하의길이 참조 이미지 (하의/싱글렛세트만)
        if (_isBottomOrSingletSetProduct(product)) ...[
          _buildGenderLengthImageSection(isAdmin),
        ],

        // ── 소재혼용율 위 이미지 (관리자: 업로드 UI / 일반: 가로 슬라이더)
        if (isAdmin || (_sectionImages['s2_fiber'] ?? []).isNotEmpty)
          isAdmin
              ? Padding(
                  padding: EdgeInsets.fromLTRB(r.w(16), r.h(0), r.w(16), r.h(0)),
                  child: _buildAdminImageSection('s2_fiber', '소재혼용율 이미지', isAdmin),
                )
              : _buildSectionImageSlider('s2_fiber'),


      ],
    );
  }

  // ── 섹션2 관리자: 일반봉제 / 심리스 업로드 버튼 (세로 2칸) ──
  Widget _buildSection2FabricAdmin(
    List<String> generalImgs,
    List<String> seamlessImgs,
    bool isAdmin,
  ) {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(r.w(16), r.h(12), r.w(16), r.h(0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 일반봉제 슬롯
          _buildFabricAdminSlot(
            key: 's2_general',
            label: '일반봉제',
            icon: Icons.straighten_rounded,
            color: const Color(0xFF1565C0),
            bgColor: const Color(0xFFE3F2FD),
            imgs: generalImgs,
            isAdmin: isAdmin,
          ),
          SizedBox(height: r.h(16)),
          // 심리스 슬롯
          _buildFabricAdminSlot(
            key: 's2_seamless',
            label: '심리스',
            icon: Icons.blur_circular_rounded,
            color: const Color(0xFF6A1B9A),
            bgColor: const Color(0xFFF3E5F5),
            imgs: seamlessImgs,
            isAdmin: isAdmin,
          ),
        ],
      ),
    );
  }

  // ── 관리자 패브릭 슬롯 (헤더 뱃지 + 업로드 버튼 + 이미지 목록) ──
  Widget _buildFabricAdminSlot({
    required String key,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required List<String> imgs,
    required bool isAdmin,
  }) {
    final r = Responsive.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 슬롯 헤더 뱃지
        Container(
          padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(7)),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              SizedBox(width: r.w(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: r.sp(12),
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              SizedBox(width: r.w(6)),
              Text(
                '이미지 ${imgs.length}장',
                style: TextStyle(
                  fontSize: r.sp(11),
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: r.h(8)),
        // 업로드 버튼 + 이미지 목록
        _buildAdminImageSection(key, '$label 이미지', isAdmin),
      ],
    );
  }

  // ── 섹션2 일반 사용자: 일반봉제 / 심리스 탭 전환 UI ──
  Widget _buildSection2FabricTabs(
    List<String> generalImgs,
    List<String> seamlessImgs,
  ) {
    return _Section2FabricTabsWidget(
      generalImgs: generalImgs,
      seamlessImgs: seamlessImgs,
      onTapGeneral: (imgs, i) => _openLightbox(imgs, i),
      onTapSeamless: (imgs, i) => _openLightbox(imgs, i),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 포켓시스템 표시 여부: 하의 카테고리 중 타이즈·5부·2.5부만 표시
  // (숏츠·단체주문 상의·세트 등 나머지는 숨김)
  // ═══════════════════════════════════════════════════════════
  bool _showPocketSection(ProductModel product) {
    final cat  = product.category;
    final sub  = product.subCategory;
    final name = product.name;
    // 단체주문은 항상 표시
    if (product.isGroupOnly) return true;
    // 하의 카테고리이면서 타이즈·5부·2.5부 포함 시만 표시
    if (cat == '하의') {
      return sub.contains('타이즈') || name.contains('타이즈') ||
             sub.contains('5부')    || name.contains('5부')    ||
             sub.contains('2.5부')  || name.contains('2.5부');
    }
    // 상의·세트 등 나머지는 숨김
    return false;
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 3: POCKET SYSTEM — 탑텐 스타일 기능 리스트
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection3Pocket(ProductModel product, bool isAdmin) {
    final r = Responsive.of(context);
    final pockets = [
      {'tag': 'BACK POCKET',    'title': loc.pocketTile1Title, 'desc': loc.pocketTile1Desc},
      {'tag': 'PHONE FIT',      'title': loc.pocketTile3Title, 'desc': loc.pocketTile3Desc},
      {'tag': 'WATER RESIST',   'title': loc.pocketTile4Title, 'desc': loc.pocketTile4Desc},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 섹션3 헤더 배너
        _sectionHeaderBanner(
          engTitle: 'POCKET\nSYSTEM',
          engSub: 'SECTION 03',
          korSub: '실용적인 수납 설계와 방수 기능으로\n운동 중에도 완벽한 편의성',
          bgColor: const Color(0xFF1C2B3A),
          trailingIcon: const Icon(Icons.inventory_2_rounded, size: 36, color: Color(0x55FFFFFF)),
        ),
        const Divider(height: 8, thickness: 8, color: Color(0xFFF5F5F5)),
        // ── 섹션3 어드민 이미지 (관리자: 업로드 UI / 일반: 가로 슬라이더)
        if (isAdmin || (_sectionImages['s3'] ?? []).isNotEmpty)
          isAdmin
              ? Padding(
                  padding: EdgeInsets.fromLTRB(r.w(16), r.h(12), r.w(16), r.h(0)),
                  child: _buildAdminImageSection('s3', '섹션3 포켓 특성', isAdmin),
                )
              : _buildSectionImageSlider('s3'),


        // ── 포켓 기능 리스트
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(r.w(20), r.h(8), r.w(20), r.h(32)),
          child: Column(
            children: pockets.asMap().entries.map((entry) {
              final r = Responsive.of(context);

              final i = entry.key;
              final p = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: r.h(18)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text('0${i + 1}',
                            style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w900,
                                color: Color(0xFFCCCCCC), letterSpacing: 1)),
                        ),
                        SizedBox(width: r.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: r.w(7), vertical: r.h(3)),
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1A1A1A))),
                                child: Text(p['tag']!,
                                  style: TextStyle(fontSize: r.sp(9), fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A1A), letterSpacing: 1.2)),
                              ),
                              SizedBox(height: r.h(8)),
                              Text(p['title']!,
                                style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A), height: 1.3)),
                              SizedBox(height: r.h(5)),
                              Text(p['desc']!,
                                style: TextStyle(fontSize: r.sp(12), color: Color(0xFF777777),
                                    height: 1.6, fontWeight: FontWeight.w400)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ※ _buildPocketFeatureTile 제거됨 (탑텐 스타일 인라인으로 교체)

  // ─── 제거됨: 섹션4 COLOR LINE (색상 선택 영역에 통합) ───
  // ─── 제거됨: 섹션5 (미사용 번호) ───
  Widget _buildSection5GoljiColors(ProductModel product, bool isAdmin) {
    return const SizedBox.shrink();
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 4: SIZE CHART (성인 / 주니어 탭) — 실 표시 번호 04
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection6SizeChart(ProductModel product, [bool isAdmin = false]) {
    final r = Responsive.of(context);
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
            color: const Color(0xFFF5F5F5),
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(12), r.w(16), r.h(0)),
            child: _buildAdminImageSection('s6', '섹션6 사이즈 차트', isAdmin),
          ),

        // ── 메인 사이즈 차트 컨테이너 ──
        Container(
          color: const Color(0xFFF5F5F5),
          padding: EdgeInsets.fromLTRB(r.w(20), r.h(28), r.w(20), r.h(32)),
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
                      // 메인 타이틀
                      Text(
                        'SIZE\nCHART',
                        style: TextStyle(
                          fontSize: r.sp(32),
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
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
                        padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(5)),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black.withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '2FiT KOREA',
                          style: TextStyle(
                            fontSize: r.sp(10),
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                            letterSpacing: 2,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      SizedBox(height: r.h(6)),
                      Text(
                        '투핏 사이즈 조건표 기준',
                        style: TextStyle(
                          fontSize: r.sp(10),
                          color: Colors.black.withValues(alpha: 0.45),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 구분선
              Padding(
                padding: EdgeInsets.symmetric(vertical: r.h(20)),
                child: Container(height: 1, color: Colors.black.withValues(alpha: 0.1)),
              ),

              // ── 탭 + 테이블 ──
              _SizeChartTabs(
                adultHeaders: adultHeaders,
                adultRows: adultRows,
                juniorHeaders: juniorHeaders,
                juniorRows: juniorRows,
                loc: loc,
              ),

              SizedBox(height: r.h(24)),

              // ── 안내 문구 ──
              Container(
                padding: EdgeInsets.all(r.w(16)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.black.withValues(alpha: 0.4)),
                        SizedBox(width: r.w(6)),
                        Expanded(
                          child: Text(
                            loc.sizeChartDesc1,
                            style: TextStyle(
                              fontSize: r.sp(11),
                              color: Colors.black.withValues(alpha: 0.55),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.h(6)),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.black.withValues(alpha: 0.4)),
                        SizedBox(width: r.w(6)),
                        Expanded(
                          child: Text(
                            loc.sizeChartDesc2,
                            style: TextStyle(
                              fontSize: r.sp(11),
                              color: Colors.black.withValues(alpha: 0.55),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.h(6)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.black.withValues(alpha: 0.4)),
                        SizedBox(width: r.w(6)),
                        Expanded(
                          child: Text(
                            '제품 이미지와 색상은 모니터의 상태에 따라 다소 다르게 보일 수 있습니다.',
                            style: TextStyle(fontSize: r.sp(11), color: Color(0xFF888888), height: 1.5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.h(6)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.black.withValues(alpha: 0.4)),
                        SizedBox(width: r.w(6)),
                        Expanded(
                          child: Text(
                            '측정 위치에 따라 1~2cm 정도의 오차가 발생할 수 있습니다.',
                            style: TextStyle(fontSize: r.sp(11), color: Color(0xFF888888), height: 1.5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.h(6)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.black.withValues(alpha: 0.4)),
                        SizedBox(width: r.w(6)),
                        Expanded(
                          child: Text(
                            '제품 생산 시기 및 생산지에 따라서 동일 상품 간 컬러 및 혼용률 차이가 발생할 수 있습니다.',
                            style: TextStyle(fontSize: r.sp(11), color: Color(0xFF888888), height: 1.5),
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
            color: const Color(0xFFF5F5F5),
            padding: EdgeInsets.fromLTRB(r.w(20), r.h(0), r.w(20), r.h(20)),
            child: _buildAdminImageSection('s6', '섹션6 사이즈 차트', isAdmin),
          ),

        // ── WASH TIP 헤더만 ──
        Container(
          width: double.infinity,
          color: const Color(0xFF1A1A1A),
          padding: EdgeInsets.fromLTRB(r.w(20), r.h(22), r.w(20), r.h(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WASH TIP',
                style: TextStyle(
                  fontSize: r.sp(26),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              SizedBox(height: r.h(6)),
              Text(
                '올바른 세탁으로 제품을 오래, 깨끗하게',
                style: TextStyle(
                  fontSize: r.sp(11),
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                  height: 1.5,
                ),
              ),
            ],
          ),
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
        final r = Responsive.of(context);

        final reviews = reviewProv.getProductReviews(product.id);
        final avg = reviewProv.getProductRating(product.id);

        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: r.h(20), horizontal: r.w(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              SizedBox(height: r.h(28)),
              Row(
                children: [
                  Text(loc.productReviewLabel,
                      style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.w800)),
                  SizedBox(width: r.w(8)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(3)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        '${reviews.length}',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: r.sp(12),
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              if (avg > 0) ...[
                SizedBox(height: r.h(14)),
                Row(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: r.sp(40),
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A)),
                    ),
                    SizedBox(width: r.w(12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                              5,
                              (i) => Icon(Icons.star_rounded,
                                  size: 20,
                                  color: i < avg.floor()
                                      ? const Color(0xFFFFD600)
                                      : const Color(0xFFE0E0E0))),
                        ),
                        SizedBox(height: r.h(4)),
                        Text(
                            '${reviews.length}개 리뷰',
                            style: TextStyle(
                                fontSize: r.sp(12), color: Color(0xFF888888))),
                      ],
                    ),
                  ],
                ),
              ],
              SizedBox(height: r.h(20)),
              SizedBox(height: r.h(4)),
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
                    padding: EdgeInsets.symmetric(vertical: r.h(14)),
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

  // 예시 리뷰 제거됨 - 실제 회원 리뷰만 표시

  Widget _reviewChip(String text) => Container(
        padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(3)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Text(text,
            style: TextStyle(fontSize: r.sp(10), color: Color(0xFF888888))),
      );

  // ═══════════════════════════════════════════════════════════
  // 하단 바 (탑텐 스타일)
  // ═══════════════════════════════════════════════════════════
  Widget _buildBottomBar(ProductModel product) {
    final r = Responsive.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(r.w(16), r.h(10), r.w(16), r.h(10)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.isGroupOnly) ...[
                // ── 단체주문 전용 ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                    label: Text(loc.groupOrderBtn,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: r.sp(16), color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A148C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => _showGroupOrderGuide(product),
                  ),
                ),
              ] else if (product.stockCount <= 0) ...[
                // ── 품절 상태 ──
                Consumer<UserProvider>(
                  builder: (_, up, __) {
                    final r = Responsive.of(context);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: r.h(9)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_shopping_cart_outlined, size: 15, color: Color(0xFFAAAAAA)),
                              SizedBox(width: r.w(6)),
                              Text('현재 품절된 상품입니다', style: TextStyle(fontSize: r.sp(13), color: Color(0xFFAAAAAA), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        SizedBox(height: r.h(8)),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.notifications_active_rounded, size: 17, color: Colors.white),
                            label: Text('재입고 알림 신청', style: TextStyle(fontWeight: FontWeight.w800, fontSize: r.sp(14), color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: () => _showRestockAlert(product, up),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                // ── 탑텐 스타일: 찜(하트+숫자) + 구매하기 풀버튼 ──
                Row(
                  children: [
                    // 찜 버튼 (탑텐: 하트 + 숫자 세로 배치, 좌측 독립)
                    Consumer<UserProvider>(
                      builder: (_, up, __) {
                        final r = Responsive.of(context);

                        final isWish = up.isInWishlist(product.id);
                        final wishCount = up.user?.wishlist.length ?? 0;
                        return GestureDetector(
                          onTap: () {
                            if (up.isLoggedIn) {
                              up.toggleWishlist(product.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.loginRequired)),
                              );
                            }
                          },
                          child: SizedBox(
                            width: 48,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isWish ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isWish ? Colors.redAccent : const Color(0xFF888888),
                                  size: 26,
                                ),
                                SizedBox(height: r.h(1)),
                                Text(
                                  wishCount.toString(),
                                  style: TextStyle(fontSize: r.sp(11), color: Color(0xFF888888), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: r.w(8)),
                    // 장바구니 버튼
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF1A1A1A)),
                          label: Text(
                            '장바구니',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: r.sp(14), color: Color(0xFF1A1A1A)),
                          ),
                          onPressed: () => _addToCart(product),
                        ),
                      ),
                    ),
                    SizedBox(width: r.w(8)),
                    // 바로구매 버튼
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          onPressed: () => _showBuyNowSheet(product),
                          child: Text(
                            '바로구매',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: r.sp(16), color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── 포켓 인포 박스 ───────────────────────────────────────────
  // ignore: unused_element
  Widget _pocketInfoBox(String label, String value) {
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.all(r.w(12)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: r.sp(10),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: r.h(5)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: r.sp(12),
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
  /// + isGroupOnly(단체전용) / isReadyMade(기성품) 상품도 항상 표시
  bool _showGroupOrderBtn(ProductModel p) {
    // 단체전용 or 기성품이면 무조건 표시
    if (p.isGroupOnly || p.isReadyMade) return true;

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
    final r = Responsive.of(context);

    final isSingletProduct = product.name.contains('싱글렛');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
        padding: EdgeInsets.fromLTRB(r.w(20), r.h(20), r.w(20), MediaQuery.of(context).padding.bottom + 24),
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
            SizedBox(height: r.h(20)),
            Text(loc.purchaseTypeTitle, style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
            SizedBox(height: r.h(6)),
            Text(loc.purchaseTypeSubtitle, style: TextStyle(fontSize: r.sp(13), color: Color(0xFF888888))),

            // ── 싱글렛 전용: 성별·타입 선택 ──
            if (isSingletProduct) ...[
              SizedBox(height: r.h(20)),
              Container(
                padding: EdgeInsets.all(r.w(16)),
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
                        SizedBox(width: r.w(6)),
                        Text(loc.singletOptionLabel, style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w800, color: Color(0xFF6A1B9A))),
                      ],
                    ),
                    SizedBox(height: r.h(14)),
                    // 성별 선택
                    Text(context.watch<LanguageProvider>().loc.gender, style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                    SizedBox(height: r.h(8)),
                    Row(
                      children: ['남성', '여성'].map((g) {
                        final r = Responsive.of(context);

                        final isSelected = _singletGender == (g == '남성' ? '남' : '여');
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() {
                              setState(() => _singletGender = g == '남성' ? '남' : '여');
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: EdgeInsets.only(right: r.w(8)),
                              padding: EdgeInsets.symmetric(vertical: r.h(10)),
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
                                  SizedBox(width: r.w(6)),
                                  Text(
                                    g,
                                    style: TextStyle(
                                      fontSize: r.sp(13), fontWeight: FontWeight.w700,
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
                    SizedBox(height: r.h(14)),
                    // 타입 선택
                    Text(loc.styleTypeLabel, style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                    SizedBox(height: r.h(8)),
                    // A타입(레이서백) 카드 제거 → B타입(스쿱넥)만 표시
                    Row(
                      children: [
                        {'type': 'B', 'label': loc.singletTypeB, 'desc': loc.singletTypeBDesc},
                      ].map((t) {
                        final r = Responsive.of(context);

                        final isSelected = _singletType == t['type'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() {
                              setState(() => _singletType = t['type']!);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: EdgeInsets.only(right: r.w(8)),
                              padding: EdgeInsets.symmetric(vertical: r.h(10), horizontal: r.w(12)),
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
                                      fontSize: r.sp(13), fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : const Color(0xFF333333),
                                    ),
                                  ),
                                  Text(
                                    t['desc']!,
                                    style: TextStyle(
                                      fontSize: r.sp(11), fontWeight: FontWeight.w500,
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

            SizedBox(height: r.h(20)),
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
              SizedBox(height: r.h(12)),
              // 기성품 + 단체전용 모두 선택된 경우 → 두 버튼 따로 표시
              if (product.isReadyMade && product.isGroupOnly) ...[
                _orderTypeBtn(
                  emoji: '📦',
                  title: '기성품 단체주문',
                  description: '기성 디자인 그대로 단체 수량으로 주문',
                  tags: ['기성품', '빠른납기'],
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    _showGroupOrderGuide(product);
                  },
                ),
                SizedBox(height: r.h(10)),
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
              ] else
                _orderTypeBtn(
                  emoji: product.isReadyMade ? '📦' : '👥',
                  title: product.isReadyMade ? '기성품 단체주문' : loc.orderTypeGroupCustomTitle,
                  description: product.isReadyMade
                      ? '기성 디자인 그대로 단체 수량으로 주문'
                      : loc.orderTypeGroupCustomDesc,
                  tags: product.isReadyMade
                      ? ['기성품', '빠른납기']
                      : [loc.orderTypeGroupCustomTag1, loc.orderTypeGroupCustomTag2],
                  color: product.isReadyMade ? Colors.teal : const Color(0xFFE53935),
                  onTap: () {
                    Navigator.pop(context);
                    _showGroupOrderGuide(product);
                  },
                ),
            ],
            SizedBox(height: r.h(8)),
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
    final r = Responsive.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.w(16)),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: r.sp(28))),
            SizedBox(width: r.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.w800, color: color)),
                  SizedBox(height: r.h(3)),
                  Text(description, style: TextStyle(fontSize: r.sp(12), color: Color(0xFF888888))),
                  SizedBox(height: r.h(6)),
                  Wrap(
                    spacing: 6,
                    children: tags.map((t) => Container(
                      padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(2)),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(t, style: TextStyle(fontSize: r.sp(11), color: color, fontWeight: FontWeight.w600)),
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

  // ─── 재입고 알림 신청 ───────────────────────────────────────────
  void _showRestockAlert(ProductModel product, UserProvider up) async {
    if (!up.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.loginRequired)),
      );
      return;
    }
    final user = up.user!;
    final email = user.email.isNotEmpty ? user.email : '';

    // Firestore에 재입고 알림 등록
    try {
      final r = Responsive.of(context);

      final db = FirebaseFirestore.instance;
      final docId = '${product.id}_${user.id}';
      await db.collection('restock_alerts').doc(docId).set({
        'productId': product.id,
        'productName': product.name,
        'userId': user.id,
        'userName': user.name,
        'userEmail': email,
        'requestedAt': FieldValue.serverTimestamp(),
        'isNotified': false,
      });
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.notifications_active_rounded, color: Color(0xFF1565C0), size: 22),
            SizedBox(width: r.w(8)),
            Text('재입고 알림 신청 완료', style: TextStyle(fontSize: r.sp(16), fontWeight: FontWeight.w800)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${product.name}', style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              SizedBox(height: r.h(8)),
              Text('재입고 시 ${email.isNotEmpty ? email : '등록된 연락처'}로 알림을 보내드립니다.',
                style: TextStyle(fontSize: r.sp(13), color: Color(0xFF555555), height: 1.5)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신청 실패: $e'), backgroundColor: Colors.red),
      );
    }
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

  // ignore: unused_element
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
  // ignore: unused_element
  void _doAddToCart(
    ProductModel product,
    String size,
    String color,
    String? bottomLength,
    int qty,
  ) {
    final r = Responsive.of(context);

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
            SizedBox(width: r.w(8)),
            Expanded(
              child: Text(
                loc.addedToCartMsg(bottomLength),
                style: TextStyle(fontSize: r.sp(13)),
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
  // ── 탑텐 스타일 섹션 헤더: 얇은 상단 라인 + 영문 대제목 + 한글 서브 ──
  // _sectionHeader: 검정 포인트 라인만 표시 (텍스트 제거)
  Widget _sectionHeader(String num, String title, String sub) =>
      Container(width: 28, height: 2, color: const Color(0xFF1A1A1A));

  // ─── 사이즈 가이드 ───
  // ignore: unused_element
  void _showSizeGuide() {
    final r = Responsive.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(r.w(20)),
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
            SizedBox(height: r.h(16)),
            Text(context.watch<LanguageProvider>().loc.sizeGuideTitle,
                style: TextStyle(fontSize: r.sp(17), fontWeight: FontWeight.w800)),
            SizedBox(height: r.h(16)),
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
        p.subCategory.contains('숏츠') ||
        p.subCategory.contains('숏츠') ||
        p.subCategory.contains('트레이닝');

    return isSingletSet || isBottom;
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
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.h(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(label,
                style: TextStyle(
                    fontSize: r.sp(12),
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555555))),
          ),
          Expanded(
            child: Text(desc,
                style: TextStyle(fontSize: r.sp(12), color: Color(0xFF888888))),
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
  final String productId;    // Firebase Storage 업로드용 상품 ID
  final String sectionKey;
  final String sectionLabel;
  final List<String> existingImgs;
  final List<XFile> pickedFiles;
  final void Function(List<String>) onSave;
  final VoidCallback onDeleteAll;

  const _PickedImagesSheet({
    required this.productId,
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
  // ignore: unused_element
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  // 최종 이미지 목록: 기존 이미지 + 새로 선택한 Base64 이미지
  late List<String> _allImages;
  // 새로 선택된 파일들 (Base64 변환 전)
  late List<XFile> _pendingFiles;
  bool _isConverting = false;
  bool _isUploadingSave = false; // 저장 버튼 클릭 후 Storage 업로드 중
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

  // ── 저장: base64 data URI → Firebase Storage 업로드 후 onSave 호출
  Future<void> _saveWithUpload() async {
    if (_isConverting || _isUploadingSave) return;

    // base64가 포함된 항목 확인
    final hasBase64 = _allImages.any((u) => u.startsWith('data:'));
    if (!hasBase64) {
      // base64 없으면 바로 저장
      Navigator.pop(context);
      widget.onSave(List<String>.from(_allImages));
      return;
    }

    // base64를 Storage에 업로드
    setState(() => _isUploadingSave = true);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final resultImages = <String>[];

    for (int i = 0; i < _allImages.length; i++) {
      final url = _allImages[i];
      if (!url.startsWith('data:')) {
        // 이미 Storage URL이면 그대로 유지
        resultImages.add(url);
        continue;
      }
      // base64 → bytes 변환 후 Storage 업로드
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx < 0) continue;
        final bytes = base64Decode(url.substring(commaIdx + 1));
        // mime type 추출 (data:image/jpeg;base64,...)
        final mimeMatch = RegExp(r'data:image/(\w+);').firstMatch(url);
        final ext = mimeMatch?.group(1) ?? 'jpg';
        final fileName = '${ts}_$i.$ext';
        final uploadedUrl = await StorageService.uploadSectionImage(
          productId: widget.productId,
          sectionKey: widget.sectionKey,
          bytes: bytes,
          fileName: fileName,
        );
        if (uploadedUrl.isNotEmpty) {
          resultImages.add(uploadedUrl);
        }
        // uploadedUrl이 비어있으면 해당 이미지 제외 (업로드 실패)
      } catch (_) {
        // 업로드 실패 시 해당 이미지 제외
      }
    }

    if (!mounted) return;
    setState(() => _isUploadingSave = false);
    Navigator.pop(context);
    widget.onSave(resultImages);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
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
            padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), r.h(0)),
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
                SizedBox(height: r.h(16)),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(r.w(8)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          size: 18, color: Color(0xFF1A1A2E)),
                    ),
                    SizedBox(width: r.w(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.imageUploadLabel,
                              style: TextStyle(
                                  fontSize: r.sp(16), fontWeight: FontWeight.w800)),
                          Text(widget.sectionLabel,
                              style: TextStyle(
                                  fontSize: r.sp(12), color: Color(0xFF888888))),
                        ],
                      ),
                    ),
                    // 이미지 수 배지
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(4)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_allImages.length}장',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: r.sp(12),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: r.h(12)),

          // ── 변환 중 진행 표시 ──
          if (_isConverting)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(20), vertical: r.h(8)),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF1A1A2E)),
                  ),
                  SizedBox(width: r.w(10)),
                  Text(
                    '이미지 변환 중... (${_convertedBase64.length}/${_pendingFiles.length + _convertedBase64.length})',
                    style: TextStyle(
                        fontSize: r.sp(12), color: Color(0xFF888888)),
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
                        SizedBox(height: r.h(12)),
                        Text(context.watch<LanguageProvider>().loc.noImageSelected,
                            style: TextStyle(
                                color: Color(0xFF888888), fontSize: r.sp(14))),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.w(12)),
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
                        final r = Responsive.of(context);

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
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: r.sp(11),
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
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(8), r.w(16), MediaQuery.of(context).padding.bottom + 12),
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
                      padding: EdgeInsets.symmetric(vertical: r.h(12)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isConverting ? null : _addMoreImages,
                  ),
                ),
                SizedBox(height: r.h(8)),
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
                                EdgeInsets.symmetric(vertical: r.h(12)),
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
                      SizedBox(width: r.w(8)),
                    // 저장
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: _isUploadingSave
                            ? SizedBox(width: r.w(16), height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _isUploadingSave
                              ? 'Storage 업로드 중...'
                              : _allImages.isEmpty
                                  ? '저장 (이미지 없음)'
                                  : '${_allImages.length}장 저장하기',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_allImages.isEmpty && !_isUploadingSave)
                              ? Colors.grey
                              : const Color(0xFF1A1A2E),
                          foregroundColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(vertical: r.h(12)),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: (_isConverting || _isUploadingSave)
                            ? null
                            : () => _saveWithUpload(),
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
      padding: EdgeInsets.fromLTRB(r.w(20), r.h(20), r.w(20), MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _step == 0 ? _buildGenderStep() : _buildOptionStep(),
    );
  }

  // ━━━ STEP 0 : 성별 선택 (싱글렛 A타입 세트 전용) ━━━
  Widget _buildGenderStep() {
    final r = Responsive.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width:40, height:4,
            decoration: BoxDecoration(color:const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)))),
        SizedBox(height: r.h(20)),
        Text('성별 선택',
            style: TextStyle(fontSize: r.sp(16), fontWeight:FontWeight.w900, color:Color(0xFF1A1A1A))),
        SizedBox(height: r.h(10)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(10)),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color:const Color(0xFFFFCC02).withValues(alpha:0.5)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size:14, color:Color(0xFF7A5000)),
            SizedBox(width: r.w(6)),
            Expanded(child: Text(
              '남성 → 하의 5부 자동 적용\n여성 → 하의 2.5부 자동 적용',
              style: TextStyle(fontSize: r.sp(12), color:Color(0xFF7A5000), height:1.5),
            )),
          ]),
        ),
        SizedBox(height: r.h(16)),
        Row(children: [
          _gBtn('남', '하의 5부'),
          SizedBox(width: r.w(12)),
          _gBtn('여', '하의 2.5부'),
        ]),
        SizedBox(height: r.h(20)),
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
              style: TextStyle(fontSize: r.sp(15), fontWeight:FontWeight.w800, color:Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gBtn(String gender, String sub) {
    final r = Responsive.of(context);
    final sel = _gender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(vertical: r.h(18)),
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
            SizedBox(height: r.h(6)),
            Text(gender == '남' ? '남성' : '여성',
                style: TextStyle(fontSize: r.sp(16), fontWeight:FontWeight.w800,
                    color: sel ? Colors.white : const Color(0xFF1A1A1A))),
            SizedBox(height: r.h(4)),
            Text(sub, style: TextStyle(fontSize: r.sp(11),
                color: sel ? Colors.white70 : const Color(0xFF888888))),
          ]),
        ),
      ),
    );
  }

  // ━━━ STEP 1 : 사이즈 → 색상 → 무게 → 수량 ━━━
  Widget _buildOptionStep() {
    final r = Responsive.of(context);
    // 사이즈 목록: 상품에 사이즈가 있으면 그대로, 없으면 기본 성인 사이즈
    final rawSizes = widget.product.sizes;
    final isJunior = rawSizes.any((s) => RegExp(r'^\d{3}$').hasMatch(s));
    final allSizes = rawSizes.isNotEmpty ? rawSizes
        : (isJunior ? AppConstants.juniorSizes : AppConstants.adultSizes);

    // 성인/주니어 분리
    final adultSizes  = allSizes.where((s) => !_isJuniorSizeLabel(s)).toList();
    final juniorSizes = allSizes.where((s) =>  _isJuniorSizeLabel(s)).toList();
    final hasBoth = adultSizes.isNotEmpty && juniorSizes.isNotEmpty;

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
          SizedBox(height: r.h(14)),
          Row(children: [
            if (_isSingletASet) ...[
              GestureDetector(
                onTap: () => setState(() => _step = 0),
                child: const Icon(Icons.chevron_left_rounded, size: 24),
              ),
              SizedBox(width: r.w(4)),
            ],
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSingletASet
                      ? '사이즈 · 색상 선택  (${_gender == "남" ? "남성" : "여성"} · 하의 ${_autoLength ?? ""})'
                      : '사이즈 · 색상 · 수량 선택',
                  style: TextStyle(fontSize: r.sp(15), fontWeight:FontWeight.w900, color:Color(0xFF1A1A1A)),
                ),
              ],
            )),
          ]),
          SizedBox(height: r.h(12)),

          // 안내 배지
          Container(
            padding: EdgeInsets.all(r.w(10)),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF43A047).withValues(alpha:0.3)),
            ),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, size:14, color:Color(0xFF2E7D32)),
              SizedBox(width: r.w(5)),
              Expanded(child: Text('기성품 · 2~3일 이내 배송',
                  style: TextStyle(fontSize: r.sp(12), fontWeight:FontWeight.w700, color:Color(0xFF2E7D32)))),
            ]),
          ),
          SizedBox(height: r.h(16)),

          // ── 사이즈 ──
          Text('사이즈', style: TextStyle(fontSize: r.sp(13), fontWeight:FontWeight.w700)),
          SizedBox(height: r.h(8)),
          if (hasBoth) ...[
            // 성인 그룹
            Row(children: [
              const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF1A1A2E)),
              SizedBox(width: r.w(4)),
              Text('성인', style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              SizedBox(width: r.w(6)),
              Expanded(child: Container(height: 1, color: const Color(0x331A1A2E))),
            ]),
            SizedBox(height: r.h(6)),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: adultSizes.map((s) {
                final r = Responsive.of(context);

                final sel = _selectedSize == s;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(8)),
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
            SizedBox(height: r.h(10)),
            // 주니어 그룹
            Row(children: [
              const Icon(Icons.child_care_rounded, size: 13, color: Color(0xFF1565C0)),
              SizedBox(width: r.w(4)),
              Text('주니어', style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
              SizedBox(width: r.w(6)),
              Expanded(child: Container(height: 1, color: const Color(0x331565C0))),
            ]),
            SizedBox(height: r.h(6)),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: juniorSizes.map((s) {
                final r = Responsive.of(context);

                final sel = _selectedSize == s;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(8)),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF1565C0) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sel ? const Color(0xFF1565C0) : const Color(0xFFE0E0E0)),
                    ),
                    child: Text(s, style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Wrap(
              spacing: 8, runSpacing: 8,
              children: allSizes.map((s) {
                final r = Responsive.of(context);

                final sel = _selectedSize == s;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(8)),
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
          ],
          SizedBox(height: r.h(16)),

          // ── 색상 ──
          _ColorSelectionWidget(
            isBottomCategory: isBottom,
            selectedColor: _selectedColor,
            onColorChanged: (c) => setState(() => _selectedColor = c),
          ),
          SizedBox(height: r.h(16)),

          // ── 무게 ──
          Text('원단 무게', style: TextStyle(fontSize: r.sp(13), fontWeight:FontWeight.w700)),
          SizedBox(height: r.h(8)),
          Row(
            children: AppConstants.fabricWeights.map((w) {
              final r = Responsive.of(context);

              final sel = _selectedWeight == w;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedWeight = w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    margin: EdgeInsets.only(right: w == AppConstants.fabricWeights.first ? 8 : 0),
                    padding: EdgeInsets.symmetric(vertical: r.h(12)),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0)),
                    ),
                    child: Column(children: [
                      Text(w, style: TextStyle(fontSize: r.sp(16), fontWeight:FontWeight.w800,
                          color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                      SizedBox(height: r.h(2)),
                      Text(w == '80g' ? '가볍고 시원함' : '두툼하고 탄탄함',
                          style: TextStyle(fontSize: r.sp(10),
                              color: sel ? Colors.white70 : const Color(0xFF888888))),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: r.h(16)),

          // ── 수량 ──
          Row(children: [
            Text('수량', style: TextStyle(fontSize: r.sp(13), fontWeight:FontWeight.w700)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            ),
            Text('$_quantity', style: TextStyle(fontSize: r.sp(16), fontWeight:FontWeight.w800)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _quantity++),
            ),
          ]),
          SizedBox(height: r.h(16)),

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
                style: TextStyle(fontSize: r.sp(15), fontWeight:FontWeight.w800, color:Colors.white),
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
// ignore: unused_element
class _QuickSizeSelectSheet extends StatefulWidget {
  final ProductModel product;
  final void Function(String size, int qty) onConfirm;
  final bool isBuyNow;

  const _QuickSizeSelectSheet({
    required this.product,
    required this.onConfirm,
    // ignore: unused_element
    this.isBuyNow = false,
  });

  @override
  State<_QuickSizeSelectSheet> createState() => _QuickSizeSelectSheetState();
}

class _QuickSizeSelectSheetState extends State<_QuickSizeSelectSheet> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  // ignore: unused_element
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
    final r = Responsive.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    final sizes = widget.product.sizes;

    return Container(
      padding: EdgeInsets.fromLTRB(r.w(20), r.h(20), r.w(20), bottom + 24),
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
              margin: EdgeInsets.only(bottom: r.h(20)),
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
                  style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(4)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.product.localizedName(_lang),
                    style: TextStyle(fontSize: r.sp(11), color: Color(0xFF666666))),
              ),
            ],
          ),
          SizedBox(height: r.h(6)),
          Text(
            widget.isBuyNow
                ? '사이즈를 선택하고 바로 결제로 이동합니다'
                : '사이즈를 선택하고 장바구니에 담습니다',
            style: TextStyle(fontSize: r.sp(12), color: Color(0xFF888888)),
          ),
          SizedBox(height: r.h(18)),

          // 사이즈 선택 그리드 (성인/주니어 구분)
          Builder(builder: (context) {
            final adultSizes  = sizes.where((s) => !_isJuniorSizeLabel(s)).toList();
            final juniorSizes = sizes.where((s) =>  _isJuniorSizeLabel(s)).toList();
            final hasBoth = adultSizes.isNotEmpty && juniorSizes.isNotEmpty;

            Widget chipWrap(List<String> list, Color activeColor) => Wrap(
              spacing: 8, runSpacing: 8,
              children: list.map((s) {
                final r = Responsive.of(context);

                final sel = _selectedSize == s;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSize = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    width: 64, height: 48,
                    decoration: BoxDecoration(
                      color: sel ? activeColor : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? activeColor : const Color(0xFFDDDDDD),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(s,
                          style: TextStyle(
                              fontSize: r.sp(14),
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                    ),
                  ),
                );
              }).toList(),
            );

            if (hasBoth) {
              final r = Responsive.of(context);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF1A1A2E)),
                    SizedBox(width: r.w(4)),
                    Text('성인', style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                    SizedBox(width: r.w(6)),
                    Expanded(child: Container(height: 1, color: const Color(0x221A1A2E))),
                  ]),
                  SizedBox(height: r.h(6)),
                  chipWrap(adultSizes, const Color(0xFF1A1A1A)),
                  SizedBox(height: r.h(12)),
                  Row(children: [
                    const Icon(Icons.child_care_rounded, size: 13, color: Color(0xFF1565C0)),
                    SizedBox(width: r.w(4)),
                    Text('주니어', style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                    SizedBox(width: r.w(6)),
                    Expanded(child: Container(height: 1, color: const Color(0x221565C0))),
                  ]),
                  SizedBox(height: r.h(6)),
                  chipWrap(juniorSizes, const Color(0xFF1565C0)),
                ],
              );
            }
            return chipWrap(sizes, const Color(0xFF1A1A1A));
          }),
          SizedBox(height: r.h(20)),

          // 수량 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.quantitySelectTitle,
                  style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700)),
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
                        style: TextStyle(fontSize: r.sp(16), fontWeight: FontWeight.w800)),
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
          SizedBox(height: r.h(16)),

          // 금액 요약
          if (_selectedSize != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
              margin: EdgeInsets.only(bottom: r.h(14)),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.product.localizedName(_lang)} · $_selectedSize',
                      style: TextStyle(fontSize: r.sp(12), color: Color(0xFF666666))),
                  Text(
                    '${_fmt((widget.product.price * _quantity).toInt())}원',
                    style: TextStyle(
                        fontSize: r.sp(16), fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
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
                padding: EdgeInsets.symmetric(vertical: r.h(16)),
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
                  SizedBox(width: r.w(8)),
                  Text(
                    _selectedSize == null
                        ? '사이즈를 선택해주세요'
                        : (widget.isBuyNow ? '바로 결제하기' : '장바구니에 담기'),
                    style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.w800),
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

  // ── 기성품 하의 전용: 주머니 제거 옵션 ──
  bool _removePocket = false; // true = 주머니 제거 (-10,000원)

  // 장바구니에 담을 옵션 목록
  final List<Map<String, dynamic>> _items = [];

  // ─────────────────────────────────────────────
  // 상품 타입 판별 getter
  // ─────────────────────────────────────────────

  /// 싱글렛 A타입 세트: 성별 선택 → 하의기장 고정(남=5부, 여=2.5부, 변경불가)
  bool get _isSingletATypeSet =>
      (widget.product.category == '세트' &&
          (widget.product.subCategory.contains('싱글렛 A타입세트') ||
           widget.product.subCategory.contains('싱글렛세트'))) ||
      widget.product.subCategory.contains('싱글렛 A타입세트') ||
      widget.product.subCategory.contains('싱글렛세트') ||
      (widget.product.category == '세트' && widget.product.name.contains('싱글렛 A타입'));

  /// 타이즈 카테고리: 하의길이 모두 선택 가능
  bool get _isTaiz =>
      widget.product.subCategory.contains('타이즈') ||
      widget.product.name.contains('타이즈');

  /// 세트 상품 여부 (상의/하의 사이즈 각각 선택)
  bool get _isSetProduct =>
      widget.product.category == '세트' ||
      widget.product.subCategory.contains('세트') ||
      widget.product.name.contains('세트');

  /// 기성품 싱글렛 (상의 색상 고정, 하의만 색상 선택 가능)
  // ignore: unused_element
  bool get _isSingletReadyMade =>
      (widget.product.category == '상의' ||
          widget.product.subCategory.contains('싱글렛')) &&
      !_isSetProduct;

  /// 하의류: 색상 선택 시 하의 색상 탭 먼저
  // ignore: unused_element
  bool get _isBottomItem =>
      widget.product.category == '하의' ||
      widget.product.subCategory.contains('타이즈') ||
      widget.product.subCategory.contains('레깅스') ||
      widget.product.subCategory.contains('팬츠') ||
      widget.product.subCategory.contains('숏츠') ||
      widget.product.subCategory.contains('숏츠') ||
      widget.product.name.contains('타이즈');

  /// 하의길이 선택이 필요한지: 타이즈이거나 싱글렛 A타입 세트
  bool get _needsLength => _isTaiz || _isSingletATypeSet;

  /// 성별 선택이 필요한지: 싱글렛 A타입 세트만
  bool get _needsGender => _isSingletATypeSet;

  /// 해당 사이즈 품절 여부: soldOutSizes 또는 sizeStocks == 0
  bool _isSizeOutOfStock(String s) {
    if (widget.product.soldOutSizes.contains(s)) return true;
    final stocks = widget.product.sizeStocks;
    if (stocks.isNotEmpty && (stocks[s] ?? 1) <= 0) return true;
    return false;
  }

  /// 기성품 하의 여부: 기성품 + (하의 카테고리 또는 반바지/트레이닝바지/타이즈 서브카테고리)
  bool get _isReadyMadeBottom =>
      widget.product.isReadyMade &&
      (widget.product.category == '하의' ||
          widget.product.subCategory.contains('숏츠') ||
          widget.product.subCategory.contains('트레이닝바지') ||
          widget.product.subCategory.contains('타이즈'));

  // ─────────────────────────────────────────────
  // 사이즈 목록
  // ─────────────────────────────────────────────

  /// 주니어 사이즈인지 판별 → top-level 함수 위임
  bool _isJuniorSize(String s) => _isJuniorSizeLabel(s);

  /// 전체 사이즈 목록 (성인+주니어 혼합 가능)
  List<String> get _allSizes {
    final raw = widget.product.sizes;
    if (raw.isNotEmpty) return raw;
    final isJunior = widget.product.name.contains('주니어') ||
        widget.product.name.contains('Jr') ||
        widget.product.subCategory.contains('주니어');
    return isJunior ? AppConstants.juniorSizes : AppConstants.adultSizes;
  }

  /// 성인 사이즈만 (J- 접두어 또는 숫자 아닌 것)
  List<String> get _adultSizes =>
      _allSizes.where((s) => !_isJuniorSize(s)).toList();

  /// 주니어 사이즈만 (J- 접두어 또는 숫자)
  List<String> get _juniorSizes =>
      _allSizes.where((s) => _isJuniorSize(s)).toList();

  /// 성인/주니어 혼합 여부
  bool get _hasBothGroups =>
      _adultSizes.isNotEmpty && _juniorSizes.isNotEmpty;

  /// 하위 호환: 단일 그룹일 때 기본 사이즈 목록
  List<String> get _defaultSizes => _allSizes;

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
    final colorExtra = needsColor ? widget.calcExtraForColor(colorValue) : 0.0;
    // 기성품 하의: 주머니 제거 선택 시 -10,000원
    final pocketDiscount = _isReadyMadeBottom && _removePocket ? -10000.0 : 0.0;
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
        'extra': colorExtra + pocketDiscount,
        'removePocket': _isReadyMadeBottom && _removePocket,
      });
      // 옵션 초기화 (새 옵션 선택)
      _topSize = null;
      _bottomSize = null;
      _size = null;
      _color = null;
      _qty = 1;
      // 성별/기장/주머니옵션은 유지
    });
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  void _proceedToCart() {
    final r = Responsive.of(context);

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
          SizedBox(width: r.w(8)),
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
    final r = Responsive.of(context);
    final lengths = AppConstants.bottomLengths
        .map((m) => m['label'] as String)
        .where((s) => s.isNotEmpty)
        .toList();

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
              padding: EdgeInsets.fromLTRB(r.w(20), r.h(12), r.w(20), r.h(0)),
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
                  SizedBox(height: r.h(14)),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isBuyNow ? '바로구매 옵션 선택' : '장바구니 옵션 선택',
                              style: TextStyle(
                                fontSize: r.sp(17),
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            SizedBox(height: r.h(2)),
                            Text(
                              '옵션을 선택하고 추가하면 한 번에 담을 수 있어요',
                              style: TextStyle(fontSize: r.sp(12), color: Color(0xFF888888)),
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
                padding: EdgeInsets.fromLTRB(r.w(20), r.h(0), r.w(20), r.h(100)),
                children: [

                  // ══════════════════════════════
                  // [1] 싱글렛 A타입 세트: 성별 선택 → 기장 고정
                  // ══════════════════════════════
                  if (_needsGender) ...[
                    _sectionTitle('성별 선택', required: true),
                    SizedBox(height: r.h(8)),
                    // 안내 배지
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(7)),
                      margin: EdgeInsets.only(bottom: r.h(10)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF7A5000)),
                        SizedBox(width: r.w(5)),
                        Text(
                          '남성 → 5부 자동선택  •  여성 → 2.5부 자동선택',
                          style: TextStyle(fontSize: r.sp(11), color: Color(0xFF7A5000), fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                    Row(
                      children: ['남', '여'].map((g) {
                        final r = Responsive.of(context);

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
                              padding: EdgeInsets.symmetric(vertical: r.h(14)),
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
                                  SizedBox(height: r.h(4)),
                                  Text(
                                    g == '남' ? '남성' : '여성',
                                    style: TextStyle(
                                      fontSize: r.sp(14),
                                      fontWeight: FontWeight.w700,
                                      color: isSel ? Colors.white : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  SizedBox(height: r.h(4)),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(2)),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : const Color(0xFF1A1A2E).withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_autoLength(g)} 자동선택',
                                      style: TextStyle(
                                        fontSize: r.sp(10),
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
                    SizedBox(height: r.h(12)),
                    // 기장 고정 표시 (변경 불가)
                    if (_gender != null) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(10)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFF2E7D32)),
                          SizedBox(width: r.w(6)),
                          Text(
                            '하의 기장: ${_length!} (고정 · 변경 불가)',
                            style: TextStyle(
                              fontSize: r.sp(13),
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ]),
                      ),
                      SizedBox(height: r.h(16)),
                    ],
                  ],

                  // ══════════════════════════════
                  // [2] 타이즈: 하의길이 모두 선택 가능 (성별 선택 없음)
                  // ══════════════════════════════
                  if (_isTaiz && !_needsGender) ...[
                    _sectionTitle('하의 기장 선택', required: true),
                    SizedBox(height: r.h(8)),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: lengths.map((len) {
                        final r = Responsive.of(context);

                        final isSel = _length == len;
                        return GestureDetector(
                          onTap: () => setState(() => _length = len),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(10)),
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
                    SizedBox(height: r.h(16)),
                  ],

                  // ══════════════════════════════
                  // [3] 사이즈 선택
                  //   - 세트 상품: 상의/하의 각각
                  //   - 단품: 공통 사이즈
                  // ══════════════════════════════
                  if (_isSetProduct) ...[
                    // 상의 사이즈
                    _sectionTitle('상의 사이즈', required: true),
                    SizedBox(height: r.h(8)),
                    if (_hasBothGroups) ...[
                      _sizeSectionLabel('성인', Icons.person_outline_rounded, const Color(0xFF1A1A2E)),
                      SizedBox(height: r.h(6)),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _adultSizes.map((s) {
                          final isSel = _topSize == s;
                          return _sizeChip(label: s, isSelected: isSel,
                            activeColor: const Color(0xFF1A1A2E),
                            isSoldOut: _isSizeOutOfStock(s),
                            onTap: () => setState(() => _topSize = s));
                        }).toList(),
                      ),
                      SizedBox(height: r.h(10)),
                      _sizeSectionLabel('주니어', Icons.child_care_rounded, const Color(0xFF1565C0)),
                      SizedBox(height: r.h(6)),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _juniorSizes.map((s) {
                          final isSel = _topSize == s;
                          return _sizeChip(label: s, isSelected: isSel,
                            activeColor: const Color(0xFF1565C0),
                            isSoldOut: _isSizeOutOfStock(s),
                            onTap: () => setState(() => _topSize = s));
                        }).toList(),
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _defaultSizes.map((s) {
                          final isSel = _topSize == s;
                          return _sizeChip(label: s, isSelected: isSel,
                            activeColor: const Color(0xFF1A1A2E),
                            isSoldOut: _isSizeOutOfStock(s),
                            onTap: () => setState(() => _topSize = s));
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: r.h(16)),
                    // 하의 사이즈
                    _sectionTitle('하의 사이즈', required: true),
                    SizedBox(height: r.h(8)),
                    if (_hasBothGroups) ...[
                      _sizeSectionLabel('성인', Icons.person_outline_rounded, const Color(0xFF5C6BC0)),
                      SizedBox(height: r.h(6)),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _adultSizes.map((s) {
                          final isSel = _bottomSize == s;
                          return _sizeChip(label: s, isSelected: isSel,
                            activeColor: const Color(0xFF5C6BC0),
                            isSoldOut: _isSizeOutOfStock(s),
                            onTap: () => setState(() => _bottomSize = s));
                        }).toList(),
                      ),
                      SizedBox(height: r.h(10)),
                      _sizeSectionLabel('주니어', Icons.child_care_rounded, const Color(0xFF1565C0)),
                      SizedBox(height: r.h(6)),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _juniorSizes.map((s) {
                          final isSel = _bottomSize == s;
                          return _sizeChip(label: s, isSelected: isSel,
                            activeColor: const Color(0xFF1565C0),
                            isSoldOut: _isSizeOutOfStock(s),
                            onTap: () => setState(() => _bottomSize = s));
                        }).toList(),
                      ),
                    ] else ...[
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _defaultSizes.map((s) {
                          final isSel = _bottomSize == s;
                          return _sizeChip(label: s, isSelected: isSel,
                            activeColor: const Color(0xFF5C6BC0),
                            isSoldOut: _isSizeOutOfStock(s),
                            onTap: () => setState(() => _bottomSize = s));
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: r.h(16)),
                  ] else ...[
                    // 단품 사이즈 — 성인/주니어 구분 표시
                    _sectionTitle('사이즈', required: true),
                    SizedBox(height: r.h(8)),

                    // ── 성인/주니어 혼합 상품: 그룹 구분 표시 ──
                    if (_hasBothGroups) ...[
                      // 성인 그룹 라벨
                      _sizeSectionLabel('성인', Icons.person_outline_rounded, const Color(0xFF1A1A2E)),
                      SizedBox(height: r.h(6)),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _adultSizes.map((s) {
                          final isSel = _size == s;
                          return _sizeChip(
                            label: s,
                            isSelected: isSel,
                            activeColor: const Color(0xFF1A1A2E),
                            isSoldOut: _isSizeOutOfStock(s),
                            onTap: () => setState(() => _size = s),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: r.h(14)),
                      // 주니어 그룹 라벨
                      _sizeSectionLabel('주니어', Icons.child_care_rounded, const Color(0xFF1565C0)),
                      SizedBox(height: r.h(6)),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _juniorSizes.map((s) {
                          final isSel = _size == s;
                          return _sizeChip(
                            label: s,
                            isSelected: isSel,
                            activeColor: const Color(0xFF1565C0),
                            isSoldOut: _isSizeOutOfStock(s),
                            onTap: () => setState(() => _size = s),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      // 단일 그룹: 기존 방식 유지
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _defaultSizes.map((s) {
                          final isSel = _size == s;
                          return _sizeChip(
                            label: s,
                            isSelected: isSel,
                            activeColor: const Color(0xFF1A1A2E),
                            isSoldOut: _isSizeOutOfStock(s),
                            onTap: () => setState(() => _size = s),
                          );
                        }).toList(),
                      ),
                    ],
                    SizedBox(height: r.h(16)),
                  ],

                  // ══════════════════════════════
                  // [3-A] 기성품: 없는 사이즈 채팅 문의 안내
                  // ══════════════════════════════
                  if (widget.product.isReadyMade) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: r.h(14)),
                      padding: EdgeInsets.all(r.w(12)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF7A5000)),
                            SizedBox(width: r.w(5)),
                            Text('원하는 사이즈가 없으신가요?',
                              style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w800, color: Color(0xFF7A5000))),
                          ]),
                          SizedBox(height: r.h(5)),
                          Text(
                            '목록에 없는 사이즈는 채팅 문의를 통해 별도 주문 가능합니다.',
                            style: TextStyle(fontSize: r.sp(11), color: Color(0xFF7A5000), height: 1.4),
                          ),
                          SizedBox(height: r.h(4)),
                          Text(
                            '⚠️ 단, 별도 주문 시 제작 소요 기간이 최소 1주일 이상 걸리며,\n    경우에 따라 더 길어질 수 있습니다.',
                            style: TextStyle(fontSize: r.sp(11), color: Color(0xFFD84315),
                              fontWeight: FontWeight.w700, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ══════════════════════════════
                  // [3-B] 기성품 하의 전용: 주머니 옵션
                  // ══════════════════════════════
                  if (_isReadyMadeBottom) ...[
                    _sectionTitle('주머니 옵션', required: false),
                    SizedBox(height: r.h(8)),
                    Container(
                      padding: EdgeInsets.all(r.w(12)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF6A1B9A)),
                          SizedBox(width: r.w(6)),
                          Expanded(
                            child: Text(
                              '기본 옵션: 주머니 포함\n주머니 제거 선택 시 10,000원 할인됩니다.',
                              style: TextStyle(fontSize: r.sp(11), color: Color(0xFF6A1B9A),
                                fontWeight: FontWeight.w600, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.h(10)),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _removePocket = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 130),
                            padding: EdgeInsets.symmetric(vertical: r.h(12)),
                            decoration: BoxDecoration(
                              color: !_removePocket ? const Color(0xFF1A1A2E) : const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !_removePocket ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0E0),
                                width: !_removePocket ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 20,
                                  color: !_removePocket ? Colors.white : const Color(0xFF888888)),
                                SizedBox(height: r.h(4)),
                                Text('주머니 포함', style: TextStyle(fontSize: r.sp(12),
                                  fontWeight: FontWeight.w700,
                                  color: !_removePocket ? Colors.white : const Color(0xFF1A1A1A))),
                                Text('기본 옵션', style: TextStyle(fontSize: r.sp(10),
                                  color: !_removePocket ? Colors.white70 : const Color(0xFF888888))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: r.w(10)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _removePocket = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 130),
                            padding: EdgeInsets.symmetric(vertical: r.h(12)),
                            decoration: BoxDecoration(
                              color: _removePocket ? const Color(0xFF6A1B9A) : const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _removePocket ? const Color(0xFF6A1B9A) : const Color(0xFFE0E0E0),
                                width: _removePocket ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.remove_shopping_cart_outlined, size: 20,
                                  color: _removePocket ? Colors.white : const Color(0xFF888888)),
                                SizedBox(height: r.h(4)),
                                Text('주머니 제거', style: TextStyle(fontSize: r.sp(12),
                                  fontWeight: FontWeight.w700,
                                  color: _removePocket ? Colors.white : const Color(0xFF1A1A1A))),
                                Text('-₩10,000', style: TextStyle(fontSize: r.sp(10),
                                  fontWeight: FontWeight.w800,
                                  color: _removePocket ? const Color(0xFFFFD600) : const Color(0xFF888888))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                    SizedBox(height: r.h(16)),
                  ],

                  // ══════════════════════════════
                  // [4] 색상 선택
                  //   - 싱글렛 A타입 세트 / 타이즈만 색상 선택 표시
                  //   - 상의, 그 외 카테고리는 색상 선택 없음
                  // ══════════════════════════════
                  if (_isSingletATypeSet || _isTaiz) ...[
                    _sectionTitle('하의 색상', required: true),
                    SizedBox(height: r.h(6)),
                    _ColorSelectionWidget(
                      isBottomCategory: true,
                      selectedColor: _color,
                      onColorChanged: (c) => setState(() => _color = c),
                    ),
                    SizedBox(height: r.h(16)),
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
                                style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.w800),
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
                  SizedBox(height: r.h(16)),

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
                    SizedBox(height: r.h(20)),
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 16, color: Color(0xFF1A1A2E)),
                        SizedBox(width: r.w(6)),
                        Text(
                          '선택된 옵션 ${_items.length}가지',
                          style: TextStyle(
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '총 ${_totalQty()}개 · ${_fmt(_totalPrice())}원',
                          style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w700, color: Color(0xFF555555)),
                        ),
                      ],
                    ),
                    SizedBox(height: r.h(10)),
                    ..._items.asMap().entries.map((e) {
                      final r = Responsive.of(context);

                      final idx = e.key;
                      final item = e.value;
                      final base = (widget.product.price as num).toInt();
                      final extra = (item['extra'] as num).toInt();
                      final itemTotal = (base + extra) * (item['qty'] as int);
                      return Container(
                        margin: EdgeInsets.only(bottom: r.h(8)),
                        padding: EdgeInsets.all(r.w(12)),
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
                                      if ((item['color'] as String) != '-')
                                        _optionChip(item['color'] as String, const Color(0xFF43A047)),
                                      if ((item['length'] as String) != '-')
                                        _optionChip(item['length'] as String, const Color(0xFF1565C0)),
                                      if (item['removePocket'] == true)
                                        _optionChip('주머니 제거', const Color(0xFF6A1B9A)),
                                    ],
                                  ),
                                  SizedBox(height: r.h(8)),
                                  Row(
                                    children: [
                                      // ── 수량 +/- 인라인 컨트롤 ──
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFE0E0E0)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: (item['qty'] as int) > 1
                                                  ? () => setState(() => _items[idx]['qty'] = (item['qty'] as int) - 1)
                                                  : null,
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                                              child: Container(
                                                width: 28, height: 28,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 13,
                                                  color: (item['qty'] as int) > 1
                                                      ? const Color(0xFF1A1A1A)
                                                      : const Color(0xFFCCCCCC),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 32, height: 28,
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${item['qty']}',
                                                style: TextStyle(
                                                  fontSize: r.sp(13),
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF1A1A1A),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => setState(() => _items[idx]['qty'] = (item['qty'] as int) + 1),
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                                              child: Container(
                                                width: 28, height: 28,
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.add, size: 13, color: Color(0xFF1A1A1A)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (item['removePocket'] == true) ...[
                                        SizedBox(width: r.w(8)),
                                        Text('주머니 제거 -10,000원',
                                          style: TextStyle(fontSize: r.sp(11), color: Color(0xFF6A1B9A), fontWeight: FontWeight.w700)),
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
                                  style: TextStyle(
                                    fontSize: r.sp(13),
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                SizedBox(height: r.h(4)),
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
              padding: EdgeInsets.fromLTRB(r.w(20), r.h(12), r.w(20), MediaQuery.of(context).padding.bottom + 16),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E),
                                    fontSize: r.sp(13),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: r.w(10)),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: r.sp(14),
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
        Text(title, style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700)),
        if (required) ...[
          SizedBox(width: r.w(4)),
          Text('*', style: TextStyle(color: Color(0xFFE53935), fontSize: r.sp(13), fontWeight: FontWeight.w900)),
        ],
      ],
    );
  }

  /// 성인/주니어 그룹 구분 라벨 (아이콘 + 텍스트)
  Widget _sizeSectionLabel(String label, IconData icon, Color color) {
    final r = Responsive.of(context);
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        SizedBox(width: r.w(4)),
        Text(
          label,
          style: TextStyle(
            fontSize: r.sp(11),
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(width: r.w(6)),
        Expanded(
          child: Container(
            height: 1,
            color: color.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  /// 사이즈 선택 칩 (공통 스타일)
  Widget _sizeChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    bool isSoldOut = false,
  }) {
    final r = Responsive.of(context);
    return GestureDetector(
      onTap: isSoldOut ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: isSoldOut ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: isSoldOut
              ? const Color(0xFFF5F5F5)
              : isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSoldOut
                ? const Color(0xFFDDDDDD)
                : isSelected ? activeColor : const Color(0xFFE0E0E0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSoldOut
                    ? const Color(0xFFBBBBBB)
                    : isSelected ? Colors.white : const Color(0xFF1A1A1A),
                decoration: isSoldOut ? TextDecoration.lineThrough : null,
                decorationColor: const Color(0xFF999999),
                decorationThickness: 2,
              ),
            ),
            if (isSoldOut) ...[
              SizedBox(height: r.h(2)),
              Text(
                '품절',
                style: TextStyle(
                  fontSize: r.sp(8),
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE53935),
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _optionChip(String label, Color color) {
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(3)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: color),
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
  // ignore: unused_element
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
    final r = Responsive.of(context);
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
      padding: EdgeInsets.fromLTRB(r.w(20), r.h(20), r.w(20), bottom + 24),
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
                margin: EdgeInsets.only(bottom: r.h(20)),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Text(loc.optionSelectTitle,
                    style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.w900)),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(4)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.product.localizedName(_lang),
                      style: TextStyle(fontSize: r.sp(11), color: Color(0xFF666666))),
                ),
              ],
            ),
            SizedBox(height: r.h(6)),
            Text(loc.buyNowCheckoutDesc,
                style: TextStyle(fontSize: r.sp(12), color: Color(0xFF888888))),
            SizedBox(height: r.h(20)),
            Text(loc.sizeLabel,
                style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700)),
            SizedBox(height: r.h(10)),
            Builder(builder: (context) {
              final adultSizes  = sizes.where((s) => !_isJuniorSizeLabel(s)).toList();
              final juniorSizes = sizes.where((s) =>  _isJuniorSizeLabel(s)).toList();
              final hasBoth = adultSizes.isNotEmpty && juniorSizes.isNotEmpty;

              Widget chipWrap(List<String> list, Color activeColor) => Wrap(
                spacing: 8, runSpacing: 8,
                children: list.map((s) {
                  final r = Responsive.of(context);

                  final sel = _selectedSize == s;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSize = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      width: 64, height: 48,
                      decoration: BoxDecoration(
                        color: sel ? activeColor : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? activeColor : const Color(0xFFDDDDDD),
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(s,
                            style: TextStyle(
                                fontSize: r.sp(14), fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                      ),
                    ),
                  );
                }).toList(),
              );

              if (hasBoth) {
                final r = Responsive.of(context);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF1A1A2E)),
                      SizedBox(width: r.w(4)),
                      Text('성인', style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                      SizedBox(width: r.w(6)),
                      Expanded(child: Container(height: 1, color: const Color(0x221A1A2E))),
                    ]),
                    SizedBox(height: r.h(6)),
                    chipWrap(adultSizes, const Color(0xFF1A1A1A)),
                    SizedBox(height: r.h(12)),
                    Row(children: [
                      const Icon(Icons.child_care_rounded, size: 13, color: Color(0xFF1565C0)),
                      SizedBox(width: r.w(4)),
                      Text('주니어', style: TextStyle(fontSize: r.sp(11), fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                      SizedBox(width: r.w(6)),
                      Expanded(child: Container(height: 1, color: const Color(0x221565C0))),
                    ]),
                    SizedBox(height: r.h(6)),
                    chipWrap(juniorSizes, const Color(0xFF1565C0)),
                  ],
                );
              }
              return chipWrap(sizes, const Color(0xFF1A1A1A));
            }),
            SizedBox(height: r.h(20)),
            // 컬러 섹션 (하의: 19가지 + 팔레트, 기타: 검정/남색)
            _ColorSelectionWidget(
              isBottomCategory: isBottom,
              selectedColor: _selectedColor,
              onColorChanged: (c) => setState(() => _selectedColor = c),
            ),
            SizedBox(height: r.h(20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.quantityLabel, style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700)),
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
                          style: TextStyle(fontSize: r.sp(16), fontWeight: FontWeight.w800)),
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
            SizedBox(height: r.h(16)),
            if (_canConfirm)
              Container(
                padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
                margin: EdgeInsets.only(bottom: r.h(14)),
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
                          style: TextStyle(fontSize: r.sp(12), color: Color(0xFF666666)),
                          softWrap: true),
                    ),
                    Text(
                      '${_fmt(((widget.product.price + _extraPrice) * _quantity).toInt())}원',
                      style: TextStyle(
                          fontSize: r.sp(16), fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
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
                  padding: EdgeInsets.symmetric(vertical: r.h(16)),
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
                    SizedBox(width: r.w(8)),
                    Text(
                      _canConfirm ? '바로 결제하기' : '사이즈와 컬러를 선택해주세요',
                      style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.w800),
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
//   - 블랙(K), 틸블루(BB): 추가비용 없음
//   - 그 외 색상(PP 포함): +20,000원 추가비용 안내
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
    final r = Responsive.of(context);
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
                style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700)),
            SizedBox(width: r.w(8)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(3)),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFB74D), width: 0.8),
              ),
              child: Text(loc.productColorExtraNote,
                  style: TextStyle(
                      fontSize: r.sp(10),
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        SizedBox(height: r.h(10)),

        // ── 선택된 색상 표시 ──
        if (widget.selectedColor != null) ...[
          Builder(builder: (_) {
            final r = Responsive.of(context);

            final col = widget.selectedColor!;
            final found = palette.firstWhere(
              (c) => c['name'] == col,
              orElse: () => <String, dynamic>{},
            );
            if (found.isEmpty) return const SizedBox.shrink();
            final isFree = freeColors.contains(col);
            final selHex = found['hex'] as int;
            final selColor = Color(selHex);
            return Padding(
              padding: EdgeInsets.only(bottom: r.h(8)),
              child: Row(children: [
                Text(loc.selectedLabel,
                    style: TextStyle(
                        fontSize: r.sp(12), color: Color(0xFF888888))),
                SizedBox(width: r.w(6)),
                RibColorSwatch(
                  color: selColor,
                  size: 20,
                  isSelected: true,
                  accentColor: const Color(0xFF1A1A1A),
                  isLight: selColor.computeLuminance() > 0.5,
                  borderRadius: 4,
                  showRib: true,
                ),
                SizedBox(width: r.w(6)),
                Text(col,
                    style: TextStyle(
                        fontSize: r.sp(13), fontWeight: FontWeight.w700)),
                SizedBox(width: r.w(6)),
                Text(
                  isFree ? '기본색상' : '+20,000원',
                  style: TextStyle(
                    fontSize: r.sp(11),
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
            final r = Responsive.of(context);

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
                    showRib: true,
                    child: sel
                        ? Icon(Icons.check_rounded,
                            size: 18,
                            color: Color(hex).computeLuminance() > 0.5
                                ? const Color(0xFF333333)
                                : Colors.white)
                        : null,
                  ),
                  SizedBox(height: r.h(3)),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: r.sp(9),
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w400,
                      color: sel
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF666666),
                    ),
                  ),
                  if (!isFree)
                    Text('+₩',
                        style: TextStyle(
                            fontSize: r.sp(8), color: Color(0xFFCC0000))),
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(height: r.h(4)),
        Text(loc.productColorExtraFull,
            style: TextStyle(fontSize: r.sp(10), color: Color(0xFF999999))),
        SizedBox(height: r.h(12)),
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
  // ignore: unused_element
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  int _tab = 0; // 0=성인, 1=주니어

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 탭 버튼 ──
        Row(
          children: [
            _tabBtn(0, 'ADULT', '성인'),
            SizedBox(width: r.w(8)),
            _tabBtn(1, 'JUNIOR', '주니어'),
          ],
        ),
        SizedBox(height: r.h(16)),
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
    final r = Responsive.of(context);
    final sel = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: r.w(18), vertical: r.h(10)),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF222222) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: sel ? const Color(0xFF222222) : Colors.black.withValues(alpha: 0.15),
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: r.sp(12),
                fontWeight: FontWeight.w900,
                color: sel ? Colors.white : Colors.black.withValues(alpha: 0.4),
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(width: r.w(5)),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: r.sp(10),
                fontWeight: FontWeight.w500,
                color: sel ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.3),
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

  // ignore: unused_element
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
        final r = Responsive.of(context);

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
                padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), r.h(0)),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('리뷰 ${reviews.length}개', style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.w800)),
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(Icons.star_rounded,
                                size: 16, color: i < avg.round() ? const Color(0xFFFFD600) : const Color(0xFFEEEEEE))),
                            SizedBox(width: r.w(6)),
                            Text(avg.toStringAsFixed(1), style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w700)),
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
                padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(8)),
                child: Row(
                  children: [
                    _sortBtn('최신순', 'latest'),
                    SizedBox(width: r.w(8)),
                    _sortBtn('평점 높은순', 'highest'),
                    SizedBox(width: r.w(8)),
                    _sortBtn('평점 낮은순', 'lowest'),
                    const Spacer(),
                    if (currentUid != null)
                      GestureDetector(
                        onTap: () => _showWriteReviewDialog(existing: myReview),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(6)),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(myReview != null ? Icons.edit : Icons.rate_review,
                                  size: 14, color: Colors.white),
                              SizedBox(width: r.w(4)),
                              Text(myReview != null ? '내 리뷰 수정' : '리뷰 작성',
                                  style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w600, color: Colors.white)),
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
                            SizedBox(height: r.h(12)),
                            Text(loc.noReviewYet, style: const TextStyle(color: Color(0xFF999999))),
                            if (currentUid != null) ...[
                              SizedBox(height: r.h(16)),
                              ElevatedButton.icon(
                                onPressed: () => _showWriteReviewDialog(),
                                icon: const Icon(Icons.rate_review, size: 16),
                                label: const Text('첫 번째 리뷰를 작성해보세요'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: r.w(20), vertical: r.h(10)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: r.w(16)),
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final rev = reviews[i];
                          final isMyReview = currentUid != null && rev.userId == currentUid;
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: r.h(14)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: isMyReview ? const Color(0xFF6C63FF) : const Color(0xFF1A1A1A),
                                      child: Text(rev.userName.isNotEmpty ? rev.userName[0].toUpperCase() : 'U',
                                          style: TextStyle(color: Colors.white, fontSize: r.sp(12), fontWeight: FontWeight.w700)),
                                    ),
                                    SizedBox(width: r.w(10)),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(rev.userName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(13))),
                                            if (isMyReview) ...[
                                              SizedBox(width: r.w(6)),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: r.w(6), vertical: r.h(2)),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text('내 리뷰', style: TextStyle(fontSize: r.sp(10), color: Color(0xFF6C63FF), fontWeight: FontWeight.w700)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Row(
                                          children: List.generate(5, (j) => Icon(Icons.star_rounded,
                                              size: 13, color: j < rev.rating ? const Color(0xFFFFD600) : const Color(0xFFEEEEEE))),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text('${rev.createdAt.year}.${rev.createdAt.month.toString().padLeft(2,'0')}.${rev.createdAt.day.toString().padLeft(2,'0')}',
                                        style: TextStyle(fontSize: r.sp(11), color: Color(0xFF999999))),
                                    if (isMyReview) ...[
                                      SizedBox(width: r.w(4)),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF999999)),
                                        onSelected: (v) {
                                          if (v == 'edit') _showWriteReviewDialog(existing: rev);
                                          if (v == 'delete') _deleteReview(rev);
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: r.w(8)), Text('수정')])),
                                          PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: r.w(8)), Text('삭제', style: TextStyle(color: Colors.red))])),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: r.h(8)),
                                if (rev.size.isNotEmpty || rev.color.isNotEmpty)
                                  Row(
                                    children: [
                                      if (rev.size.isNotEmpty) _chip('사이즈: ${rev.size}'),
                                      if (rev.color.isNotEmpty) ...[SizedBox(width: r.w(6)), _chip('색상: ${rev.color}')],
                                    ],
                                  ),
                                SizedBox(height: r.h(6)),
                                Text(rev.content, style: TextStyle(fontSize: r.sp(13), height: 1.5, color: Color(0xFF333333))),
                                if (rev.images.isNotEmpty) ...[
                                  SizedBox(height: r.h(8)),
                                  SizedBox(
                                    height: 60,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: rev.images.length,
                                      separatorBuilder: (_, __) => SizedBox(width: r.w(6)),
                                      itemBuilder: (_, j) => ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(rev.images[j], width: 60, height: 60, fit: BoxFit.cover,
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
        padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(6)),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD)),
        ),
        child: Text(label, style: TextStyle(fontSize: r.sp(12), fontWeight: FontWeight.w600, color: sel ? Colors.white : Color(0xFF555555))),
      ),
    );
  }

  Widget _chip(String text) {
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(3)),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: r.sp(11), color: Color(0xFF555555))),
    );
  }
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
    final r = Responsive.of(context);
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
              padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), r.h(0)),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
                  SizedBox(height: r.h(12)),
                  Row(
                    children: [
                      Text(widget.existing != null ? '리뷰 수정' : '리뷰 작성',
                          style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.w800)),
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
                padding: EdgeInsets.all(r.w(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상품명
                    Text(widget.product.name,
                        style: TextStyle(fontSize: r.sp(14), color: Color(0xFF666666)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: r.h(20)),
                    // 별점
                    Text('별점', style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w700)),
                    SizedBox(height: r.h(8)),
                    Row(
                      children: [
                        ...List.generate(5, (i) => GestureDetector(
                          onTap: () => setState(() => _rating = (i + 1).toDouble()),
                          child: Padding(
                            padding: EdgeInsets.only(right: r.w(4)),
                            child: Icon(Icons.star_rounded, size: 36,
                                color: i < _rating ? const Color(0xFFFFD600) : const Color(0xFFDDDDDD)),
                          ),
                        )),
                        SizedBox(width: r.w(8)),
                        Text('${_rating.toInt()}점', style: TextStyle(fontSize: r.sp(16), fontWeight: FontWeight.w700)),
                      ],
                    ),
                    SizedBox(height: r.h(20)),
                    // 리뷰 내용
                    Text('리뷰 내용', style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w700)),
                    SizedBox(height: r.h(8)),
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
                    SizedBox(height: r.h(16)),
                    // 사이즈 / 색상 (선택)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('구매 사이즈 (선택)', style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w600)),
                              SizedBox(height: r.h(6)),
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
                        SizedBox(width: r.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('구매 색상 (선택)', style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w600)),
                              SizedBox(height: r.h(6)),
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
                    SizedBox(height: r.h(24)),
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
                            ? SizedBox(width: r.w(20), height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(widget.existing != null ? '리뷰 수정 완료' : '리뷰 등록',
                                style: TextStyle(fontSize: r.sp(16), fontWeight: FontWeight.w700)),
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
        // 기본 배경 (라이트 테마)
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
          ),
          child: Row(
            children: headers.asMap().entries.map((e) {
              final r = Responsive.of(context);

              final isFirst = e.key == 0;
              return Expanded(
                flex: isFirst ? 3 : 3,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: r.h(13), horizontal: r.w(4)),
                  decoration: BoxDecoration(
                    border: Border(
                      right: e.key < headers.length - 1
                          ? BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1)
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.sp(9.5),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                      height: 1.3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 골지 라인 오버레이
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
    final r = Responsive.of(context);
    // 짝수 행: 흰색, 홀수 행: 아주 연한 회색
    final bg = isEven
        ? const Color(0xFFFFFFFF)
        : const Color(0xFFF8F8F8);
    final ribColor = isEven
        ? Colors.black.withValues(alpha: 0.02)
        : Colors.black.withValues(alpha: 0.02);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: Colors.black.withValues(alpha: 0.07), width: 1),
            ),
          ),
          child: Row(
            children: values.asMap().entries.map((e) {
              final r = Responsive.of(context);

              final isFirst = e.key == 0;
              final isSize = isFirst && isSizeCol;
              return Expanded(
                flex: isFirst ? 3 : 3,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: r.h(12), horizontal: r.w(4)),
                  decoration: BoxDecoration(
                    color: isSize
                        ? const Color(0xFFEEEEEE)
                        : Colors.transparent,
                    border: Border(
                      right: e.key < values.length - 1
                          ? BorderSide(color: Colors.black.withValues(alpha: 0.07), width: 1)
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isSize ? 10 : 11.5,
                      fontWeight: isSize ? FontWeight.w800 : FontWeight.w500,
                      color: isSize
                          ? const Color(0xFF111111)
                          : const Color(0xFF333333),
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
    final r = Responsive.of(context);
    return RibColorSwatch(
      color: color,
      size: size,
      isLight: isLight,
      showRib: true,
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
  // ignore: unused_element
  AppLanguage get _lang => context.watch<LanguageProvider>().language;

  static const Color _purple = Color(0xFF4A148C);

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      padding: EdgeInsets.fromLTRB(r.w(0), r.h(0), r.w(0), bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            width: 40, height: 4,
            margin: EdgeInsets.symmetric(vertical: r.h(12)),
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(20), r.h(0), r.w(20), r.h(12)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(r.w(9)),
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.groups_rounded, color: _purple, size: 22),
                ),
                SizedBox(width: r.w(12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.groupOrderGuideAppBar,
                        style: TextStyle(fontSize: r.sp(18), fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                    Text(loc.groupOrderGuideHeroTitle,
                        style: TextStyle(fontSize: r.sp(11), color: Color(0xFF888888), letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // 스크롤 가능 내용
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(r.w(20), r.h(20), r.w(20), r.h(0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ─── 1. 기본 안내 ───────────────────────────────
                  _sheetSectionTitle(Icons.info_outline_rounded, loc.groupOrderGuideAppBar, const Color(0xFF1565C0)),
                  SizedBox(height: r.h(10)),
                  _infoCard(
                    icon: Icons.people_outline_rounded,
                    iconBg: const Color(0xFFE8EAF6),
                    iconColor: _purple,
                    title: loc.groupOrderMinQty,
                    content: loc.groupOrderMinQtyDesc,
                  ),
                  SizedBox(height: r.h(8)),
                  _infoCard(
                    icon: Icons.schedule_outlined,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF6A1B9A),
                    title: loc.groupOrderProductionPeriod,
                    content: loc.groupOrderProductionPeriodDesc,
                  ),
                  SizedBox(height: r.h(8)),
                  _infoCardWidget(
                    icon: Icons.local_shipping_outlined,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    title: loc.groupOrderGuideShippingTitle,
                    contentWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.groupOrderGuideShipping1, style: TextStyle(fontSize: r.sp(13), height: 1.6)),
                        Text(loc.groupOrderGuideShipping2, style: TextStyle(fontSize: r.sp(13), height: 1.6)),
                        Text(loc.groupOrderGuideShipping3, style: TextStyle(fontSize: r.sp(13), height: 1.6)),
                        Text(loc.groupOrderGuideShipping4, style: TextStyle(fontSize: r.sp(13), height: 1.6)),
                      ],
                    ),
                  ),
                  SizedBox(height: r.h(20)),

                  // ─── 3. 사이즈 안내 ──────────────────────────────
                  _sheetSectionTitle(null, loc.groupOrderGuideSizeTitle, const Color(0xFF1A1A1A), emoji: '📏'),
                  SizedBox(height: r.h(10)),
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
                  SizedBox(height: r.h(12)),
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
                  SizedBox(height: r.h(12)),
                  Container(
                    padding: EdgeInsets.all(r.w(14)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('↕', style: TextStyle(fontSize: r.sp(20))),
                        SizedBox(width: r.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.groupOrderGuideNoSizeHint,
                                  style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w700)),
                              SizedBox(height: r.h(4)),
                              Text(
                                loc.groupOrderGuideNoSizeDesc,
                                style: TextStyle(fontSize: r.sp(13), height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: r.h(20)),

                  // ─── 4. 교환·환불 정책 ───────────────────────────
                  _sheetSectionTitle(null, loc.groupOrderGuideExchangeTitle, const Color(0xFFE65100), emoji: '⚠️'),
                  SizedBox(height: r.h(10)),
                  Container(
                    padding: EdgeInsets.all(r.w(14)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.groupOrderGuideExchange1,
                            style: TextStyle(fontSize: r.sp(13), height: 1.7)),
                        Text(loc.groupOrderGuideExchange2,
                            style: TextStyle(fontSize: r.sp(13), height: 1.7)),
                        Text(loc.groupOrderSheetCancelNote,
                            style: TextStyle(fontSize: r.sp(13), height: 1.7)),
                        Text(loc.groupOrderSheetColorNote,
                            style: TextStyle(fontSize: r.sp(13), height: 1.7)),
                      ],
                    ),
                  ),
                  SizedBox(height: r.h(24)),

                  // ─── 동의 체크박스 ────────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _checked = !_checked),
                    child: Container(
                      padding: EdgeInsets.all(r.w(14)),
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
                          SizedBox(width: r.w(10)),
                          Expanded(
                            child: Text(
                              loc.groupOrderSheetAgreeBtn,
                              style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: r.h(16)),

                  // ─── 서식 작성 버튼 ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                      label: Text(loc.groupOrderSheetFillForm,
                          style: TextStyle(fontSize: r.sp(16), fontWeight: FontWeight.w800, color: Colors.white)),
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
                                    builder: (_) => GroupOrderFormScreen(
                                      product: widget.product,
                                      isBottomOrder: widget.product?.category == '하의' ||
                                          (widget.product?.subCategory.contains('타이즈') ?? false) ||
                                          (widget.product?.subCategory.contains('남성 5부') ?? false) ||
                                          (widget.product?.subCategory.contains('여성 2.5부') ?? false) ||
                                          (widget.product?.name.contains('타이즈') ?? false) ||
                                          (widget.product?.name.contains('하의') ?? false),
                                    )),
                              );
                            }
                          : null,
                    ),
                  ),
                  SizedBox(height: r.h(24)),
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
    final r = Responsive.of(context);
    return Row(
      children: [
        if (emoji != null) ...[
          Text(emoji, style: TextStyle(fontSize: r.sp(16))),
          SizedBox(width: r.w(6)),
        ] else if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          SizedBox(width: r.w(6)),
        ],
        Text(title,
            style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.w800, color: color)),
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
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.all(r.w(12)),
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
            padding: EdgeInsets.all(r.w(8)),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          SizedBox(width: r.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w800)),
                SizedBox(height: r.h(3)),
                Text(content, style: TextStyle(fontSize: r.sp(13), color: Color(0xFF555555), height: 1.5)),
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
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.all(r.w(12)),
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
            padding: EdgeInsets.all(r.w(8)),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          SizedBox(width: r.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w800)),
                SizedBox(height: r.h(3)),
                contentWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 옵션 카드 ─────────────────────────────────────────────────
  // ── 사이즈 표 ─────────────────────────────────────────────────
  Widget _sizeTable({
    required String title,
    required String emoji,
    required Color headerColor,
    required Color headerBg,
    required List<List<String>> rows,
  }) {
    final r = Responsive.of(context);
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
            padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(8)),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: r.sp(14))),
                SizedBox(width: r.w(6)),
                Text(title,
                    style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: headerColor)),
              ],
            ),
          ),
          // 헤더 행
          Container(
            color: headerColor,
            child: Row(
              children: headers.asMap().entries.map((e) {
                return Expanded(
                  flex: e.key == 0 ? 3 : 3,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: r.h(6), horizontal: r.w(4)),
                    child: Text(
                      e.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: r.sp(10), fontWeight: FontWeight.w700, color: Colors.white),
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
                  final r = Responsive.of(context);

                  return Expanded(
                    flex: cell.key == 0 ? 3 : 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: r.h(5), horizontal: r.w(4)),
                      child: Text(
                        cell.value,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
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
          SizedBox(height: r.h(2)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 탑텐 탭바 Sticky Header Delegate
// ══════════════════════════════════════════════════════════════
class _ToptenTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  const _ToptenTabBarDelegate(this.tabBar);

  @override
  double get minExtent => 46.0;
  @override
  double get maxExtent => 46.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return tabBar;
  }

  @override
  bool shouldRebuild(_ToptenTabBarDelegate oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════
// 섹션 이미지 가로 슬라이더 위젯 (2장 이상일 때 사용)
// ══════════════════════════════════════════════════════════════
class _SectionImageSliderWidget extends StatefulWidget {
  final List<String> imgs;
  final void Function(int index)? onTap; // 탭 → 라이트박스 콜백
  const _SectionImageSliderWidget({required this.imgs, this.onTap});

  @override
  State<_SectionImageSliderWidget> createState() => _SectionImageSliderWidgetState();
}

class _SectionImageSliderWidgetState extends State<_SectionImageSliderWidget> {
  late final PageController _ctrl;
  int _idx = 0;
  // 첫 이미지 로드 후 측정된 높이 (null = 아직 로드 중)
  double? _measuredHeight;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    // 첫 번째 이미지의 실제 높이를 미리 측정
    _measureFirstImageHeight();
  }

  void _measureFirstImageHeight() {
    if (widget.imgs.isEmpty) return;
    final img = NetworkImage(widget.imgs.first);
    img.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        if (!mounted) return;
        final imageW = info.image.width.toDouble();
        final imageH = info.image.height.toDouble();
        if (imageW <= 0) return;
        // 이미지의 실제 비율(높이/너비)을 저장 → build()에서 w × ratio로 높이 계산
        final ratio = imageH / imageW;
        setState(() => _measuredHeight = ratio);
      }, onError: (_, __) {
        if (!mounted) return;
        setState(() => _measuredHeight = 1.25); // 에러 시 기본 비율 4:5 (=1.25) 적용
      }),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.imgs;
    return LayoutBuilder(
      builder: (_, constraints) {
        final r = Responsive.of(context);

        final w = constraints.maxWidth;
        // _measuredHeight 값은 실제로 "비율(height/width)"을 저장함
        // PageView 높이 = 너비 × 비율 (로드 전에는 기본 비율 4:5 사용)
        final ratio = _measuredHeight ?? 1.25; // 기본 비율: 4:5 (=1.25)
        final pageViewHeight = w * ratio;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 이미지 PageView — bounded height 명시 (버그 수정 핵심)
            SizedBox(
              width: w,
              height: pageViewHeight,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: imgs.length,
                onPageChanged: (i) => setState(() => _idx = i),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => widget.onTap?.call(i),
                  child: Image.network(
                    imgs[i],
                    width: w,
                    height: pageViewHeight,
                    fit: BoxFit.fitWidth,
                    errorBuilder: (_, __, ___) => SizedBox(
                      height: pageViewHeight,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 48, color: Color(0xFFCCCCCC)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── 하단 pill-dot 인디케이터 + 페이지 카운터
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(r.w(0), r.h(10), r.w(0), r.h(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // pill dots
                  ...List.generate(imgs.length, (i) {
                    final r = Responsive.of(context);

                    final active = _idx == i;
                    return GestureDetector(
                      onTap: () => _ctrl.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: EdgeInsets.symmetric(horizontal: r.w(3)),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFCCCCCC),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                  SizedBox(width: r.w(10)),
                  // 페이지 카운터 텍스트
                  Text(
                    '${_idx + 1} / ${imgs.length}',
                    style: TextStyle(
                      fontSize: r.sp(11),
                      color: Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 섹션2 일반봉제 / 심리스 탭 전환 위젯 (일반 사용자용)
// ══════════════════════════════════════════════════════════════
class _Section2FabricTabsWidget extends StatefulWidget {
  final List<String> generalImgs;
  final List<String> seamlessImgs;
  final void Function(List<String> imgs, int index) onTapGeneral;
  final void Function(List<String> imgs, int index) onTapSeamless;

  const _Section2FabricTabsWidget({
    required this.generalImgs,
    required this.seamlessImgs,
    required this.onTapGeneral,
    required this.onTapSeamless,
  });

  @override
  State<_Section2FabricTabsWidget> createState() =>
      _Section2FabricTabsWidgetState();
}

class _Section2FabricTabsWidgetState
    extends State<_Section2FabricTabsWidget> {
  // 0 = 일반봉제, 1 = 심리스
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // 일반봉제 이미지가 없고 심리스만 있으면 심리스 탭 먼저 표시
    if (widget.generalImgs.isEmpty && widget.seamlessImgs.isNotEmpty) {
      _selectedTab = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final hasGeneral  = widget.generalImgs.isNotEmpty;
    final hasSeamless = widget.seamlessImgs.isNotEmpty;

    // 두 탭 모두 이미지 없으면 숨김
    if (!hasGeneral && !hasSeamless) return const SizedBox.shrink();

    // 한 쪽만 있으면 탭 없이 해당 이미지만 표시
    if (hasGeneral && !hasSeamless) {
      return _buildImageBody(widget.generalImgs, widget.onTapGeneral);
    }
    if (!hasGeneral && hasSeamless) {
      return _buildImageBody(widget.seamlessImgs, widget.onTapSeamless);
    }

    // 양쪽 모두 있을 때 → 탭 UI
    final currentImgs = _selectedTab == 0 ? widget.generalImgs : widget.seamlessImgs;
    final currentOnTap = _selectedTab == 0 ? widget.onTapGeneral : widget.onTapSeamless;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 탭 바 ──────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _FabricTab(
                label: '일반봉제',
                icon: Icons.straighten_rounded,
                isSelected: _selectedTab == 0,
                activeColor: const Color(0xFF1565C0),
                onTap: () => setState(() => _selectedTab = 0),
              ),
              _FabricTab(
                label: '심리스',
                icon: Icons.blur_circular_rounded,
                isSelected: _selectedTab == 1,
                activeColor: const Color(0xFF6A1B9A),
                onTap: () => setState(() => _selectedTab = 1),
              ),
            ],
          ),
        ),
        // ── 탭 하단 구분선 ──
        Container(height: 1, color: const Color(0xFFEEEEEE)),
        // ── 이미지 본체 ─────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: KeyedSubtree(
            key: ValueKey(_selectedTab),
            child: _buildImageBody(currentImgs, currentOnTap),
          ),
        ),
      ],
    );
  }

  Widget _buildImageBody(
    List<String> imgs,
    void Function(List<String>, int) onTap,
  ) {
    if (imgs.isEmpty) {
      final r = Responsive.of(context);

      return Container(
        height: 120,
        color: const Color(0xFFF9F9F9),
        child: Center(
          child: Text(
            '등록된 이미지가 없습니다.',
            style: TextStyle(fontSize: r.sp(13), color: Color(0xFFAAAAAA)),
          ),
        ),
      );
    }

    if (imgs.length == 1) {
      return GestureDetector(
        onTap: () => onTap(imgs, 0),
        child: Image.network(
          imgs.first,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    return _SectionImageSliderWidget(
      imgs: imgs,
      onTap: (i) => onTap(imgs, i),
    );
  }
}

// ── 개별 탭 버튼 위젯 ───────────────────────────────────────────
class _FabricTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FabricTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: r.h(13)),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.06) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? activeColor : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeColor : const Color(0xFFAAAAAA),
              ),
              SizedBox(width: r.w(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: r.sp(13),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF999999),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
