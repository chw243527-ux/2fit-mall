import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../main_screen.dart' show kPcBreakpoint;
import '../../widgets/pc_layout.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/product_card.dart';
import '../products/product_list_screen.dart';
import '../products/product_detail_screen.dart';
import '../products/category_detail_screen.dart';
import '../admin/admin_screen.dart';
import '../../services/analytics_service.dart';
import '../chat/chat_screen.dart';
import '../../widgets/app_drawer.dart';
import '../notifications/notification_center_screen.dart';
import '../../services/fcm_service.dart';
import '../../services/product_service.dart';

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
  int _bannerIndex = 0;
  String _selectedCategoryKey = 'all'; // 카테고리 key (언어 무관)
  String? _expandedCatName;            // 사이드바 펼쳐진 카테고리 이름
  late AnimationController _chatPulse;

  // 카테고리 정의 (key 기반, 다국어 텍스트는 loc에서)
  List<Map<String, dynamic>> _getCategoryItems(AppLocalizations loc) => [
    {'key': 'all',       'label': loc.catAll,       'icon': Icons.grid_view_rounded,        'color': const Color(0xFF1A1A1A)},
    {'key': '상의',      'label': loc.catTop,       'icon': Icons.dry_cleaning_rounded,     'color': const Color(0xFF1565C0)},
    {'key': '하의',      'label': loc.catBottom,    'icon': Icons.style_rounded,            'color': const Color(0xFF2E7D32)},
    {'key': '세트',      'label': loc.catSet,       'icon': Icons.checkroom_rounded,        'color': const Color(0xFFE53935)},
    {'key': '아우터',    'label': loc.catOuter,     'icon': Icons.layers_rounded,           'color': const Color(0xFF37474F)},
    {'key': '스킨슈트',  'label': '스킨슈트',        'icon': Icons.accessibility_new_rounded, 'color': const Color(0xFF00838F)},
    {'key': '악세사리',  'label': loc.catAccessory, 'icon': Icons.backpack_rounded,         'color': const Color(0xFF6A1B9A)},
    {'key': '이벤트',    'label': '이벤트',          'icon': Icons.local_offer_rounded,      'color': const Color(0xFFFF6B35)},
  ];

  @override
  void initState() {
    super.initState();
    _chatPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // 공지사항 팝업은 MainScreen 레벨에서 처리됨
  }

  @override
  void dispose() {
    _chatPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    // PC 웹이면 PC 전용 레이아웃, 모바일이면 모바일 레이아웃
    if (isPcWeb(context)) return _buildPcLayout(loc);
    return _buildMobileLayout(loc);
  }

  // ─── PC 레이아웃 (넓은 화면 최적화, PC 전용 섹션 사용) ─────────────────
  // PC 드로어용 GlobalKey
  final GlobalKey<ScaffoldState> _pcScaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildPcLayout(AppLocalizations loc) {
    // Scaffold 제거: main_screen._PcLayout의 Scaffold 안에서 실행되므로
    // 중첩 Scaffold를 피하고 CustomScrollView만 반환
    return CustomScrollView(
      slivers: [
        // PC 전용 배너 (이미지 없이 그라디언트만)
        SliverToBoxAdapter(child: _buildPcBannerOnly(loc)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // 베스트 상품 (5열 PC 그리드)
        SliverToBoxAdapter(
          child: _buildPcProductGridSection(
            title: loc.sectionBestSeller,
            englishTitle: loc.sectionBestSellerSub,
            accentColor: const Color(0xFFE53935),
            isNew: false,
            loc: loc,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // 단체주문 섹션
        SliverToBoxAdapter(child: _buildPcGroupOrderSection(loc)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        // 신상품 (5열 PC 그리드)
        SliverToBoxAdapter(
          child: _buildPcProductGridSection(
            title: loc.sectionNewArrival,
            englishTitle: loc.sectionNewArrivalSub,
            accentColor: const Color(0xFF1A1A1A),
            isNew: true,
            loc: loc,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildBrandFeatureSection()),
        SliverToBoxAdapter(child: _buildPcFooter(loc)),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  // ── PC 카테고리 드로어 (햄버거 버튼으로 열림) ──
  Widget _buildPcCategoryDrawer(AppLocalizations loc) {
    return Drawer(
      width: 300,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ─── 드로어 헤더 (다크 배경) ───
          Container(
            color: const Color(0xFF111111),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20, right: 8, bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 카테고리 타이틀 + 닫기
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.homeCategory,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ─── 마이페이지 버튼 ───
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onNavigate?.call(3);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loc.navMyPage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.5), size: 13),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // ─── 전체 상품 바로가기 ───
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: Color(0xFF111111), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.homeAllProducts,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFBBBBBB)),
                ],
              ),
            ),
          ),
          // ─── 카테고리 아코디언 목록 ───
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: getCategories(loc).map((cat) {
                  final isExpanded = _expandedCatName == cat.name;
                  final subs = cat.subCategories.where((s) => !s.name.startsWith('전체')).toList();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => setState(() {
                          _expandedCatName = isExpanded ? null : cat.name;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(cat.icon, color: cat.color, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isExpanded ? FontWeight.w800 : FontWeight.w600,
                                    color: isExpanded ? cat.color : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => CategoryDetailScreen(
                                      categoryName: cat.name,
                                      categoryColor: cat.color,
                                      categoryIcon: cat.icon,
                                      subCategories: cat.subCategories,
                                    ),
                                  ));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cat.color.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(loc.homeCategoryAll, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cat.color)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: isExpanded ? cat.color : const Color(0xFFBBBBBB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 서브카테고리 펼침
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.03),
                            border: Border(
                              left: BorderSide(color: cat.color.withValues(alpha: 0.25), width: 3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: subs.map((sub) {
                                final isSubSel = _selectedCategoryKey == '${cat.name}/${sub.name}';
                                return InkWell(
                                  onTap: () {
                                    setState(() => _selectedCategoryKey = '${cat.name}/${sub.name}');
                                    Navigator.pop(context);
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ProductListScreen(initialCategory: sub.filter),
                                    ));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(52, 10, 20, 10),
                                    color: isSubSel ? cat.color.withValues(alpha: 0.07) : Colors.transparent,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 5, height: 5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSubSel ? cat.color : const Color(0xFFCCCCCC),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            sub.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSubSel ? FontWeight.w700 : FontWeight.w500,
                                              color: isSubSel ? cat.color : const Color(0xFF555555),
                                            ),
                                          ),
                                        ),
                                        if (sub.tag != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: sub.tag == 'BEST'
                                                  ? const Color(0xFFFF6B35)
                                                  : sub.tag == 'NEW'
                                                      ? cat.color
                                                      : const Color(0xFFE53935),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              sub.tag!,
                                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_rounded, size: 16, color: Color(0xFF111111)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.homeCategory,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111111),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductListScreen()),
                  ),
                  child: const Text(
                    '전체',
                    style: TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // ── 카테고리 아코디언 목록 ──
          ...getCategories(loc).map((cat) {
            final isExpanded = _expandedCatName == cat.name;
            final subs = cat.subCategories.where((s) => !s.name.startsWith('전체')).toList();
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isExpanded ? FontWeight.w800 : FontWeight.w500,
                              color: isExpanded ? cat.color : const Color(0xFF333333),
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: isExpanded ? cat.color : const Color(0xFFBBBBBB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 서브카테고리 펼침
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.03),
                      border: Border(
                        left: BorderSide(color: cat.color.withValues(alpha: 0.3), width: 2.5),
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
                            padding: const EdgeInsets.fromLTRB(40, 8, 14, 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 4, height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cat.color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  loc.homeViewAll,
                                  style: TextStyle(
                                    fontSize: 12,
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
                          final isSubSel = _selectedCategoryKey == '${cat.name}/${sub.name}';
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedCategoryKey = '${cat.name}/${sub.name}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductListScreen(initialCategory: sub.filter),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(40, 7, 14, 7),
                              color: isSubSel ? cat.color.withValues(alpha: 0.06) : Colors.transparent,
                              child: Row(
                                children: [
                                  Container(
                                    width: 4, height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSubSel ? cat.color : const Color(0xFFCCCCCC),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      sub.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSubSel ? FontWeight.w700 : FontWeight.w400,
                                        color: isSubSel ? cat.color : const Color(0xFF555555),
                                      ),
                                    ),
                                  ),
                                  if (sub.tag != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: sub.tag == 'BEST'
                                            ? const Color(0xFFFF6B35)
                                            : sub.tag == 'NEW'
                                                ? cat.color
                                                : const Color(0xFFE53935),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        sub.tag!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: const Color(0xFFF5F5F5)),
              ],
            );
          }),
          const SizedBox(height: 8),
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
    final provider = context.watch<ProductProvider>();
    List<ProductModel> allProds = provider.products;
    if (allProds.isEmpty) allProds = ProductService.getAllProductsSync();

    final List<ProductModel> products;
    if (isNew) {
      products = allProds.where((p) => p.isNew).toList();
    } else {
      products = List<ProductModel>.from(allProds)
        ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }

    if (products.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  englishTitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: accentColor == const Color(0xFF1A1A1A) ? const Color(0xFFAAAAAA) : accentColor,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
              ],
            ),
            const Spacer(),
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      englishTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accentColor == const Color(0xFF1A1A1A) ? const Color(0xFFAAAAAA) : accentColor,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111111),
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
                          ? const ProductListScreen()
                          : const ProductListScreen(initialSortBy: '인기순'),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'VIEW ALL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 4컬럼 그리드
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: display.length,
              itemBuilder: (_, i) => _buildPcHomeProductCard(display[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ── PC 전용 NavBar (배너 위에 표시) ──
  Widget _buildPcNavBar(AppLocalizations loc) {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      height: 28,
                      child: Image.asset(
                        'assets/images/logo_2fit_white.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text(
                          '2FIT',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  tooltip: loc.search,
                  onPressed: () => _showSearchSheet(context, loc),
                ),
                Consumer<CartProvider>(
                  builder: (ctx, cart, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                        tooltip: loc.cart,
                        onPressed: () => widget.onNavigate?.call(2),
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          top: 6, right: 6,
                          child: Container(
                            width: 14, height: 14,
                            decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                            child: Center(child: Text(cart.itemCount > 9 ? '9+' : '${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900))),
                          ),
                        ),
                    ],
                  ),
                ),
                Consumer<UserProvider>(
                  builder: (ctx, userProv, _) {
                    final userId = userProv.user?.id;
                    if (userId == null) {
                      return IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20), onPressed: () => _showNotificationsSheet(context, loc));
                    }
                    return StreamBuilder<int>(
                      stream: FcmService.watchUnreadCount(userId),
                      builder: (ctx2, snap) {
                        final unread = snap.data ?? 0;
                        return Stack(clipBehavior: Clip.none, children: [
                          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterScreen()))),
                          if (unread > 0) Positioned(top: 6, right: 6, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFFFF0000), shape: BoxShape.circle), child: Center(child: Text(unread > 9 ? '9+' : '$unread', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900))))),
                        ]);
                      },
                    );
                  },
                ),
                // ── 마이페이지 버튼 (라벨 포함) ──
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(3),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            color: Color(0xFF111111), size: 16),
                        const SizedBox(width: 6),
                        Text(loc.navMyPage,
                            style: const TextStyle(
                                color: Color(0xFF111111),
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                Consumer<UserProvider>(
                  builder: (ctx, user, _) => user.isAdmin
                      ? IconButton(icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFE53935), size: 22), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())))
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── PC 전용 배너 (외부 이미지 없이 그라디언트만 사용, 항상 표시됨) ──
  Widget _buildPcBannerOnly(AppLocalizations loc) {
    final banners = [
      {
        'title': 'JUST\nDO IT.',
        'sub': loc.language == AppLanguage.korean ? '2025 S/S 컬렉션 · 고퀄리티 단체 스포츠웨어' : '2025 S/S COLLECTION · Premium Sportswear',
        'tag': 'NEW SEASON',
        'accent': const Color(0xFFE53935),
        'bg1': const Color(0xFF0D0D0D),
        'bg2': const Color(0xFF1A1A1A),
        'bgMid': const Color(0xFF141414),
        'btnAction': 0,
        'icon': Icons.sports_soccer_rounded,
        'desc': loc.language == AppLanguage.korean
            ? loc.homeBrandSpecialty
            : 'Team Uniforms & Custom Sportswear',
      },
      {
        'title': 'BEST\nSELLER.',
        'sub': loc.language == AppLanguage.korean ? '2FIT 인기 상품 · 최대 10% 단체 할인' : 'TOP PRODUCTS · Up to 10% Group Discount',
        'tag': 'POPULAR',
        'accent': const Color(0xFFFF6B35),
        'bg1': const Color(0xFF1A0000),
        'bg2': const Color(0xFF2D0000),
        'bgMid': const Color(0xFF220000),
        'btnAction': 3,
        'icon': Icons.local_fire_department_rounded,
        'desc': loc.language == AppLanguage.korean
            ? '30인 이상 5% · 50인 이상 10% 할인'
            : '5% off 30+ · 10% off 50+ people',
      },
      {
        'assetImage': 'assets/images/banner_custom_fit.jpg',
        'btnAction': 0,
      },
    ];

    // 배너 높이를 화면 너비 기준 3:2 비율로 동적 계산 (이미지 실제 비율 1536x1024)
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 2 / 3;

    return Container(
      color: const Color(0xFF111111),
      child: Column(
        children: [
          SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: PageController(),
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemCount: banners.length,
              itemBuilder: (_, idx) {
                final b = banners[idx];
                // 로컬 asset 이미지 배너 처리
                final assetImage = b['assetImage'] as String?;
                if (assetImage != null && assetImage.isNotEmpty) {
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: Image.asset(
                        assetImage,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
                      ),
                    ),
                  );
                }
                // 이미지 URL 배너 처리
                final imageUrl = b['imageUrl'] as String?;
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(color: const Color(0xFF111111),
                              child: const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
                    ),
                  );
                }
                final bg1 = b['bg1'] as Color;
                final bg2 = b['bg2'] as Color;
                final bgMid = b['bgMid'] as Color;
                final accent = b['accent'] as Color;
                final icon = b['icon'] as IconData;
                final btnAction = b['btnAction'] as int;
                void onShop() {
                  switch (btnAction) {
                    case 3:
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const ProductListScreen(initialSortBy: '인기순'),
                      ));
                      break;
                    default:
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                  }
                }
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [bg1, bgMid, bg2],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 왼쪽: 텍스트 컨텐츠
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      b['tag'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    b['title'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 64,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2,
                                      height: 0.95,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    b['sub'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    b['desc'] as String,
                                    style: TextStyle(
                                      color: accent.withValues(alpha: 0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: onShop,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: const Text(
                                            'SHOP NOW',
                                            style: TextStyle(
                                              color: Color(0xFF111111),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => Navigator.pushNamed(context, '/group-guide'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            loc.homeBannerGroupOrder,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // 오른쪽: 아이콘 + 통계
                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.05),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.15)),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // 통계 배지들
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _pcBannerStat('1,200+', loc.homeBannerTeams),
                                      Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 16)),
                                      _pcBannerStat('98%', loc.homeBannerSatisfaction),
                                      Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 16)),
                                      _pcBannerStat('15일', loc.homeBannerDelivery),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // 인디케이터
          Container(
            color: const Color(0xFF0D0D0D),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map((e) {
                final active = _bannerIndex == e.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: active ? 24 : 6,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pcBannerStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }

  // ── PC 전용 카테고리 사이드바 (아코디언) ──
  // ── PC 배너 섹션 (모바일과 동일, 높이만 조정) ──
  Widget _buildPcBannerSection(AppLocalizations loc) {
    final banners = [
      {
        'title': 'JUST\nDO IT.',
        'sub': loc.language == AppLanguage.korean ? '2025 S/S 컬렉션' : '2025 S/S COLLECTION',
        'tag': 'NEW SEASON',
        'bg1': const Color(0xFF0D0D0D),
        'bg2': const Color(0xFF1A1A1A),
        'image': 'https://images.unsplash.com/photo-1513689125086-6c432170e843?w=1600&auto=format&fit=crop',
        'btnAction': 0,
      },
      {
        'title': 'BEST\nSELLER.',
        'sub': loc.language == AppLanguage.korean ? '2FIT 인기 상품' : 'TOP PRODUCTS',
        'tag': 'POPULAR',
        'bg1': const Color(0xFF1A0000),
        'bg2': const Color(0xFF330000),
        'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1600&auto=format&fit=crop',
        'btnAction': 3,
      },
      {
        'assetImage': 'assets/images/banner_custom_fit.jpg',
        'btnAction': 0,
      },
    ];

    return Container(
      color: const Color(0xFF111111),
      child: Column(
        children: [
          // ── PC 상단 네비게이션 바 ──
          Container(
            color: const Color(0xFF111111),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // ── 햄버거 버튼 (카테고리 드로어 열기) ──
                      IconButton(
                        icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                        tooltip: loc.homeCategory,
                        onPressed: () => _pcScaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 4),
                      // 로고
                      GestureDetector(
                        onTap: () => widget.onNavigate?.call(0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            height: 28,
                            child: Image.asset(
                              'assets/images/logo_2fit_white.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text(
                                '2FIT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // 검색
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                        tooltip: loc.search,
                        onPressed: () => _showSearchSheet(context, loc),
                      ),
                      // 장바구니
                      Consumer<CartProvider>(
                        builder: (ctx, cart, _) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                              tooltip: loc.cart,
                              onPressed: () => widget.onNavigate?.call(2),
                            ),
                            if (cart.itemCount > 0)
                              Positioned(
                                top: 6, right: 6,
                                child: Container(
                                  width: 14, height: 14,
                                  decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
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
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                              onPressed: () => _showNotificationsSheet(context, loc),
                            );
                          }
                          return StreamBuilder<int>(
                            stream: FcmService.watchUnreadCount(userId),
                            builder: (ctx2, snap) {
                              final unread = snap.data ?? 0;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                                    ),
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      top: 6, right: 6,
                                      child: Container(
                                        width: 14, height: 14,
                                        decoration: const BoxDecoration(color: Color(0xFFFF0000), shape: BoxShape.circle),
                                        child: Center(
                                          child: Text(
                                            unread > 9 ? '9+' : '$unread',
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
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
                        icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                        tooltip: loc.navMyPage,
                        onPressed: () => widget.onNavigate?.call(3),
                      ),
                      // 관리자 대시보드 (관리자 로그인 시에만 표시)
                      Consumer<UserProvider>(
                        builder: (ctx, user, _) => user.isAdmin
                            ? Tooltip(
                                message: loc.homeAdminDashboard,
                                child: IconButton(
                                  icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFE53935), size: 22),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminScreen()),
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
              final b = e.value;
              final btnAction = b['btnAction'] as int? ?? 0;
              void onShop() {
                switch (btnAction) {
                  case 3:
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen(initialSortBy: '인기순')));
                    break;
                  default:
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                }
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
                    child: Image.asset(
                      assetImage,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
                    ),
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
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(color: const Color(0xFF111111),
                              child: const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
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
                    child: Image.network(
                      b['image'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2A2A2A)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 60),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    b['tag'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF111111),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  b['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  b['sub'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: onShop,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      'SHOP NOW',
                                      style: TextStyle(
                                        color: Color(0xFF111111),
                                        fontSize: 12,
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
                    top: 20, right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_bannerIndex + 1} / 2',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          // 모바일과 동일한 점 인디케이터
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map((e) {
                final active = _bannerIndex == e.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: active ? 24 : 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.5),
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
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
    final items = _getCategoryItems(loc);
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (_, i) => _buildPcCategoryTabItem(items[i], loc),
                  ),
                ),
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  Widget _buildPcCategoryTabItem(Map<String, dynamic> item, AppLocalizations loc) {
    final isSelected = _selectedCategoryKey == item['key'];
    final label = item['label'] as String;
    final key = item['key'] as String;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryKey = key);
        if (key == 'all') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
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
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProductListScreen(initialCategory: key)));
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? const Color(0xFF111111) : const Color(0xFFDDDDDD),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF444444),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ── PC 상품 그리드 섹션 (신상품/베스트 — 모바일 가로 스크롤 대신 5컬럼 그리드) ──
  Widget _buildPcProductGridSection({
    required String title,
    required String englishTitle,
    required Color accentColor,
    required bool isNew,
    required AppLocalizations loc,
  }) {
    final provider = context.watch<ProductProvider>();
    // 로딩 중이더라도 더미 데이터(sync)로 즉시 표시
    List<ProductModel> allProds = provider.products;
    if (allProds.isEmpty) {
      allProds = ProductService.getAllProductsSync();
    }
    final List<ProductModel> products;
    if (isNew) {
      products = allProds.where((p) => p.isNew).toList();
    } else {
      products = List<ProductModel>.from(allProds)
        ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    // 빈 리스트이면 로딩 스켈레톤 표시
    if (products.isEmpty) {
      return Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 1, color: const Color(0xFFF0F0F0)),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(englishTitle.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w800,
                                color: accentColor == const Color(0xFF1A1A1A)
                                    ? const Color(0xFFAAAAAA) : accentColor,
                                letterSpacing: 2.5)),
                          const SizedBox(height: 3),
                          Text(title,
                              style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w900,
                                color: Color(0xFF111111), letterSpacing: -0.5, height: 1.1)),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 24, height: 24,
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
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          // 헤더
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          englishTitle.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: accentColor == const Color(0xFF1A1A1A)
                                ? const Color(0xFFAAAAAA)
                                : accentColor,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111111),
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
                              ? const ProductListScreen()
                              : const ProductListScreen(initialSortBy: '인기순'),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'VIEW ALL',
                          style: TextStyle(
                            fontSize: 11,
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
          const SizedBox(height: 20),
          // 5컬럼 그리드
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: display.length,
                  itemBuilder: (_, i) => _buildPcHomeProductCard(display[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPcHomeProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF0F0F0),
                              child: const Icon(Icons.checkroom_rounded, size: 40, color: Color(0xFFCCCCCC)),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(Icons.checkroom_rounded, size: 40, color: Color(0xFFCCCCCC)),
                          ),
                  ),
                  if (product.isNew)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                    ),
                  if (product.isSale)
                    Positioned(
                      top: product.isNew ? 32 : 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                    ),
                ],
              ),
            ),
            // 정보
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2FIT KOREA',
                        style: TextStyle(fontSize: 9, color: Color(0xFF888888), letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      product.localizedName(_lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A), height: 1.3),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_fmtPrice(product.price)}${loc.wonUnit2}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF111111)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFB300)),
                        const SizedBox(width: 2),
                        Text('${product.rating}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                        const SizedBox(width: 3),
                        Text('(${product.reviewCount})',
                            style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA))),
                      ],
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
  Widget _buildPcGroupOrderSection(AppLocalizations loc) {
    List<ProductModel> allProds = context.watch<ProductProvider>().products;
    // 비어있으면 더미 데이터로 즉시 폴백
    if (allProds.isEmpty) {
      allProds = ProductService.getAllProductsSync();
    }
    final groupProducts = allProds.where((p) => p.isGroupOnly).toList();
    if (groupProducts.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('GROUP ONLY',
                    style: TextStyle(color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TEAM ORDER', style: TextStyle(color: Color(0xFFFF6B35),
                      fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
                  Text(loc.homeGroupOnly, style: const TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const ProductListScreen(initialCategory: '단체주문'))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(loc.homeViewAll, style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _groupBadge('👥 5명 이상'),
              _groupBadge(loc.homeGroupBadge),
              _groupBadge('🚀 빠른 제작'),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: groupProducts.length,
            itemBuilder: (ctx, i) => ProductCard(product: groupProducts[i]),
          ),
          const SizedBox(height: 20),
          // 안내 메시지
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: Color(0xFFFF6B35), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.homeGroupOrderNote,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
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
  Widget _buildPcNewArrivalCta() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text('2025 S/S COLLECTION',
                      style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                const SizedBox(height: 14),
                Text(
                  loc.homeNewSeason,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.homeNewSeasonSub,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProductListScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF111111),
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  elevation: 0,
                ),
                child: Text(loc.homeNewArrivalsBtn,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProductListScreen(initialCategory: '이벤트'))),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: Text(loc.homeEventBtn,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 모바일 레이아웃 ────────────────────────────
  Widget _buildMobileLayout(AppLocalizations loc) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // ── 메인 스크롤 콘텐츠 ──
          CustomScrollView(
            slivers: [
              // 헤더 높이만큼 상단 여백 (배너가 헤더 아래에서 시작)
              SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 56)),
              // 배너 (헤더 바로 아래)
              SliverToBoxAdapter(child: _buildBannerSection(loc)),
              // 베스트 상품
              SliverToBoxAdapter(child: _buildBestSection(loc)),
              // 단체주문전용 상품 섹션
              SliverToBoxAdapter(child: _buildGroupOrderSection(loc)),
              SliverToBoxAdapter(child: _buildNewArrivalsSection(loc)),
              SliverToBoxAdapter(child: _buildBrandFeatureSection()),
              if (kIsWeb && MediaQuery.of(context).size.width >= kPcBreakpoint)
                SliverToBoxAdapter(child: _buildPcFooter(loc)),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          // ── 상단 오버레이 헤더 (1행, 투명→다크 그라디언트) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildOverlayHeader(loc),
          ),
        ],
      ),
      floatingActionButton: _buildChatFAB(loc),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── 1행 오버레이 헤더 ──
  Widget _buildOverlayHeader(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF111111),
            const Color(0xFF111111).withValues(alpha: 0.92),
            const Color(0xFF111111).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.75, 1.0],
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
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
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
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/2fit_logo.png',
                        height: 32,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (_, __, ___) => const Text(
                          '2FIT KOREA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // ── 우: 검색 + 장바구니 + 언어버튼 ──
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                onPressed: () => _showSearchSheet(context, loc),
              ),
              Consumer<CartProvider>(
                builder: (ctx, cart, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                      onPressed: () => widget.onNavigate?.call(2),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          width: 15, height: 15,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
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
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(langProv.language.flagEmoji,
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 3),
                        Text(
                          langProv.language.code,
                          style: const TextStyle(
                            fontSize: 10,
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
  Widget _buildGroupOrderSection(AppLocalizations loc) {
    List<ProductModel> allProds = context.watch<ProductProvider>().products;
    if (allProds.isEmpty) allProds = ProductService.getAllProductsSync();
    final groupProducts = allProds.where((p) => p.isGroupOnly).toList();
    if (groupProducts.isEmpty) return const SizedBox.shrink();
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'GROUP ONLY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TEAM ORDER',
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Text(
                      loc.homeGroupOnly,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                      builder: (_) => const ProductListScreen(initialCategory: '단체주문'),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      loc.homeViewAll,
                      style: const TextStyle(
                        fontSize: 11,
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
          const SizedBox(height: 8),
          // 5명 이상 안내 배지
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                _groupBadge('👥 5명 이상'),
                _groupBadge(loc.homeGroupBadge),
                _groupBadge('🚀 빠른 제작'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // PC처럼 그리드 레이아웃
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: groupProducts.length,
              itemBuilder: (ctx, i) => ProductCard(product: groupProducts[i]),
            ),
          ),
          const SizedBox(height: 16),
          // 단체 커스텀 오더 신청 → 상품 상세에서만 가능 안내
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: Color(0xFFFF6B35), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.homeGroupOrderNote2,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _groupBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.5)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ── 상단 알림 띠배너 ──
  // ignore: unused_element
  Widget _buildNoticeBanner() {
    return Container(
      color: const Color(0xFFE53935),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text(
            '🎉 봄 시즌 SALE 최대 40% 할인 · 3만원 이상 무료배송',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
          SizedBox(width: 6),
          Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  // ── 퀵메뉴 바 (이벤트/신상품) ──
  // ignore: unused_element
  Widget _buildQuickMenuBar(AppLocalizations loc) {
    final menus = [
      {'icon': Icons.local_offer_rounded, 'label': loc.homeEvent, 'color': const Color(0xFFE53935)},
      {'icon': Icons.fiber_new_rounded, 'label': loc.homeNewArrival, 'color': const Color(0xFF6A1B9A)},
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: menus.asMap().entries.map((e) {
          final m = e.value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                switch (e.key) {
                  case 0:
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen(initialCategory: '이벤트')));
                    break;
                  case 1:
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                    break;
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: (m['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(m['label'] as String,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
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
    final saleProducts = context.watch<ProductProvider>().products
        .where((p) => p.isSale || (p.originalPrice != null && p.originalPrice! > p.price))
        .take(6).toList();
    if (saleProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            color: const Color(0xFFE53935),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('FLASH SALE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text(loc.homeMaxDiscount, style: const TextStyle(color: Color(0xFFE53935), fontSize: 11, fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                  child: Text(loc.homeViewAllArrow, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // 상품 가로 스크롤
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: saleProducts.length,
              itemBuilder: (_, i) {
                final p = saleProducts[i];
                final discount = p.originalPrice != null
                    ? ((1 - p.price / p.originalPrice!) * 100).round()
                    : 0;
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              child: p.images.isNotEmpty
                                  ? Image.network(p.images.first, width: 130, height: 120, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(height: 120, color: const Color(0xFFF5F5F5),
                                          child: const Icon(Icons.checkroom_rounded, color: Color(0xFFCCCCCC), size: 40)))
                                  : Container(height: 120, color: const Color(0xFFF5F5F5)),
                            ),
                            if (discount > 0)
                              Positioned(top: 6, left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(3)),
                                  child: Text('-$discount%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                              const SizedBox(height: 2),
                              if (p.originalPrice != null)
                                Text('${_fmtPrice(p.originalPrice!)}${loc.wonUnit2}',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA), decoration: TextDecoration.lineThrough)),
                              Text('${_fmtPrice(p.price)}${loc.wonUnit2}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFE53935))),
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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // ── 배너 1: 신상품 안내 ──
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
            child: Container(
              color: const Color(0xFF0D1B2A),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(3)),
                          child: const Text('NEW ARRIVAL', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 10),
                        Text('2025 S/S\n${loc.homeNewArrival}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.3)),
                        const SizedBox(height: 6),
                        Text(loc.homeLatestCollection, style: const TextStyle(color: Color(0xFF8899AA), fontSize: 13)),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          child: Text(loc.homeNewArrivalsArrow, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.fiber_new_rounded, color: Color(0xFF1E3A5F), size: 90),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          // ── 배너 2: 이벤트 특가 ──
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen(initialCategory: '이벤트'))),
            child: Container(
              color: const Color(0xFF1A0A0A),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(3)),
                          child: const Text('EVENT SALE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 10),
                        Text(loc.homeSeasonDiscount, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.3)),
                        const SizedBox(height: 6),
                        Text(loc.homeSeasonDiscountSub, style: const TextStyle(color: Color(0xFF9988AA), fontSize: 13)),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          child: Text(loc.homeEventArrow, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.local_offer_rounded, color: Color(0xFF5F1E1E), size: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 브랜드 특징 섹션 ──
  Widget _buildBrandFeatureSection() {
    final features = [
      {'icon': Icons.local_shipping_outlined, 'title': loc.homeFreeShipping, 'sub': loc.homeFreeShippingSub},
      {'icon': Icons.verified_outlined, 'title': loc.homeQualityGuarantee, 'sub': loc.homeQualityGuaranteeSub},
      {'icon': Icons.replay_rounded, 'title': loc.home7DayExchange, 'sub': loc.home7DayExchangeSub},
      {'icon': Icons.headset_mic_outlined, 'title': loc.homeConsultation, 'sub': loc.homeConsultationSub},
    ];
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: features.map((f) => Expanded(
          child: Column(
            children: [
              Icon(f['icon'] as IconData, size: 28, color: const Color(0xFF333333)),
              const SizedBox(height: 6),
              Text(f['title'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              Text(f['sub'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ────────────────────────────────────────────
  // 앱바: Nike 스타일 — 블랙 배경, 흰 로고, 최소 UI
  // ────────────────────────────────────────────
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
    final langProv = context.watch<LanguageProvider>();
    return GestureDetector(
      onTap: () => _showLanguageSheet(context, loc),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(langProv.language.flagEmoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              langProv.language.code,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  // ── 언어 선택 바텀시트 ──
  void _showLanguageSheet(BuildContext context, AppLocalizations loc) {
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
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.selectLanguage,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            // 스크롤 가능한 언어 목록 (모든 언어 표시)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.55,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AppLanguage.values.map((lang) {
                    final isSelected = langProv.language == lang;
                    return GestureDetector(
                      onTap: () {
                        langProv.setLanguage(lang);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFE8E8E8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(lang.flagEmoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 14),
                            Text(
                              lang.nativeName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
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
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Text(
                      loc.notifications,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        notifProv.markAllAsRead();
                        setModalState(() {});
                      },
                      child: Text(loc.homeMarkReadAll,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
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
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(loc.noNotifications,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFFAAAAAA))),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 60),
                      itemBuilder: (_, i) {
                        final n = list[i];
                        final iconData = n.type == 'order'
                            ? Icons.receipt_long_rounded
                            : n.type == 'promo'
                                ? Icons.local_offer_rounded
                                : Icons.info_outline_rounded;
                        final iconColor = n.type == 'order'
                            ? const Color(0xFF1565C0)
                            : n.type == 'promo'
                                ? const Color(0xFFE53935)
                                : const Color(0xFF43A047);
                        return InkWell(
                          onTap: () {
                            notifProv.markAsRead(n.id);
                            setModalState(() {});
                          },
                          child: Container(
                            color: n.isRead
                                ? Colors.white
                                : const Color(0xFFFFF8E1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
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
                                const SizedBox(width: 12),
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
                                                  fontSize: 13,
                                                  fontWeight: n.isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  color: const Color(0xFF1A1A1A),
                                                )),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFE53935),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(n.body,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF888888),
                                          )),
                                      const SizedBox(height: 3),
                                      Text(
                                        _timeAgo(n.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFBBBBBB),
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
  Widget _buildBannerSection(AppLocalizations loc) {
    final banners = [
      {
        'title': 'JUST\nDO IT.',
        'sub': loc.language == AppLanguage.korean ? '2025 S/S 컬렉션' : '2025 S/S COLLECTION',
        'tag': 'NEW SEASON',
        'accent': const Color(0xFFE53935),
        'bg1': const Color(0xFF0D0D0D),
        'bg2': const Color(0xFF1A1A1A),
        'icon': Icons.sports_soccer_rounded,
        'btnAction': 0,
      },
      {
        'title': 'BEST\nSELLER.',
        'sub': loc.language == AppLanguage.korean ? '2FIT 인기 상품' : 'TOP PRODUCTS',
        'tag': 'POPULAR',
        'accent': const Color(0xFFFF6B35),
        'bg1': const Color(0xFF1A0000),
        'bg2': const Color(0xFF330000),
        'icon': Icons.local_fire_department_rounded,
        'btnAction': 3,
      },
      {
        'assetImage': 'assets/images/banner_custom_fit.jpg',
        'btnAction': 0,
      },
    ];

    // 배너 높이를 화면 너비 기준 3:2 비율로 동적 계산 (이미지 실제 비율 1536x1024)
    final bannerHeightMobile = MediaQuery.of(context).size.width * 2 / 3;

    return Container(
      color: const Color(0xFF111111),
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: bannerHeightMobile,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 600),
              autoPlayCurve: Curves.easeInOutCubic,
              onPageChanged: (index, _) => setState(() => _bannerIndex = index),
            ),
            items: banners.asMap().entries
                .map((e) => _buildBannerItem(e.value, e.key, loc))
                .toList(),
          ),
          // 점 인디케이터
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map((e) {
                final active = _bannerIndex == e.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: active ? 20 : 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner, int index, AppLocalizations loc) {
    // 로컬 asset 이미지 배너인 경우
    final assetImage = banner['assetImage'] as String?;
    if (assetImage != null && assetImage.isNotEmpty) {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(color: Colors.black),
          child: Image.asset(
            assetImage,
            fit: BoxFit.contain,
            width: double.infinity,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
          ),
        ),
      );
    }
    // 이미지 URL 배너인 경우
    final imageUrl = banner['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(color: Colors.black),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(color: const Color(0xFF111111),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))),
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111111)),
          ),
        ),
      );
    }

    final bg1 = banner['bg1'] as Color? ?? const Color(0xFF0D0D0D);
    final bg2 = banner['bg2'] as Color? ?? const Color(0xFF1A1A1A);
    final accent = banner['accent'] as Color? ?? const Color(0xFFE53935);
    final icon = banner['icon'] as IconData? ?? Icons.sports_soccer_rounded;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg1, bg2],
        ),
      ),
      child: Stack(
        children: [
          // 배경 패턴 (아이콘으로 시각적 장식)
          Positioned(
            right: -20,
            top: -20,
            child: Icon(icon, size: 220, color: Colors.white.withValues(alpha: 0.04)),
          ),
          // 콘텐츠
          Positioned(
            left: 20, right: 20, bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 태그 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    banner['tag'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  banner['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  banner['sub'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    switch (index) {
                      case 1:
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ProductListScreen(initialSortBy: '인기순'),
                        ));
                        break;
                      default:
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'SHOP NOW',
                      style: TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 우상단 페이지 카운터
          Positioned(
            top: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_bannerIndex + 1} / 2',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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
      'badge': '🆕 신규 컬렉션',
      'btn': loc.homeBanner1Btn,
      'gradient1': const Color(0xFF1A1A1A),
      'gradient2': const Color(0xFF3D3D3D),
    },
    {
      'title': 'BEST SELLER\n인기 상품',
      'subtitle': loc.homeBanner2Subtitle,
      'badge': '🔥 베스트',
      'btn': loc.homeBanner2Btn,
      'gradient1': const Color(0xFFE53935),
      'gradient2': const Color(0xFFFF6B35),
    },
  ];

  // 카테고리 바 (다국어 라벨)
  // ────────────────────────────────────────────
  // ── 쇼핑몰 스타일 카테고리 그리드 ──
  // ignore: unused_element
  Widget _buildCategoryBar(AppLocalizations loc) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(loc.homeCategory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                  child: Text(loc.homeViewAllArrow, style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── 카테고리 아코디언 목록 ──
          ...getCategories(loc).map((cat) {
            final isExpanded = _expandedCatName == cat.name;
            final subs = cat.subCategories.where((s) => !s.name.startsWith('전체')).toList();
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isExpanded ? FontWeight.w800 : FontWeight.w600,
                              color: isExpanded ? cat.color : const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        // ALL 탭 이동 버튼
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => CategoryDetailScreen(
                                categoryName: cat.name,
                                categoryColor: cat.color,
                                categoryIcon: cat.icon,
                                subCategories: cat.subCategories,
                              ),
                            ));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(loc.homeCategoryAll, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cat.color)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isExpanded ? cat.color : const Color(0xFFBBBBBB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 서브카테고리 펼침
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.03),
                      border: Border(
                        left: BorderSide(color: cat.color.withValues(alpha: 0.25), width: 3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          const SizedBox(width: 0), // 좌측 패딩용
                          ...subs.map((sub) {
                            final isSubSel = _selectedCategoryKey == '${cat.name}/${sub.name}';
                            return Padding(
                              padding: const EdgeInsets.only(left: 52),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedCategoryKey = '${cat.name}/${sub.name}');
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ProductListScreen(initialCategory: sub.filter),
                                  ));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSubSel ? cat.color.withValues(alpha: 0.12) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5, height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSubSel ? cat.color : const Color(0xFFCCCCCC),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        sub.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSubSel ? FontWeight.w700 : FontWeight.w500,
                                          color: isSubSel ? cat.color : const Color(0xFF555555),
                                        ),
                                      ),
                                      if (sub.tag != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: sub.tag == 'BEST'
                                                ? const Color(0xFFFF6B35)
                                                : sub.tag == 'NEW'
                                                    ? cat.color
                                                    : const Color(0xFFE53935),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            sub.tag!,
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
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
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCategoryGridItem(Map<String, dynamic> item, AppLocalizations loc) {
    final label = item['label'] as String;
    final key   = item['key']   as String;
    final color = item['color'] as Color;
    final icon  = item['icon']  as IconData;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryKey = key);
        if (key == 'all') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
        } else {
          final matched = getCategories(loc).cast<CategoryData?>().firstWhere(
            (c) => c?.name == key,
            orElse: () => null,
          );
          if (matched != null) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => CategoryDetailScreen(
                categoryName: matched.name,
                categoryColor: matched.color,
                categoryIcon: matched.icon,
                subCategories: matched.subCategories,
              ),
            ));
          } else {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProductListScreen(initialCategory: key)));
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
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
    final isSelected = _selectedCategoryKey == item['key'];
    final label = item['label'] as String;
    final key   = item['key']   as String;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryKey = key);
        if (key == 'all') {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProductListScreen()));
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
            Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => ProductListScreen(initialCategory: key)));
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? const Color(0xFF111111) : const Color(0xFFDDDDDD),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF444444),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // 신상품 / 베스트 섹션
  // ────────────────────────────────────────────
  Widget _buildNewArrivalsSection(AppLocalizations loc) {
    List<ProductModel> allProds = context.watch<ProductProvider>().products;
    if (allProds.isEmpty) allProds = ProductService.getAllProductsSync();
    final products = allProds.where((p) => p.isNew).toList();
    return _buildProductSection(
      title: loc.sectionNewArrival,
      englishTitle: loc.sectionNewArrivalSub,
      accentColor: const Color(0xFF1A1A1A),
      products: products,
      category: '이벤트',
      viewAllLabel: loc.viewAll,
    );
  }

  Widget _buildBestSection(AppLocalizations loc) {
    List<ProductModel> rawProds = context.watch<ProductProvider>().products;
    if (rawProds.isEmpty) rawProds = ProductService.getAllProductsSync();
    final allProducts = List<ProductModel>.from(rawProds)
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return _buildProductSection(
      title: loc.sectionBestSeller,
      englishTitle: loc.sectionBestSellerSub,
      accentColor: const Color(0xFFE53935),
      products: allProducts.take(8).toList(),
      category: '전체',
      viewAllLabel: loc.viewAll,
    );
  }

  Widget _buildProductSection({
    required String title,
    required String englishTitle,
    required Color accentColor,
    required List<ProductModel> products,
    required String category,
    required String viewAllLabel,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();
    final screenWidth = MediaQuery.of(context).size.width;
    // 모바일 폭 기준으로 컬럼 수 및 비율 결정
    final crossAxisCount = screenWidth >= 600 ? 3 : 2;
    final childAspectRatio = screenWidth >= 600 ? 0.62 : 0.58;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          // 섹션 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      englishTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accentColor == const Color(0xFF1A1A1A)
                            ? const Color(0xFFAAAAAA)
                            : accentColor,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111111),
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
                      builder: (_) => ProductListScreen(initialCategory: category),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      viewAllLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: products.length > 8 ? 8 : products.length,
              itemBuilder: (context, index) => ProductCard(product: products[index]),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // 우하단 채팅 FAB
  // ────────────────────────────────────────────
  // ── PC 푸터 (홈 스크롤 맨 아래) ──
  Widget _buildPcFooter(AppLocalizations loc) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            child: const Text(
                              '2FIT MALL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            loc.homeBrandSlogan,
                            style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.7),
                          ),
                          const SizedBox(height: 20),
                          _footerInfoRow('🏢 주식회사 2FIT Korea'),
                          _footerInfoRow('📞 010-1234-5678'),
                          _footerInfoRow('✉ cs@2fitkorea.com'),
                          _footerInfoRow('💬 카카오톡 @2fitkorea'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _footerSocialBtn(loc.homeKakao, const Color(0xFFFFE000), Colors.black,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                              const SizedBox(width: 8),
                              _footerSocialBtn('고객센터', const Color(0xFF333333), Colors.white,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    // 쇼핑 안내
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.homeShopInfo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 14),
                          _footerLink('상품 목록', () => widget.onNavigate?.call(1)),
                          _footerLink('배송 안내', null),
                          _footerLink(loc.footerReturnPolicy, null),
                          _footerLink('사이즈 가이드', null),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    // 주문 서비스
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.homeOrderService, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 14),
                          _footerLink(loc.footerGroupOrder, () => Navigator.pushNamed(context, '/group-guide')),
                          _footerLink('주문 현황 조회', () => widget.onNavigate?.call(3)),
                          _footerLink('장바구니', () => widget.onNavigate?.call(2)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    // 고객 지원
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.homeCustomerSupport, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 14),
                          _footerLink('1:1 문의', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                          _footerLink('자주 묻는 질문', null),
                          _footerLink(loc.myPageLabel, () => widget.onNavigate?.call(3)),
                          _footerLink('카카오톡 채널', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '© 2025 2FIT Korea Co., Ltd. All rights reserved.',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                    Row(
                      children: [
                        Text(loc.homeTermsOfUse, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(width: 16),
                        Text(loc.homePrivacyPolicy, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _footerInfoRow(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
  );

  Widget _footerSocialBtn(String label, Color bg, Color fg, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );

  Widget _footerLink(String label, VoidCallback? onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: onTap != null
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Text(label, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13)),
            ),
          )
        : Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
  );

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
            color: const Color(0xFF111111),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25 + _chatPulse.value * 0.10),
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
                top: 10, right: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF111111), width: 1.5),
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
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        builder: (ctx2, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.search,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: loc.searchHint,
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF1A1A1A)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF888888)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      AnalyticsService.logSearch(v.trim());
                    }
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(searchQuery: v),
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
  final PageController _pc = PageController();

  @override
  void dispose() { _pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final notice  = widget.notices[_page];
    final title   = notice.localizedTitle(widget.language);
    final content = notice.localizedContent(widget.language);
    final total   = widget.notices.length;
    final sw      = MediaQuery.of(context).size.width;
    // PC는 최대 460, 모바일은 화면 너비 - 48
    final dialogW = sw > 600 ? 460.0 : sw - 48.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: sw > 600 ? (sw - dialogW) / 2 : 24,
        vertical: 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogW),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 헤더 ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                decoration: const BoxDecoration(color: Color(0xFF1A1A2E)),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (total > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_page + 1} / $total',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),
              // ── 본문 ──
              Container(
                color: Colors.white,
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF333333), height: 1.75),
                  ),
                ),
              ),
              // ── 페이지 인디케이터 ──
              if (total > 1)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(total, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _page ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _page ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                ),
              // ── 구분선 ──
              Container(height: 1, color: const Color(0xFFF0F0F0)),
              // ── 하단 버튼 ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Row(
                  children: [
                    // 오늘 하루 보지 않기
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          widget.onDismissToday();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFAAAAAA),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                        ),
                        child: Text(loc.homePopupDismiss, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 다음 / 닫기
                    if (total > 1 && _page < total - 1)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _page++),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A2E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(loc.nextNoticeBtn, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A2E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(loc.confirm, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

  double _topPadding(BuildContext ctx) =>
      MediaQuery.of(ctx).padding.top;

  @override
  double get minExtent => 100;
  @override
  double get maxExtent => 100 + MediaQuery.of(context).padding.top;

  @override
  bool shouldRebuild(covariant _MobileHeaderDelegate old) => true;

  @override
  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    final topPad = MediaQuery.of(ctx).padding.top;
    return Material(
      color: const Color(0xFF111111),
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
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
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
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/2fit_logo.png',
                          height: 30,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (_, __, ___) => const Text(
                            '2FIT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 언어 버튼
                Consumer<LanguageProvider>(
                  builder: (_, langProv, __) => GestureDetector(
                    onTap: onLanguageTap,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            langProv.language.code,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 2),
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
                          final unread = snap.data ?? 0;
                          return Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const NotificationCenterScreen()),
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
                                  top: 6, right: 8,
                                  child: Container(
                                    width: 14, height: 14,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF0000),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unread > 9 ? '9+' : '$unread',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
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
                _iconBtn(icon: Icons.person_outline_rounded, onTap: onMyPageTap),
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
                            top: 6, right: 8,
                            child: Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
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
                                    color: Color(0xFFE53935), size: 20),
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
