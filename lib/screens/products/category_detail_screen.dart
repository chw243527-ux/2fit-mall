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

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;
  final List<SubCategory> subCategories;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.subCategories,
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
  // 추가 필터
  String? _selectedSize;
  double _minPrice = 0;
  double _maxPrice = 300000;
  bool _onlySale = false;
  bool _onlyFreeShipping = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.subCategories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ProductModel> _getProducts(String filter) {
    final allCached = context.watch<ProductProvider>().products;
    List<ProductModel> all;
    if (filter == loc.sortNewArrival) {
      all = allCached.where((p) => p.isNew).toList();
    } else if (filter == '세일') {
      all = allCached.where((p) => p.isSale).toList();
    } else if (filter == '전체') {
      all = List.from(allCached);
    } else {
      all = allCached.where((p) => p.category == filter).toList();
    }
    // 검색 필터
    if (_searchQuery.isNotEmpty) {
      all = all.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    // 사이즈 필터
    if (_selectedSize != null) {
      all = all.where((p) => p.sizes.contains(_selectedSize)).toList();
    }
    // 가격 범위 필터
    all = all.where((p) => p.price >= _minPrice && p.price <= _maxPrice).toList();
    // 세일 필터
    if (_onlySale) {
      all = all.where((p) => p.isSale || (p.originalPrice != null && p.originalPrice! > p.price)).toList();
    }
    // 무료배송 필터
    if (_onlyFreeShipping) {
      all = all.where((p) => p.isFreeShipping).toList();
    }
    // 정렬
    final sorted = List<ProductModel>.from(all);
    switch (_sortBy) {
      case 'priceLow':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'priceHigh':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'popular':
        sorted.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case 'rating':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            _buildFilterSortBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: widget.subCategories.map((sub) {
                  final products = _getProducts(sub.filter);
                  return _isGridView
                      ? _buildProductGrid(products)
                      : _buildProductList(products);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 필터/정렬 바 ──
  Widget _buildFilterSortBar() {
    final hasFilter = _selectedSize != null || _onlySale || _onlyFreeShipping
        || _minPrice > 0 || _maxPrice < 300000;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 필터 버튼
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: hasFilter ? widget.categoryColor : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: hasFilter ? widget.categoryColor : const Color(0xFFDDDDDD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 14,
                      color: hasFilter ? Colors.white : const Color(0xFF555555)),
                  const SizedBox(width: 4),
                  Text(loc.filterTitle, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: hasFilter ? Colors.white : const Color(0xFF555555),
                  )),
                  if (hasFilter) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 10, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 정렬 탭들
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...(<String, String>{
                    'newest': loc.sortNewest,
                    'popular': loc.sortPopular,
                    'priceLow': loc.sortPriceLow,
                    'priceHigh': loc.sortPriceHigh,
                    'rating': loc.sortRating,
                  }).entries.map((entry) => GestureDetector(
                    onTap: () => setState(() => _sortBy = entry.key),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _sortBy == entry.key
                            ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(entry.value, style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _sortBy == entry.key
                            ? Colors.white : const Color(0xFF555555),
                      )),
                    ),
                  )),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isGridView = !_isGridView),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
              child: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  size: 18, color: const Color(0xFF555555)),
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
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 핸들 + 타이틀
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Row(
                  children: [
                    Text(loc.filterTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModal(() {
                          _selectedSize = null;
                          _minPrice = 0;
                          _maxPrice = 300000;
                          _onlySale = false;
                          _onlyFreeShipping = false;
                        });
                        setState(() {});
                      },
                      child: Text(loc.filterReset2, style: const TextStyle(color: Color(0xFF888888))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── 사이즈 필터 ──
                    Text(loc.filterSize, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
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
                            width: 52, height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel ? widget.categoryColor : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSel ? widget.categoryColor : const Color(0xFFDDDDDD)),
                            ),
                            child: Text(s, style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : const Color(0xFF333333),
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // ── 가격 필터 ──
                    Row(children: [
                      Text(loc.filterPriceRange, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('${_fmtPrice(_minPrice)}${loc.wonUnit} ~ ${_fmtPrice(_maxPrice)}${loc.wonUnit}',
                          style: TextStyle(fontSize: 12, color: widget.categoryColor, fontWeight: FontWeight.w700)),
                    ]),
                    RangeSlider(
                      values: RangeValues(_minPrice, _maxPrice),
                      min: 0, max: 300000,
                      divisions: 30,
                      activeColor: widget.categoryColor,
                      inactiveColor: const Color(0xFFEEEEEE),
                      onChanged: (v) => setModal(() {
                        _minPrice = v.start;
                        _maxPrice = v.end;
                        setState(() {});
                      }),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0${loc.wonUnit2}', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                        Text('300,000${loc.wonUnit2}', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // ── 추가 필터 ──
                    Text(loc.filterExtraOption, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _filterCheckRow(loc.filterSaleOnly, _onlySale, widget.categoryColor, (v) {
                      setModal(() { _onlySale = v; setState(() {}); });
                    }),
                    const SizedBox(height: 8),
                    _filterCheckRow(loc.filterFreeShipOnly, _onlyFreeShipping, widget.categoryColor, (v) {
                      setModal(() { _onlyFreeShipping = v; setState(() {}); });
                    }),
                  ],
                ),
              ),
              // 적용 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.categoryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(loc.filterApply, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterCheckRow(String label, bool value, Color color, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.06) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? color.withValues(alpha: 0.3) : const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Icon(value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20, color: value ? color : const Color(0xFFAAAAAA)),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(
              fontSize: 14, fontWeight: value ? FontWeight.w700 : FontWeight.w400,
              color: value ? const Color(0xFF1A1A1A) : const Color(0xFF555555),
            )),
          ],
        ),
      ),
    );
  }

  String _fmtPrice(double v) =>
      v.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ──────────────────────────────────────────────────────────────────
  // PC 레이아웃
  // ──────────────────────────────────────────────────────────────────
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1A1A1A), size: 28),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            Icon(widget.categoryIcon, color: widget.categoryColor, size: 22),
            const SizedBox(width: 8),
            Text(widget.categoryName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          ],
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: widget.categoryColor,
          unselectedLabelColor: const Color(0xFF888888),
          indicatorColor: widget.categoryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: widget.subCategories.map((sub) {
            return Tab(
              child: Row(
                children: [
                  Text(sub.name),
                  if (sub.tag != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: sub.tag == 'NEW'
                            ? widget.categoryColor
                            : sub.tag == 'SALE'
                                ? Colors.amber
                                : Colors.greenAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        sub.tag!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: sub.tag == 'NEW' ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
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
                // ── 좌측 필터 사이드바 ──
                SizedBox(
                  width: 220,
                  child: _buildPcFilterSidebar(),
                ),
                const SizedBox(width: 24),
                // ── 우측 상품 목록 ──
                Expanded(
                  child: Column(
                    children: [
                      // 검색 + 정렬 바
                      _buildPcSearchSortBar(),
                      const SizedBox(height: 16),
                      // 상품 그리드
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: widget.subCategories.map((sub) {
                            final products = _getProducts(sub.filter);
                            return _buildPcProductGrid(products);
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
    );
  }

  Widget _buildPcFilterSidebar() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 정보 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.categoryColor, widget.categoryColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.categoryIcon, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                Text(
                  widget.categoryName,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getProducts(widget.subCategories.first.filter).length}${loc.productCountUnit}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 정렬 필터
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.sortTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ...AppConstants.sortOptions.map((opt) => InkWell(
                      onTap: () => setState(() => _sortBy = opt),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 16, height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _sortBy == opt
                                      ? widget.categoryColor
                                      : const Color(0xFFCCCCCC),
                                  width: 2,
                                ),
                                color: _sortBy == opt ? widget.categoryColor : Colors.transparent,
                              ),
                              child: _sortBy == opt
                                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              opt,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    _sortBy == opt ? FontWeight.w700 : FontWeight.w400,
                                color: _sortBy == opt
                                    ? widget.categoryColor
                                    : const Color(0xFF444444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 보기 방식
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.viewMode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _viewToggleBtn(
                        icon: Icons.grid_view_rounded,
                        label: loc.viewGrid,
                        isActive: _isGridView,
                        onTap: () => setState(() => _isGridView = true),
                        color: widget.categoryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _viewToggleBtn(
                        icon: Icons.view_list_rounded,
                        label: loc.viewList,
                        isActive: !_isGridView,
                        onTap: () => setState(() => _isGridView = false),
                        color: widget.categoryColor,
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

  Widget _viewToggleBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : const Color(0xFFE0E0E0),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isActive ? color : const Color(0xFF888888)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? color : const Color(0xFF888888))),
          ],
        ),
      ),
    );
  }

  Widget _buildPcSearchSortBar() {
    return Row(
      children: [
        // 검색창
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: Color(0xFF999999), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: '${widget.categoryName} ${loc.productSearchHint}...',
                      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFAAAAAA)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF999999)),
                    onPressed: () => setState(() => _searchQuery = ''),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 그리드/리스트 토글
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              _toggleIconBtn(Icons.grid_view_rounded, _isGridView, () => setState(() => _isGridView = true)),
              Container(width: 1, height: 24, color: const Color(0xFFE0E0E0)),
              _toggleIconBtn(Icons.view_list_rounded, !_isGridView, () => setState(() => _isGridView = false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleIconBtn(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? widget.categoryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20, color: isActive ? widget.categoryColor : const Color(0xFF999999)),
      ),
    );
  }

  Widget _buildPcProductGrid(List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.categoryIcon, size: 64, color: widget.categoryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(loc.productEmpty,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('"$_searchQuery" ${loc.searchNoResult}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
            ],
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => ProductCard(product: products[i]),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: products.length,
        itemBuilder: (context, i) => _buildPcListItem(context, products[i]),
      );
    }
  }

  Widget _buildPcListItem(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: SizedBox(
                width: 140,
                height: 140,
                child: product.images.isNotEmpty
                    ? Image.network(product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: AppColors.background,
                              child: Icon(widget.categoryIcon, color: AppColors.border, size: 40),
                            ))
                    : Container(
                        color: AppColors.background,
                        child: Icon(widget.categoryIcon, color: AppColors.border, size: 40),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (product.isNew) _tag('NEW', AppColors.primary),
                        if (product.isSale) _tag('SALE', AppColors.accent),
                        if (product.isFreeShipping) _tag(loc.freeShippingBadge, AppColors.success),
                      ],
                    ),
                    if (product.isNew || product.isSale || product.isFreeShipping)
                      const SizedBox(height: 6),
                    Text(product.localizedName(_lang),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (product.originalPrice != null)
                      Text(
                        '${_fmt(product.originalPrice!)}원',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      '${_fmt(product.price)}원',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD600)),
                        const SizedBox(width: 3),
                        Text(
                          '${product.rating} (${product.reviewCount})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(loc.categoryDetailView, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 모바일 전용
  // ──────────────────────────────────────────────────────────────────

  // ── Sliver AppBar (카테고리 헤더 + 탭바) ──
  SliverAppBar _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      forceElevated: innerBoxIsScrolled,
      expandedHeight: 130,
      backgroundColor: widget.categoryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: Colors.white,
          ),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort_rounded, color: Colors.white),
          onSelected: (v) => setState(() => _sortBy = v),
          itemBuilder: (_) => AppConstants.sortOptions
              .map((s) => PopupMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        if (_sortBy == s)
                          const Icon(Icons.check,
                              size: 16, color: AppColors.primary)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 6),
                        Text(s,
                            style: TextStyle(
                                fontWeight: _sortBy == s
                                    ? FontWeight.w700
                                    : FontWeight.normal)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.categoryColor,
                widget.categoryColor.withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: 30,
                child: Opacity(
                  opacity: 0.12,
                  child: Icon(widget.categoryIcon, size: 110, color: Colors.white),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.categoryName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_getProducts(widget.subCategories.first.filter).length}${loc.productCountUnit}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicatorColor: Colors.white,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        tabs: widget.subCategories.map((sub) {
          return Tab(
            child: Row(
              children: [
                Text(sub.name),
                if (sub.tag != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: sub.tag == 'NEW'
                          ? Colors.white
                          : sub.tag == 'SALE'
                              ? Colors.amber
                              : Colors.greenAccent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      sub.tag!,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: sub.tag == 'NEW'
                            ? widget.categoryColor
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 모바일 상품 그리드 / 리스트 ──
  Widget _buildProductGrid(List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.categoryIcon, size: 64, color: widget.categoryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(loc.categoryNoProducts, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(product: products[i]),
    );
  }

  Widget _buildListItem(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: SizedBox(
                width: 110,
                height: 110,
                child: product.images.isNotEmpty
                    ? Image.network(product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: AppColors.background,
                              child: Icon(widget.categoryIcon,
                                  color: AppColors.border, size: 36),
                            ))
                    : Container(
                        color: AppColors.background,
                        child: Icon(widget.categoryIcon,
                            color: AppColors.border, size: 36),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (product.isNew) _tag('NEW', AppColors.primary),
                        if (product.isSale) _tag('SALE', AppColors.accent),
                        if (product.isFreeShipping) _tag(loc.freeShippingBadge, AppColors.success),
                      ],
                    ),
                    if (product.isNew || product.isSale || product.isFreeShipping)
                      const SizedBox(height: 4),
                    Text(
                      product.localizedName(_lang),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      softWrap: true,
                    ),
                    const SizedBox(height: 6),
                    if (product.originalPrice != null)
                      Text(
                        '${_fmt(product.originalPrice!)}원',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      '${_fmt(product.price)}원',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFFD600)),
                        const SizedBox(width: 2),
                        Text(
                          '${product.rating} (${product.reviewCount})',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
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

  // ── 리스트 뷰 ──
  Widget _buildProductList(List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.categoryIcon, size: 64, color: widget.categoryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(loc.categoryNoProducts, style: const TextStyle(fontSize: 16, color: Color(0xFF888888))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, i) => _buildListItem(context, products[i]),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800)),
    );
  }

  String _fmt(double price) => price
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
