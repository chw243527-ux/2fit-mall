import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/net_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
// ignore: unused_import
import '../main_screen.dart' show kPcBreakpoint;
import '../../widgets/video_banner_widget.dart';
import '../../widgets/pc_layout.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/wishlist_coupon_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/product_card.dart';
import '../products/product_list_screen.dart';
import '../products/product_detail_screen.dart';
import '../products/category_detail_screen.dart';
import '../orders/group_order_landing_screen.dart';
import '../orders/group_order_only_screen.dart';
import '../orders/order_guide_screen.dart';
import '../admin/admin_screen.dart';
import '../../services/analytics_service.dart';
import '../chat/chat_screen.dart';
import '../../widgets/app_drawer.dart';
import '../notifications/notification_center_screen.dart';
import '../../services/fcm_service.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final void Function(int index)? onNavigate; // 탭 이동 콜백
  const HomeScreen({super.key, this.scaffoldKey, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;

  /// 상품명: Firestore 번역 있으면 사용, 없으면 loc.t()로 런타임 번역 등록
  String _pName(ProductModel p) {
    final translated = p.localizedName(_lang);
    if (translated != p.name) return translated;
    return loc.t('product_name_\${p.id}', p.name);
  }

  int _bannerIndex = 0;
  String _selectedCategoryKey = 'all'; // 카테고리 key (언어 무관)
  String? _expandedCatName; // 사이드바 펼쳐진 카테고리 이름
  late AnimationController _chatPulse;

  // ── 배너 자동 슬라이드 ──
  final PageController _pcBannerCtrl = PageController();
  final PageController _mobileBannerCtrl = PageController();
  Timer? _bannerTimer;
  static const Duration _bannerAutoInterval = Duration(seconds: 5);

  // 카테고리 정의 (key 기반, 다국어 텍스트는 loc에서)
  List<Map<String, dynamic>> _getCategoryItems(AppLocalizations loc) => [
        {
          'key': 'all',
          'label': loc.catAll,
          'icon': Icons.grid_view_rounded,
          'color': AppColors.primary
        },
        {
          'key': '상의',
          'label': loc.catTop,
          'icon': Icons.dry_cleaning_rounded,
          'color': AppColors.primary
        },
        {
          'key': '하의',
          'label': loc.catBottom,
          'icon': Icons.style_rounded,
          'color': AppColors.primary
        },
        {
          'key': '세트',
          'label': loc.catSet,
          'icon': Icons.checkroom_rounded,
          'color': AppColors.accent
        },
        {
          'key': '아우터',
          'label': loc.catOuter,
          'icon': Icons.layers_rounded,
          'color': AppColors.primaryLight
        },
        {
          'key': '스킨슈트',
          'label': context.loc.t('스킨슈트', '스킨슈트'),
          'icon': Icons.accessibility_new_rounded,
          'color': AppColors.primary
        },
        {
          'key': '악세사리',
          'label': loc.catAccessory,
          'icon': Icons.backpack_rounded,
          'color': AppColors.primary
        },
        {
          'key': '이벤트',
          'label': context.loc.t('이벤트', '이벤트'),
          'icon': Icons.local_offer_rounded,
          'color': AppColors.accent
        },
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 언어 변경 시 번역 트리거
      context.read<LanguageProvider>().triggerTranslation();
    });
    _chatPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // 배너 자동 슬라이드 타이머 시작
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(_bannerAutoInterval, (_) {
      if (!mounted) return;
      // Firestore에서 로드된 활성 배너 수 기반으로 동적 계산
      final total = context.read<BannerProvider>().activeBanners.length;
      if (total < 2) return; // 배너가 1개 이하면 슬라이드 불필요
      final nextIndex = (_bannerIndex + 1) % total;
      // PC/모바일 둘 다 같은 인덱스로 이동
      if (_pcBannerCtrl.hasClients) {
        _pcBannerCtrl.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
      if (_mobileBannerCtrl.hasClients) {
        _mobileBannerCtrl.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pcBannerCtrl.dispose();
    _mobileBannerCtrl.dispose();
    _chatPulse.dispose();
    super.dispose();
  }

  /// 배너 CTA(btnAction==3) 클릭 시 특정 쿠폰 또는 전체 다운로드 팝업 표시
  void _showBannerCouponPopup(String? couponId) {
    final userProv = context.read<UserProvider>();
    final isPc = MediaQuery.of(context).size.width >= kPcBreakpoint;
    final popup = _BannerCouponPopup(
      userId: userProv.user?.id,
      couponId: couponId,
      isPc: isPc,
    );
    if (isPc) {
      final r = Responsive.of(context);
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        barrierDismissible: true,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              EdgeInsets.symmetric(horizontal: r.w(40), vertical: r.h(60)),
          child: popup,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (_) => popup,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final w = MediaQuery.of(context).size.width;
    // PC(≥900px): PC NavBar + 풀스크린 배너 레이아웃
    if (w >= kPcBreakpoint) return _buildPcLayout(loc);
    // 모바일(<600) + 태블릿(600~899): 모바일 기반 레이아웃
    // 태블릿은 _buildMobileLayout 내부 isMobileW 분기가 헤더 자동 처리
    return _buildMobileLayout(loc);
  }

  // ─── PC 레이아웃 (넓은 화면 최적화, PC 전용 섹션 사용) ─────────────────
  // PC 드로어용 GlobalKey
  final GlobalKey<ScaffoldState> _pcScaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildPcLayout(AppLocalizations loc) {
    final r = Responsive.of(context);
    final bannerProv = context.watch<BannerProvider>();
    final activeBanners = bannerProv.activeBanners;

    // PC TopBar 높이 (main_screen._PcTopBar 기준)
    const double kPcTopBarHeight = 64.0;

    // 배너 위젯 (뷰포트 전체 높이 — TopBar 제외)
    final bannerWidget = activeBanners.isEmpty
        ? _buildPcLocalBanner(loc)
        : _buildPcBannerBody(loc, activeBanners);

    // PC: 배너(뷰포트 전체) + 스크롤 섹션 (단체주문·베스트·신상품)
    // Scaffold/NavBar는 main_screen._PcLayout 담당 — 여기서는 반환하지 않음
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      onRefresh: () async {
        restartAllVideoBanners(); // 배너 영상 첫 프레임부터 재시작
        await context.read<ProductProvider>().refresh();
        if (mounted) setState(() {});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ① 배너: 화면 너비 기준 16:9 비율 (영상 잘림 방지)
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.width * (9 / 16),
              child: ColoredBox(
                color: Colors.black,
                child: bannerWidget,
              ),
            ),
          ),

          // ② 기성품 베스트 섹션
          SliverToBoxAdapter(
            child: _buildPcSectionMaxWidthWrapper(
              child: _buildBestSection(loc),
            ),
          ),

          // ③ 단체주문 섹션 (기성품 베스트 아래)
          SliverToBoxAdapter(
            child: _buildPcSectionMaxWidthWrapper(
              child: _buildPcGroupOrderSectionV2(loc),
            ),
          ),

          // ④ 신상품 섹션
          SliverToBoxAdapter(
            child: _buildPcSectionMaxWidthWrapper(
              child: _buildNewArrivalsSection(loc),
            ),
          ),

          // ⑤ PC 푸터
          SliverToBoxAdapter(child: _buildPcFooter(loc)),
        ],
      ),
    );
  }

  // PC NavBar 높이 상수
  static const double _kPcNavBarHeight = 64.0;

  // PC 섹션 공통 래퍼 (maxWidth 1280 + 좌우 패딩 + 배경색)
  // 단체주문처럼 자체 배경색이 없는 섹션에 사용
  Widget _buildPcHomeSectionWrapper(
      {required Widget child, Color color = Colors.white}) {
    final r = Responsive.of(context);
    return Container(
      color: color,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: r.w(32), vertical: r.h(40)),
            child: child,
          ),
        ),
      ),
    );
  }

  // PC 섹션 래퍼 (가로 스크롤 섹션용 — 베스트·신상품)
  // 섹션이 풀 너비 가로 스크롤을 사용하므로 width 제한 없이 그대로 반환
  Widget _buildPcSectionMaxWidthWrapper({required Widget child}) => child;

  // PC 단체주문 섹션 (홈용 5컬럼 그리드)
  Widget _buildPcGroupOrderSectionV2(AppLocalizations loc) {
    final pp = context.watch<ProductProvider>();
    // groupOnlyProducts 우선, 없으면 products에서 필터링
    final groupProds = (pp.groupOnlyProducts.isNotEmpty
            ? pp.groupOnlyProducts
            : pp.products.where((p) => p.isGroupOnly && p.isActive).toList())
        .where((p) => p.isActive)
        .toList()
      ..sort((a, b) => b.salesCount.compareTo(a.salesCount));

    // _buildProductSection 재사용 — 단체주문 전용 accent 색상
    return _buildProductSection(
      title: loc.homeGroupOnly,
      englishTitle: 'GROUP ORDER',
      accentColor: AppColors.primary,
      products: groupProds.take(10).toList(),
      category: '단체주문',
      viewAllLabel: loc.viewAll,
      isHorizontal: true,
    );
  }

  // ── PC 카테고리 드로어 (햄버거 버튼으로 열림) ──
  // ignore: unused_element
  Widget _buildPcCategoryDrawer(AppLocalizations loc) {
    final r = Responsive.of(context);
    return Drawer(
      width: 300,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ─── 드로어 헤더 (다크 배경) ───
          Container(
            color: AppColors.textPrimary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 8,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 카테고리 타이틀 + 닫기
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: r.w(10)),
                    Expanded(
                      child: Text(
                        loc.homeCategory,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(15),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: r.h(16)),
                // ─── 마이페이지 버튼 ───
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onNavigate?.call(3);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(14), vertical: r.h(11)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: r.w(10)),
                        Expanded(
                          child: Text(
                            loc.navMyPage,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.sp(14),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 13),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: r.h(10)),
              ],
            ),
          ),
          // ─── 전체 상품 바로가기 ───
          InkWell(
            onTap: () {
              Navigator.pop(context);
              widget.onNavigate?.call(1);
            },
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: r.w(20), vertical: r.h(14)),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.surfaceGray)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grid_view_rounded,
                        color: AppColors.textPrimary, size: 16),
                  ),
                  SizedBox(width: r.w(12)),
                  Expanded(
                    child: Text(
                      loc.homeAllProducts,
                      style: TextStyle(
                          fontSize: r.sp(14),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textHint),
                ],
              ),
            ),
          ),
          // ─── 카테고리 아코디언 목록 ───
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: getCategories(loc).map((cat) {
                  final r = Responsive.of(context);

                  final isExpanded = _expandedCatName == cat.name;
                  final subs = cat.subCategories
                      .where((s) => !s.name.startsWith('전체'))
                      .toList();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => setState(() {
                          _expandedCatName = isExpanded ? null : cat.name;
                        }),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: r.w(20), vertical: r.h(13)),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    Icon(cat.icon, color: cat.color, size: 16),
                              ),
                              SizedBox(width: r.w(12)),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: r.sp(14),
                                    fontWeight: isExpanded
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isExpanded
                                        ? cat.color
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CategoryDetailScreen(
                                          categoryName: cat.name,
                                          categoryColor: cat.color,
                                          categoryIcon: cat.icon,
                                          subCategories: cat.subCategories,
                                        ),
                                      ));
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: r.w(8), vertical: r.h(3)),
                                  decoration: BoxDecoration(
                                    color: cat.color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(loc.homeCategoryAll,
                                      style: TextStyle(
                                          fontSize: r.sp(10),
                                          fontWeight: FontWeight.w700,
                                          color: cat.color)),
                                ),
                              ),
                              SizedBox(width: r.w(8)),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: isExpanded
                                      ? cat.color
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 서브카테고리 펼침
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.03),
                            border: Border(
                              left: BorderSide(
                                  color: cat.color.withValues(alpha: 0.25),
                                  width: 3),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: r.h(6)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: subs.map((sub) {
                                final r = Responsive.of(context);

                                final isSubSel = _selectedCategoryKey ==
                                    '${cat.name}/${sub.name}';
                                return InkWell(
                                  onTap: () {
                                    setState(() => _selectedCategoryKey =
                                        '${cat.name}/${sub.name}');
                                    Navigator.pop(context);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductListScreen(
                                              initialCategory: sub.filter),
                                        ));
                                  },
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(
                                        r.w(52), r.h(10), r.w(20), r.h(10)),
                                    color: isSubSel
                                        ? cat.color.withValues(alpha: 0.07)
                                        : Colors.transparent,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSubSel
                                                ? cat.color
                                                : AppColors.border,
                                          ),
                                        ),
                                        SizedBox(width: r.w(8)),
                                        Expanded(
                                          child: Text(
                                            sub.name,
                                            style: TextStyle(
                                              fontSize: r.sp(13),
                                              fontWeight: isSubSel
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSubSel
                                                  ? cat.color
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        if (sub.tag != null)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: r.w(5),
                                                vertical: r.h(1)),
                                            decoration: BoxDecoration(
                                              color: sub.tag == 'BEST'
                                                  ? AppColors.accent
                                                  : sub.tag == 'NEW'
                                                      ? cat.color
                                                      : AppColors.accent,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              sub.tag!,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: r.sp(8),
                                                  fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      Container(height: 1, color: const Color(0xFFF3F3F3)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PC 전용 카테고리 사이드바 (아코디언) — 드로어로 대체됨 ──
  // ignore: unused_element
  Widget _buildPcCategorySidebar(AppLocalizations loc) {
    final r = Responsive.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          Container(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(16), r.w(16), r.h(12)),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceGray)),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_rounded,
                    size: 16, color: AppColors.textPrimary),
                SizedBox(width: r.w(8)),
                Expanded(
                  child: Text(
                    loc.homeCategory,
                    style: TextStyle(
                      fontSize: r.sp(13),
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(1),
                  child: Text(
                    context.loc.t('전체', '전체'),
                    style: TextStyle(
                        fontSize: r.sp(11),
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // ── 카테고리 아코디언 목록 ──
          ...getCategories(loc).map((cat) {
            final r = Responsive.of(context);

            final isExpanded = _expandedCatName == cat.name;
            final subs = cat.subCategories
                .where((s) => !s.name.startsWith('전체'))
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 카테고리 행
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedCatName = isExpanded ? null : cat.name;
                      _selectedCategoryKey = cat.name;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(14), vertical: r.h(10)),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 14),
                        ),
                        SizedBox(width: r.w(10)),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: r.sp(13),
                              fontWeight: isExpanded
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isExpanded
                                  ? cat.color
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: isExpanded ? cat.color : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 서브카테고리 펼침
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.03),
                      border: Border(
                        left: BorderSide(
                            color: cat.color.withValues(alpha: 0.3),
                            width: 2.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 전체 보기
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryDetailScreen(
                                categoryName: cat.name,
                                categoryColor: cat.color,
                                categoryIcon: cat.icon,
                                subCategories: cat.subCategories,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                r.w(40), r.h(8), r.w(14), r.h(4)),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cat.color,
                                  ),
                                ),
                                SizedBox(width: r.w(8)),
                                Text(
                                  loc.homeViewAll,
                                  style: TextStyle(
                                    fontSize: r.sp(12),
                                    fontWeight: FontWeight.w700,
                                    color: cat.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 서브카테고리 항목들
                        ...subs.map((sub) {
                          final r = Responsive.of(context);

                          final isSubSel =
                              _selectedCategoryKey == '${cat.name}/${sub.name}';
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedCategoryKey =
                                  '${cat.name}/${sub.name}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductListScreen(
                                      initialCategory: sub.filter),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                  r.w(40), r.h(7), r.w(14), r.h(7)),
                              color: isSubSel
                                  ? cat.color.withValues(alpha: 0.06)
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSubSel
                                          ? cat.color
                                          : AppColors.border,
                                    ),
                                  ),
                                  SizedBox(width: r.w(8)),
                                  Expanded(
                                    child: Text(
                                      sub.name,
                                      style: TextStyle(
                                        fontSize: r.sp(12),
                                        fontWeight: isSubSel
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isSubSel
                                            ? cat.color
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  if (sub.tag != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: r.w(4), vertical: r.h(1)),
                                      decoration: BoxDecoration(
                                        color: sub.tag == 'BEST'
                                            ? AppColors.accent
                                            : sub.tag == 'NEW'
                                                ? cat.color
                                                : AppColors.accent,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        sub.tag!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: r.sp(8),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        SizedBox(height: r.h(4)),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: AppColors.surfaceGray),
              ],
            );
          }),
          SizedBox(height: r.h(8)),
        ],
      ),
    );
  }

  // ── PC 메인 영역 상품 그리드 (4컬럼, 사이드바와 함께) ──
  // ignore: unused_element
  Widget _buildPcMainProductSection({
    required String title,
    required String englishTitle,
    required Color accentColor,
    required bool isNew,
    required AppLocalizations loc,
  }) {
    final r = Responsive.of(context);
    final provider = context.watch<ProductProvider>();
    List<ProductModel> allProds = provider.products;
    if (allProds.isEmpty) allProds = ProductService.getAllProductsSync();

    final List<ProductModel> products;
    if (isNew) {
      products = allProds.where((p) => p.isNewActive).toList();
    } else {
      products = List<ProductModel>.from(allProds)
        ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }

    if (products.isEmpty) {
      final r = Responsive.of(context);

      return Container(
        color: Colors.white,
        padding: EdgeInsets.all(r.w(20)),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  englishTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: r.sp(9),
                    fontWeight: FontWeight.w800,
                    color: accentColor == AppColors.primary
                        ? AppColors.textHint
                        : accentColor,
                    letterSpacing: 2.5,
                  ),
                ),
                SizedBox(height: r.h(3)),
                Text(title,
                    style: TextStyle(
                        fontSize: r.sp(20),
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
              ],
            ),
            const Spacer(),
            SizedBox(
                width: r.w(20),
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      );
    }

    final display = products.take(8).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(16), r.w(16), r.h(0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      englishTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: r.sp(9),
                        fontWeight: FontWeight.w800,
                        color: accentColor == AppColors.primary
                            ? AppColors.textHint
                            : accentColor,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: r.h(2)),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: r.sp(20),
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => isNew
                          ? const ProductListScreen(initialOnlyNew: true)
                          : const ProductListScreen(initialOnlyBest: true),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(12), vertical: r.h(6)),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'VIEW ALL',
                      style: TextStyle(
                          fontSize: r.sp(10),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: r.h(14)),
          // 4컬럼 그리드 — Wrap으로 카드 실제 높이 유지
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(12), r.h(0), r.w(12), r.h(16)),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                const cols = 4;
                const spacing = 10.0;
                final cardW =
                    (constraints.maxWidth - spacing * (cols - 1)) / cols;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: display
                      .map((p) => SizedBox(
                          width: cardW, child: _buildPcHomeProductCard(p)))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── PC 전용 NavBar (배너 위에 표시) ──
  // ignore: unused_element
  Widget _buildPcNavBar(AppLocalizations loc) {
    final r = Responsive.of(context);
    return Container(
      color: Colors.white,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(24)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(0),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: r.h(12)),
                    child: SizedBox(
                      height: 28,
                      child: Image.asset(
                        'assets/images/2fit_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: AppColors.textPrimary, size: 22),
                  tooltip: loc.search,
                  onPressed: () => _showSearchSheet(context, loc),
                ),
                Consumer<CartProvider>(
                  builder: (ctx, cart, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined,
                            color: AppColors.textPrimary, size: 22),
                        tooltip: loc.cart,
                        onPressed: () => widget.onNavigate?.call(2),
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle),
                            child: Center(
                                child: Text(
                                    cart.itemCount > 9
                                        ? '9+'
                                        : '${cart.itemCount}',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: r.sp(8),
                                        fontWeight: FontWeight.w900))),
                          ),
                        ),
                    ],
                  ),
                ),
                Consumer<UserProvider>(
                  builder: (ctx, userProv, _) {
                    final userId = userProv.user?.id;
                    if (userId == null) {
                      return IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: AppColors.textPrimary, size: 22),
                          onPressed: () =>
                              _showNotificationsSheet(context, loc));
                    }
                    return StreamBuilder<int>(
                      stream: FcmService.watchUnreadCount(userId),
                      builder: (ctx2, snap) {
                        final r = Responsive.of(context);

                        final unread = snap.data ?? 0;
                        return Stack(clipBehavior: Clip.none, children: [
                          IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: AppColors.textPrimary, size: 22),
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationCenterScreen()))),
                          if (unread > 0)
                            Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                        color: Color(0xFFFF0000),
                                        shape: BoxShape.circle),
                                    child: Center(
                                        child: Text(
                                            unread > 9 ? '9+' : '$unread',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: r.sp(8),
                                                fontWeight:
                                                    FontWeight.w900))))),
                        ]);
                      },
                    );
                  },
                ),
                // ── 마이페이지 버튼 (라벨 포함) ──
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(3),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: r.w(4)),
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(14), vertical: r.h(7)),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: r.w(6)),
                        Text(loc.navMyPage,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                Consumer<UserProvider>(
                  builder: (ctx, user, _) => user.isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.admin_panel_settings_rounded,
                              color: AppColors.accent, size: 22),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminScreen())))
                      : const SizedBox.shrink(),
                ),
                // ── PC 로그아웃 버튼 ──
                Consumer<UserProvider>(
                  builder: (ctx, userProv, _) {
                    if (!userProv.isLoggedIn) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.textSecondary, size: 20),
                      tooltip: context.loc.t('로그아웃', '로그아웃'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(context.loc.t('로그아웃', '로그아웃')),
                            content: Text(
                                context.loc.t('로그아웃 하시겠습니까', '로그아웃 하시겠습니까?')),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(context.loc.t('취소', '취소'))),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(context.loc.t('로그아웃', '로그아웃'),
                                    style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          await AuthService.logout();
                          if (mounted) {
                            context.read<UserProvider>().logout();
                            context.read<CartProvider>().clearCart();
                            context.read<CouponProvider>().clear();
                            context.read<PointProvider>().clear();
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── PC 전용 배너 (Firestore BannerProvider에서 실시간 로드) ──
  Widget _buildPcBannerOnly(AppLocalizations loc) {
    final bannerProv = context.watch<BannerProvider>();
    final activeBanners = bannerProv.activeBanners;

    // PC 레이아웃: NavBar(상단 고정) + 배너(나머지 공간 전체)
    return Scaffold(
      key: _pcScaffoldKey,
      backgroundColor: Colors.black,
      drawer: AppDrawer(onNavigateToMyPage: () => widget.onNavigate?.call(3)),
      body: Column(
        children: [
          // ── PC NavBar (상단 고정) ──
          _buildPcNavBar(loc),

          // ── 배너 (NavBar 아래 남은 공간 전체) ──
          Expanded(
            child: activeBanners.isEmpty
                // Firestore 로딩 중 또는 배너 없을 때 → 로컬 asset 동영상 + 텍스트 즉시 표시
                ? _buildPcLocalBanner(loc)
                : _buildPcBannerBody(loc, activeBanners),
          ),
        ],
      ),
      floatingActionButton: _buildChatFAB(loc),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── PC 배너 슬라이더 본체 (BannerModel 리스트 사용) ──
  Widget _buildPcBannerBody(AppLocalizations loc, List<BannerModel> banners) {
    final isKo = loc.language == AppLanguage.korean;
    return Stack(
      children: [
        PageView.builder(
          controller: _pcBannerCtrl,
          onPageChanged: (i) => setState(() => _bannerIndex = i),
          itemCount: banners.length,
          itemBuilder: (_, idx) {
            final r = Responsive.of(context);

            final b = banners[idx];
            final accent = Color(b.accentColor);
            // order==0 인 슬라이드는 videoUrl 우선 (없으면 이미지)
            final videoUrl = b.videoUrl?.isNotEmpty == true ? b.videoUrl : null;
            final title = isKo ? b.titleKo : b.titleEn;
            final cta = isKo ? b.ctaKo : b.ctaEn;

            // CTA 아이콘 (btnAction 기반)
            final ctaIcon = switch (b.btnAction) {
              1 => Icons.local_fire_department_rounded,
              2 => Icons.groups_rounded,
              _ => Icons.arrow_forward_rounded,
            };

            void onTap() {
              switch (b.btnAction) {
                case 1:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductListScreen(initialCategory: '전체'),
                      ));
                  break;
                case 2:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GroupOrderOnlyScreen(),
                      ));
                  break;
                case 3:
                  // 쿠폰 다운로드 팝업
                  _showBannerCouponPopup(b.couponId);
                  break;
                default:
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductListScreen(initialCategory: '전체'),
                      ));
              }
            }

            // PC 배너: 컨테이너 전체 꽉 채움 (AspectRatio 없음)
            // ── 텍스트+CTA 오버레이: 배경과 독립 레이어 → 항상 즉시 표시 ──
            final pcTextOverlay = Positioned(
              left: 60,
              bottom: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (b.tag.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: r.w(12), vertical: r.h(5)),
                      decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(3)),
                      child: Text(b.tag,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: r.sp(11),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2)),
                    ),
                  if (b.tag.isNotEmpty) SizedBox(height: r.h(16)),
                  if (title.isNotEmpty)
                    Text(title,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: r.sp(46),
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.5)),
                  if (title.isNotEmpty) SizedBox(height: r.h(24)),
                  if (cta.isNotEmpty)
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: r.w(22), vertical: r.h(15)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 14,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(ctaIcon, size: 17, color: accent),
                          SizedBox(width: r.w(10)),
                          Text(cta,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: r.sp(14),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3)),
                        ]),
                      ),
                    ),
                ],
              ),
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── 배경색 (이미지/비디오 로딩 전 placeholder) ──
                const ColoredBox(color: AppColors.textPrimary),
                // ── 배경 미디어 ──
                if (videoUrl != null)
                  VideoBannerWidget(
                    videoUrl: videoUrl,
                    thumbnailUrl: b.imageUrl,
                    onTap: onTap,
                    onProductTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProductListScreen(initialCategory: '전체'))),
                  )
                else if (b.imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: onTap,
                    child: NetImage(
                      b.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                else
                  GestureDetector(
                      onTap: onTap,
                      child: const ColoredBox(color: AppColors.primary)),

                // ── 그라데이션 오버레이 ──
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.3, 0.6, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.40),
                            Colors.black.withValues(alpha: 0.82),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 텍스트 + CTA: 배경 로딩과 무관하게 즉시 표시 ──
                pcTextOverlay,
              ],
            );
          },
        ),
        // 우측 세로 점 인디케이터
        Positioned(
          right: 20,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: banners.asMap().entries.map((e) {
                final r = Responsive.of(context);

                final active = _bannerIndex == e.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 4,
                  height: active ? 26 : 6,
                  margin: EdgeInsets.symmetric(vertical: r.h(3)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  // end _buildPcBannerBody

  // ── PC 로컬 asset 배너 (Firestore 배너 없을 때 즉시 표시) ──
  Widget _buildPcLocalBanner(AppLocalizations loc) {
    final r = Responsive.of(context);
    void goShop() => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductListScreen(initialCategory: '전체')));
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 배경 영상 ──
        VideoBannerWidget(
          videoUrl: 'assets/images/banner_video.mp4',
          thumbnailUrl: 'assets/images/banner_custom_fit.jpg',
          onTap: goShop,
          onProductTap: goShop,
        ),
        // ── 텍스트 오버레이 ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(r.w(60), r.h(0), r.w(60), r.h(48)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: r.h(16)),
                Text(
                  loc.language == AppLanguage.korean
                      ? context.loc.t('함께 달리는 2FIT', '함께 달리는\n2FIT')
                      : 'Run Together\nwith 2FIT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: r.sp(48),
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.5),
                ),
                SizedBox(height: r.h(28)),
                GestureDetector(
                  onTap: goShop,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(26), vertical: r.h(14)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_forward_rounded,
                            size: 18, color: AppColors.accent),
                        SizedBox(width: r.w(10)),
                        Text(
                          loc.language == AppLanguage.korean
                              ? context.loc.t('쇼핑하러 가기', '쇼핑하러 가기')
                              : 'Shop Now',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: r.sp(15),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _unusedLegacyPcBanner() => const SizedBox.shrink();

  // ── PC 전용 카테고리 사이드바 (아코디언) ──
  // ── PC 배너 섹션 (모바일과 동일, 높이만 조정) ──
  // ignore: unused_element
  Widget _buildPcBannerSection(AppLocalizations loc) {
    final r = Responsive.of(context);
    final banners = [
      {
        'title': 'JUST\nDO IT.',
        'sub': loc.language == AppLanguage.korean
            ? context.loc.t('k_2025_ss_컬렉션', '2025 S/S 컬렉션')
            : '2025 S/S COLLECTION',
        'tag': 'NEW SEASON',
        'bg1': const Color(0xFF0D0D0D),
        'bg2': AppColors.primary,
        'image':
            'https://images.unsplash.com/photo-1513689125086-6c432170e843?w=1600&auto=format&fit=crop',
        'btnAction': 0,
      },
      {
        'title': 'BEST\nSELLER.',
        'sub': loc.language == AppLanguage.korean
            ? context.loc.t('k_2fit_인기_상품', '2FIT 인기 상품')
            : 'TOP PRODUCTS',
        'tag': 'POPULAR',
        'bg1': const Color(0xFF1A0000),
        'bg2': const Color(0xFF330000),
        'image':
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1600&auto=format&fit=crop',
        'btnAction': 3,
      },
      {
        'assetImage': 'assets/images/banner_custom_fit.jpg',
        'btnAction': 0,
      },
    ];

    return Container(
      color: AppColors.textPrimary,
      child: Column(
        children: [
          // ── PC 상단 네비게이션 바 ──
          Container(
            color: AppColors.textPrimary,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.w(24)),
                  child: Row(
                    children: [
                      // ── 햄버거 버튼 (카테고리 드로어 열기) ──
                      IconButton(
                        icon: const Icon(Icons.menu_rounded,
                            color: Colors.white, size: 22),
                        tooltip: loc.homeCategory,
                        onPressed: () =>
                            _pcScaffoldKey.currentState?.openDrawer(),
                      ),
                      SizedBox(width: r.w(4)),
                      // 로고
                      GestureDetector(
                        onTap: () => widget.onNavigate?.call(0),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: r.h(12)),
                          child: SizedBox(
                            height: 28,
                            child: Image.asset(
                              'assets/images/logo_2fit_white.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // 검색
                      IconButton(
                        icon: const Icon(Icons.search_rounded,
                            color: Colors.white, size: 20),
                        tooltip: loc.search,
                        onPressed: () => _showSearchSheet(context, loc),
                      ),
                      // 장바구니
                      Consumer<CartProvider>(
                        builder: (ctx, cart, _) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_bag_outlined,
                                  color: Colors.white, size: 20),
                              tooltip: loc.cart,
                              onPressed: () => widget.onNavigate?.call(2),
                            ),
                            if (cart.itemCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      cart.itemCount > 9
                                          ? '9+'
                                          : '${cart.itemCount}',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: r.sp(8),
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // 알림
                      Consumer<UserProvider>(
                        builder: (ctx, userProv, _) {
                          final userId = userProv.user?.id;
                          if (userId == null) {
                            return IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 20),
                              onPressed: () =>
                                  _showNotificationsSheet(context, loc),
                            );
                          }
                          return StreamBuilder<int>(
                            stream: FcmService.watchUnreadCount(userId),
                            builder: (ctx2, snap) {
                              final r = Responsive.of(context);

                              final unread = snap.data ?? 0;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 20),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationCenterScreen()),
                                    ),
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFFF0000),
                                            shape: BoxShape.circle),
                                        child: Center(
                                          child: Text(
                                            unread > 9 ? '9+' : '$unread',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: r.sp(8),
                                                fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      // 언어
                      _buildLanguageButton(loc),
                      // 마이페이지
                      IconButton(
                        icon: const Icon(Icons.person_outline_rounded,
                            color: Colors.white, size: 20),
                        tooltip: loc.navMyPage,
                        onPressed: () => widget.onNavigate?.call(3),
                      ),
                      // 관리자 대시보드 (관리자 로그인 시에만 표시)
                      Consumer<UserProvider>(
                        builder: (ctx, user, _) => user.isAdmin
                            ? Tooltip(
                                message: loc.homeAdminDashboard,
                                child: IconButton(
                                  icon: const Icon(
                                      Icons.admin_panel_settings_rounded,
                                      color: AppColors.accent,
                                      size: 22),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const AdminScreen()),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── 구분선 ──
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          CarouselSlider(
            options: CarouselOptions(
              height: 480,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 600),
              autoPlayCurve: Curves.easeInOutCubic,
              onPageChanged: (index, _) => setState(() => _bannerIndex = index),
            ),
            items: banners.asMap().entries.map((e) {
              final r = Responsive.of(context);

              final b = e.value;
              final btnAction = b['btnAction'] as int? ?? 0;
              void onShop() {
                widget.onNavigate?.call(1);
              }

              // 로컬 asset 이미지 배너
              final assetImage = b['assetImage'] as String?;
              if (assetImage != null && assetImage.isNotEmpty) {
                return GestureDetector(
                  onTap: onShop,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: Image.asset(assetImage,
                        fit: BoxFit.contain, alignment: Alignment.center),
                  ),
                );
              }
              // 이미지 URL 배너
              final imageUrl = b['imageUrl'] as String?;
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return GestureDetector(
                  onTap: onShop,
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: NetImage(
                      imageUrl,
                      fit: BoxFit.cover,
                      // loadingBuilder 제거 → 배경색이 placeholder 역할, 텍스트 즉시 표시
                    ),
                  ),
                );
              }
              final bg1 = b['bg1'] as Color;
              final bg2 = b['bg2'] as Color;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [bg1, bg2],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: NetImage(
                      b['image'] as String,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: r.w(60)),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: r.h(60)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: r.w(10), vertical: r.h(4)),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    b['tag'] as String,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: r.sp(10),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                ),
                                SizedBox(height: r.h(14)),
                                Text(
                                  b['title'] as String,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: r.sp(56),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(height: r.h(12)),
                                Text(
                                  b['sub'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: r.sp(15),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: r.h(24)),
                                GestureDetector(
                                  onTap: onShop,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: r.w(28), vertical: r.h(13)),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      'SHOP NOW',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: r.sp(12),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 24,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: r.w(10), vertical: r.h(5)),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_bannerIndex + 1} / 2',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: r.sp(11),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          // 모바일과 동일한 점 인디케이터
          Padding(
            padding: EdgeInsets.symmetric(vertical: r.h(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map((e) {
                final r = Responsive.of(context);

                final active = _bannerIndex == e.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: active ? 24 : 5,
                  height: 5,
                  margin: EdgeInsets.symmetric(horizontal: r.w(2)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.5),
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── PC 카테고리 탭 섹션 (모바일 카테고리바와 동일) ──
  // ignore: unused_element
  Widget _buildPcCategoryTabSection(AppLocalizations loc) {
    final r = Responsive.of(context);
    final items = _getCategoryItems(loc);
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AppColors.surfaceGray),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: r.w(20)),
                child: SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (_, i) =>
                        _buildPcCategoryTabItem(items[i], loc),
                  ),
                ),
              ),
            ),
          ),
          Container(height: 1, color: AppColors.surfaceGray),
        ],
      ),
    );
  }

  Widget _buildPcCategoryTabItem(
      Map<String, dynamic> item, AppLocalizations loc) {
    final r = Responsive.of(context);
    final isSelected = _selectedCategoryKey == item['key'];
    final label = item['label'] as String;
    final key = item['key'] as String;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryKey = key);
        if (key == 'all') {
          widget.onNavigate?.call(1);
        } else {
          final matched = getCategories(loc).cast<CategoryData?>().firstWhere(
                (c) => c?.name == key,
                orElse: () => null,
              );
          if (matched != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailScreen(
                  categoryName: matched.name,
                  categoryColor: matched.color,
                  categoryIcon: matched.icon,
                  subCategories: matched.subCategories,
                ),
              ),
            );
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductListScreen(initialCategory: key)));
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: r.w(3), vertical: r.h(10)),
        padding: EdgeInsets.symmetric(horizontal: r.w(18), vertical: r.h(6)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: r.sp(12),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ── PC 상품 그리드 섹션 (신상품/베스트 — 모바일 가로 스크롤 대신 5컬럼 그리드) ──
  // ignore: unused_element
  Widget _buildPcProductGridSection({
    required String title,
    required String englishTitle,
    required Color accentColor,
    required bool isNew,
    required AppLocalizations loc,
  }) {
    final r = Responsive.of(context);
    final provider = context.watch<ProductProvider>();
    // 로딩 중이더라도 더미 데이터(sync)로 즉시 표시
    List<ProductModel> allProds = provider.products;
    if (allProds.isEmpty) {
      allProds = ProductService.getAllProductsSync();
    }
    final List<ProductModel> products;
    if (isNew) {
      products = allProds.where((p) => p.isNewActive).toList();
    } else {
      products = List<ProductModel>.from(allProds)
        ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    // 빈 리스트이면 로딩 스켈레톤 표시
    if (products.isEmpty) {
      final r = Responsive.of(context);

      return Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 1, color: AppColors.surfaceGray),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(r.w(20), r.h(24), r.w(20), r.h(24)),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(englishTitle.toUpperCase(),
                              style: TextStyle(
                                  fontSize: r.sp(10),
                                  fontWeight: FontWeight.w800,
                                  color: accentColor == AppColors.primary
                                      ? AppColors.textHint
                                      : accentColor,
                                  letterSpacing: 2.5)),
                          SizedBox(height: r.h(3)),
                          Text(title,
                              style: TextStyle(
                                  fontSize: r.sp(26),
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                  height: 1.1)),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                          width: r.w(24),
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final display = products.take(10).toList();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AppColors.surfaceGray),
          // 헤더
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.w(20), r.h(24), r.w(20), r.h(0)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          englishTitle.toUpperCase(),
                          style: TextStyle(
                            fontSize: r.sp(10),
                            fontWeight: FontWeight.w800,
                            color: accentColor == AppColors.primary
                                ? AppColors.textHint
                                : accentColor,
                            letterSpacing: 2.5,
                          ),
                        ),
                        SizedBox(height: r.h(3)),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: r.sp(26),
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => isNew
                              ? const ProductListScreen(initialOnlyNew: true)
                              : const ProductListScreen(initialOnlyBest: true),
                        ),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: r.w(14), vertical: r.h(8)),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'VIEW ALL',
                          style: TextStyle(
                            fontSize: r.sp(11),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: r.h(20)),
          // 5컬럼 그리드 — Wrap으로 카드 실제 높이 유지
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: r.w(20)),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    const cols = 5;
                    const sp = 12.0;
                    final cardW =
                        (constraints.maxWidth - sp * (cols - 1)) / cols;
                    return Wrap(
                      spacing: sp,
                      runSpacing: sp,
                      children: display
                          .map((p) => SizedBox(
                              width: cardW, child: _buildPcHomeProductCard(p)))
                          .toList(),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: r.h(32)),
        ],
      ),
    );
  }

  Widget _buildPcHomeProductCard(ProductModel product) {
    final r = Responsive.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 이미지 — 카드 완전히 채움
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: product.images.isNotEmpty
                        ? NetImage(
                            product.images.first,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          )
                        : const Icon(Icons.checkroom_rounded,
                            size: 40, color: AppColors.border),
                  ),
                  if (product.isNewActive)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: r.w(6), vertical: r.h(3)),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text('NEW',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: r.sp(9),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                      ),
                    ),
                  if (product.isSale)
                    Positioned(
                      top: product.isNewActive ? 32 : 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: r.w(6), vertical: r.h(3)),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text('BEST',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: r.sp(9),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5)),
                      ),
                    ),
                ],
              ),
            ),
            // 정보
            Padding(
              padding: EdgeInsets.fromLTRB(r.w(8), r.h(7), r.w(8), r.h(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2FIT KOREA',
                      style: TextStyle(
                          fontSize: r.sp(9),
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5)),
                  SizedBox(height: r.h(2)),
                  Text(
                    product.localizedName(_lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        height: 1.3),
                  ),
                  SizedBox(height: r.h(4)),
                  Text(
                    '${_fmtPrice(product.price)}${loc.wonUnit2}',
                    style: TextStyle(
                        fontSize: r.sp(13),
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary),
                  ),
                  if (product.rating > 0 && product.reviewCount > 0) ...[
                    SizedBox(height: r.h(2)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 11, color: Color(0xFFFFB300)),
                        SizedBox(width: r.w(2)),
                        Text('${product.rating}',
                            style: TextStyle(
                                fontSize: r.sp(10),
                                color: AppColors.textSecondary)),
                        SizedBox(width: r.w(3)),
                        Text('(${product.reviewCount})',
                            style: TextStyle(
                                fontSize: r.sp(10), color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ── PC 단체주문전용 상품 섹션 ──
  // ignore: unused_element
  Widget _buildPcGroupOrderSection(AppLocalizations loc) {
    final r = Responsive.of(context);
    List<ProductModel> allProds = context.watch<ProductProvider>().products;
    // 비어있으면 더미 데이터로 즉시 폴백
    if (allProds.isEmpty) {
      allProds = ProductService.getAllProductsSync();
    }
    final groupProducts = allProds.where((p) => p.isGroupOnly).toList();
    if (groupProducts.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(r.w(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(4)),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('GROUP ONLY',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: r.sp(9),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
              ),
              SizedBox(width: r.w(12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TEAM ORDER',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: r.sp(9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0)),
                  Text(loc.homeGroupOnly,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(20),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProductListScreen(initialCategory: '단체주문'))),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.w(14), vertical: r.h(8)),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(loc.homeViewAll,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          SizedBox(height: r.h(8)),
          Wrap(
            spacing: 8,
            children: [
              _groupBadge(context.loc.t('👥 5명 이상', '👥 5명 이상')),
              _groupBadge(loc.homeGroupBadge),
              _groupBadge(context.loc.t('🚀 빠른 제작', '🚀 빠른 제작')),
            ],
          ),
          SizedBox(height: r.h(16)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.58, // 4:5 이미지 + 텍스트
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: groupProducts.length,
            itemBuilder: (ctx, i) => ProductCard(product: groupProducts[i]),
          ),
          SizedBox(height: r.h(20)),
          // 안내 메시지
          Container(
            padding:
                EdgeInsets.symmetric(vertical: r.h(10), horizontal: r.w(14)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded,
                    color: AppColors.accent, size: 16),
                SizedBox(width: r.w(8)),
                Expanded(
                  child: Text(
                    loc.homeGroupOrderNote,
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PC 단체주문 CTA 배너 ──
  // ignore: unused_element
  Widget _buildPcNewArrivalCta() {
    final r = Responsive.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(vertical: r.h(36), horizontal: r.w(32)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.w(10), vertical: r.h(4)),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text('2025 S/S COLLECTION',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: r.sp(10),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                ),
                SizedBox(height: r.h(14)),
                Text(
                  loc.homeNewSeason,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.sp(36),
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: r.h(12)),
                Text(
                  loc.homeNewSeasonSub,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: r.sp(14)),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => widget.onNavigate?.call(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)),
                  elevation: 0,
                ),
                child: Text(loc.homeNewArrivalsBtn,
                    style: TextStyle(
                        fontSize: r.sp(14),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ),
              SizedBox(height: r.h(10)),
              OutlinedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProductListScreen(initialCategory: '이벤트'))),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)),
                ),
                child: Text(loc.homeEventBtn,
                    style: TextStyle(
                        fontSize: r.sp(14), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 모바일 / 태블릿 레이아웃 (<900px) ──────────────────
  Widget _buildMobileLayout(AppLocalizations loc) {
    final pp = context.watch<ProductProvider>();
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 600; // <600: 모바일
    final isTablet = screenW >= 600; // 600~899: 태블릿

    // Firestore 로딩 중이면 로컬 캐시에서 즉시 폴백 → 스피너 없이 바로 표시
    final groupProds = pp.groupOnlyProducts.isNotEmpty
        ? pp.groupOnlyProducts
        : ProductService.getAllProductsSync()
            .where((p) => p.isGroupOnly && p.isActive)
            .toList();

    final sortedGroupProds = [...groupProds]
      ..sort((a, b) => b.salesCount.compareTo(a.salesCount));
    const previewCount = 5;
    final previewProds = sortedGroupProds.take(previewCount).toList();
    final hasMore = sortedGroupProds.length > previewCount;

    return Stack(
      children: [
        Column(
          children: [
            // ── 헤더 ──
            // 모바일(<600): 기존 고정 헤더
            if (isMobile)
              SafeArea(bottom: false, child: _buildFixedHeader(loc)),
            // 태블릿(600~899): PC NavBar 스타일 헤더
            if (isTablet) _buildPcNavBar(loc),

            // ── 스크롤 영역 ──
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  restartAllVideoBanners(); // 배너 영상 첫 프레임부터 재시작
                  await context.read<ProductProvider>().refresh();
                  if (mounted) setState(() {});
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── 배너 ──
                    SliverToBoxAdapter(child: _buildCompactBanner(loc)),

                    // ── 기성품 베스트 ──
                    SliverToBoxAdapter(child: _buildBestSection(loc)),

                    // ── 단체주문 전용 헤더 ──
                    SliverToBoxAdapter(
                        child:
                            _buildGroupSectionHeader(loc, groupProds.length)),

                    // ── 단체주문 상품 (가로 스크롤 컴팩트 3개) ──
                    if (groupProds.isEmpty)
                      SliverToBoxAdapter(child: _buildGroupEmptyState(loc))
                    else
                      SliverToBoxAdapter(
                        child:
                            _buildGroupProductsCompact(loc, sortedGroupProds),
                      ),

                    // ── 신상품 (모바일/태블릿 모두 표시) ──
                    SliverToBoxAdapter(child: _buildNewArrivalsSection(loc)),

                    // ── 모바일 푸터 ──
                    SliverToBoxAdapter(child: _buildMobileFooter(loc)),

                    SliverToBoxAdapter(
                        child: SizedBox(height: isMobile ? 80 : 48)),
                  ],
                ),
              ),
            ),
          ],
        ),
        // ── FAB ──
        Positioned(
          right: 16,
          bottom: 16,
          child: _buildChatFAB(loc),
        ),
      ],
    );
  }

  // ── 단체주문 상품 가로 5개 진열 + 전체보기 버튼 ──
  Widget _buildGroupProductsRow(
    AppLocalizations loc,
    List<ProductModel> previewProds,
    bool hasMore,
    List<ProductModel> allGroupProds,
  ) {
    final r = Responsive.of(context);
    void goAll() => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GroupOrderOnlyScreen()),
        );

    final screenW = MediaQuery.of(context).size.width;
    // 반응형 카드 수: 태블릿(600~899)은 4개, 모바일(<600)은 5개
    // 양쪽 패딩 12×2=24, 카드 간격 8×(n-1)
    final isTabletW = screenW >= 600;
    final colCount = isTabletW ? 4 : 5;
    final cardW = ((screenW - 24 - 8 * (colCount - 1)) / colCount)
        .clamp(72.0, isTabletW ? 200.0 : 150.0);
    final imgH = cardW * 1.25; // 4:5 비율

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 가로 스크롤 상품 목록
          SizedBox(
            height: imgH + 58, // 이미지 + 텍스트 영역
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: r.w(12)),
              itemCount: previewProds.length,
              itemBuilder: (_, i) {
                final r = Responsive.of(context);

                final p = previewProds[i];
                final discount =
                    p.originalPrice != null && p.originalPrice! > p.price
                        ? ((1 - p.price / p.originalPrice!) * 100).round()
                        : 0;
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: p))),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    elevation: 1,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                    child: SizedBox(
                      width: cardW,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 이미지
                              AspectRatio(
                                aspectRatio: 4 / 5,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Positioned.fill(
                                      child: p.images.isNotEmpty
                                          ? NetImage(
                                              p.images.first,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.topCenter,
                                            )
                                          : Container(
                                              color: AppColors.surfaceGray,
                                              child: const Icon(
                                                  Icons
                                                      .image_not_supported_rounded,
                                                  color: Colors.white54,
                                                  size: 28),
                                            ),
                                    ),
                                    if (discount > 0)
                                      Positioned(
                                        top: 5,
                                        left: 5,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: r.w(4),
                                              vertical: r.h(2)),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text('$discount%',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: r.sp(9),
                                                  fontWeight: FontWeight.w800)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: r.h(6)),
                              // 상품명
                              Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: r.w(8)),
                                child: Text(_pName(p),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: r.sp(10),
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF222222),
                                        height: 1.3)),
                              ),
                              SizedBox(height: r.h(2)),
                              // 가격
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                    r.w(8), 0, r.w(8), r.h(8)),
                                child: Text(
                                  '${p.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                                  style: TextStyle(
                                      fontSize: r.sp(11),
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          // border overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 전체보기 버튼 (상품이 5개 초과일 때만)
          if (hasMore)
            Padding(
              padding: EdgeInsets.fromLTRB(r.w(12), r.h(12), r.w(12), r.h(20)),
              child: GestureDetector(
                onTap: goAll,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: r.h(13)),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.loc.t('전체 상품 보기 _개',
                            '전체 상품 보기 (${allGroupProds.length}개)'),
                        style: TextStyle(
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.2),
                      ),
                      SizedBox(width: r.w(6)),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 15, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            )
          else
            SizedBox(height: r.h(20)),
        ],
      ),
    );
  }

  // ── 단체주문 컴팩트 가로 스크롤 (홈화면 미리보기 — 3개 고정) ──
  Widget _buildGroupProductsCompact(
    AppLocalizations loc,
    List<ProductModel> allGroupProds,
  ) {
    final r = Responsive.of(context);
    final preview = allGroupProds.take(5).toList();
    final screenW = MediaQuery.of(context).size.width;
    final isTabletW = screenW >= 600;
    // 카드 너비: 모바일은 화면의 40%, 태블릿은 28%
    final cardW = isTabletW ? screenW * 0.28 : screenW * 0.40;
    final imgH = cardW * 1.25; // 4:5 비율

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: r.h(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: imgH + 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: r.w(12)),
              itemCount: preview.length + 1, // +1 = 전체보기 카드
              itemBuilder: (_, i) {
                // 마지막 아이템: 전체보기 카드
                if (i == preview.length) {
                  final r = Responsive.of(context);

                  return GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GroupOrderOnlyScreen())),
                    child: Container(
                      width: cardW * 0.75,
                      margin: EdgeInsets.only(right: r.w(8)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 22),
                          ),
                          SizedBox(height: r.h(10)),
                          Text(
                            context.loc
                                .t('전체보기 _개', '전체보기\n${allGroupProds.length}개'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: r.sp(12),
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final p = preview[i];
                final discount =
                    p.originalPrice != null && p.originalPrice! > p.price
                        ? ((1 - p.price / p.originalPrice!) * 100).round()
                        : 0;
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: p))),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    elevation: 1,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                    child: SizedBox(
                      width: cardW,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 이미지
                              AspectRatio(
                                aspectRatio: 4 / 5,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Positioned.fill(
                                      child: p.images.isNotEmpty
                                          ? NetImage(
                                              p.images.first,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.topCenter,
                                            )
                                          : const Icon(
                                              Icons.image_not_supported_rounded,
                                              color: AppColors.border,
                                              size: 28),
                                    ),
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: r.w(5),
                                            vertical: r.h(2)),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text('GROUP',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: r.sp(8),
                                                fontWeight: FontWeight.w900)),
                                      ),
                                    ),
                                    if (discount > 0)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: r.w(5),
                                              vertical: r.h(2)),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text('$discount%',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: r.sp(9),
                                                  fontWeight: FontWeight.w900)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // 상품 정보
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                    r.w(8), r.h(7), r.w(8), r.h(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_pName(p),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: r.sp(11),
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                            height: 1.3)),
                                    SizedBox(height: r.h(3)),
                                    Text(
                                      '${_fmtGroupPrice(p.price)}원',
                                      style: TextStyle(
                                          fontSize: r.sp(12),
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // border overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 고정 헤더 (흰 배경) ──
  Widget _buildFixedHeader(AppLocalizations loc) {
    final r = Responsive.of(context);
    return Container(
      height: 52,
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded,
                color: AppColors.textPrimary, size: 24),
            onPressed: () {
              if (widget.scaffoldKey != null) {
                widget.scaffoldKey!.currentState?.openDrawer();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onNavigate?.call(0),
              child: Center(
                child: Image.asset(
                  'assets/images/logo_2fit.png',
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: AppColors.textPrimary, size: 24),
            onPressed: () => _showSearchSheet(context, loc),
          ),
          Consumer<CartProvider>(
            builder: (ctx, cart, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.textPrimary, size: 24),
                  onPressed: () => widget.onNavigate?.call(2),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                          color: AppColors.accent, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: r.sp(8),
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Consumer<LanguageProvider>(
            builder: (_, langProv, __) => GestureDetector(
              onTap: () => _showLanguageSheet(context, loc),
              child: Container(
                margin: EdgeInsets.only(right: r.w(10)),
                padding:
                    EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(4)),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGray,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(langProv.language.flagEmoji,
                        style: TextStyle(fontSize: r.sp(13))),
                    SizedBox(width: r.w(3)),
                    Text(langProv.language.code,
                        style: TextStyle(
                            fontSize: r.sp(10),
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5)),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.textSecondary, size: 13),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 카테고리 가로 탭바 ──
  Widget _buildCategoryTabBar(AppLocalizations loc) {
    final r = Responsive.of(context);
    final cats = ['전체', '상의', '하의', '세트', '아우터', '스킨슈트', '악세사리', '단체주문'];
    return Container(
      color: Colors.white,
      height: 44,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: r.w(12)),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final r = Responsive.of(context);

                final cat = cats[i];
                final isGroup = cat == '단체주문';
                return GestureDetector(
                  onTap: () {
                    if (isGroup) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GroupOrderOnlyScreen(),
                          ));
                      return;
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductListScreen(initialCategory: cat),
                        ));
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                        right: r.w(4), top: r.h(6), bottom: r.h(6)),
                    padding: EdgeInsets.symmetric(
                        horizontal: isGroup ? 10 : 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: isGroup ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isGroup ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isGroup) ...[
                          const Icon(Icons.groups_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: r.w(4)),
                        ],
                        Text(cat,
                            style: TextStyle(
                              fontSize: r.sp(12.5),
                              fontWeight:
                                  isGroup ? FontWeight.w800 : FontWeight.w500,
                              color: isGroup
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  // ── 모바일 풀스크린 배너 (헤더 오버레이 포함) ──
  Widget _buildCompactBanner(AppLocalizations loc) {
    final bannerProv = context.watch<BannerProvider>();
    final activeBanners = bannerProv.activeBanners;
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    // ── 배너 높이: 항상 화면 너비 기준 16:9 정비율 ──
    // PC/태블릿/모바일 모두 동일 공식 → 디바이스 너비에 맞게 자동 조절
    final bannerH = screenW * 9 / 16;

    // Firestore 로딩 중이거나 배너가 없을 때 → 로컬 asset 동영상 + 텍스트 오버레이 즉시 표시
    if (activeBanners.isEmpty) {
      final r = Responsive.of(context);

      void goShop() => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductListScreen(initialCategory: '전체')));
      // 배너 높이 비례 텍스트 크기 (스크린샷 기준: bannerH≈580 → title≈62px)
      final titleSize = (bannerH * 0.107).clamp(28.0, 72.0);
      final tagSize = (bannerH * 0.018).clamp(8.0, 14.0);
      final ctaSize = (bannerH * 0.026).clamp(11.0, 18.0);
      final hPad = screenW < 600 ? 16.0 : 36.0;
      final bottomPad = (bannerH * 0.045).clamp(14.0, 48.0);
      return SizedBox(
        width: double.infinity,
        height: bannerH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 배경 영상 ──
            VideoBannerWidget(
              videoUrl: 'assets/images/banner_video.mp4',
              thumbnailUrl: 'assets/images/banner_custom_fit.jpg',
              onTap: goShop,
              onProductTap: goShop,
            ),
            // ── 텍스트 오버레이 (영상과 동시에 즉시 표시) ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(hPad, r.h(0), hPad, bottomPad),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: bannerH * 0.018),
                    // 메인 타이틀 (bannerH 비례)
                    Text(
                      loc.language == AppLanguage.korean
                          ? context.loc.t('함께 달리는 2FIT', '함께 달리는\n2FIT')
                          : 'Run Together\nwith 2FIT',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -0.5),
                    ),
                    SizedBox(height: bannerH * 0.032),
                    // CTA 버튼
                    GestureDetector(
                      onTap: goShop,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: ctaSize + 4, vertical: ctaSize * 0.75),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                size: ctaSize + 2, color: AppColors.accent),
                            SizedBox(width: r.w(8)),
                            Text(
                              loc.language == AppLanguage.korean
                                  ? context.loc.t('쇼핑하러 가기', '쇼핑하러 가기')
                                  : 'Shop Now',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: ctaSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: bannerH,
      child: Stack(
        children: [
          // 배너 슬라이더 — 헤더 없이 꽉 채워 시작
          Positioned.fill(
            child: PageView.builder(
              controller: _mobileBannerCtrl,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemCount: activeBanners.length,
              itemBuilder: (_, i) =>
                  _buildFullBannerItem(activeBanners[i], i, loc),
            ),
          ),
          // 우측 세로 인디케이터
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: activeBanners.asMap().entries.map((e) {
                  final r = Responsive.of(context);

                  final active = _bannerIndex == e.key;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 4,
                    height: active ? 20 : 4,
                    margin: EdgeInsets.symmetric(vertical: r.h(2)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 단체주문 전용 상품 섹션 헤더 ──
  Widget _buildGroupSectionHeader(AppLocalizations loc, int count) {
    final r = Responsive.of(context);
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(r.w(16), r.h(18), r.w(16), r.h(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(7), vertical: r.h(3)),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text('GROUP ORDER ONLY',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: r.sp(9),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5)),
                  ),
                ],
              ),
              SizedBox(height: r.h(6)),
              Text(context.loc.t('단체주문 전용 상품', '단체주문 전용 상품'),
                  style: TextStyle(
                      fontSize: r.sp(20),
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3)),
              SizedBox(height: r.h(2)),
              Text(
                  context.loc
                      .t('5명 이상 · 팀 맞춤 제작 · 무료배송', '5명 이상 · 팀 맞춤 제작 · 무료배송'),
                  style: TextStyle(
                      fontSize: r.sp(11), color: AppColors.textSecondary)),
              SizedBox(height: r.h(6)),
              // 엘리트 선수 안내
              GestureDetector(
                onTap: () async {
                  final uri = Uri(
                      scheme: 'tel',
                      path: AppConstants.eliteAthletePhone.replaceAll('-', ''));
                  // ignore: deprecated_member_use
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.w(8), vertical: r.h(4)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          size: 12, color: AppColors.primaryLight),
                      SizedBox(width: r.w(4)),
                      Text(
                          context.loc.t('🏅 엘리트 선수 주문',
                              '🏅 엘리트 선수 주문: ${AppConstants.eliteAthletePhone}'),
                          style: TextStyle(
                              fontSize: r.sp(10.5),
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GroupOrderOnlyScreen(),
                )),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(7)),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.loc.t('전체보기 _', '전체보기 $count'),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(11),
                          fontWeight: FontWeight.w800)),
                  SizedBox(width: r.w(3)),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 11),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 가격 포맷 헬퍼 ──
  String _fmtGroupPrice(double v) => v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ── 단체주문 전용 상품 카드 (홈화면용) ──
  Widget _buildGroupProductCard(ProductModel p) {
    final r = Responsive.of(context);
    final discount = p.originalPrice != null && p.originalPrice! > p.price
        ? ((1 - p.price / p.originalPrice!) * 100).round()
        : 0;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.04),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이미지
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: p.images.isNotEmpty
                              ? NetImage(
                                  p.images.first,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                )
                              : const Icon(Icons.image_not_supported_outlined,
                                  color: AppColors.textHint, size: 36),
                        ),
                        // GROUP ONLY 배지
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: r.w(6), vertical: r.h(3)),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text('GROUP',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: r.sp(8),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0)),
                          ),
                        ),
                        if (discount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: r.w(6), vertical: r.h(3)),
                              decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(3)),
                              child: Text('$discount%',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: r.sp(10),
                                      fontWeight: FontWeight.w900)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 정보
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(r.w(10), r.h(8), r.w(10), r.h(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.subCategory.isNotEmpty)
                          Text(p.subCategory,
                              style: TextStyle(
                                  fontSize: r.sp(10),
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        SizedBox(height: r.h(2)),
                        Text(_pName(p),
                            style: TextStyle(
                                fontSize: r.sp(13),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: r.h(4)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${_fmtGroupPrice(p.price)}원',
                                style: TextStyle(
                                    fontSize: r.sp(14),
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary)),
                            if (p.originalPrice != null &&
                                p.originalPrice! > p.price) ...[
                              SizedBox(width: r.w(5)),
                              Text('${_fmtGroupPrice(p.originalPrice!)}원',
                                  style: TextStyle(
                                      fontSize: r.sp(11),
                                      color: AppColors.textHint,
                                      decoration: TextDecoration.lineThrough)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // border overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ],
          ), // Stack
        ), // Material
      ), // GestureDetector
    ); // RepaintBoundary
  }

  // ── 단체주문 상품 없음 상태 ──
  Widget _buildGroupEmptyState(AppLocalizations loc) {
    final r = Responsive.of(context);
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: r.h(48), horizontal: r.w(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.groups_rounded,
                size: 38, color: AppColors.primary),
          ),
          SizedBox(height: r.h(14)),
          Text(context.loc.t('단체주문 상품 준비 중', '단체주문 상품 준비 중'),
              style: TextStyle(
                  fontSize: r.sp(16),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          SizedBox(height: r.h(6)),
          Text(
              context.loc
                  .t('새로운 단체주문 전용 상품이 곧 업데이트됩니다', '새로운 단체주문 전용 상품이 곧 업데이트됩니다.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: r.sp(12),
                  color: AppColors.textSecondary,
                  height: 1.5)),
          SizedBox(height: r.h(18)),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GroupOrderOnlyScreen(),
                )),
            icon: const Icon(Icons.info_outline_rounded, size: 15),
            label: Text(context.loc.t('단체주문 안내 보기', '단체주문 안내 보기')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1행 오버레이 헤더 ──
  Widget _buildOverlayHeader(AppLocalizations loc) {
    final r = Responsive.of(context);
    // 배너 풀스크린 위에 올라오는 헤더 — 상단 그라데이션으로 가독성 확보
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.28),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              // ── 좌: 햄버거 ──
              IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 26),
                onPressed: () {
                  if (widget.scaffoldKey != null) {
                    widget.scaffoldKey!.currentState?.openDrawer();
                  } else {
                    Scaffold.of(context).openDrawer();
                  }
                },
              ),
              // ── 중앙: 로고 ──
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onNavigate?.call(0),
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo_2fit_white.png',
                      height: 30,
                      fit: BoxFit.contain,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              // ── 우: 검색 + 장바구니 + 언어버튼 ──
              IconButton(
                icon: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 24),
                onPressed: () => _showSearchSheet(context, loc),
              ),
              Consumer<CartProvider>(
                builder: (ctx, cart, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white, size: 24),
                      onPressed: () => widget.onNavigate?.call(2),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: r.sp(8),
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 언어 버튼
              Consumer<LanguageProvider>(
                builder: (_, langProv, __) => GestureDetector(
                  onTap: () => _showLanguageSheet(context, loc),
                  child: Container(
                    margin: EdgeInsets.only(right: r.w(10)),
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(8), vertical: r.h(4)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(langProv.language.flagEmoji,
                            style: TextStyle(fontSize: r.sp(13))),
                        SizedBox(width: r.w(3)),
                        Text(
                          langProv.language.code,
                          style: TextStyle(
                            fontSize: r.sp(10),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded,
                            color: Colors.white, size: 13),
                      ],
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

  // ── 사이드바 + 배너 가로 배치 (모바일) ──

  // ── 단체주문전용 상품 섹션 ──
  // ignore: unused_element
  Widget _buildGroupOrderSection(AppLocalizations loc) {
    final r = Responsive.of(context);
    List<ProductModel> allProds = context.watch<ProductProvider>().products;
    if (allProds.isEmpty) allProds = ProductService.getAllProductsSync();
    final groupProducts = allProds.where((p) => p.isGroupOnly).toList();
    if (groupProducts.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(20), r.w(16), r.h(0)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.w(8), vertical: r.h(4)),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'GROUP ONLY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: r.sp(9),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SizedBox(width: r.w(8)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEAM ORDER',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: r.sp(9),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Text(
                      loc.homeGroupOnly,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.sp(20),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductListScreen(initialCategory: '단체주문'),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(12), vertical: r.h(7)),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      loc.homeViewAll,
                      style: TextStyle(
                        fontSize: r.sp(11),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: r.h(8)),
          // 5명 이상 안내 배지
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(16)),
            child: Wrap(
              spacing: 8,
              children: [
                _groupBadge(context.loc.t('👥 5명 이상', '👥 5명 이상')),
                _groupBadge(loc.homeGroupBadge),
                _groupBadge(context.loc.t('🚀 빠른 제작', '🚀 빠른 제작')),
              ],
            ),
          ),
          SizedBox(height: r.h(12)),
          // 2컬럼 — Wrap으로 카드 실제 높이 유지
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(12)),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                const cols = 2;
                const spacing = 8.0;
                final cardW =
                    (constraints.maxWidth - spacing * (cols - 1)) / cols;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: groupProducts
                      .map((p) => SizedBox(
                          width: cardW,
                          child:
                              ProductCard(product: p, showGroupBadge: false)))
                      .toList(),
                );
              },
            ),
          ),
          SizedBox(height: r.h(16)),
          // 단체 커스텀 오더 신청 → 상품 상세에서만 가능 안내
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(16)),
            child: Container(
              padding:
                  EdgeInsets.symmetric(vertical: r.h(10), horizontal: r.w(14)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded,
                      color: AppColors.accent, size: 16),
                  SizedBox(width: r.w(8)),
                  Expanded(
                    child: Text(
                      loc.homeGroupOrderNote2,
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: r.h(20)),
        ],
      ),
    );
  }

  Widget _groupBadge(String text) {
    final r = Responsive.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(4)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: r.sp(11),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── 상단 알림 띠배너 ──
  // ignore: unused_element
  Widget _buildNoticeBanner() {
    final r = Responsive.of(context);
    return Container(
      color: AppColors.accent,
      padding: EdgeInsets.symmetric(vertical: r.h(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 14),
          SizedBox(width: r.w(6)),
          Text(
            context.loc
                .t('🎉 단체 맞춤 제작 · 3만원 이상 무료배송', '🎉 단체 맞춤 제작 · 3만원 이상 무료배송'),
            style: TextStyle(
                color: Colors.white,
                fontSize: r.sp(12),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3),
          ),
          SizedBox(width: r.w(6)),
          Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 14),
        ],
      ),
    );
  }

  // ── 퀵메뉴 바 (이벤트/신상품) ──
  // ignore: unused_element
  Widget _buildQuickMenuBar(AppLocalizations loc) {
    final r = Responsive.of(context);
    final menus = [
      {
        'icon': Icons.local_offer_rounded,
        'label': loc.homeEvent,
        'color': AppColors.accent
      },
      {
        'icon': Icons.fiber_new_rounded,
        'label': loc.homeNewArrival,
        'color': AppColors.primary
      },
    ];
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: r.h(16)),
      child: Row(
        children: menus.asMap().entries.map((e) {
          final r = Responsive.of(context);

          final m = e.value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                switch (e.key) {
                  case 0:
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProductListScreen(initialCategory: '이벤트')));
                    break;
                  case 1:
                    widget.onNavigate?.call(1);
                    break;
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: (m['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(m['icon'] as IconData,
                        color: m['color'] as Color, size: 26),
                  ),
                  SizedBox(height: r.h(6)),
                  Text(m['label'] as String,
                      style: TextStyle(
                          fontSize: r.sp(11),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 플래시세일 섹션 ──
  // ignore: unused_element
  Widget _buildFlashSaleSection(AppLocalizations loc) {
    final r = Responsive.of(context);
    final saleProducts = context
        .watch<ProductProvider>()
        .products
        .where((p) =>
            p.isSale || (p.originalPrice != null && p.originalPrice! > p.price))
        .take(6)
        .toList();
    if (saleProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: r.h(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            color: AppColors.accent,
            padding:
                EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: r.w(8)),
                Text('FLASH SALE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: r.sp(16),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
                SizedBox(width: r.w(8)),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.w(8), vertical: r.h(2)),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(loc.homeMaxDiscount,
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: r.sp(11),
                          fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(1),
                  child: Text(loc.homeViewAllArrow,
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // 상품 가로 스크롤
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(12)),
              itemCount: saleProducts.length,
              itemBuilder: (_, i) {
                final r = Responsive.of(context);

                final p = saleProducts[i];
                final discount = p.originalPrice != null
                    ? ((1 - p.price / p.originalPrice!) * 100).round()
                    : 0;
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: p))),
                  child: Container(
                    width: 130,
                    margin: EdgeInsets.only(right: r.w(8)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                              child: p.images.isNotEmpty
                                  ? NetImage(p.images.first,
                                      width: 130,
                                      height: 120,
                                      fit: BoxFit.cover)
                                  : Container(
                                      height: 120,
                                      color: AppColors.surfaceGray),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                              r.w(8), r.h(6), r.w(8), r.h(4)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_pName(p),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: r.sp(11),
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF222222))),
                              SizedBox(height: r.h(2)),
                              if (p.originalPrice != null)
                                Text(
                                    '${_fmtPrice(p.originalPrice!)}${loc.wonUnit2}',
                                    style: TextStyle(
                                        fontSize: r.sp(10),
                                        color: AppColors.textHint,
                                        decoration:
                                            TextDecoration.lineThrough)),
                              Text('${_fmtPrice(p.price)}${loc.wonUnit2}',
                                  style: TextStyle(
                                      fontSize: r.sp(13),
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 중간 프로모션 배너 (복수 배너) ──
  // ignore: unused_element
  Widget _buildPromoBanner() {
    final r = Responsive.of(context);
    return Container(
      margin: EdgeInsets.only(top: r.h(8)),
      child: Column(
        children: [
          // ── 배너 1: 신상품 안내 ──
          GestureDetector(
            onTap: () => widget.onNavigate?.call(1),
            child: Container(
              color: const Color(0xFF0D1B2A),
              padding: EdgeInsets.all(r.w(20)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: r.w(8), vertical: r.h(3)),
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(3)),
                          child: Text('NEW ARRIVAL',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: r.sp(9),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                        ),
                        SizedBox(height: r.h(10)),
                        Text('2025 S/S\n${loc.homeNewArrival}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: r.sp(20),
                                fontWeight: FontWeight.w900,
                                height: 1.3)),
                        SizedBox(height: r.h(6)),
                        Text(loc.homeLatestCollection,
                            style: TextStyle(
                                color: Color(0xFF8899AA), fontSize: r.sp(13))),
                        SizedBox(height: r.h(14)),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: r.w(18), vertical: r.h(9)),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(loc.homeNewArrivalsArrow,
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: r.sp(12),
                                  fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: r.w(10)),
                  const Icon(Icons.fiber_new_rounded,
                      color: Color(0xFF1E3A5F), size: 90),
                ],
              ),
            ),
          ),
          SizedBox(height: r.h(2)),
          // ── 배너 2: 이벤트 특가 ──
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductListScreen(initialCategory: '이벤트'))),
            child: Container(
              color: const Color(0xFF1A0A0A),
              padding: EdgeInsets.all(r.w(20)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: r.w(8), vertical: r.h(3)),
                          decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(3)),
                          child: Text('CUSTOM ORDER',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: r.sp(9),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                        ),
                        SizedBox(height: r.h(10)),
                        Text(loc.homeSeasonDiscount,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: r.sp(20),
                                fontWeight: FontWeight.w900,
                                height: 1.3)),
                        SizedBox(height: r.h(6)),
                        Text(loc.homeSeasonDiscountSub,
                            style: TextStyle(
                                color: Color(0xFF9988AA), fontSize: r.sp(13))),
                        SizedBox(height: r.h(14)),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: r.w(18), vertical: r.h(9)),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          child: Text(loc.homeEventArrow,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: r.sp(12),
                                  fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: r.w(10)),
                  const Icon(Icons.local_offer_rounded,
                      color: Color(0xFF5F1E1E), size: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 브랜드 특징 섹션 ──
  // ignore: unused_element
  Widget _buildBrandFeatureSection() {
    final r = Responsive.of(context);
    final features = [
      {
        'icon': Icons.local_shipping_outlined,
        'title': loc.homeFreeShipping,
        'sub': loc.homeFreeShippingSub
      },
      {
        'icon': Icons.verified_outlined,
        'title': loc.homeQualityGuarantee,
        'sub': loc.homeQualityGuaranteeSub
      },
      {
        'icon': Icons.replay_rounded,
        'title': loc.home7DayExchange,
        'sub': loc.home7DayExchangeSub
      },
      {
        'icon': Icons.headset_mic_outlined,
        'title': loc.homeConsultation,
        'sub': loc.homeConsultationSub
      },
    ];
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: r.h(8)),
      padding: EdgeInsets.symmetric(vertical: r.h(20)),
      child: Row(
        children: features
            .map((f) => Expanded(
                  child: Column(
                    children: [
                      Icon(f['icon'] as IconData,
                          size: 28, color: AppColors.textPrimary),
                      SizedBox(height: r.h(6)),
                      Text(f['title'] as String,
                          style: TextStyle(
                              fontSize: r.sp(12),
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                      Text(f['sub'] as String,
                          style: TextStyle(
                              fontSize: r.sp(10),
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ────────────────────────────────────────────
  // 앱바: Nike 스타일 — 블랙 배경, 흰 로고, 최소 UI
  // ────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildAppBar(AppLocalizations loc) {
    return SliverPersistentHeader(
      pinned: false,
      floating: true,
      delegate: _MobileHeaderDelegate(
        onMenuTap: () {
          if (widget.scaffoldKey != null) {
            widget.scaffoldKey!.currentState?.openDrawer();
          } else {
            Scaffold.of(context).openDrawer();
          }
        },
        onSearchTap: () => _showSearchSheet(context, loc),
        onCartTap: () => widget.onNavigate?.call(2),
        onNotifTap: () => _showNotificationsSheet(context, loc),
        onMyPageTap: () => widget.onNavigate?.call(3),
        onLogoTap: () => widget.onNavigate?.call(0),
        onLanguageTap: () => _showLanguageSheet(context, loc),
        context: context,
        loc: loc,
      ),
    );
  }

  // ── 언어 선택 버튼 ──
  Widget _buildLanguageButton(AppLocalizations loc) {
    final r = Responsive.of(context);
    final langProv = context.watch<LanguageProvider>();
    return GestureDetector(
      onTap: () => _showLanguageSheet(context, loc),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: r.h(10), horizontal: r.w(4)),
        padding: EdgeInsets.symmetric(horizontal: r.w(9), vertical: r.h(5)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.6), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(langProv.language.flagEmoji,
                style: TextStyle(fontSize: r.sp(14))),
            SizedBox(width: r.w(4)),
            Text(
              langProv.language.code,
              style: TextStyle(
                  fontSize: r.sp(11),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.8),
            ),
            SizedBox(width: r.w(2)),
            const Icon(Icons.arrow_drop_down_rounded,
                color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  // ── 언어 선택 바텀시트 ──
  void _showLanguageSheet(BuildContext context, AppLocalizations loc) {
    final r = Responsive.of(context);

    final langProv = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20),
            MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: r.h(16)),
            Text(
              loc.selectLanguage,
              style: TextStyle(
                fontSize: r.sp(17),
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: r.h(16)),
            // 스크롤 가능한 언어 목록 (모든 언어 표시)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.55,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AppLanguage.values.map((lang) {
                    final r = Responsive.of(context);

                    final isSelected = langProv.language == lang;
                    return GestureDetector(
                      onTap: () {
                        langProv.setLanguage(lang);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: r.h(10)),
                        padding: EdgeInsets.symmetric(
                            horizontal: r.w(16), vertical: r.h(14)),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE8E8E8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(lang.flagEmoji,
                                style: TextStyle(fontSize: r.sp(22))),
                            SizedBox(width: r.w(14)),
                            Text(
                              lang.nativeName,
                              style: TextStyle(
                                fontSize: r.sp(15),
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 알림 바텀시트 ──
  void _showNotificationsSheet(BuildContext context, AppLocalizations loc) {
    final r = Responsive.of(context);

    final notifProv = context.read<NotificationProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 핸들
              Container(
                margin: EdgeInsets.only(top: r.h(12)),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(12), r.h(8)),
                child: Row(
                  children: [
                    Text(
                      loc.notifications,
                      style: TextStyle(
                        fontSize: r.sp(17),
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        notifProv.markAllAsRead();
                        setModalState(() {});
                      },
                      child: Text(loc.homeMarkReadAll,
                          style: TextStyle(
                              fontSize: r.sp(13),
                              color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (_, np, __) {
                    final list = np.notifications;
                    if (list.isEmpty) {
                      final r = Responsive.of(context);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 56, color: Colors.grey.shade300),
                          SizedBox(height: r.h(12)),
                          Text(loc.noNotifications,
                              style: TextStyle(
                                  fontSize: r.sp(14),
                                  color: AppColors.textHint)),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: r.h(8)),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 60),
                      itemBuilder: (_, i) {
                        final r = Responsive.of(context);

                        final n = list[i];
                        final iconData = n.type == 'order'
                            ? Icons.receipt_long_rounded
                            : n.type == 'promo'
                                ? Icons.local_offer_rounded
                                : Icons.info_outline_rounded;
                        final iconColor = n.type == 'order'
                            ? AppColors.primary
                            : n.type == 'promo'
                                ? AppColors.accent
                                : AppColors.success;
                        return InkWell(
                          onTap: () {
                            notifProv.markAsRead(n.id);
                            setModalState(() {});
                          },
                          child: Container(
                            color: n.isRead
                                ? Colors.white
                                : const Color(0xFFFFF8E1),
                            padding: EdgeInsets.symmetric(
                                horizontal: r.w(16), vertical: r.h(12)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconData,
                                      size: 18, color: iconColor),
                                ),
                                SizedBox(width: r.w(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(n.title,
                                                style: TextStyle(
                                                  fontSize: r.sp(13),
                                                  fontWeight: n.isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  color: AppColors.primary,
                                                )),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                color: AppColors.accent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: r.h(3)),
                                      Text(n.body,
                                          style: TextStyle(
                                            fontSize: r.sp(12),
                                            color: AppColors.textSecondary,
                                          )),
                                      SizedBox(height: r.h(3)),
                                      Text(
                                        _timeAgo(n.createdAt),
                                        style: TextStyle(
                                          fontSize: r.sp(11),
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  // ────────────────────────────────────────────
  // 메인 배너 (다국어 subtitle 적용)
  // ────────────────────────────────────────────
  // 모바일 배너 섹션 (Firestore BannerProvider 실시간)
  // ────────────────────────────────────────────
  Widget _buildBannerSection(AppLocalizations loc) {
    final bannerProv = context.watch<BannerProvider>();
    final activeBanners = bannerProv.activeBanners;

    // 배너: 모바일 → 화면 전체 높이, 태블릿/PC → 16:9 비율
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final isMobile = screenW < 600;
    final bannerHeight =
        isMobile ? mq.size.height - mq.viewPadding.bottom : screenW * (9 / 16);

    // Firestore 로딩 중이거나 배너가 없을 때 → 로컬 asset 동영상 + 텍스트 즉시 표시
    if (activeBanners.isEmpty) {
      final r = Responsive.of(context);

      void goShop() => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductListScreen(initialCategory: '전체')));
      return SizedBox(
        width: double.infinity,
        height: bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 배경 영상 ──
            VideoBannerWidget(
              videoUrl: 'assets/images/banner_video.mp4',
              thumbnailUrl: 'assets/images/banner_custom_fit.jpg',
              onTap: goShop,
              onProductTap: goShop,
            ),
            // ── 텍스트 오버레이 (영상과 동시에 즉시 표시) ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(r.w(16), r.h(0), r.w(16), r.h(24)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.language == AppLanguage.korean
                          ? context.loc.t('함께 달리는 2FIT', '함께 달리는\n2FIT')
                          : 'Run Together\nwith 2FIT',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(20),
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.3),
                    ),
                    SizedBox(height: r.h(14)),
                    GestureDetector(
                      onTap: goShop,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: r.w(12), vertical: r.h(8)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_forward_rounded,
                                size: 12, color: AppColors.accent),
                            SizedBox(width: r.w(8)),
                            Text(
                              loc.language == AppLanguage.korean
                                  ? context.loc.t('쇼핑하러 가기', '쇼핑하러 가기')
                                  : 'Shop Now',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: r.sp(10),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        children: [
          // ── 슬라이드 ──
          PageView.builder(
            controller: _mobileBannerCtrl,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemCount: activeBanners.length,
            itemBuilder: (_, i) =>
                _buildFullBannerItem(activeBanners[i], i, loc),
          ),
          // ── 우측 세로 점 인디케이터 ──
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: activeBanners.asMap().entries.map((e) {
                  final r = Responsive.of(context);

                  final active = _bannerIndex == e.key;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 4,
                    height: active ? 22 : 5,
                    margin: EdgeInsets.symmetric(vertical: r.h(2.5)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 모바일 배너 개별 슬라이드 아이템 (BannerModel 기반) ──
  Widget _buildFullBannerItem(
      BannerModel banner, int index, AppLocalizations loc) {
    final isKo = loc.language == AppLanguage.korean;
    final accent = Color(banner.accentColor);
    final title = isKo ? banner.titleKo : banner.titleEn;
    final cta = isKo ? banner.ctaKo : banner.ctaEn;
    // order==0 인 슬라이드는 videoUrl 우선
    final videoUrl =
        banner.videoUrl?.isNotEmpty == true ? banner.videoUrl : null;
    final imageUrl = banner.imageUrl;

    // CTA 아이콘
    final ctaIcon = switch (banner.btnAction) {
      1 => Icons.local_fire_department_rounded,
      2 => Icons.groups_rounded,
      _ => Icons.arrow_forward_rounded,
    };

    void onTap() {
      switch (banner.btnAction) {
        case 1:
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListScreen(initialCategory: '전체'),
              ));
          break;
        case 2:
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GroupOrderOnlyScreen(),
              ));
          break;
        case 3:
          // 쿠폰 다운로드 팝업
          _showBannerCouponPopup(banner.couponId);
          break;
        default:
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListScreen(initialCategory: '전체'),
              ));
      }
    }

    // ── 공통: 텍스트/CTA 오버레이 (배경과 독립 레이어 → 항상 즉시 표시) ──
    final overlayWidget = Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _buildBannerOverlay(
        banner: banner,
        title: title,
        cta: cta,
        ctaIcon: ctaIcon,
        accent: accent,
        onTap: onTap,
      ),
    );

    // ── 배너 아이템: 컨테이너 전체를 꽉 채움 (AspectRatio 래퍼 없음) ──
    Widget buildVideoWithOverlay() {
      return Stack(
        fit: StackFit.expand,
        children: [
          // ── 배경 영상 (컨테이너 꽉 채움) ──
          VideoBannerWidget(
            videoUrl: videoUrl!,
            thumbnailUrl: imageUrl,
            onTap: onTap,
            onProductTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductListScreen(initialCategory: '전체'))),
          ),
          // ── 텍스트/CTA: 비디오 로딩과 무관하게 즉시 표시 ──
          overlayWidget,
        ],
      );
    }

    Widget buildImageBanner() {
      return Stack(
        fit: StackFit.expand,
        children: [
          // ── 배경색 (이미지 로드 전에도 오버레이가 보이도록 배경 확보) ──
          const ColoredBox(color: AppColors.textPrimary),
          GestureDetector(
            onTap: onTap,
            child: NetImage(
              imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // ── 텍스트/CTA: 이미지 로딩과 무관하게 즉시 표시 ──
          overlayWidget,
        ],
      );
    }

    if (videoUrl != null) return buildVideoWithOverlay();
    if (imageUrl.isNotEmpty) return buildImageBanner();
    return GestureDetector(
        onTap: onTap, child: Container(color: AppColors.primary));
  }

  // ── 배너 하단 텍스트/CTA 오버레이 (공통) ──
  Widget _buildBannerOverlay({
    required BannerModel banner,
    required String title,
    required String cta,
    required IconData ctaIcon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final r = Responsive.of(context);
    final w = MediaQuery.of(context).size.width;
    final isTablet = w >= 600 && w < 1024;
    final isPc = w >= 1024;

    // 화면 너비 기준 비율 조정 (모바일 작은 화면에서 텍스트 겹침 방지)
    final screenW2 = MediaQuery.of(context).size.width;
    final isSmallMobile = screenW2 < 380; // 아이폰 SE 등 소형 기기

    final hPad = isPc
        ? 60.0
        : isTablet
            ? 36.0
            : 16.0;
    final titleSize = isPc
        ? 48.0
        : isTablet
            ? 34.0
            : (isSmallMobile ? 16.0 : 18.0);
    final tagSize = isPc
        ? 12.0
        : isTablet
            ? 10.0
            : 8.0;
    final ctaSize = isPc
        ? 15.0
        : isTablet
            ? 13.0
            : 10.0;
    final ctaVPad = isPc
        ? 14.0
        : isTablet
            ? 12.0
            : 10.0;
    final ctaHPad = isPc
        ? 26.0
        : isTablet
            ? 20.0
            : 16.0;
    final bottomPad = isPc
        ? 48.0
        : isTablet
            ? 32.0
            : 18.0;

    return Container(
      padding: EdgeInsets.fromLTRB(hPad, r.h(0), hPad, bottomPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.78),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (banner.tag.isNotEmpty)
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: tagSize + 1, vertical: 3),
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(2)),
              child: Text(banner.tag,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: tagSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8)),
            ),
          if (banner.tag.isNotEmpty)
            SizedBox(height: isTablet || isPc ? 16 : 10),
          if (title.isNotEmpty)
            Text(title,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.3)),
          if (title.isNotEmpty) SizedBox(height: isTablet || isPc ? 28 : 16),
          if (cta.isNotEmpty)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: ctaHPad, vertical: ctaVPad),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ctaIcon, size: ctaSize + 3, color: accent),
                    SizedBox(width: r.w(10)),
                    Text(cta,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: ctaSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // ────────────────────────────────────────────
  // PC 배너 데이터 헬퍼
  // ────────────────────────────────────────────
  // ignore: unused_element
  List<Map<String, dynamic>> _getBannerItems(AppLocalizations loc) => [
        {
          'title': 'NEW SEASON\n2025 S/S',
          'subtitle': loc.homeBanner1Subtitle,
          'badge': context.loc.t('신규_컬렉션', '🆕 신규 컬렉션'),
          'btn': loc.homeBanner1Btn,
          'gradient1': AppColors.primary,
          'gradient2': const Color(0xFF3D3D3D),
        },
        {
          'title': context.loc.t('BEST_SELLER_n인기_상품', 'BEST SELLER\n인기 상품'),
          'subtitle': loc.homeBanner2Subtitle,
          'badge': context.loc.t('베스트', '🔥 베스트'),
          'btn': loc.homeBanner2Btn,
          'gradient1': AppColors.accent,
          'gradient2': AppColors.accent,
        },
      ];

  // 카테고리 바 (다국어 라벨)
  // ────────────────────────────────────────────
  // ── 쇼핑몰 스타일 카테고리 그리드 ──
  // ignore: unused_element
  Widget _buildCategoryBar(AppLocalizations loc) {
    final r = Responsive.of(context);
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: r.h(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(16), r.w(16), r.h(0)),
            child: Row(
              children: [
                Text(loc.homeCategory,
                    style: TextStyle(
                        fontSize: r.sp(16),
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                const Spacer(),
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(1),
                  child: Text(loc.homeViewAllArrow,
                      style: TextStyle(
                          fontSize: r.sp(12),
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          SizedBox(height: r.h(12)),
          // ── 카테고리 아코디언 목록 ──
          ...getCategories(loc).map((cat) {
            final r = Responsive.of(context);

            final isExpanded = _expandedCatName == cat.name;
            final subs = cat.subCategories
                .where((s) => !s.name.startsWith('전체'))
                .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 카테고리 행
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedCatName = isExpanded ? null : cat.name;
                      _selectedCategoryKey = cat.name;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(16), vertical: r.h(13)),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 16),
                        ),
                        SizedBox(width: r.w(12)),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: r.sp(14),
                              fontWeight: isExpanded
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isExpanded ? cat.color : AppColors.primary,
                            ),
                          ),
                        ),
                        // ALL 탭 이동 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoryDetailScreen(
                                    categoryName: cat.name,
                                    categoryColor: cat.color,
                                    categoryIcon: cat.icon,
                                    subCategories: cat.subCategories,
                                  ),
                                ));
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: r.w(8), vertical: r.h(3)),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(loc.homeCategoryAll,
                                style: TextStyle(
                                    fontSize: r.sp(10),
                                    fontWeight: FontWeight.w700,
                                    color: cat.color)),
                          ),
                        ),
                        SizedBox(width: r.w(8)),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isExpanded ? cat.color : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 서브카테고리 펼침
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.03),
                      border: Border(
                        left: BorderSide(
                            color: cat.color.withValues(alpha: 0.25), width: 3),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: r.h(6)),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          SizedBox(width: r.w(0)), // 좌측 패딩용
                          ...subs.map((sub) {
                            final r = Responsive.of(context);

                            final isSubSel = _selectedCategoryKey ==
                                '${cat.name}/${sub.name}';
                            return Padding(
                              padding: EdgeInsets.only(left: r.w(52)),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedCategoryKey =
                                      '${cat.name}/${sub.name}');
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductListScreen(
                                            initialCategory: sub.filter),
                                      ));
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: r.w(12), vertical: r.h(7)),
                                  decoration: BoxDecoration(
                                    color: isSubSel
                                        ? cat.color.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSubSel
                                              ? cat.color
                                              : AppColors.border,
                                        ),
                                      ),
                                      SizedBox(width: r.w(8)),
                                      Text(
                                        sub.name,
                                        style: TextStyle(
                                          fontSize: r.sp(13),
                                          fontWeight: isSubSel
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSubSel
                                              ? cat.color
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      if (sub.tag != null) ...[
                                        SizedBox(width: r.w(6)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: r.w(5),
                                              vertical: r.h(1)),
                                          decoration: BoxDecoration(
                                            color: sub.tag == 'BEST'
                                                ? AppColors.accent
                                                : sub.tag == 'NEW'
                                                    ? cat.color
                                                    : AppColors.accent,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            sub.tag!,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: r.sp(8),
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(height: 1, color: const Color(0xFFF3F3F3)),
              ],
            );
          }),
          SizedBox(height: r.h(4)),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCategoryGridItem(
      Map<String, dynamic> item, AppLocalizations loc) {
    final r = Responsive.of(context);
    final label = item['label'] as String;
    final key = item['key'] as String;
    final color = item['color'] as Color;
    final icon = item['icon'] as IconData;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryKey = key);
        if (key == 'all') {
          widget.onNavigate?.call(1);
        } else {
          final matched = getCategories(loc).cast<CategoryData?>().firstWhere(
                (c) => c?.name == key,
                orElse: () => null,
              );
          if (matched != null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(
                    categoryName: matched.name,
                    categoryColor: matched.color,
                    categoryIcon: matched.icon,
                    subCategories: matched.subCategories,
                  ),
                ));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductListScreen(initialCategory: key)));
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border:
                  Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          SizedBox(height: r.h(6)),
          Text(
            label,
            style: TextStyle(
                fontSize: r.sp(11),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCategoryItem(Map<String, dynamic> item, AppLocalizations loc) {
    final r = Responsive.of(context);
    final isSelected = _selectedCategoryKey == item['key'];
    final label = item['label'] as String;
    final key = item['key'] as String;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryKey = key);
        if (key == 'all') {
          widget.onNavigate?.call(1);
        } else {
          final matched = getCategories(loc).cast<CategoryData?>().firstWhere(
                (c) => c?.name == key,
                orElse: () => null,
              );
          if (matched != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailScreen(
                  categoryName: matched.name,
                  categoryColor: matched.color,
                  categoryIcon: matched.icon,
                  subCategories: matched.subCategories,
                ),
              ),
            );
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductListScreen(initialCategory: key)));
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: r.w(2), vertical: r.h(10)),
        padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(5)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: r.sp(11),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // 신상품 / 베스트 섹션
  // ────────────────────────────────────────────

  /// provider → 캐시 → 더미 순으로 폴백. 절대 빈 리스트 반환 안 함.
  List<ProductModel> _getAllActiveProducts(ProductProvider provider) {
    // ① Firestore 로드 완료된 provider 데이터
    final fromProvider = provider.products.where((p) => p.isActive).toList();
    if (fromProvider.isNotEmpty) return fromProvider;
    // ② 캐시 + 더미 — 절대 빈 리스트 없음
    final guaranteed = ProductService.getAllProductsGuaranteed();
    final active = guaranteed.where((p) => p.isActive).toList();
    return active.isNotEmpty ? active : guaranteed;
  }

  // ignore: unused_element
  Widget _buildNewArrivalsSection(AppLocalizations loc) {
    // provider 없이도 즉시 표시 — 캐시/더미로 먼저 렌더, Firestore 완료 시 rebuild
    final provider = context.watch<ProductProvider>();
    final allProds = _getAllActiveProducts(provider);

    // isNew 배지가 있는 상품만 표시 (폴백 없음)
    List<ProductModel> products = allProds.where((p) => p.isNewActive).toList();

    if (products.isEmpty) return const SizedBox.shrink();

    return _buildProductSection(
      title: loc.sectionNewArrival,
      englishTitle: loc.sectionNewArrivalSub,
      accentColor: AppColors.primary,
      products: products,
      category: context.loc.t('이벤트', '이벤트'),
      viewAllLabel: loc.viewAll,
      isHorizontal: true, // PC/모바일 모두 가로 스크롤
      isNewCategory: true, // 신상품 섹션 → CategoryDetailScreen(신상품) 이동
    );
  }

  Widget _buildBestSection(AppLocalizations loc) {
    final provider = context.watch<ProductProvider>();
    final allProds = _getAllActiveProducts(provider);

    // ── 기성품 전용 베스트: isReadyMade 상품 판매순 상위 10개 ──
    final readyMadeProds =
        allProds.where((p) => p.isReadyMade && p.isActive).toList()
          ..sort((a, b) {
            final sa = b.salesCount.compareTo(a.salesCount);
            if (sa != 0) return sa;
            return b.reviewCount.compareTo(a.reviewCount);
          });

    final bestProds = readyMadeProds.take(10).toList();

    if (bestProds.isEmpty) return const SizedBox.shrink();

    return _buildProductSection(
      title: context.loc.t('기성품 베스트', '기성품 베스트'),
      englishTitle: 'READY-MADE BEST',
      accentColor: AppColors.primary,
      products: bestProds,
      category: context.loc.t('상의', '상의'),
      viewAllLabel: loc.viewAll,
      isHorizontal: true,
    );
  }

  /// 섹션 로딩 중 스켈레톤 (shimmer 효과)
  Widget _buildSectionSkeleton(String title) {
    final r = Responsive.of(context);
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: r.h(24), horizontal: r.w(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AppColors.surfaceGray),
          SizedBox(height: r.h(20)),
          Container(
            width: 120,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: r.h(16)),
          Row(
            children: List.generate(
              2,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 0 ? 8 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: r.h(8)),
                      Container(height: 14, color: AppColors.border),
                      SizedBox(height: r.h(4)),
                      Container(width: 60, height: 14, color: AppColors.border),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection({
    required String title,
    required String englishTitle,
    required Color accentColor,
    required List<ProductModel> products,
    required String category,
    required String viewAllLabel,
    bool isHorizontal = true,
    bool isNewCategory =
        false, // 신상품 섹션이면 true → CategoryDetailScreen(신상품 필터)로 이동
  }) {
    final r = Responsive.of(context);
    if (products.isEmpty) return const SizedBox.shrink();

    final screenW = MediaQuery.of(context).size.width;
    final isTabletW = screenW >= 600;

    // ── 카드 크기: PC 220px 고정, 태블릿 28%, 모바일 40%
    final isPc = screenW >= kPcBreakpoint;
    final cardW = isPc ? 220.0 : (isTabletW ? screenW * 0.28 : screenW * 0.40);
    final imgH = cardW * (5 / 4); // 4:5 비율

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: r.h(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AppColors.surfaceGray),

          // ── 섹션 헤더 ──────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(16), r.w(16), r.h(0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      englishTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: r.sp(9),
                        fontWeight: FontWeight.w800,
                        color: accentColor == AppColors.primary
                            ? AppColors.textHint
                            : accentColor,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: r.h(2)),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: r.sp(20),
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (isNewCategory) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryDetailScreen(
                              categoryName: context.loc.t('신상품', '신상품'),
                              categoryColor: AppColors.primary,
                              categoryIcon: Icons.new_releases_outlined,
                              subCategories: [
                                SubCategory(
                                    name: context.loc.t('신상품', '신상품'),
                                    filter: context.loc.t('신상품', '신상품')),
                              ],
                            ),
                          ));
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductListScreen(initialCategory: category),
                          ));
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.w(12), vertical: r.h(6)),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      viewAllLabel,
                      style: TextStyle(
                        fontSize: r.sp(11),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: r.h(12)),

          // ── PC 그리드 (isHorizontal=false) ─────────
          if (!isHorizontal)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(12)),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final cols = screenW >= 1200 ? 5 : (screenW >= 900 ? 4 : 3);
                  const sp = 12.0;
                  final cw = (constraints.maxWidth - sp * (cols - 1)) / cols;
                  final display =
                      products.length > 10 ? products.sublist(0, 10) : products;
                  return Wrap(
                    spacing: sp,
                    runSpacing: sp,
                    children: display
                        .map((p) =>
                            SizedBox(width: cw, child: ProductCard(product: p)))
                        .toList(),
                  );
                },
              ),
            ),

          // ── 가로 스크롤 (최대 10개 + 전체보기 카드) ─
          if (isHorizontal)
            SizedBox(
              height: imgH + 120, // 이미지(4:5) + 정보영역 + 상하 shadow 여백
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(
                    r.w(12), 6, r.w(12), 6), // 상하 6px: shadow 클리핑 방지
                itemCount: products.length.clamp(0, 10) + 1, // 최대 10개 + 전체보기 카드
                itemBuilder: (_, i) {
                  final display = products.take(10).toList();
                  // ── 마지막: 전체보기 카드 ──────────
                  if (i == display.length) {
                    final r = Responsive.of(context);

                    return GestureDetector(
                      onTap: () {
                        if (isNewCategory) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryDetailScreen(
                                  categoryName: context.loc.t('신상품', '신상품'),
                                  categoryColor: AppColors.primary,
                                  categoryIcon: Icons.new_releases_outlined,
                                  subCategories: [
                                    SubCategory(
                                        name: context.loc.t('신상품', '신상품'),
                                        filter: context.loc.t('신상품', '신상품')),
                                  ],
                                ),
                              ));
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductListScreen(
                                    initialCategory: category),
                              ));
                        }
                      },
                      child: Container(
                        width: cardW * 0.75,
                        margin: EdgeInsets.only(right: r.w(8)),
                        decoration: BoxDecoration(
                          color: accentColor == AppColors.accent
                              ? const Color(0xFFFFEBEE)
                              : AppColors.surfaceGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            SizedBox(height: r.h(10)),
                            Text(
                              context.loc
                                  .t('전체보기 _개', '전체보기\n${products.length}개'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ── 상품 카드 (최대 5개) ──
                  final p = display[i];
                  return Container(
                    width: cardW,
                    margin: EdgeInsets.only(right: r.w(10)),
                    // clipBehavior 없음 — ProductCard 자체 borderRadius가 모서리 처리
                    child: ProductCard(product: p),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // 우하단 채팅 FAB
  // ────────────────────────────────────────────
  // ── PC 푸터 (홈 스크롤 맨 아래) ──
  // ignore: unused_element
  // ── 모바일/태블릿 푸터 ──
  Widget _buildMobileFooter(AppLocalizations loc) {
    final r = Responsive.of(context);
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(r.w(20), r.h(32), r.w(20), r.h(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 브랜드명
          Text(
            '2FIT MALL',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: r.sp(18),
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: r.h(6)),
          Text(
            loc.homeBrandSlogan,
            style: TextStyle(
                color: Colors.white54, fontSize: r.sp(12), height: 1.6),
          ),
          SizedBox(height: r.h(16)),
          // 사업자 정보
          _footerInfoRow('🏢 ${AppConstants.companyName}'),
          _footerInfoRow('👤 대표자: ${AppConstants.ceoName}'),
          _footerInfoRow('📍 ${AppConstants.companyAddress}'),
          _footerInfoRow('📋 사업자등록번호: ${AppConstants.businessRegNumber}'),
          _footerInfoRow(
              '🛒 통신판매업신고번호: ${AppConstants.ecommerceRegNumber.isEmpty ? "심사 중" : AppConstants.ecommerceRegNumber}'),
          _footerInfoRow('📞 ${AppConstants.customerServicePhone}'),
          _footerInfoRow('✉ ${AppConstants.customerServiceEmail}'),
          _footerInfoRow('💬 카카오톡 ${AppConstants.kakaoTalkId}'),
          _footerInfoRow(
              '🕐 ${AppConstants.customerServiceHours.replaceAll("\n", " / ")}'),
          _footerInfoRow(context.loc.t('토일공휴일_휴무', '🚫 토·일·공휴일 휴무')),
          SizedBox(height: r.h(14)),
          // 소셜 버튼
          Row(
            children: [
              _footerSocialBtn(loc.homeKakao, const Color(0xFFFFE000),
                  Colors.black, () => _openKakaoChannel()),
              SizedBox(width: r.w(8)),
              _footerSocialBtn(
                  context.loc.t('고객센터', '고객센터'),
                  AppColors.textPrimary,
                  Colors.white,
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()))),
            ],
          ),
          SizedBox(height: r.h(20)),
          const Divider(color: Colors.white12),
          SizedBox(height: r.h(12)),
          // 링크 모음
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _footerLink(context.loc.t('상품 목록', '상품 목록'),
                  () => widget.onNavigate?.call(1)),
              _footerLink(loc.footerGroupOrder,
                  () => Navigator.pushNamed(context, '/group-guide')),
              _footerLink(context.loc.t('주문 현황', '주문 현황'),
                  () => widget.onNavigate?.call(3)),
              _footerLink(
                  context.loc.t('k_11_문의', '1:1 문의'),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()))),
              _footerLink(context.loc.t('카카오톡 채널', '카카오톡 채널'),
                  () => _openKakaoChannel()),
            ],
          ),
          SizedBox(height: r.h(16)),
          const Divider(color: Colors.white12),
          SizedBox(height: r.h(12)),
          // 저작권 및 약관
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '© 2025 2FIT Korea Co., Ltd.',
                  style: TextStyle(color: Colors.white30, fontSize: r.sp(11)),
                ),
              ),
              Row(
                children: [
                  Text(loc.homeTermsOfUse,
                      style:
                          TextStyle(color: Colors.white38, fontSize: r.sp(11))),
                  SizedBox(width: r.w(10)),
                  Text(loc.homePrivacyPolicy,
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: r.sp(11),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPcFooter(AppLocalizations loc) {
    final r = Responsive.of(context);
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.symmetric(vertical: r.h(40)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 브랜드
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => widget.onNavigate?.call(0),
                            child: Text(
                              '2FIT MALL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: r.sp(22),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          SizedBox(height: r.h(10)),
                          Text(
                            loc.homeBrandSlogan,
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: r.sp(13),
                                height: 1.7),
                          ),
                          SizedBox(height: r.h(20)),
                          _footerInfoRow('🏢 ${AppConstants.companyName}'),
                          _footerInfoRow('👤 대표자: ${AppConstants.ceoName}'),
                          _footerInfoRow('📍 ${AppConstants.companyAddress}'),
                          _footerInfoRow(
                              '📋 사업자등록번호: ${AppConstants.businessRegNumber}'),
                          _footerInfoRow(
                              '🛒 통신판매업신고번호: ${AppConstants.ecommerceRegNumber.isEmpty ? "심사 중" : AppConstants.ecommerceRegNumber}'),
                          _footerInfoRow(
                              '📞 ${AppConstants.customerServicePhone}'),
                          _footerInfoRow(
                              '✉ ${AppConstants.customerServiceEmail}'),
                          _footerInfoRow('💬 카카오톡 ${AppConstants.kakaoTalkId}'),
                          _footerInfoRow(
                              '🕐 ${AppConstants.customerServiceHours.replaceAll("\n", " / ")}'),
                          _footerInfoRow(
                              context.loc.t('토일공휴일_휴무', '🚫 토·일·공휴일 휴무')),
                          SizedBox(height: r.h(16)),
                          Row(
                            children: [
                              _footerSocialBtn(
                                  loc.homeKakao,
                                  const Color(0xFFFFE000),
                                  Colors.black,
                                  () => _openKakaoChannel()),
                              SizedBox(width: r.w(8)),
                              _footerSocialBtn(
                                  context.loc.t('고객센터', '고객센터'),
                                  AppColors.textPrimary,
                                  Colors.white,
                                  () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const ChatScreen()))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: r.w(40)),
                    // 쇼핑 안내
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.homeShopInfo,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: r.sp(14))),
                          SizedBox(height: r.h(14)),
                          _footerLink(context.loc.t('상품 목록', '상품 목록'),
                              () => widget.onNavigate?.call(1)),
                          _footerLink(
                              context.loc.t('배송 안내', '배송 안내'),
                              () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const OrderGuideScreen()))),
                          _footerLink(
                              loc.footerReturnPolicy,
                              () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const OrderGuideScreen()))),
                          _footerLink(
                              context.loc.t('사이즈 가이드', '사이즈 가이드'),
                              () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const OrderGuideScreen()))),
                        ],
                      ),
                    ),
                    SizedBox(width: r.w(40)),
                    // 주문 서비스
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.homeOrderService,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: r.sp(14))),
                          SizedBox(height: r.h(14)),
                          _footerLink(
                              loc.footerGroupOrder,
                              () =>
                                  Navigator.pushNamed(context, '/group-guide')),
                          _footerLink(context.loc.t('주문 현황 조회', '주문 현황 조회'),
                              () => widget.onNavigate?.call(3)),
                          _footerLink(context.loc.t('장바구니', '장바구니'),
                              () => widget.onNavigate?.call(2)),
                        ],
                      ),
                    ),
                    SizedBox(width: r.w(40)),
                    // 고객 지원
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.homeCustomerSupport,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: r.sp(14))),
                          SizedBox(height: r.h(14)),
                          _footerLink(
                              context.loc.t('k_11_문의', '1:1 문의'),
                              () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ChatScreen()))),
                          _footerLink(
                              context.loc.t('자주 묻는 질문', '자주 묻는 질문'),
                              () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const OrderGuideScreen()))),
                          _footerLink(loc.myPageLabel,
                              () => widget.onNavigate?.call(3)),
                          _footerLink(context.loc.t('카카오톡 채널', '카카오톡 채널'),
                              () => _openKakaoChannel()),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.h(28)),
                const Divider(color: Colors.white12),
                SizedBox(height: r.h(16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '© 2025 2FIT Korea Co., Ltd. All rights reserved.',
                      style:
                          TextStyle(color: Colors.white30, fontSize: r.sp(12)),
                    ),
                    Row(
                      children: [
                        Text(loc.homeTermsOfUse,
                            style: TextStyle(
                                color: Colors.white38, fontSize: r.sp(12))),
                        SizedBox(width: r.w(16)),
                        Text(loc.homePrivacyPolicy,
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openKakaoChannel() async {
    final appUrl = Uri.parse('kakaoplus://plusfriend/home/@2fit-mall');
    final webUrl = Uri.parse('https://pf.kakao.com/_MQxjXX/chat');
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _footerInfoRow(String text) {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.h(5)),
      child: Text(text,
          style: TextStyle(color: Colors.white54, fontSize: r.sp(12.5))),
    );
  }

  Widget _footerSocialBtn(
      String label, Color bg, Color fg, VoidCallback onTap) {
    final r = Responsive.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(7)),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: r.sp(12), fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _footerLink(String label, VoidCallback? onTap) {
    final r = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.h(10)),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(label,
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: r.sp(13))),
              ),
            )
          : Text(label,
              style: TextStyle(color: Colors.white38, fontSize: r.sp(13))),
    );
  }

  Widget _buildChatFAB(AppLocalizations loc) {
    return AnimatedBuilder(
      animation: _chatPulse,
      builder: (context, _) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.25 + _chatPulse.value * 0.10),
                blurRadius: 12 + _chatPulse.value * 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.chat_bubble_rounded,
                  color: Colors.white, size: 24),
              // 온라인 도트
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.textPrimary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // 검색 시트
  // ────────────────────────────────────────────
  void _showSearchSheet(BuildContext context, AppLocalizations loc) {
    final r = Responsive.of(context);
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드 높이만큼 시트 밀어올림
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // viewInsets.bottom = 키보드 높이 → Padding으로 시트 위로 밀기
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min, // 내용 크기만큼만 높이 차지
                children: [
                  // 핸들
                  SizedBox(height: r.h(12)),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: r.h(14)),
                  // 타이틀
                  Text(
                    loc.search,
                    style: TextStyle(
                      fontSize: r.sp(16),
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  // 검색 입력 필드
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(r.w(16), r.h(12), r.w(16), r.h(16)),
                    child: TextField(
                      controller: ctrl,
                      autofocus: true,
                      style: TextStyle(fontSize: r.sp(15)),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: loc.searchHint,
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: r.w(16), vertical: r.h(14)),
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          AnalyticsService.logSearch(v.trim());
                        }
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductListScreen(searchQuery: v.trim()),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
// 공지사항 팝업 위젯
// ══════════════════════════════════════════════════════════
class _NoticePopup extends StatefulWidget {
  final List<NoticeModel> notices;
  final AppLanguage language;
  final AppLocalizations loc;
  final VoidCallback onDismissToday;
  const _NoticePopup({
    required this.notices,
    required this.language,
    required this.loc,
    required this.onDismissToday,
  });
  @override
  State<_NoticePopup> createState() => _NoticePopupState();
}

class _NoticePopupState extends State<_NoticePopup> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  int _page = 0;
  // 실제 이미지 비율 (로드 후 동적 업데이트)
  double? _imageAspectRatio;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  void _loadImageSize() {
    final url = widget.notices[_page].imageUrl;
    if (url.isEmpty) return;
    setState(() => _imageAspectRatio = null); // 페이지 전환 시 초기화
    final provider = NetworkImage(url);
    final stream = provider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      if (!mounted) return;
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (w > 0 && h > 0) {
        setState(() => _imageAspectRatio = w / h);
      }
    }));
  }

  // ── 테마별 그라디언트 (이미지 없을 때) ──
  static const Map<String, List<Color>> _themeGradients = {
    'general': [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
    'event': [Color(0xFF8E24AA), Color(0xFFE040FB)],
    'delivery': [AppColors.primary, Color(0xFF42A5F5)],
    'warning': [Color(0xFFBF360C), Color(0xFFFF7043)],
    'update': [Color(0xFF1B5E20), AppColors.success],
    'promo': [Color(0xFFC62828), Color(0xFFE57373)],
    'holiday': [Color(0xFF00695C), Color(0xFF26A69A)],
    'newitem': [Color(0xFF01579B), Color(0xFF29B6F6)],
    'weather': [Color(0xFF0277BD), Color(0xFF81D4FA)],
    'review': [AppColors.accent, Color(0xFFFFCC02)],
  };

  List<Color> _gradientColors(String theme) =>
      _themeGradients[theme] ?? _themeGradients['general']!;

  @override
  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final notice = widget.notices[_page];
    final title = notice.localizedTitle(widget.language);
    final content = notice.localizedContent(widget.language);
    final total = widget.notices.length;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hasImage = notice.imageUrl.isNotEmpty;
    final gradColors = _gradientColors(notice.theme);
    final emoji = NoticeThemeHelper.themeEmoji[notice.theme] ?? '📢';
    final sheetW = sw > 600 ? 480.0 : sw;
    // 실제 이미지 비율로 정확한 높이 계산
    // - 비율 로드 전: 화면 높이의 25%만 (shimmer placeholder)
    // - 비율 로드 후: 실제 비율 기반 높이 (최대 화면 높이의 55%)
    final imgH = _imageAspectRatio != null
        ? (sheetW / _imageAspectRatio!).clamp(120.0, sh * 0.50)
        : (sh * 0.25).clamp(120.0, 180.0);

    return Container(
      width: sheetW,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 드래그 핸들 ──
            Container(
              margin: EdgeInsets.only(top: r.h(10), bottom: r.h(6)),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // ① 이미지 / 그라디언트 배너
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: double.infinity,
              height: imgH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 배경: 이미지 or 그라디언트
                  if (hasImage)
                    NetImage(
                      notice.imageUrl,
                      fit: BoxFit.fill, // imgH가 이미지 비율로 정확히 계산됨 → fill로 딱 맞춤
                      alignment: Alignment.topCenter,
                    )
                  else
                    _buildGradientBg(gradColors, emoji, title),

                  // 우상단 X 버튼
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 17),
                      ),
                    ),
                  ),

                  // 좌하단 '01 / 01' 캡슐
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: r.w(11), vertical: r.h(5)),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(_page + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(11),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // ② 제목 + 본문 텍스트 (이미지 아래 항상 표시)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            if (title.isNotEmpty || content.isNotEmpty)
              Container(
                color: Colors.white,
                width: double.infinity,
                padding:
                    EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), r.h(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: r.sp(17),
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                          letterSpacing: -0.3,
                        ),
                      ),
                    if (title.isNotEmpty && content.isNotEmpty)
                      SizedBox(height: r.h(8)),
                    if (content.isNotEmpty)
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: r.sp(13),
                          color: AppColors.textSecondary,
                          height: 1.65,
                        ),
                      ),
                  ],
                ),
              ),

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // ③ 하단 버튼 바
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 1, color: AppColors.border),
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              widget.onDismissToday();
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: EdgeInsets.zero,
                              shape: const RoundedRectangleBorder(),
                              minimumSize: const Size(0, 52),
                            ),
                            child: Text(
                              loc.homePopupDismiss,
                              style: TextStyle(
                                  fontSize: r.sp(13),
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: total > 1 && _page < total - 1
                                ? () => setState(() {
                                      _page++;
                                      _loadImageSize();
                                    })
                                : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              padding: EdgeInsets.zero,
                              shape: const RoundedRectangleBorder(),
                              minimumSize: const Size(0, 52),
                            ),
                            child: Text(
                              total > 1 && _page < total - 1
                                  ? loc.nextNoticeBtn
                                  : loc.confirm,
                              style: TextStyle(
                                  fontSize: r.sp(13),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // iOS 홈 인디케이터 여백
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _textBoxHeight(String content) => content.isNotEmpty ? 124.0 : 84.0;

  // 테마 그라디언트 배너 (이미지 없을 때)
  Widget _buildGradientBg(List<Color> colors, String emoji, String title) {
    final r = Responsive.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // 장식 원
        Positioned(
          right: -40,
          top: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          left: -30,
          bottom: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        // 이모지 + 제목 (하단 왼쪽)
        Positioned(
          left: 22,
          right: 22,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: r.sp(52))),
              SizedBox(height: r.h(12)),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: r.sp(20),
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  letterSpacing: -0.3,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// 모바일 헤더 Delegate (2줄 구성: 로고행 + 아이콘행)
// ─────────────────────────────────────────────────────────
class _MobileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final VoidCallback onCartTap;
  final VoidCallback onNotifTap;
  final VoidCallback onMyPageTap;
  final VoidCallback onLogoTap;
  final VoidCallback onLanguageTap;
  final BuildContext context;
  final AppLocalizations loc;

  const _MobileHeaderDelegate({
    required this.onMenuTap,
    required this.onSearchTap,
    required this.onCartTap,
    required this.onNotifTap,
    required this.onMyPageTap,
    required this.onLogoTap,
    required this.onLanguageTap,
    required this.context,
    required this.loc,
  });

  // ignore: unused_element
  double _topPadding(BuildContext ctx) => MediaQuery.of(ctx).padding.top;

  @override
  double get minExtent => 100;
  @override
  double get maxExtent => 100 + MediaQuery.of(context).padding.top;

  @override
  bool shouldRebuild(covariant _MobileHeaderDelegate old) => true;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    final r = Responsive.of(ctx);
    final topPad = MediaQuery.of(ctx).padding.top;
    return Material(
      color: AppColors.textPrimary,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상태바 여백
          SizedBox(height: topPad),
          // ── 1행: 햄버거 | 로고(중앙) | 언어버튼 ──
          SizedBox(
            height: 50,
            child: Row(
              children: [
                // 햄버거
                IconButton(
                  icon: const Icon(Icons.menu_rounded,
                      color: Colors.white, size: 26),
                  onPressed: onMenuTap,
                ),
                // 로고 중앙
                Expanded(
                  child: GestureDetector(
                    onTap: onLogoTap,
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo_2fit_white.png',
                        height: 30,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                // 언어 버튼
                Consumer<LanguageProvider>(
                  builder: (_, langProv, __) => GestureDetector(
                    onTap: onLanguageTap,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          vertical: r.h(10), horizontal: r.w(8)),
                      padding: EdgeInsets.symmetric(
                          horizontal: r.w(10), vertical: r.h(5)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(langProv.language.flagEmoji,
                              style: TextStyle(fontSize: r.sp(14))),
                          SizedBox(width: r.w(4)),
                          Text(
                            langProv.language.code,
                            style: TextStyle(
                              fontSize: r.sp(11),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(width: r.w(2)),
                          const Icon(Icons.arrow_drop_down_rounded,
                              color: Colors.white, size: 15),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── 구분선 ──
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          // ── 2행: 검색 · 알림 · 마이페이지 · 장바구니 ──
          SizedBox(
            height: 48,
            child: Row(
              children: [
                // 검색
                _iconBtn(icon: Icons.search_rounded, onTap: onSearchTap),
                _vDivider(),
                // 알림
                Consumer<UserProvider>(
                  builder: (_, userProv, __) {
                    final userId = userProv.user?.id;
                    if (userId == null) {
                      return Expanded(
                        child: InkWell(
                          onTap: onNotifTap,
                          child: const Center(
                            child: Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      );
                    }
                    return Expanded(
                      child: StreamBuilder<int>(
                        stream: FcmService.watchUnreadCount(userId),
                        builder: (ctx2, snap) {
                          final r = Responsive.of(context);

                          final unread = snap.data ?? 0;
                          return Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationCenterScreen()),
                                ),
                                child: const SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: Center(
                                    child: Icon(Icons.notifications_outlined,
                                        color: Colors.white, size: 22),
                                  ),
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  top: 6,
                                  right: 8,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF0000),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unread > 9 ? '9+' : '$unread',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: r.sp(8),
                                            fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
                _vDivider(),
                // 마이페이지
                _iconBtn(
                    icon: Icons.person_outline_rounded, onTap: onMyPageTap),
                _vDivider(),
                // 장바구니
                Consumer<CartProvider>(
                  builder: (_, cart, __) => Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        InkWell(
                          onTap: onCartTap,
                          child: const SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                              child: Icon(Icons.shopping_bag_outlined,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                        if (cart.itemCount > 0)
                          Positioned(
                            top: 6,
                            right: 8,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  cart.itemCount > 9
                                      ? '9+'
                                      : '${cart.itemCount}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: r.sp(8),
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // 관리자
                Consumer<UserProvider>(
                  builder: (_, user, __) => user.isAdmin
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          _vDivider(),
                          SizedBox(
                            width: 44,
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminScreen()),
                              ),
                              child: const Center(
                                child: Icon(Icons.admin_panel_settings_rounded,
                                    color: AppColors.accent, size: 20),
                              ),
                            ),
                          ),
                        ])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 20,
        color: Colors.white.withValues(alpha: 0.15),
      );
}

// ══════════════════════════════════════════════════════
// 배너 쿠폰 다운로드 팝업 (배너 CTA btnAction==3 전용)
// ══════════════════════════════════════════════════════
class _BannerCouponPopup extends StatefulWidget {
  final String? userId;
  final String? couponId; // null이면 전체 다운로드 가능 쿠폰 표시
  final bool isPc;
  const _BannerCouponPopup({this.userId, this.couponId, required this.isPc});

  @override
  State<_BannerCouponPopup> createState() => _BannerCouponPopupState();
}

class _BannerCouponPopupState extends State<_BannerCouponPopup> {
  Set<String> _downloadedIds = {};
  final Map<String, bool> _loadingMap = {};
  bool _initLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDownloaded();
  }

  Future<void> _loadDownloaded() async {
    if (widget.userId != null) {
      final ids = await CouponService.getDownloadedCouponIds(widget.userId!);
      if (mounted) setState(() => _downloadedIds = ids);
    }
    if (mounted) setState(() => _initLoaded = true);
  }

  Future<void> _download(CouponModel coupon) async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('로그인 후 쿠폰을 다운로드할 수 있습니다.'),
        backgroundColor: AppColors.primary,
      ));
      return;
    }
    setState(() => _loadingMap[coupon.id] = true);
    final result = await CouponService.downloadCoupon(
        userId: widget.userId!, coupon: coupon);
    if (!mounted) return;
    setState(() => _loadingMap.remove(coupon.id));

    if (result == '' || result == 'already_downloaded') {
      setState(() => _downloadedIds.add(coupon.id));
      if (result == '') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('「${coupon.name}」 쿠폰이 저장되었습니다! 마이페이지 > 쿠폰함에서 확인하세요.'),
          backgroundColor: AppColors.success,
        ));
      }
    } else if (result == 'limit_exceeded') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('다운로드 수량이 모두 소진되었습니다.'),
        backgroundColor: AppColors.warning,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: AppColors.error));
    }
  }

  String _fmtDiscount(CouponModel c) {
    if (c.type == CouponType.percent) {
      final base = '${c.value.toInt()}% 할인';
      if (c.maxDiscountAmount != null) {
        final max = c.maxDiscountAmount!.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
        return '$base (최대 ${max}원)';
      }
      return base;
    }
    final v = c.value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '${v}원 할인';
  }

  String _fmtExpiry(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} 까지';

  Stream<List<CouponModel>> get _stream => widget.couponId != null
      ? CouponService.watchDownloadableCoupons()
          .map((list) => list.where((c) => c.id == widget.couponId).toList())
      : CouponService.watchDownloadableCoupons();

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return StreamBuilder<List<CouponModel>>(
      stream: _stream,
      builder: (context, snap) {
        final coupons = snap.data ?? [];
        if (snap.connectionState != ConnectionState.waiting &&
            coupons.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
          return const SizedBox.shrink();
        }
        final inner = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(r),
            Flexible(child: _buildList(r, coupons)),
            _buildFooter(r),
          ],
        );
        if (widget.isPc) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ],
              ),
              child: inner,
            ),
          );
        }
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              Flexible(child: inner),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Responsive r) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(20), vertical: r.h(14)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_activity_rounded,
                color: Colors.white, size: 20),
          ),
          SizedBox(width: r.w(12)),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🎁 쿠폰 다운로드',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: r.sp(15),
                      fontWeight: FontWeight.w800)),
              Text('지금 바로 받아서 할인 혜택을 누리세요',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: r.sp(11))),
            ]),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded,
                color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Responsive r, List<CouponModel> coupons) {
    if (!_initLoaded) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
      itemCount: coupons.length,
      separatorBuilder: (_, __) => SizedBox(height: r.h(8)),
      itemBuilder: (_, i) => _buildItem(r, coupons[i]),
    );
  }

  Widget _buildItem(Responsive r, CouponModel coupon) {
    final isDownloaded = _downloadedIds.contains(coupon.id);
    final isLoading = _loadingMap[coupon.id] == true;
    final isPercent = coupon.type == CouponType.percent;
    final accentColor = isPercent ? AppColors.primary : AppColors.primary;
    final remain = coupon.downloadLimit != null
        ? coupon.downloadLimit! - coupon.downloadCount
        : null;
    final isSoldOut = remain != null && remain <= 0;

    return Container(
      decoration: BoxDecoration(
        color: isSoldOut ? const Color(0xFFF9F9F9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDownloaded
              ? const Color(0xFF9C27B0).withValues(alpha: 0.35)
              : AppColors.border,
          width: isDownloaded ? 1.5 : 1,
        ),
        boxShadow: isSoldOut
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Opacity(
        opacity: isSoldOut ? 0.6 : 1.0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(12)),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPercent ? Icons.percent_rounded : Icons.attach_money_rounded,
                color: accentColor,
                size: 20,
              ),
            ),
            SizedBox(width: r.w(12)),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(coupon.name,
                      style: TextStyle(
                          fontSize: r.sp(14), fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: r.h(3)),
                  Text(_fmtDiscount(coupon),
                      style: TextStyle(
                          fontSize: r.sp(13),
                          color: accentColor,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: r.h(2)),
                  Row(children: [
                    Text(_fmtExpiry(coupon.expiresAt),
                        style:
                            TextStyle(fontSize: r.sp(11), color: Colors.grey)),
                    if (remain != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSoldOut
                              ? Colors.grey.withValues(alpha: 0.1)
                              : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isSoldOut ? '마감' : '잔여 ${remain}개',
                          style: TextStyle(
                            fontSize: r.sp(10),
                            fontWeight: FontWeight.w700,
                            color: isSoldOut ? Colors.grey : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ])),
            SizedBox(width: r.w(10)),
            _buildBtn(r, coupon, isDownloaded, isLoading, isSoldOut),
          ]),
        ),
      ),
    );
  }

  Widget _buildBtn(Responsive r, CouponModel coupon, bool isDownloaded,
      bool isLoading, bool isSoldOut) {
    if (isDownloaded) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(7)),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_rounded,
              size: 13, color: AppColors.primaryLight),
          SizedBox(width: r.w(3)),
          Text('완료',
              style: TextStyle(
                  fontSize: r.sp(12),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight)),
        ]),
      );
    }
    if (isSoldOut) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: r.w(10), vertical: r.h(7)),
        decoration: BoxDecoration(
            color: AppColors.surfaceGray,
            borderRadius: BorderRadius.circular(8)),
        child: Text('마감',
            style: TextStyle(
                fontSize: r.sp(12),
                fontWeight: FontWeight.w700,
                color: Colors.grey)),
      );
    }
    return GestureDetector(
      onTap: isLoading ? null : () => _download(coupon),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(7)),
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [AppColors.primaryLight, Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isLoading ? Colors.grey[200] : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isLoading
            ? SizedBox(
                width: r.w(36),
                height: r.h(16),
                child: const Center(
                    child: SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.grey))))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.download_rounded,
                    size: 13, color: Colors.white),
                SizedBox(width: r.w(3)),
                Text('받기',
                    style: TextStyle(
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
      ),
    );
  }

  Widget _buildFooter(Responsive r) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(10)),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceGray))),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 12, color: Colors.grey[400]),
        SizedBox(width: r.w(6)),
        Expanded(
            child: Text('마이페이지 > 쿠폰함에서 확인하세요',
                style: TextStyle(fontSize: r.sp(11), color: Colors.grey))),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(4)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('닫기', style: TextStyle(fontSize: r.sp(13))),
        ),
      ]),
    );
  }
}
