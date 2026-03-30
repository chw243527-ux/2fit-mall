import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String? initialCategory;
  final String? searchQuery;
  final String? initialSortBy;

  const ProductListScreen({super.key, this.initialCategory, this.searchQuery, this.initialSortBy});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  AppLanguage get _lang => context.watch<LanguageProvider>().language;
  late String _selectedCategory;
  String _sortBy = '';
  bool _isGridView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  // 가격 범위 필터
  double _minPrice = 0;
  double _maxPrice = 500000;
  bool _showPriceFilter = false;
  // 추가 필터
  bool _onlyNew = false;
  bool _onlySale = false;
  bool _onlyFreeShip = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? '';
    _searchQuery = widget.searchQuery ?? '';
    _searchController.text = _searchQuery;
    if (widget.initialSortBy != null) _sortBy = widget.initialSortBy!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().setCategory(_selectedCategory);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _getFilteredSorted(List<ProductModel> source) {
    List<ProductModel> list = _searchQuery.isNotEmpty
        ? source.where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.localizedName(_lang)).toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList()
        : List.from(source);
    // 가격 범위 필터
    list = list.where((p) => p.price >= _minPrice && p.price <= _maxPrice).toList();
    // 추가 필터
    if (_onlyNew) list = list.where((p) => p.isNew).toList();
    if (_onlySale) list = list.where((p) => p.isSale).toList();
    if (_onlyFreeShip) list = list.where((p) => p.isFreeShipping).toList();
    // 정렬
    if (_sortBy == loc.sortPriceLow) { list.sort((a, b) => a.price.compareTo(b.price)); }
    else if (_sortBy == loc.sortPriceHigh) { list.sort((a, b) => b.price.compareTo(a.price)); }
    else if (_sortBy == loc.sortPopular) { list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount)); }
    else if (_sortBy == loc.sortRating) { list.sort((a, b) => b.rating.compareTo(a.rating)); }
    else { list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); }
    return list;
  }

  // 활성 필터 수
  int get _activeFilterCount {
    int c = 0;
    if (_minPrice > 0 || _maxPrice < 500000) c++;
    if (_onlyNew) c++;
    if (_onlySale) c++;
    if (_onlyFreeShip) c++;
    return c;
  }

  String _fmt(double v) => v.toInt().toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final filteredProducts = _getFilteredSorted(provider.products);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategoryBar(provider),
          _buildSortFilterBar(filteredProducts.length),
          if (_showPriceFilter) _buildPriceFilterPanel(),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : _isGridView
                        ? _buildGridView(filteredProducts)
                        : _buildListView(filteredProducts),
          ),
        ],
      ),
    );
  }

  // ── 앱바 ──
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF111111),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: widget.searchQuery != null
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: loc.productSearchHint,
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : Text(loc.homeAllProducts, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen(searchQuery: ''))),
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: Colors.white, size: 22),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── 카테고리 탭 ──
  Widget _buildCategoryBar(ProductProvider provider) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: AppConstants.categories.length,
              itemBuilder: (_, i) {
                final cat = AppConstants.categories[i];
                final isSel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() { _selectedCategory = cat; _searchQuery = ''; _searchController.clear(); });
                    provider.setCategory(cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF111111) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSel ? const Color(0xFF111111) : const Color(0xFFDDDDDD)),
                    ),
                    child: Text(cat, style: TextStyle(
                      fontSize: 12.5, fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      color: isSel ? Colors.white : const Color(0xFF444444),
                    )),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
        ],
      ),
    );
  }

  // ── 정렬/필터 바 ──
  Widget _buildSortFilterBar(int count) {
    // loc 기반 정렬 키
    final sortLabels = [loc.sortLatest, loc.sortPopular, loc.sortRating, loc.sortPriceLow, loc.sortPriceHigh];
    // 최초 진입 시 기본값 설정
    if (_sortBy.isEmpty) _sortBy = sortLabels[0];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('$count${loc.productCount}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF888888), fontWeight: FontWeight.w500)),
          const Spacer(),
          // 정렬 버튼들
          ...sortLabels.map((label) {
            final isSel = _sortBy == label;
            return GestureDetector(
              onTap: () => setState(() => _sortBy = label),
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(label, style: TextStyle(
                  fontSize: 11, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? Colors.white : const Color(0xFF666666),
                )),
              ),
            );
          }),
          const SizedBox(width: 4),
          // 필터 버튼
          GestureDetector(
            onTap: () => setState(() => _showPriceFilter = !_showPriceFilter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _activeFilterCount > 0 || _showPriceFilter
                    ? const Color(0xFF111111)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.tune_rounded, size: 14,
                    color: _activeFilterCount > 0 || _showPriceFilter
                        ? Colors.white
                        : const Color(0xFF444444)),
                if (_activeFilterCount > 0) ...[const SizedBox(width: 3),
                  Text('$_activeFilterCount', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))],
              ]),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _isGridView = !_isGridView),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
              child: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, size: 16, color: const Color(0xFF444444)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 가격 범위 + 추가 필터 패널 ──
  Widget _buildPriceFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(loc.filterPriceRange, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
              const Spacer(),
              Text('${_fmt(_minPrice)}${loc.wonUnit} ~ ${_maxPrice >= 500000 ? loc.productListPriceRange : '${_fmt(_maxPrice)}${loc.wonUnit}'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
            ],
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 500000,
            divisions: 50,
            activeColor: const Color(0xFF1A1A2E),
            inactiveColor: const Color(0xFFEEEEEE),
            onChanged: (v) => setState(() { _minPrice = v.start; _maxPrice = v.end; }),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              _filterChip(loc.filterNewOnly, _onlyNew, (v) => setState(() => _onlyNew = v)),
              _filterChip(loc.filterSale, _onlySale, (v) => setState(() => _onlySale = v)),
              _filterChip(loc.filterFreeShip, _onlyFreeShip, (v) => setState(() => _onlyFreeShip = v)),
            ],
          ),
          if (_activeFilterCount > 0) ...[const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                _minPrice = 0; _maxPrice = 500000;
                _onlyNew = false; _onlySale = false; _onlyFreeShip = false;
              }),
              child: Text(loc.filterResetBtn, style: const TextStyle(fontSize: 12, color: Colors.red, decoration: TextDecoration.underline)),
            )],
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white : const Color(0xFF444444), fontWeight: FontWeight.w600)),
      selected: selected,
      onSelected: onChanged,
      selectedColor: const Color(0xFF1A1A2E),
      backgroundColor: const Color(0xFFF5F5F5),
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
    );
  }

  // ── 그리드 뷰 ──
  Widget _buildGridView(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,   // 4:5 이미지 + 텍스트 영역
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _buildProductCard(products[i]),
    );
  }

  // ── 리스트 뷰 ──
  Widget _buildListView(List<ProductModel> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: products.length,
      itemBuilder: (_, i) => _buildProductListTile(products[i]),
    );
  }

  // ── 쇼핑몰 스타일 상품 카드 ──
  Widget _buildProductCard(ProductModel p) {
    final discount = p.originalPrice != null && p.originalPrice! > p.price
        ? ((1 - p.price / p.originalPrice!) * 100).round() : 0;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역 — 4:5 고정 비율, contain으로 전신 표시
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Container(
                      color: const Color(0xFFF5F5F5),
                      child: p.images.isNotEmpty
                          ? Image.network(p.images.first,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF0F0F0),
                                  child: const Icon(Icons.checkroom_rounded, color: Color(0xFFCCCCCC), size: 48)))
                          : Container(color: const Color(0xFFF0F0F0),
                              child: const Icon(Icons.checkroom_rounded, color: Color(0xFFCCCCCC), size: 48)),
                    ),
                  ),
                  // 배지들
                  if (p.isNew) Positioned(top: 8, left: 8,
                    child: _badge('NEW', const Color(0xFF111111))),
                  if (discount > 0) Positioned(top: p.isNew ? 32 : 8, left: 8,
                    child: _badge('-$discount%', const Color(0xFFE53935))),
                  if (p.isFreeShipping) Positioned(bottom: 8, left: 8,
                    child: _badge(loc.filterFreeShip, const Color(0xFF00A651))),
                  // 찜 버튼
                  Positioned(top: 8, right: 8,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      child: const Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFF888888)),
                    )),
                ],
              ),
            ),
            // 정보 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2FIT KOREA', style: TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(p.localizedName(_lang), maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A), height: 1.3)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.originalPrice != null)
                            Text('${_fmt(p.originalPrice!)}${loc.wonUnit}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA), decoration: TextDecoration.lineThrough)),
                          Row(
                            children: [
                              if (discount > 0) ...[
                                Text('$discount%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFE53935))),
                                const SizedBox(width: 4),
                              ],
                              Text('${_fmt(p.price)}${loc.wonUnit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFB300)),
                          const SizedBox(width: 1),
                          Text('${p.rating}', style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 리스트 타일 ──
  Widget _buildProductListTile(ProductModel p) {
    final discount = p.originalPrice != null && p.originalPrice! > p.price
        ? ((1 - p.price / p.originalPrice!) * 100).round() : 0;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Stack(
                children: [
                  SizedBox(
                    width: 110, height: 110,
                    child: p.images.isNotEmpty
                        ? Image.network(p.images.first, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF0F0F0),
                                child: const Icon(Icons.checkroom_rounded, color: Color(0xFFCCCCCC))))
                        : Container(color: const Color(0xFFF0F0F0)),
                  ),
                  if (discount > 0) Positioned(top: 6, left: 6, child: _badge('-$discount%', const Color(0xFFE53935))),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (p.isNew) _badge('NEW', const Color(0xFF111111)),
                      if (p.isNew) const SizedBox(width: 4),
                      if (p.isFreeShipping) _badge(loc.filterFreeShip, const Color(0xFF00A651)),
                    ]),
                    if (p.isNew || p.isFreeShipping) const SizedBox(height: 4),
                    Text(p.localizedName(_lang), maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 6),
                    if (p.originalPrice != null)
                      Text('${_fmt(p.originalPrice!)}${loc.wonUnit}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), decoration: TextDecoration.lineThrough)),
                    Row(
                      children: [
                        if (discount > 0) ...[
                          Text('$discount%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFE53935))),
                          const SizedBox(width: 4),
                        ],
                        Text('${_fmt(p.price)}${loc.wonUnit}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF111111))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text('${p.rating} (${p.reviewCount})', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
  );

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFDDDDDD)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? loc.searchNoResult(_searchQuery) : loc.noCategoryProduct,
            style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () { setState(() { _selectedCategory = loc.catAll; _searchQuery = ''; }); context.read<ProductProvider>().setCategory(loc.catAll); },
            child: Text(loc.homeAllProducts, style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
