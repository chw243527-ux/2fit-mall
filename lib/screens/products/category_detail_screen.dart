import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/product_card.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/pc_layout.dart';
import 'product_detail_screen.dart';
import '../../utils/navigation_helper.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;
  final List<SubCategory> subCategories;
  final int initialTabIndex;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.subCategories,
    this.initialTabIndex = 0,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  late TabController _tabController;
  String _sortBy = 'newest';
  bool _isGridView = true;
  String _searchQuery = '';
  String? _selectedSize;
  double _minPrice = 0;
  double _maxPrice = 300000;
  bool _onlySale = false;
  bool _onlyFreeShipping = false;

  // ── 색상 팔레트: 약간 밝게 조정 ──
  static const Color _bg       = Color(0xFF1A1A1A);   // 이전 0xFF111111 → 더 밝게
  static const Color _surface  = Color(0xFF222222);   // 이전 0xFF181818
  static const Color _card     = Color(0xFF2A2A2A);   // 이전 0xFF1C1C1C
  static const Color _border   = Color(0xFF3A3A3A);   // 이전 0xFF2A2A2A
  static const Color _divider  = Color(0xFF303030);   // 이전 0xFF222222
  static const Color _white    = Colors.white;
  static const Color _grey     = Color(0xFFAAAAAA);   // 이전 0xFF888888 → 더 밝게
  static const Color _greyDim  = Color(0xFF777777);   // 이전 0xFF555555 → 더 밝게

  // 카테고리 사이드 드로어용 스크롤 키
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.subCategories.length,
      initialIndex: widget.initialTabIndex.clamp(0, widget.subCategories.length - 1),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ProductModel> _getProducts(String filter, {String? subName}) {
    final provider = context.watch<ProductProvider>();
    final allCached = provider.products;
    List<ProductModel> all;
    if (filter == loc.sortNewArrival) {
      all = allCached.where((p) => p.isNewActive).toList();
    } else if (filter == '세일') {
      all = allCached.where((p) => p.isSale).toList();
    } else if (filter == '전체') {
      all = List.from(allCached);
    } else {
      all = allCached.where((p) => p.category == filter).toList();
      if (subName != null && subName.isNotEmpty &&
          !subName.startsWith('전체') && subName != filter) {
        all = all.where((p) {
          final sub = p.subCategory;
          if (sub.isEmpty) return false;
          return sub == subName || sub.contains(subName) || subName.contains(sub);
        }).toList();
      }
    }
    if (_searchQuery.isNotEmpty) {
      all = all.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedSize != null) {
      all = all.where((p) => p.sizes.contains(_selectedSize)).toList();
    }
    all = all.where((p) => p.price >= _minPrice && p.price <= _maxPrice).toList();
    if (_onlySale) {
      all = all.where((p) => p.isSale || (p.originalPrice != null && p.originalPrice! > p.price)).toList();
    }
    if (_onlyFreeShipping) {
      all = all.where((p) => p.isFreeShipping).toList();
    }
    final sorted = List<ProductModel>.from(all);
    switch (_sortBy) {
      case 'priceLow':  sorted.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'priceHigh': sorted.sort((a, b) => b.price.compareTo(a.price)); break;
      case 'popular':   sorted.sort((a, b) => b.reviewCount.compareTo(a.reviewCount)); break;
      case 'rating':    sorted.sort((a, b) => b.rating.compareTo(a.rating)); break;
      default:          sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  bool get _hasFilter =>
      _selectedSize != null || _onlySale || _onlyFreeShipping ||
      _minPrice > 0 || _maxPrice < 300000;

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return wrapWithPopScope(context, Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      // ── 우측 카테고리 드로어 ──
      endDrawer: _buildCategoryDrawer(context),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: Column(
          children: [
            _buildSortBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: widget.subCategories.map((sub) {
                  final provider = context.watch<ProductProvider>();
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white38,
                        strokeWidth: 1.5,
                      ),
                    );
                  }
                  final products = _getProducts(sub.filter, subName: sub.name);
                  return RefreshIndicator(
                    color: _white,
                    backgroundColor: _card,
                    onRefresh: () => context.read<ProductProvider>().refreshAll(),
                    child: _isGridView
                        ? _buildProductGrid(products)
                        : _buildProductList(products),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // ── 우측 카테고리 드로어 ──
  Widget _buildCategoryDrawer(BuildContext context) {
    final categories = getCategories(loc);
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: _surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'CATEGORIES',
                    style: TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: _grey, size: 22),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: _divider),
            // 카테고리 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: categories.length + 1, // 전체 상품 항목 추가
                itemBuilder: (ctx, i) {
                  // 첫 번째 항목: 전체 상품
                  if (i == 0) {
                    final isActive = widget.categoryName == '전체';
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          if (!isActive) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryDetailScreen(
                                  categoryName: '전체',
                                  categoryColor: const Color(0xFF888888),
                                  categoryIcon: Icons.grid_view_rounded,
                                  subCategories: const [
                                    SubCategory(name: '전체 상품', filter: '전체'),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: isActive ? _card : Colors.transparent,
                            border: isActive
                                ? const Border(left: BorderSide(color: _white, width: 2))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.grid_view_rounded,
                                  size: 16,
                                  color: isActive ? _white : _grey),
                              const SizedBox(width: 12),
                              Text(
                                '전체 상품',
                                style: TextStyle(
                                  color: isActive ? _white : _grey,
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final cat = categories[i - 1];
                  final isActive = cat.name == widget.categoryName;
                  return _buildDrawerCategoryItem(context, cat, isActive);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerCategoryItem(BuildContext context, CategoryData cat, bool isActive) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // 드로어 닫기
          if (!isActive) {
            // 현재 화면을 교체하여 선택한 카테고리로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailScreen(
                  categoryName: cat.name,
                  categoryColor: cat.color,
                  categoryIcon: cat.icon,
                  subCategories: cat.subCategories,
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? _card : Colors.transparent,
            border: isActive
                ? const Border(left: BorderSide(color: _white, width: 2))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                cat.icon,
                size: 18,
                color: isActive ? _white : _grey,
              ),
              const SizedBox(width: 14),
              Text(
                cat.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? _white : _grey,
                  letterSpacing: 0.3,
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: _white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── SliverAppBar: 텍스트 겹침 방지 + 햄버거 버튼 ──
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 100,
      backgroundColor: _surface,
      elevation: 0,
      // 뒤로가기 버튼 (좌측)
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _white, size: 19),
        onPressed: () => goBackOrHome(context),
      ),
      actions: [
        // 그리드/리스트 토글
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: _grey,
            size: 22,
          ),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        // 필터
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.tune_rounded, color: _hasFilter ? _white : _grey, size: 22),
              onPressed: _showFilterSheet,
            ),
            if (_hasFilter)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: _white, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        // 햄버거 버튼 (카테고리 전환용)
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: _white, size: 22),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
        const SizedBox(width: 4),
      ],
      // 접혔을 때 AppBar 타이틀
      title: Text(
        widget.categoryName.toUpperCase(),
        style: const TextStyle(
          color: _white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
      centerTitle: false,
      // 펼쳤을 때 큰 타이틀 (겹침 없이 AppBar 영역 아래에 표시)
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // 현재 확장 정도 계산
          final expandRatio = (constraints.maxHeight - kToolbarHeight) /
              (100 - kToolbarHeight);
          final opacity = expandRatio.clamp(0.0, 1.0);
          return FlexibleSpaceBar(
            background: Container(
              color: _surface,
              // padding top: kToolbarHeight + statusBar → 겹침 방지
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + kToolbarHeight + 4,
                20,
                14,
              ),
              child: Opacity(
                opacity: opacity,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    widget.categoryName.toUpperCase(),
                    style: const TextStyle(
                      color: _white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      // TabBar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Container(
          color: _surface,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _divider)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _white,
            unselectedLabelColor: _greyDim,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: _white, width: 2),
              insets: EdgeInsets.symmetric(horizontal: 4),
            ),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            padding: EdgeInsets.zero,
            tabs: widget.subCategories.map((sub) => Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(sub.name),
                  if (sub.tag != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _greyDim,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(sub.tag!,
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _white),
                      ),
                    ),
                  ],
                ],
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  // ── 정렬 바 ──
  Widget _buildSortBar() {
    final sortMap = <String, String>{
      'newest':    loc.sortNewest,
      'popular':   loc.sortPopular,
      'priceLow':  loc.sortPriceLow,
      'priceHigh': loc.sortPriceHigh,
      'rating':    loc.sortRating,
    };
    return Container(
      height: 44,
      color: _bg,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: sortMap.entries.map((e) {
                  final isSelected = _sortBy == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _sortBy = e.key),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? _white : _greyDim,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(width: 1, height: 16, color: _border),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _isGridView = !_isGridView),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                size: 19,
                color: _grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 필터 바텀시트 ──
  void _showFilterSheet() {
    final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 32, height: 3,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                child: Row(
                  children: [
                    const Text('FILTER',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                          color: _white, letterSpacing: 2.5)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModal(() {
                          _selectedSize = null; _minPrice = 0;
                          _maxPrice = 300000; _onlySale = false; _onlyFreeShipping = false;
                        });
                        setState(() {});
                      },
                      child: const Text('초기화',
                        style: TextStyle(fontSize: 12, color: _greyDim)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _grey, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _divider),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _filterLabel('SIZE'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: sizes.map((s) {
                        final isSel = _selectedSize == s;
                        return GestureDetector(
                          onTap: () => setModal(() {
                            _selectedSize = isSel ? null : s;
                            setState(() {});
                          }),
                          child: Container(
                            width: 54, height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel ? _white : _card,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isSel ? _white : _border),
                            ),
                            child: Text(s,
                              style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700,
                                color: isSel ? _bg : _grey,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Row(children: [
                      _filterLabel('PRICE'),
                      const Spacer(),
                      Text(
                        '${_fmtPrice(_minPrice)}${loc.wonUnit} ~ ${_fmtPrice(_maxPrice)}${loc.wonUnit}',
                        style: const TextStyle(fontSize: 12, color: _grey),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _white,
                        inactiveTrackColor: _border,
                        thumbColor: _white,
                        overlayColor: Colors.white12,
                        trackHeight: 1.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: RangeSlider(
                        values: RangeValues(_minPrice, _maxPrice),
                        min: 0, max: 300000, divisions: 30,
                        activeColor: _white,
                        inactiveColor: _border,
                        onChanged: (v) => setModal(() {
                          _minPrice = v.start; _maxPrice = v.end; setState(() {});
                        }),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0${loc.wonUnit2}', style: const TextStyle(fontSize: 11, color: _greyDim)),
                        Text('300,000${loc.wonUnit2}', style: const TextStyle(fontSize: 11, color: _greyDim)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _filterLabel('OPTIONS'),
                    const SizedBox(height: 12),
                    _filterToggleRow(loc.filterSaleOnly, _onlySale, (v) {
                      setModal(() { _onlySale = v; setState(() {}); });
                    }),
                    const SizedBox(height: 8),
                    _filterToggleRow(loc.filterFreeShipOnly, _onlyFreeShipping, (v) {
                      setModal(() { _onlyFreeShipping = v; setState(() {}); });
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _white,
                      foregroundColor: _bg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(loc.filterApply,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterLabel(String text) => Text(text,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
        color: _greyDim, letterSpacing: 2));

  Widget _filterToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: value ? _card : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: value ? _border : _divider),
        ),
        child: Row(
          children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: value ? _white : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: value ? _white : _greyDim, width: 1.5),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 12, color: _bg)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                color: value ? _white : _grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(double v) =>
      v.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ══════════════════════════════════════════════════════
  // PC 레이아웃
  // ══════════════════════════════════════════════════════
  Widget _buildPcLayout(BuildContext context) {
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: _white, size: 26),
          onPressed: () => goBackOrHome(context),
        ),
        title: Text(
          widget.categoryName.toUpperCase(),
          style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w900,
            color: _white, letterSpacing: 3,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _divider)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: _white,
              unselectedLabelColor: _greyDim,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: _white, width: 2),
                insets: EdgeInsets.symmetric(horizontal: 4),
              ),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              padding: EdgeInsets.zero,
              tabs: widget.subCategories.map((sub) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sub.name),
                    if (sub.tag != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: _greyDim, borderRadius: BorderRadius.circular(2)),
                        child: Text(sub.tag!,
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _white)),
                      ),
                    ],
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 200, child: _buildPcSidebar()),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    children: [
                      _buildPcTopBar(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: widget.subCategories.map((sub) {
                            final provider = context.watch<ProductProvider>();
                            if (provider.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(color: Colors.white30, strokeWidth: 1.5),
                              );
                            }
                            final products = _getProducts(sub.filter, subName: sub.name);
                            return RefreshIndicator(
                              color: _white,
                              backgroundColor: _card,
                              onRefresh: () => context.read<ProductProvider>().refreshAll(),
                              child: _buildPcProductGrid(products),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildPcSidebar() {
    final sortMap = <String, String>{
      'newest':    loc.sortNewest,
      'popular':   loc.sortPopular,
      'priceLow':  loc.sortPriceLow,
      'priceHigh': loc.sortPriceHigh,
      'rating':    loc.sortRating,
    };
    final sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SORT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                color: _greyDim, letterSpacing: 2.5)),
          const SizedBox(height: 12),
          ...sortMap.entries.map((e) {
            final isSel = _sortBy == e.key;
            return GestureDetector(
              onTap: () => setState(() => _sortBy = e.key),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSel ? _white : Colors.transparent,
                        border: Border.all(color: isSel ? _white : _greyDim, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(e.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                        color: isSel ? _white : _grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Container(height: 1, color: _divider),
          const SizedBox(height: 24),
          const Text('SIZE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                color: _greyDim, letterSpacing: 2.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: sizes.map((s) {
              final isSel = _selectedSize == s;
              return GestureDetector(
                onTap: () => setState(() => _selectedSize = isSel ? null : s),
                child: Container(
                  width: 44, height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSel ? _white : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: isSel ? _white : _border),
                  ),
                  child: Text(s,
                    style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700,
                      color: isSel ? _bg : _grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: _divider),
          const SizedBox(height: 24),
          Row(children: [
            const Text('PRICE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                  color: _greyDim, letterSpacing: 2.5)),
            const Spacer(),
            Text(
              '${_fmtPrice(_minPrice)}~${_fmtPrice(_maxPrice)}',
              style: const TextStyle(fontSize: 10, color: _grey),
            ),
          ]),
          const SizedBox(height: 4),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0, max: 300000, divisions: 30,
            activeColor: _white,
            inactiveColor: _border,
            onChanged: (v) => setState(() { _minPrice = v.start; _maxPrice = v.end; }),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: _divider),
          const SizedBox(height: 24),
          const Text('OPTIONS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                color: _greyDim, letterSpacing: 2.5)),
          const SizedBox(height: 12),
          _sidebarToggle(loc.filterSaleOnly, _onlySale,
              (v) => setState(() => _onlySale = v)),
          const SizedBox(height: 8),
          _sidebarToggle(loc.filterFreeShipOnly, _onlyFreeShipping,
              (v) => setState(() => _onlyFreeShipping = v)),
          const SizedBox(height: 24),
          if (_hasFilter)
            GestureDetector(
              onTap: () => setState(() {
                _selectedSize = null; _minPrice = 0; _maxPrice = 300000;
                _onlySale = false; _onlyFreeShipping = false;
              }),
              child: const Text('초기화',
                style: TextStyle(fontSize: 12, color: _greyDim,
                    decoration: TextDecoration.underline)),
            ),
        ],
      ),
    );
  }

  Widget _sidebarToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: value ? _white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: value ? _white : _greyDim, width: 1.5),
            ),
            child: value ? const Icon(Icons.check_rounded, size: 11, color: _bg) : null,
          ),
          const SizedBox(width: 10),
          Text(label,
            style: TextStyle(
              fontSize: 13,
              color: value ? _white : _grey,
              fontWeight: value ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPcTopBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: _greyDim, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(fontSize: 13, color: _white),
                    decoration: InputDecoration(
                      hintText: '${widget.categoryName} 검색...',
                      hintStyle: const TextStyle(fontSize: 13, color: _greyDim),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _searchQuery = ''),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.close_rounded, size: 16, color: _greyDim),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              _pcToggleBtn(Icons.grid_view_rounded, _isGridView,
                  () => setState(() => _isGridView = true)),
              Container(width: 1, height: 20, color: _border),
              _pcToggleBtn(Icons.view_list_rounded, !_isGridView,
                  () => setState(() => _isGridView = false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pcToggleBtn(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isActive ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: isActive ? _white : _greyDim),
      ),
    );
  }

  Widget _buildPcProductGrid(List<ProductModel> products) {
    if (products.isEmpty) return _buildEmpty();
    if (_isGridView) {
      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 0.72,
          crossAxisSpacing: 14, mainAxisSpacing: 14,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => ProductCard(product: products[i]),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: products.length,
      itemBuilder: (ctx, i) => _buildListItem(ctx, products[i], pc: true),
    );
  }

  // ══════════════════════════════════════════════════════
  // 모바일 상품 그리드 / 리스트
  // ══════════════════════════════════════════════════════
  Widget _buildProductGrid(List<ProductModel> products) {
    if (products.isEmpty) return _buildEmpty();
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.68,
        crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(product: products[i]),
    );
  }

  Widget _buildProductList(List<ProductModel> products) {
    if (products.isEmpty) return _buildEmpty();
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: products.length,
      itemBuilder: (ctx, i) => _buildListItem(ctx, products[i]),
    );
  }

  Widget _buildListItem(BuildContext context, ProductModel product, {bool pc = false}) {
    final imgSize = pc ? 130.0 : 100.0;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: SizedBox(
                width: imgSize, height: imgSize,
                child: product.images.isNotEmpty
                    ? Image.network(product.images.first, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: _surface,
                            child: const Icon(Icons.image_not_supported_outlined,
                                color: _greyDim, size: 28)))
                    : Container(color: _surface,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: _greyDim, size: 28)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.isNewActive || product.isSale || product.isFreeShipping)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            if (product.isNewActive) _tag('NEW'),
                            if (product.isSale) _tag('SALE'),
                            if (product.isFreeShipping) _tag('무료배송'),
                          ],
                        ),
                      ),
                    Text(product.localizedName(_lang),
                      style: TextStyle(
                        fontSize: pc ? 14.0 : 13.0,
                        fontWeight: FontWeight.w600, color: _white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (product.originalPrice != null)
                      Text('${_fmt(product.originalPrice!)}원',
                        style: const TextStyle(
                          fontSize: 11, color: _greyDim,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text('${_fmt(product.price)}원',
                      style: TextStyle(
                        fontSize: pc ? 16.0 : 15.0,
                        fontWeight: FontWeight.w800, color: _white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (product.reviewCount > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFD600)),
                          const SizedBox(width: 2),
                          Text('${product.rating} (${product.reviewCount})',
                            style: const TextStyle(fontSize: 11, color: _greyDim)),
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

  // ── 빈 상태 ──
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: _greyDim),
          const SizedBox(height: 14),
          Text(loc.categoryNoProducts,
            style: const TextStyle(fontSize: 14, color: _grey)),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"$_searchQuery" ${loc.searchNoResult}',
              style: const TextStyle(fontSize: 12, color: _greyDim)),
          ],
        ],
      ),
    );
  }

  // ── 배지 ──
  Widget _tag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(text,
        style: const TextStyle(color: _grey, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  String _fmt(double price) => price
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
