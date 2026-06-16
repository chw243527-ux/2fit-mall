// group_order_only_screen.dart
// 단체주문 전용 상품 목록 — 카테고리 탭 + 그리드 뷰
import 'package:flutter/material.dart';
import '../../widgets/net_image.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/app_localizations.dart';
import '../../models/models.dart';
import '../../widgets/pc_layout.dart';
import '../products/product_detail_screen.dart';
import '../../utils/navigation_helper.dart';
import 'group_order_landing_screen.dart';

class GroupOrderOnlyScreen extends StatefulWidget {
  const GroupOrderOnlyScreen({super.key});
  @override
  State<GroupOrderOnlyScreen> createState() => _GroupOrderOnlyScreenState();
}

class _GroupOrderOnlyScreenState extends State<GroupOrderOnlyScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  TabController? _tabCtrl;
  List<String> _tabs = [];
  bool _isGridView = true;

  // 카테고리 메타 (아이콘 + 색상)
  static const Map<String, Map<String, dynamic>> _catMeta = {
    '전체': {'icon': Icons.apps_rounded, 'color': Color(0xFF1A1A2E)},
    '싱글렛 A타입세트': {'icon': Icons.sports_rounded, 'color': Color(0xFF1565C0)},
    '타이즈': {'icon': Icons.fitness_center_rounded, 'color': Color(0xFF6A1B9A)},
    '스킨슈트': {'icon': Icons.directions_run_rounded, 'color': Color(0xFF2E7D32)},
    '트레이닝복세트': {'icon': Icons.dry_cleaning_rounded, 'color': Color(0xFFE65100)},
    '기타': {'icon': Icons.category_rounded, 'color': Color(0xFF546E7A)},
  };

  String _fmt(double v) => v
      .toInt()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<ProductProvider>();
      // 항상 최신 단체주문 상품 재로드 (화면 진입 시마다)
      pp.loadGroupOnlyProducts().then((_) {
        if (mounted) _initTabs();
      });
      pp.addListener(_onProductsUpdated);
      // 이미 데이터 있으면 바로 탭 초기화
      if (pp.groupOnlyProducts.isNotEmpty) _initTabs();
    });
  }

  void _onProductsUpdated() {
    if (!mounted) return;
    _initTabs();
  }

  void _initTabs() {
    if (!mounted) return;
    final pp = context.read<ProductProvider>();
    // 단체주문 전용 상품 로딩 중이고 아직 데이터 없으면 대기
    if (pp.isGroupOnlyLoading && pp.groupOnlyProducts.isEmpty) return;
    // groupOnlyProducts: Firestore에서 직접 로드된 isGroupOnly=true & isActive=true 상품
    final groupProducts = pp.groupOnlyProducts;

    // subCategory 유니크 목록 (등장 순서 유지)
    final seen = <String>{};
    final subCats = <String>[];
    for (final p in groupProducts) {
      if (p.subCategory.isNotEmpty && seen.add(p.subCategory)) {
        subCats.add(p.subCategory);
      }
    }

    final tabs = ['전체', ...subCats];

    // 탭이 실제로 바뀐 경우에만 갱신 (동일하면 스킵)
    final tabsChanged = _tabs.length != tabs.length ||
        !List.generate(tabs.length, (i) => _tabs.length > i && _tabs[i] == tabs[i])
            .every((e) => e);
    if (!tabsChanged && _tabCtrl != null) return;

    setState(() {
      _tabs = tabs;
      _tabCtrl?.dispose();
      _tabCtrl = TabController(
        length: tabs.isEmpty ? 1 : tabs.length,
        vsync: this,
      );
    });
  }

  @override
  void dispose() {
    // ProductProvider 리스너 해제
    try {
      context.read<ProductProvider>().removeListener(_onProductsUpdated);
    } catch (_) {}
    _tabCtrl?.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();

    // Firestore 로딩 중이고 탭이 아직 없으면 로딩 표시
    if ((pp.isLoading || pp.isGroupOnlyLoading) && _tabs.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF6B35)),
              const SizedBox(height: 16),
              Text('단체주문 상품을 불러오는 중...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      );
    }

    // 탭이 비어있으면 기본 탭 하나 생성
    if (_tabs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initTabs());
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
      );
    }

    return isPcWeb(context) ? _buildPcLayout() : _buildMobileLayout();
  }

  // ════════════════════════════════════════════
  // 모바일 레이아웃
  // ════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return wrapWithPopScope(
      context,
      Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            // ── SliverAppBar (히어로 배너 포함) ──
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.white,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: Colors.white),
                      onPressed: () => goBackOrHome(context),
                    )
                  : null,
              actions: [
                // 그리드/리스트 토글
                IconButton(
                  icon: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _isGridView = !_isGridView),
                ),
                // 단체주문 안내 버튼
                TextButton(
                  onPressed: _goToLanding,
                  child: const Text('주문안내',
                      style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _buildHeroBanner(compact: true),
              ),
              bottom: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: const Color(0xFFFF6B35),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: _tabs.map((tab) {
              return Consumer<ProductProvider>(
                builder: (_, pp, __) {
                  final list = _filterByTab(pp.groupOnlyProducts, tab);
                  return _buildProductBody(list, gridColumns: 2);
                },
              );
            }).toList(),
          ),
        ),
        // 하단 단체주문서 작성 버튼
        bottomNavigationBar: _buildBottomCta(),
      ),
    );
  }

  // ════════════════════════════════════════════
  // PC 레이아웃
  // ════════════════════════════════════════════
  Widget _buildPcLayout() {
    return wrapWithPopScope(
      context,
      Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A2E),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: Color(0xFF1A1A2E)),
                  onPressed: () => goBackOrHome(context),
                )
              : null,
          title: const Text('단체주문 전용 상품',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Color(0xFF1A1A2E))),
          actions: [
            // 그리드/리스트 토글
            IconButton(
              icon: Icon(
                _isGridView
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
                color: const Color(0xFF888888),
                size: 22,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
            const SizedBox(width: 8),
            // 단체주문 안내 버튼
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: OutlinedButton.icon(
                onPressed: _goToLanding,
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('단체주문 안내',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A2E),
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFEEEEEE)),
          ),
        ),
        body: Consumer<ProductProvider>(
          builder: (_, pp, __) {
            return Column(
              children: [
                // 히어로 배너 (PC)
                _buildHeroBanner(compact: false),

                // 탭바
                Container(
                  color: Colors.white,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: TabBar(
                        controller: _tabCtrl,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: const Color(0xFF1A1A2E),
                        indicatorWeight: 3,
                        labelColor: const Color(0xFF1A1A2E),
                        unselectedLabelColor: const Color(0xFF888888),
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                        dividerHeight: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        tabs: _tabs.map((t) {
                          final meta = _catMeta[t] ??
                              {'icon': Icons.category_rounded,
                               'color': const Color(0xFF1A1A2E)};
                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(meta['icon'] as IconData, size: 15),
                                const SizedBox(width: 6),
                                Text(t),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Container(height: 1, color: const Color(0xFFEEEEEE)),

                // 상품 그리드
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: _tabs.map((tab) {
                      final list = _filterByTab(pp.groupOnlyProducts, tab);
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1280),
                          child: _buildProductBody(list, gridColumns: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // 히어로 배너
  // ════════════════════════════════════════════
  Widget _buildHeroBanner({required bool compact}) {
    if (compact) {
      // 모바일용 — FlexibleSpaceBar background
      return Stack(
        fit: StackFit.expand,
        children: [
          NetImage(
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          // 그라데이션 오버레이
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          // 텍스트
          Positioned(
            left: 20, bottom: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('GROUP ORDER ONLY',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                ),
                const SizedBox(height: 8),
                const Text('단체주문\n전용 상품',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.2)),
                const SizedBox(height: 4),
                const Text('10인 이상 팀 맞춤 제작 · 무료배송',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      );
    }

    // PC용 히어로
    return SizedBox(
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetImage(
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=1600',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.80),
                  Colors.black.withValues(alpha: 0.30),
                ],
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    // 좌측 텍스트
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text('GROUP ORDER ONLY',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.8)),
                          ),
                          const SizedBox(height: 10),
                          const Text('단체주문 전용 상품',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          const Text(
                              '10인 이상 팀 맞춤 제작 전용 · 무료배송 · 14~21일 제작',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    // 우측 CTA 카드들
                    Row(
                      children: [
                        _heroCta(
                          icon: Icons.local_shipping_rounded,
                          label: '무료배송',
                          sub: '단체전용',
                          color: const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 12),
                        _heroCta(
                          icon: Icons.discount_rounded,
                          label: '최대 10% 할인',
                          sub: '50인 이상',
                          color: const Color(0xFFFF6B35),
                        ),
                        const SizedBox(width: 12),
                        _heroCta(
                          icon: Icons.palette_rounded,
                          label: '맞춤 제작',
                          sub: '컬러·로고·마킹',
                          color: const Color(0xFF1565C0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCta(
      {required IconData icon,
      required String label,
      required String sub,
      required Color color}) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // 상품 리스트 / 그리드 바디
  // ════════════════════════════════════════════
  Widget _buildProductBody(List<ProductModel> list,
      {required int gridColumns}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 40, color: Color(0xFFBBBBBB)),
              ),
              const SizedBox(height: 16),
              const Text('준비 중인 상품입니다',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF444444))),
              const SizedBox(height: 6),
              const Text('단체주문 문의는 주문안내를 확인해주세요.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF888888))),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _goToLanding,
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: const Text('단체주문 안내 보기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 상단 카운트 + 뷰 토글 헤더
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader(list.length),
        Expanded(
          child: _isGridView
              ? _buildGridView(list, columns: gridColumns)
              : _buildListView(list),
        ),
      ],
    );
  }

  Widget _buildListHeader(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('$count개 상품',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF444444))),
          const Spacer(),
          // 그리드/리스트 토글 (모바일용 - appBar에도 있지만 여기에도 작은 토글 표시)
          GestureDetector(
            onTap: () => setState(() => _isGridView = !_isGridView),
            child: Row(
              children: [
                Icon(
                  _isGridView
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded,
                  size: 18,
                  color: const Color(0xFF444444),
                ),
                const SizedBox(width: 4),
                Text(
                  _isGridView ? '그리드' : '리스트',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 그리드 뷰 ──
  Widget _buildGridView(List<ProductModel> list, {int columns = 2}) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: columns == 4 ? 0.72 : 0.68,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildGridCard(list[i]),
    );
  }

  Widget _buildGridCard(ProductModel p) {
    final accentColor = _catMeta[p.subCategory]?['color'] as Color? ??
        const Color(0xFF1565C0);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: p.images.isNotEmpty
                        ? NetImage(
                            p.images.first,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          )
                        : _imgPlaceholder(full: true),
                  ),
                  // 배지들 (단체전용 배지 제거 — 이 화면 자체가 단체주문 전용)
                  if (p.isSale || p.isNewActive)
                    Positioned(
                      top: 8, left: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.isSale) _gridBadge('SALE', const Color(0xFFC62828)),
                          if (p.isSale && p.isNewActive) const SizedBox(height: 4),
                          if (p.isNewActive) _gridBadge('NEW', const Color(0xFF1565C0)),
                        ],
                      ),
                    ),
                  // 무료배송 태그
                  if (p.isFreeShipping)
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('무료배송',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),

            // 정보 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.subCategory.isNotEmpty)
                    Text(p.subCategory,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accentColor)),
                  const SizedBox(height: 2),
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // 가격
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_fmt(p.price)}원',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A2E)),
                      ),
                      if (p.originalPrice != null &&
                          p.originalPrice! > p.price) ...[
                        const SizedBox(width: 5),
                        Text(
                          '${_fmt(p.originalPrice!)}원',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFAAAAAA),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // 할인율
                  if (p.originalPrice != null && p.originalPrice! > p.price)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${(((p.originalPrice! - p.price) / p.originalPrice!) * 100).round()}% 할인',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w700),
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

  // ── 리스트 뷰 ──
  Widget _buildListView(List<ProductModel> list) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildListCard(list[i]),
    );
  }

  Widget _buildListCard(ProductModel p) {
    final accentColor = _catMeta[p.subCategory]?['color'] as Color? ??
        const Color(0xFF1565C0);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // 썸네일
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: p.images.isNotEmpty
                  ? NetImage(
                      p.images.first,
                      width: 110,
                      height: 120,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : _imgPlaceholder(),
            ),
            // 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.isSale || p.isNewActive) ...[
                      Row(
                        children: [
                          if (p.isSale) _badge('SALE', const Color(0xFFC62828)),
                          if (p.isSale && p.isNewActive) const SizedBox(width: 4),
                          if (p.isNewActive) _badge('NEW', const Color(0xFF1565C0)),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (p.subCategory.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(p.subCategory,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${_fmt(p.price)}원',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A2E))),
                        if (p.originalPrice != null &&
                            p.originalPrice! > p.price) ...[
                          const SizedBox(width: 6),
                          Text('${_fmt(p.originalPrice!)}원',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFAAAAAA),
                                decoration: TextDecoration.lineThrough,
                              )),
                          const SizedBox(width: 4),
                          Text(
                            '${(((p.originalPrice! - p.price) / p.originalPrice!) * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                    if (p.isFreeShipping)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('무료배송',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 44),
              child: Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFBBBBBB), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // 하단 CTA (모바일 전용)
  // ════════════════════════════════════════════
  Widget _buildBottomCta() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _goToLanding,
          icon: const Icon(Icons.edit_note_rounded, size: 20),
          label: const Text('단체주문서 작성하기',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // 헬퍼
  // ════════════════════════════════════════════
  List<ProductModel> _filterByTab(List<ProductModel> groupOnly, String tab) {
    // groupOnly는 이미 isGroupOnly=true, isActive=true 필터링된 목록
    if (tab == '전체') return groupOnly;
    return groupOnly.where((p) => p.subCategory == tab).toList();
  }

  void _goToLanding() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupOrderLandingScreen()),
    );
  }

  Widget _gridBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800)),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _imgPlaceholder({bool full = false}) => Container(
        width: full ? double.infinity : 110,
        height: full ? double.infinity : 120,
        color: const Color(0xFFEEEEEE),
        child: const Icon(Icons.checkroom_rounded,
            color: Color(0xFFAAAAAA), size: 36),
      );
}
