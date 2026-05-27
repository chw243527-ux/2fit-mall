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
import '../../utils/app_localizations.dart';
import '../../services/analytics_service.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../utils/navigation_helper.dart';
import '../main_screen.dart';

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

  // ── 로컬 섹션 이미지 캐시 (관리자 업로드 시 즉시 반영) ──
  late Map<String, List<String>> _sectionImages;
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
      // Firestore 최신 sectionImages 강제 로드 (캐시 우선 → 최신 반영)
      _refreshSectionImagesFromFirestore();
    });
  }

  /// Firestore에서 최신 상품 데이터를 가져와 sectionImages를 갱신
  /// (앱 첫 진입 시 1회만 실행 – 관리자가 업로드한 이미지를 일반 사용자에게 즉시 반영)
  Future<void> _refreshSectionImagesFromFirestore() async {
    if (_sectionImagesLoaded) return; // 이미 로드됐으면 skip (업로드/삭제 후 덮어쓰기 방지)
    try {
      final fresh = await ProductService.getProductByIdFresh(widget.product.id);
      if (fresh == null || !mounted) return;
      _sectionImagesLoaded = true;
      final freshImages = fresh.sectionImages;
      bool changed = false;
      // Firestore에 있는 키만 반영
      for (final key in freshImages.keys) {
        final newList = freshImages[key]!;
        _sectionImages[key] = List<String>.from(newList);
        changed = true;
      }
      // Firestore에서 삭제된 키 제거
      _sectionImages.keys.toList().forEach((key) {
        if (!freshImages.containsKey(key)) {
          _sectionImages.remove(key);
          changed = true;
        }
      });
      if (changed && mounted) setState(() {});
    } catch (_) {
      _sectionImagesLoaded = true; // 실패해도 재시도 방지
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
    final isAdmin = context.watch<UserProvider>().isAdmin;

    // ProductProvider를 watch → 상품 기본 정보(가격, 이름 등) 변경 시 즉시 반영
    // ⚠️ _sectionImages는 build()에서 절대 덮어쓰지 않음
    //    (덮어쓰면 업로드/삭제 직후 setState가 무효화됨)
    final productProvider = context.watch<ProductProvider>();
    final liveProduct = productProvider.products
        .firstWhere((p) => p.id == widget.product.id, orElse: () => widget.product);
    final product = liveProduct;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // PC/모바일 모두 전체 너비 사용 (좌우 여백 없음)
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── 콘텐츠: 전체 너비 ──
          CustomScrollView(
            controller: _scrollCtrl,
            cacheExtent: 1200,
            slivers: [
              // ① 앱바
              _buildSliverAppBarOnly(product),
              // ② 이미지 슬라이더 + 썸네일 바
              SliverToBoxAdapter(child: _buildImageSlider(product)),
              SliverToBoxAdapter(child: _buildThumbnailBar(product)),
              // ③ 기본정보 (브랜드명/상품명/별점/가격/색상/시즌/해시태그/배송비/포인트)
              SliverToBoxAdapter(child: _buildBasicInfo(product)),
              // ④ 두꺼운 회색 구분선 + 브랜드 로고 섹션
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 8, color: Color(0xFFF5F5F5), thickness: 8),
                    _buildToptenBrandSection(product),
                    const Divider(height: 8, color: Color(0xFFF5F5F5), thickness: 8),
                  ],
                ),
              ),
              // ⑤ 탭바 (sticky — 스크롤해도 앱바 바로 아래 고정)
              SliverPersistentHeader(
                pinned: true,
                delegate: _ToptenTabBarDelegate(_buildToptenTabBar()),
              ),
              // ⑥ 영문 대제목 + 메인 상품 이미지 배너
              SliverToBoxAdapter(child: _buildMobileDesignImageBanner(product)),
              // ⑦ INFO / PRODUCT / MATERIAL / COLOR 블록
              SliverToBoxAdapter(child: KeyedSubtree(key: _keyInfo, child: _buildToptenInfoSection(product))),
              // ⑧ 어드민 업로드 섹션 이미지들
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection1Banner(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection2Material(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection3Pocket(product, isAdmin))),
              SliverToBoxAdapter(child: RepaintBoundary(child: _buildSection5GoljiColors(product, isAdmin))),
              // ⑨ 사이즈 차트
              SliverToBoxAdapter(child: RepaintBoundary(key: _keySize, child: _buildSection6SizeChart(product, isAdmin))),
              // ⑩ WASHING TIP
              SliverToBoxAdapter(child: KeyedSubtree(key: _keyWashing, child: _buildWashingTipSection(product))),
              // ⑪ 리뷰 섹션 (최하단)
              SliverToBoxAdapter(child: RepaintBoundary(key: _keyReview, child: _buildReviewSection(product))),
              // 하단 여백
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // ── 하단 구매 버튼 ──
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomBar(product),
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
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      leading: Container(
        margin: const EdgeInsets.all(8),
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
          margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        ),
      ],
    );
  }

  // 앱바 원형 아이콘 버튼 헬퍼
  Widget _appBarIconBtn({required IconData icon, required VoidCallback onTap, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.only(right: 2, top: 8, bottom: 8),
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
    final imgCount = product.images.isNotEmpty ? product.images.length : 1;

    // LayoutBuilder로 실제 부모 너비 기준 → PC/태블릿/모바일 모두 자동 대응
    return LayoutBuilder(
      builder: (_, constraints) {
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
              final url = product.images.isNotEmpty ? product.images[i] : '';
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_mainImageIndex + 1} / $imgCount',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
      }, // LayoutBuilder builder
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

  // ══ 모바일: 메인이미지 아래 디자인 이미지 배너 ══
  Widget _buildMobileDesignImageBanner(ProductModel product) {
    final designImgs = _sectionImages['design'] ?? [];
    if (designImgs.isEmpty) return const SizedBox.shrink();

    // 풀너비 이미지 세로 스택
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 풀너비 이미지 세로 스택
        ...designImgs.asMap().entries.map((entry) {
          final i = entry.key;
          final url = entry.value;
          return GestureDetector(
            onTap: () => _showDesignLightbox(designImgs, i),
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: const Color(0xFFEEEEEE),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 40, color: Color(0xFFCCCCCC)),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ══ 탑텐 스타일: 썸네일 바 (심플 정사각형, 선택 시 검정 테두리) ══
  Widget _buildThumbnailBar(ProductModel product) {
    if (product.images.length <= 1) return const SizedBox.shrink();
    return Container(
      height: 78,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: product.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
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
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F8FF),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
          ),
          child: Text(
            matched[1],
            style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.w600),
          ),
        ),
        if (matched.length > 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
            ),
            child: Text(
              matched[2],
              style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // 기본 정보 (탑텐 스타일)
  // ═══════════════════════════════════════
  Widget _buildBasicInfo(ProductModel product) {
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildDesignImageSection(product, isAdmin),
          ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: PAYBACK / 특별사이즈 탭 버튼
          // ═══════════════════════════════════════════════
          if (!product.isGroupOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                _toptenTabChip('PAYBACK', true),
                const SizedBox(width: 8),
                _toptenTabChip('단체주문', product.isGroupOnly),
              ]),
            ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 브랜드명 > + 공유 버튼
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: const Row(
                    children: [
                      Text(
                        '2FIT KOREA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 2),
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
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 소제목
                Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // 상품명 대제목
                Text(
                  product.localizedName(_lang),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GestureDetector(
              onTap: () {},
              child: Row(children: [
                const Icon(Icons.star_rounded, size: 15, color: Color(0xFF1A1A1A)),
                const SizedBox(width: 3),
                Text(
                  product.rating > 0 ? product.rating.toStringAsFixed(1) : '4.8',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(width: 4),
                Text(
                  '리뷰 ${product.reviewCount > 0 ? product.reviewCount : 0}건',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF888888), fontWeight: FontWeight.w500),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF888888)),
              ]),
            ),
          ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 가격 영역 (파란 할인율 + 현재가 + 취소선)
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1976D2),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 현재가
                      Text(
                        '${_fmt(product.price)}${loc.wonUnit}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 취소선 원가
                      Text(
                        '${_fmt(product.originalPrice!)}',
                        style: const TextStyle(
                          fontSize: 14,
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
                    style: const TextStyle(
                      fontSize: 22,
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
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            _buildToptenColorSection(product),
          ],

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 시즌 | 상품번호
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Text(
              '시즌 : SS26  |  상품번호 : ${product.productCode.isNotEmpty ? product.productCode.toUpperCase() : product.id.toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w400),
            ),
          ),

          // ═══════════════════════════════════════════════
          // 탑텐 스타일: 해시태그 칩
          // ═══════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              _hashtagChip('#2fit'),
              _hashtagChip('#스포츠웨어'),
              if (product.isFreeShipping) _hashtagChip('#무료배송'),
              if (product.isNew) _hashtagChip('#신상품'),
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
  Widget _toptenTabChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : const Color(0xFF888888),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ── 탑텐 스타일: 색상 원형 그리드 선택 UI ──
  Widget _buildToptenColorSection(ProductModel product) {
    // 색상명 → Color 매핑
    final colorMap = {
      'Black': const Color(0xFF1A1A1A), '블랙': const Color(0xFF1A1A1A),
      'White': const Color(0xFFF8F8F8), '화이트': const Color(0xFFF8F8F8),
      'Navy': const Color(0xFF1B3055), '네이비': const Color(0xFF1B3055),
      'Gray': const Color(0xFF9E9E9E), '그레이': const Color(0xFF9E9E9E),
      'Red': const Color(0xFFD32F2F), '레드': const Color(0xFFD32F2F),
      'Blue': const Color(0xFF1565C0), '블루': const Color(0xFF1565C0),
      'Pink': const Color(0xFFE91E8C), '핑크': const Color(0xFFE91E8C),
      'Purple': const Color(0xFF7B1FA2), '퍼플': const Color(0xFF7B1FA2),
      'Sky Blue': const Color(0xFF29B6F6), '스카이블루': const Color(0xFF29B6F6),
      'Yellow': const Color(0xFFFBC02D), '옐로우': const Color(0xFFFBC02D),
      'Green': const Color(0xFF388E3C), '그린': const Color(0xFF388E3C),
      'Brown': const Color(0xFF795548), '브라운': const Color(0xFF795548),
      'Beige': const Color(0xFFD7CCC8), '베이지': const Color(0xFFD7CCC8),
      'K': const Color(0xFF1A1A1A), 'PP': const Color(0xFFF8F8F8),
      '블랙': const Color(0xFF1A1A1A), '화이트': const Color(0xFFF8F8F8),
    };

    String _selectedColor = product.colors.isNotEmpty ? product.colors.first : '';

    return StatefulBuilder(builder: (ctx, setSt) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 색상 라벨 + 선택된 색상명
            Row(children: [
              const Text('색상', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const SizedBox(width: 10),
              Text(
                _selectedColor,
                style: const TextStyle(fontSize: 13, color: Color(0xFF888888), fontWeight: FontWeight.w400),
              ),
            ]),
            const SizedBox(height: 12),
            // 원형 색상 버튼 그리드 (5개씩)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: product.colors.map((colorName) {
                final isSelected = _selectedColor == colorName;
                final dotColor = colorMap[colorName] ?? const Color(0xFFCCCCCC);
                final isLight = dotColor.computeLuminance() > 0.7;
                return GestureDetector(
                  onTap: () => setSt(() => _selectedColor = colorName),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // 선택된 색상: 외부 테두리 링
                      border: isSelected
                          ? Border.all(color: const Color(0xFF1A1A1A), width: 2)
                          : Border.all(color: isLight ? const Color(0xFFDDDDDD) : Colors.transparent, width: 1),
                      // 선택된 경우 내부 여백을 위해 padding처럼 처리
                    ),
                    padding: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  // ── 탑텐 스타일: 해시태그 칩 ──
  Widget _hashtagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF555555), fontWeight: FontWeight.w400),
      ),
    );
  }

  // ── 탑텐 스타일: 배송비 + 포인트 구조형 섹션 ──
  Widget _buildToptenShippingSection(ProductModel product) {
    return Column(children: [
      // 배송비 행
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 44,
              child: Text('배송비', style: TextStyle(fontSize: 13, color: Color(0xFF888888), fontWeight: FontWeight.w500)),
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
                      fontSize: 13,
                      color: product.isFreeShipping ? const Color(0xFF2E7D32) : const Color(0xFF1A1A1A),
                      fontWeight: product.isFreeShipping ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  if (!product.isFreeShipping)
                    const Text(
                      '(도서산간 배송시 3,000원 추가)',
                      style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
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
      final isWish = up.isInWishlist(product.id);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // 브랜드 로고 — logo_2fit_text.png 이미지
          SizedBox(
            width: 90,
            height: 40,
            child: Image.asset(
              'assets/images/logo_2fit_text.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, __, ___) => const Text(
                '2FIT',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 브랜드명 텍스트
          GestureDetector(
            onTap: () {},
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2FIT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), letterSpacing: -0.3)),
                Text('2FIT KOREA', style: TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w400, letterSpacing: 0.5)),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w500),
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
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Column(children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
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
    final productCode = product.productCode.isNotEmpty
        ? product.productCode.toUpperCase()
        : product.id.toUpperCase();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 상단 구분선
          Container(height: 1, color: const Color(0xFFE8E8E8)),

          const SizedBox(height: 8),

          // ── INFO 블록: 제품 설명
          _toptenInfoBlock(
            num: '01',
            label: 'INFO',
            labelSub: '제품 설명',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.localizedDescription(_lang),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
                    height: 1.85,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // ── PRODUCT 블록: 제품 기본 정보 테이블
          _toptenInfoBlock(
            num: '02',
            label: 'PRODUCT',
            labelSub: '제품 기본 정보',
            content: _toptenInfoTable([
              ('제품명', product.localizedName(_lang)),
              if (product.subCategory.isNotEmpty) ('분류', product.subCategory),
              ('상품코드', productCode),
              ('시즌', 'SS26'),
            ]),
          ),

          // ── MATERIAL 블록: 소재 정보
          if (product.material != null && product.material!.isNotEmpty)
            _toptenInfoBlock(
              num: '03',
              label: 'MATERIAL',
              labelSub: '소재 정보',
              content: Text(
                product.material!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF444444),
                  height: 1.85,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

          // ── COLOR 블록: 색상 정보
          _toptenInfoBlock(
            num: product.material != null && product.material!.isNotEmpty ? '04' : '03',
            label: 'COLOR',
            labelSub: '색상 라인업',
            content: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: product.colors.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  color: Colors.white,
                ),
                child: Text(
                  c.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                    letterSpacing: 0.5,
                  ),
                ),
              )).toList(),
            ),
            isLast: true,
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 분리선
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 1,
          color: const Color(0xFFE0E0E0),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: content,
        ),
        if (isLast) const SizedBox(height: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFE0E0E0))),
                    color: Color(0xFFF5F5F5),
                  ),
                  child: Text(
                    row.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                // 값 셀
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 11,
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

          const SizedBox(height: 8),

          // ── 세탁 가이드 아이콘 그리드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
              childAspectRatio: 1.15,
              children: washGuide.map((g) => Container(
                color: const Color(0xFFF2F2F2),
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(g.$1, size: 22, color: const Color(0xFF333333)),
                    const SizedBox(height: 8),
                    Text(
                      g.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      g.$3,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF888888),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ── WASHING TIP 상세 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 팁 리스트
                ..._washingTips.asMap().entries.map((entry) {
                  final tip = entry.value;
                  final isLast = entry.key == _washingTips.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('·', style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFBBBBBB),
                              height: 1.2,
                            )),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(
                                  fontSize: 12,
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

                const SizedBox(height: 20),

                // ── 하단 주의사항 박스 (탑텐 스타일: 검정 좌측 라인)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    border: Border(
                      left: BorderSide(color: Color(0xFF1A1A1A), width: 2),
                    ),
                  ),
                  child: const Text(
                    '재고는 조기 소진될 수 있으며, 소비자 부주의로 인한 제품 손상은 보상이 되지 않으므로 위의 세탁 방법을 반드시 준수 바랍니다.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.65),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 탑텐 스타일: 섹션 내 소타이틀 (기존 _infoBlockTitle 대체)
  Widget _infoBlockTitle(String title) {
    return Row(
      children: [
        Container(width: 12, height: 1.5, color: const Color(0xFF1A1A1A)),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w500, letterSpacing: 0.1),
            ),
          ),
          Container(width: 1, height: 14, color: const Color(0xFFDDDDDD), margin: const EdgeInsets.only(top: 1, right: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF222222), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── 탑텐 스타일: 태그 위젯 ──
  Widget _toptenTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // ── 탑텐 스타일: 배송/혜택 정보 심플 라인형 ──
  Widget _buildToptenShippingInfo(ProductModel product) {
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
        final r = entry.value;
        final isHighlight = r['highlight'] as bool;
        final isLast = entry.key == items.length - 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
              Icon(r['icon'] as IconData, size: 15, color: isHighlight ? const Color(0xFF2E7D32) : const Color(0xFF999999)),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: Text(
                  r['label'] as String,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Text(
                  r['value'] as String,
                  style: TextStyle(
                    fontSize: 12,
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
  // ignore: unused_element
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

  // ── 원단 타입 선택 버튼 (일반원단 / 심리스) ──
  Widget _fabricTypeBtn(String type, String subLabel, IconData icon) {
    final sel = _selectedFabricType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFabricType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
              const SizedBox(height: 6),
              Text(
                type,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: sel ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
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

          // ── 기성품 원단 선택 버튼 (일반원단 / 심리스) ──
          if (!product.isGroupOnly) ...[
            const SizedBox(height: 4),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            Text('원단 선택',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Row(children: [
              _fabricTypeBtn('일반원단', '기본 기능성 원단', Icons.layers_outlined),
              const SizedBox(width: 8),
              _fabricTypeBtn('심리스', '봉제선 없는 심리스', Icons.auto_awesome_outlined),
            ]),
            const SizedBox(height: 10),
          ],

          // ── 구매방식 버튼: 단체주문 전용 → 단체주문 1개, 기성품 → 기성품 1개 ──
          if (product.isGroupOnly) ...[
            GestureDetector(
              onTap: () => _showGroupOrderGuide(product),
              child: Container(
                width: double.infinity,
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
          ] else ...[
            GestureDetector(
              onTap: () => _showBuyNowSheet(product),
              child: Container(
                width: double.infinity,
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
          ],

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
  // ── 기본 하의길이 참조 이미지 (이미지 미등록 시 fallback) ──
  static const String _defaultMaleLengthImg =
      'https://firebasestorage.googleapis.com/v0/b/fit-mall.firebasestorage.app/o/section_images%2Flength_male_default.jpg?alt=media';
  static const String _defaultFemaleLengthImg =
      'https://firebasestorage.googleapis.com/v0/b/fit-mall.firebasestorage.app/o/section_images%2Flength_female_default.jpg?alt=media';

  Widget _buildGenderLengthImageSection(bool isAdmin) {
    // 통합 키 's2_length' 하나로 관리 (남녀 구분 없음)
    final imgs = _sectionImages['s2_length'] ?? [];
    // 기존 남자키 데이터도 폴백으로 사용
    final legacyMale = _sectionImages['s2_length_male'] ?? [];
    final effectiveImgs = imgs.isNotEmpty
        ? imgs
        : (legacyMale.isNotEmpty ? legacyMale : [_defaultMaleLengthImg]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin) ...[
          // 관리자: 단일 업로드 섹션
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
          const SizedBox(height: 10),
          _buildAdminImageSection('s2_length', '하의길이 참조 이미지', isAdmin),
        ] else ...[
          // 일반 유저: 이미지만 표시
          _buildStaticImageList(effectiveImgs),
        ],
      ],
    );
  }

  // ── 정적 이미지 리스트 (fallback 포함) ──
  Widget _buildStaticImageList(List<String> imgs) {
    if (imgs.isEmpty) return const SizedBox.shrink();
    return Column(
      children: imgs.map((url) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
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
                          // loadingBuilder 제거 → 배경색이 placeholder 역할, 텍스트 즉시 표시
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
                // loadingBuilder 제거 → 배경색이 placeholder 역할, 텍스트 즉시 표시
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

  // ── 파일 선택 → Base64 변환 → 자동 저장 ──
  Future<void> _pickAndUploadImages(
      String sectionKey, String sectionLabel, List<String> existingImgs) async {
    final picker = ImagePicker();

    // 1) 이미지 선택
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 12),
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
          const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 12),
          Text('${pickedFiles.length}장 업로드 중... (잠시 기다려 주세요)'),
        ]),
        duration: const Duration(seconds: 120),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );

    try {
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
            const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
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
            const SizedBox(width: 10),
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
  // 섹션 1: PERFORMANCE — 탑텐 스타일 모노크롬 특징 리스트
  // ═══════════════════════════════════════════════════════════
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
    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 영문 서브 태그
                Text(
                  engSub,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.45),
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 4),
                // 영문 대제목
                Text(
                  engTitle,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                // 한글 설명
                Text(
                  korSub,
                  style: TextStyle(
                    fontSize: 11,
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
    final features = [
      {'tag': 'ULTRA LIGHT',      'title': loc.feat1Title, 'desc': loc.feat1Desc},
      {'tag': 'SEAMLESS',         'title': loc.feat2Title, 'desc': loc.feat2Desc},
      {'tag': 'A-TYPE RACERBACK', 'title': loc.feat3Title, 'desc': loc.feat3Desc},
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
        // ── 섹션1 어드민 이미지 (풀너비, 이미지가 있으면 표시)
        if (isAdmin || (_sectionImages['s1'] ?? []).isNotEmpty)
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(0, isAdmin ? 12 : 0, 0, 0),
            child: isAdmin
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildAdminImageSection('s1', '섹션1 메인 배너', isAdmin),
                  )
                : Column(
                    children: (_sectionImages['s1'] ?? []).map((url) =>
                      Image.network(url, width: double.infinity, fit: BoxFit.fitWidth,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                    ).toList(),
                  ),
          ),
        // ── 특징 리스트: 탑텐 스타일 (분리선 + 영문 태그 + 제목 + 설명)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: features.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 번호
                        SizedBox(
                          width: 28,
                          child: Text(
                            '0${i + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFCCCCCC),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 영문 태그
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF1A1A1A)),
                                ),
                                child: Text(
                                  f['tag']!,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 제목
                              Text(
                                f['title']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // 설명
                              Text(
                                f['desc']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF777777),
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
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

  // ═══════════════════════════════════════════════════════════
  // 섹션 2: MATERIAL — 탑텐 스타일 소재/기술 + 섬유 혼용율 표
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection2Material(ProductModel product, bool isAdmin) {
    final fiberTable = loc.fiberTableData;
    final techRows = [
      {'label': 'SEAMLESS', 'desc': loc.feat2Title, 'sub': loc.feat2Desc},
      {'label': 'FAST DRY',  'desc': loc.techDryTitle,  'sub': loc.techDryDesc},
      {'label': 'MOISTURE',  'desc': loc.techAbsorbTitle,'sub': loc.techAbsorbDesc},
    ];

    // 싱글렛/싱글렛세트 카테고리 판별
    final isSingletProduct =
        product.category.contains('싱글렛') ||
        product.subCategory.contains('싱글렛') ||
        product.name.contains('싱글렛') ||
        (product.category == '상의' &&
            (product.subCategory.contains('싱글렛') || product.name.contains('singlet')));
    // 싱글렛 상의 소재 행 (폴리에스터 92% / 라이크라 8%)
    final singletTopRow = _getSingletTopFiberRow();

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
        // ── 섹션2 어드민 이미지
        if (isAdmin || (_sectionImages['s2'] ?? []).isNotEmpty)
          isAdmin
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildAdminImageSection('s2', '섹션2 소재 및 기술', isAdmin),
                )
              : Column(
                  children: (_sectionImages['s2'] ?? []).map((url) =>
                    Image.network(url, width: double.infinity, fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ).toList(),
                ),


        // ── 기술 특징 리스트 (분리선)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: techRows.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const Divider(height: 1, color: Color(0xFFE8E8E8)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text('0${i + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                                color: Color(0xFFCCCCCC), letterSpacing: 1)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF555555))),
                                child: Text(t['label']!,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                      color: Color(0xFF555555), letterSpacing: 1.2)),
                              ),
                              const SizedBox(height: 8),
                              Text(t['desc']!,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A), height: 1.3)),
                              const SizedBox(height: 5),
                              Text(t['sub']!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF777777),
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

        // ── 소재혼용율 위 이미지
        if (isAdmin || (_sectionImages['s2_fiber'] ?? []).isNotEmpty)
          isAdmin
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _buildAdminImageSection('s2_fiber', '소재혼용율 이미지', isAdmin),
                )
              : Column(
                  children: (_sectionImages['s2_fiber'] ?? []).map((url) =>
                    Image.network(url, width: double.infinity, fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ).toList(),
                ),

        // ── 섬유 혼용율 표 (탑텐 스타일: 검정 헤더 + 흰 배경 + 검정 구분선)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 표 제목
              const Text('FABRIC COMPOSITION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A), letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(loc.productFabricCompositionNote,
                style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
              const SizedBox(height: 16),
              // 표
              Container(
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDDDDD))),
                child: Column(
                  children: [
                    // 헤더행
                    Container(
                      color: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(flex: 5, child: Text(loc.fiberCategory,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
                          Expanded(flex: 4, child: Text(loc.fiberMainMaterial,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                            textAlign: TextAlign.center)),
                          Expanded(flex: 3, child: Text(loc.fiberMix,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                            textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    // 싱글렛/싱글렛세트: 상의 소재 행 강조 표시 (최상단)
                    if (isSingletProduct && singletTopRow != null)
                      Container(
                        color: const Color(0xFFFFF8E1),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(flex: 5, child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6F00),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text('상의', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                                ),
                                Flexible(child: Text(singletTopRow[0],
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF333333), fontWeight: FontWeight.w600))),
                              ],
                            )),
                            Expanded(flex: 4, child: Text(singletTopRow[1],
                              style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center)),
                            Expanded(flex: 3, child: Text(singletTopRow[2],
                              style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                    // 데이터행
                    ...fiberTable.asMap().entries.map((e) {
                      final row = e.value;
                      final even = e.key % 2 == 0;
                      return Container(
                        color: even ? Colors.white : const Color(0xFFF8F8F8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(flex: 5, child: Text(row[0],
                              style: const TextStyle(fontSize: 11, color: Color(0xFF333333)))),
                            Expanded(flex: 4, child: Text(row[1],
                              style: const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center)),
                            Expanded(flex: 3, child: Text(row[2],
                              style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                              textAlign: TextAlign.center)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 섹션 3: POCKET SYSTEM — 탑텐 스타일 기능 리스트
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection3Pocket(ProductModel product, bool isAdmin) {
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
        // ── 섹션3 어드민 이미지
        if (isAdmin || (_sectionImages['s3'] ?? []).isNotEmpty)
          isAdmin
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildAdminImageSection('s3', '섹션3 포켓 특성', isAdmin),
                )
              : Column(
                  children: (_sectionImages['s3'] ?? []).map((url) =>
                    Image.network(url, width: double.infinity, fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ).toList(),
                ),


        // ── 포켓 기능 리스트
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: pockets.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text('0${i + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                                color: Color(0xFFCCCCCC), letterSpacing: 1)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1A1A1A))),
                                child: Text(p['tag']!,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A1A), letterSpacing: 1.2)),
                              ),
                              const SizedBox(height: 8),
                              Text(p['title']!,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A), height: 1.3)),
                              const SizedBox(height: 5),
                              Text(p['desc']!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF777777),
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

    // ═══════════════════════════════════════════════════════════
  // 섹션 5: COLOR LINE — 탑텐 스타일 컬러 차트
  // ═══════════════════════════════════════════════════════════
  Widget _buildSection5GoljiColors(ProductModel product, bool isAdmin) {
    // ── 섹션5 컬러 데이터
    final goljiColors = [
      {'code': 'K',  'name': '블랙',       'hex': 0xFF1A1A1A},
      {'code': 'N',  'name': '네이비',      'hex': 0xFF0D1B4F},
      {'code': 'W',  'name': '화이트',      'hex': 0xFFF5F5F5},
      {'code': 'G',  'name': '그레이',      'hex': 0xFF9E9E9E},
      {'code': 'DG', 'name': '다크그레이',  'hex': 0xFF424242},
      {'code': 'SB', 'name': '스카이블루',  'hex': 0xFF90CAF9},
      {'code': 'B',  'name': '블루',        'hex': 0xFF1A4DB3},
      {'code': 'DB', 'name': '다크블루',    'hex': 0xFF2C3D6E},
      {'code': 'SP', 'name': '스킨핑크',    'hex': 0xFFE8C8C0},
      {'code': 'LP', 'name': '라이트핑크',  'hex': 0xFFE8A8B0},
      {'code': 'IO', 'name': '아이보리',    'hex': 0xFFD4CFC4},
      {'code': 'LG', 'name': '라이트그레이','hex': 0xFFBDBDBD},
      {'code': 'R',  'name': '레드',        'hex': 0xFFCC1111},
      {'code': 'PP', 'name': '퍼플네이비',  'hex': 0xFF1B1B3A},
      {'code': 'ND', 'name': '올리브그린',  'hex': 0xFF4A5240},
      {'code': 'BB', 'name': '틸블루',      'hex': 0xFF0F6B7A},
      {'code': 'FP', 'name': '형광핑크',    'hex': 0xFFFF1493},
      {'code': 'FO', 'name': '형광오렌지',  'hex': 0xFFFF6600},
      {'code': 'FG', 'name': '형광그린',    'hex': 0xFF88EE00},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 섹션5 어드민 이미지
        if (isAdmin || (_sectionImages['s5'] ?? []).isNotEmpty)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildAdminImageSection('s5', '섹션5 골지 원단 색상', isAdmin),
          ),

        // ── 골지 색상 차트 (이전 스타일 유지)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        '${reviews.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              if (avg > 0) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
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
                                  color: i < avg.floor()
                                      ? const Color(0xFFFFD600)
                                      : const Color(0xFFE0E0E0))),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '${reviews.length}개 리뷰',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              const SizedBox(height: 4),
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

  // 예시 리뷰 제거됨 - 실제 회원 리뷰만 표시

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
  // 하단 바 (탑텐 스타일)
  // ═══════════════════════════════════════════════════════════
  Widget _buildBottomBar(ProductModel product) {
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
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
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_shopping_cart_outlined, size: 15, color: Color(0xFFAAAAAA)),
                              SizedBox(width: 6),
                              Text('현재 품절된 상품입니다', style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.notifications_active_rounded, size: 17, color: Colors.white),
                            label: const Text('재입고 알림 신청', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
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
                                const SizedBox(height: 1),
                                Text(
                                  wishCount.toString(),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // 구매하기 풀버튼 (탑텐: 검정 배경 + 큰 텍스트)
                    Expanded(
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
                          child: const Text(
                            '구매하기',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
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
                    // A타입(레이서백) 카드 제거 → B타입(스쿱넥)만 표시
                    Row(
                      children: [
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
          title: const Row(children: [
            Icon(Icons.notifications_active_rounded, color: Color(0xFF1565C0), size: 22),
            SizedBox(width: 8),
            Text('재입고 알림 신청 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${product.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text('재입고 시 ${email.isNotEmpty ? email : '등록된 연락처'}로 알림을 보내드립니다.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.5)),
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
  // ── 탑텐 스타일 섹션 헤더: 얇은 상단 라인 + 영문 대제목 + 한글 서브 ──
  // _sectionHeader: 검정 포인트 라인만 표시 (텍스트 제거)
  Widget _sectionHeader(String num, String title, String sub) =>
      Container(width: 28, height: 2, color: const Color(0xFF1A1A1A));

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
  // ignore: unused_element
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
                child: widget.images[i].startsWith('data:image')
                    ? Image.memory(
                        base64Decode(widget.images[i].split(',').last),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white54,
                            size: 80),
                      )
                    : Image.network(
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
  // ignore: unused_element
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
      widget.product.subCategory.contains('반바지') ||
      widget.product.subCategory.contains('숏츠') ||
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
        widget.product.subCategory.contains('주니어');
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
            final selHex = found['hex'] as int;
            final selColor = Color(selHex);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text(loc.selectedLabel,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
                const SizedBox(width: 6),
                RibColorSwatch(
                  color: selColor,
                  size: 20,
                  isSelected: true,
                  accentColor: const Color(0xFF1A1A1A),
                  isLight: selColor.computeLuminance() > 0.5,
                  borderRadius: 4,
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
  // ignore: unused_element
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
  // ignore: unused_element
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
