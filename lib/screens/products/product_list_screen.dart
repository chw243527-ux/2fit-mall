import 'package:flutter/material.dart';
import '../../widgets/net_image.dart';
import '../../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../services/category_service.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'product_detail_screen.dart';
import '../../utils/navigation_helper.dart';
import '../orders/group_order_only_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String? initialCategory;
  final String? searchQuery;
  final String? initialSortBy;
  /// 신상품 필터 자동 적용
  final bool initialOnlyNew;
  /// 베스트(인기순) 정렬 자동 적용
  final bool initialOnlyBest;
  /// IndexedStack 안에 있을 때 뒤로가기 콜백 (홈탭 이동)
  final VoidCallback? onBack;

  const ProductListScreen({
    super.key,
    this.initialCategory,
    this.searchQuery,
    this.initialSortBy,
    this.initialOnlyNew = false,
    this.initialOnlyBest = false,
    this.onBack,
  });

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
  bool _onlyBest = false;
  bool _onlySale = false;
  bool _onlyFreeShip = false;
  // 서브카테고리 필터
  String _selectedSubCategory = '';  // '' = 전체

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? '';
    _searchQuery = widget.searchQuery ?? '';
    _searchController.text = _searchQuery;
    if (widget.initialSortBy != null) _sortBy = widget.initialSortBy!;
    if (widget.initialOnlyNew) _onlyNew = true;
    if (widget.initialOnlyBest) { _onlyBest = true; _sortBy = context.loc.t('인기순', '인기순'); }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 언어 변경 시 번역 트리거
      context.read<LanguageProvider>().triggerTranslation();

      // initialCategory='단체주문'이면 GroupOrderOnlyScreen으로 자동 리다이렉트
      if (_selectedCategory == context.loc.t('단체주문', '단체주문')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GroupOrderOnlyScreen()),
        );
        return;
      }
      // 베스트/신상품 탭은 전체 상품을 로드해야 함
      final cat = (_onlyBest || _onlyNew)
          ? context.loc.t('전체', '전체')
          : (_selectedCategory.isEmpty ? context.loc.t('전체', '전체') : _selectedCategory);
      context.read<ProductProvider>().setCategory(cat);
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
    // 서브카테고리 필터
    if (_selectedSubCategory.isNotEmpty) {
      list = list.where((p) => p.subCategory == _selectedSubCategory).toList();
    }
    // 가격 범위 필터
    list = list.where((p) => p.price >= _minPrice && p.price <= _maxPrice).toList();
    // 추가 필터
    if (_onlyNew) {
      final now = DateTime.now();
      list = list.where((p) {
        // isNew 플래그가 있으면 기존 로직, 없어도 등록일 30일 이내면 신상품으로 표시
        if (p.isNew) return p.isNewActive;
        return now.difference(p.createdAt).inDays <= 30;
      }).toList();
    }
    if (_onlySale) list = list.where((p) => p.isSale).toList();
    if (_onlyFreeShip) list = list.where((p) => p.isFreeShipping).toList();
    // 정렬 (_onlyBest: 판매량 내림차순, salesCount가 모두 0이면 최신순 폴백)
    if (_onlyBest) {
      final totalSales = list.fold(0, (s, p) => s + p.salesCount);
      if (totalSales == 0) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        list.sort((a, b) {
          final cmp = b.salesCount.compareTo(a.salesCount);
          if (cmp != 0) return cmp;
          return b.createdAt.compareTo(a.createdAt); // 동점이면 최신순
        });
      }
    } else if (_sortBy == loc.sortPriceLow) {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == loc.sortPriceHigh) {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == loc.sortPopular) {
      list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    } else if (_sortBy == loc.sortRating) {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == loc.sortLatest) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == context.loc.t('추천순', '추천순')) {
      list.sort((a, b) {
        final scoreA = a.rating * (a.reviewCount + 1);
        final scoreB = b.rating * (b.reviewCount + 1);
        return scoreB.compareTo(scoreA);
      });
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategoryBar(provider),
          _buildSubCategoryBar(),
          _buildSortFilterBar(filteredProducts.length),
          if (_showPriceFilter) _buildPriceFilterPanel(),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF1A1A2E),
              backgroundColor: Colors.white,
              onRefresh: () => context.read<ProductProvider>().refresh(),
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : _isGridView
                          ? _buildGridView(filteredProducts)
                          : _buildListView(filteredProducts),
            ),
          ),
        ],
      ),
    );
  }

  // ── 앱바 ──
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A1A), size: 20),
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      title: widget.searchQuery != null
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15),
              decoration: InputDecoration(
                hintText: loc.productSearchHint,
                hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 14),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : Text(loc.homeAllProducts, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 16, fontWeight: FontWeight.w800)),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Color(0xFF1A1A1A), size: 22),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen(searchQuery: ''))),
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: const Color(0xFF1A1A1A), size: 22),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── 카테고리 탭 ──
  Widget _buildCategoryBar(ProductProvider provider) {
    // 특별 탭: 전체 목록 앞에 베스트/신상품 삽입 (전체 탭 다음에 표시)
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                // ── 순서: 전체 → 베스트 → 신상품 → 단체주문 → 나머지 카테고리 ──

                // [1] 전체 탭
                _buildCatTab(context.loc.t('전체', '전체'), provider),

                // [2] 베스트 탭
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _onlyBest = true;
                      _onlyNew = false;
                      _selectedCategory = '';
                      _selectedSubCategory = '';
                      _sortBy = context.loc.t('인기순', '인기순');
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    provider.setCategory(context.loc.t('전체', '전체'));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _onlyBest ? const Color(0xFF1A1A2E) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _onlyBest ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                          size: 13,
                          color: _onlyBest ? Colors.white : const Color(0xFF888888)),
                        const SizedBox(width: 3),
                        Text(context.loc.t('베스트', '베스트'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _onlyBest ? Colors.white : const Color(0xFF777777),
                          )),
                      ],
                    ),
                  ),
                ),

                // [3] 신상품 탭
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _onlyNew = true;
                      _onlyBest = false;
                      _selectedCategory = '';
                      _selectedSubCategory = '';
                      _sortBy = context.loc.t('최신순', '최신순');
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    provider.setCategory(context.loc.t('전체', '전체'));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _onlyNew ? const Color(0xFF1A1A2E) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _onlyNew ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_new_rounded,
                          size: 13,
                          color: _onlyNew ? Colors.white : const Color(0xFF888888)),
                        const SizedBox(width: 3),
                        Text(context.loc.t('신상품', '신상품'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _onlyNew ? Colors.white : const Color(0xFF777777),
                          )),
                      ],
                    ),
                  ),
                ),

                // [4] 단체주문 탭 (항상 보라색 고정)
                _buildCatTab(context.loc.t('단체주문', '단체주문'), provider),

                // [5] 나머지 카테고리 탭 (전체·단체주문 제외)
                ...AppConstants.categories
                    .where((cat) => cat != context.loc.t('전체', '전체') && cat != '단체주문')
                    .map((cat) => _buildCatTab(cat, provider)),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE8E8E8)),
        ],
      ),
    );
  }

  // ── 서브카테고리 바 ──
  Widget _buildSubCategoryBar() {
    // CategoryService 기반 서브카테고리 목록 (드로어와 동일한 소스)
    final subs = CategoryService.subCatsFor(_selectedCategory);

    // 서브카테고리가 없거나, 베스트/신상품 탭이면 숨김
    if (subs.isEmpty || _onlyBest || _onlyNew) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                // 전체 칩
                _buildSubCatChip(context.loc.t('전체', '전체'), ''),
                ...subs.map((sub) => _buildSubCatChip(sub, sub)),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildSubCatChip(String label, String value) {
    final isSel = _selectedSubCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1A1A2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
            color: isSel ? Colors.white : const Color(0xFF777777),
          ),
        ),
      ),
    );
  }

  // ── 일반 카테고리 탭 위젯 ──
  Widget _buildCatTab(String cat, ProductProvider provider) {
    final isGroup = cat == '단체주문';
    // 단체주문은 항상 보라색, 그 외는 선택 상태에 따라
    final isSel = _selectedCategory == cat && !_onlyBest && !_onlyNew;
    final bgColor = isGroup
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.08)  // 단체주문
        : isSel
            ? const Color(0xFF1A1A2E)                      // 선택됨
            : Colors.transparent;                          // 미선택
    final borderColor = isGroup
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.4)
        : isSel ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD);
    final textColor = isGroup ? const Color(0xFF1A1A2E) : isSel ? Colors.white : const Color(0xFF555555);

    return GestureDetector(
      onTap: () {
        if (isGroup) {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const GroupOrderOnlyScreen()));
          return;
        }
        setState(() {
          _selectedCategory = cat;
          _onlyBest = false;
          _onlyNew = false;
          _selectedSubCategory = '';
          _searchQuery = '';
          _searchController.clear();
        });
        provider.setCategory(cat);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGroup) ...[
              const Icon(Icons.groups_rounded, size: 13, color: Color(0xFF1A1A2E)),
              const SizedBox(width: 4),
            ],
            Text(cat, style: TextStyle(
              fontSize: 12.5,
              fontWeight: (isSel || isGroup) ? FontWeight.w800 : FontWeight.w500,
              color: textColor,
            )),
          ],
        ),
      ),
    );
  }

  // ── 정렬 바텀시트 ──
  void _showSortBottomSheet() {
    final sortOptions = [
      {'key': 'recommend', 'label': context.loc.t('추천순', '추천순')},
      {'key': 'priceLow',  'label': loc.sortPriceLow},
      {'key': 'priceHigh', 'label': loc.sortPriceHigh},
      {'key': 'popular',   'label': loc.sortPopular},
      {'key': 'rating',    'label': loc.sortRating},
      {'key': 'latest',    'label': loc.sortLatest},
    ];
    if (_sortBy.isEmpty) _sortBy = sortOptions[0]['label']!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 타이틀
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(context.loc.t('정렬', '정렬'), style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A),
                  )),
                ),
              ),
              // 구분선
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              // 옵션 목록
              ...sortOptions.map((opt) {
                final label = opt['label']!;
                final isSelected = _sortBy == label;
                return InkWell(
                  onTap: () {
                    setModal(() {});
                    setState(() => _sortBy = label);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: Row(
                      children: [
                        // 라디오 버튼
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
                              width: isSelected ? 2 : 1.5,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10, height: 10,
                                    decoration: const BoxDecoration(
                                      color: const Color(0xFF1A1A2E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Text(label, style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFF666666),
                        )),
                      ],
                    ),
                  ),
                );
              }),
              // 하단 여백 (iOS 홈 바 대응)
              SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
            ],
          ),
        ),
      ),
    );
  }

  // ── 정렬/필터 바 ──
  Widget _buildSortFilterBar(int count) {
    final sortOptions = [
      {'key': 'recommend', 'label': context.loc.t('추천순', '추천순')},
      {'key': 'priceLow',  'label': loc.sortPriceLow},
      {'key': 'priceHigh', 'label': loc.sortPriceHigh},
      {'key': 'popular',   'label': loc.sortPopular},
      {'key': 'rating',    'label': loc.sortRating},
      {'key': 'latest',    'label': loc.sortLatest},
    ];
    if (_sortBy.isEmpty) _sortBy = sortOptions[0]['label']!;

    // 현재 선택된 정렬 라벨
    final currentSortLabel = _sortBy.isNotEmpty ? _sortBy : sortOptions[0]['label']!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (_onlyBest) ...[
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(context.loc.t('베스트', '베스트'), style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
          if (_onlyNew) ...[
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(context.loc.t('신상품', '신상품'), style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            ),
          ],
          Text('$count${loc.productCount}', style: const TextStyle(
            fontSize: 12.5, color: Color(0xFF999999), fontWeight: FontWeight.w500)),
          const Spacer(),
          // ── 정렬 버튼 (바텀시트 트리거) ──
          GestureDetector(
            onTap: _showSortBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort_rounded, size: 14, color: Color(0xFF888888)),
                  const SizedBox(width: 5),
                  Text(
                    currentSortLabel,
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Color(0xFF999999)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // ── 필터 버튼 ──
          GestureDetector(
            onTap: () => setState(() => _showPriceFilter = !_showPriceFilter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _activeFilterCount > 0 || _showPriceFilter
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _activeFilterCount > 0 || _showPriceFilter
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFFDDDDDD),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.tune_rounded, size: 14,
                    color: _activeFilterCount > 0 || _showPriceFilter
                        ? Colors.white : const Color(0xFF888888)),
                const SizedBox(width: 5),
                Text(context.loc.t('필터', '필터'), style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: _activeFilterCount > 0 || _showPriceFilter
                      ? Colors.white : const Color(0xFF777777),
                )),
                if (_activeFilterCount > 0) ...[const SizedBox(width: 4),
                  Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('$_activeFilterCount',
                      style: const TextStyle(fontSize: 9, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w800))),
                  )],
              ]),
            ),
          ),
          const SizedBox(width: 6),
          // ── 그리드/리스트 토글 ──
          GestureDetector(
            onTap: () => setState(() => _isGridView = !_isGridView),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                size: 16, color: const Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 가격 범위 + 추가 필터 패널 ──
  Widget _buildPriceFilterPanel() {
    return Container(
      color: const Color(0xFFF8F8F8),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(loc.filterPriceRange, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const Spacer(),
              Text('${_fmt(_minPrice)}${loc.wonUnit} ~ ${_maxPrice >= 500000 ? loc.productListPriceRange : '${_fmt(_maxPrice)}${loc.wonUnit}'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF333333), fontWeight: FontWeight.w600)),
            ],
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 500000,
            divisions: 50,
            activeColor: const Color(0xFF1A1A2E),
            inactiveColor: const Color(0xFFDDDDDD),
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
              child: Text(loc.filterResetBtn, style: const TextStyle(fontSize: 12, color: Color(0xFF999999), decoration: TextDecoration.underline)),
            )],
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white : const Color(0xFF555555), fontWeight: FontWeight.w600)),
      selected: selected,
      onSelected: onChanged,
      selectedColor: const Color(0xFF1A1A2E),
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide.none,
    );
  }

  // ── 그리드 뷰 — Wrap으로 교체 (카드 실제 높이 유지, 이미지 잘림 없음) ──
  Widget _buildGridView(List<ProductModel> products) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        const cols = 2;
        const spacing = 8.0;
        const padding = 10.0;
        final cardW = (constraints.maxWidth - padding * 2 - spacing * (cols - 1)) / cols;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: products.map((p) =>
                SizedBox(width: cardW, child: _buildProductCard(p))
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  // ── 리스트 뷰 ──
  Widget _buildListView(List<ProductModel> products) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 영역 — 4:5 고정 비율
                AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: p.images.isNotEmpty
                            ? NetImage(
                                p.images.first,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: const Color(0xFFF0F0F0),
                                child: const Icon(Icons.checkroom_rounded, color: Color(0xFFCCCCCC), size: 48)),
                      ),
                      // 배지들
                      if (p.isGroupOnly) Positioned(top: 8, left: 8,
                        child: _badge(context.loc.t('단체전용', '단체전용'), Color(0xFF555555))),
                      if (p.isNewActive) Positioned(top: p.isGroupOnly ? 32 : 8, left: 8,
                        child: _badge('NEW', const Color(0xFF1A1A2E))),
                      if (discount > 0) Positioned(
                        top: p.isGroupOnly ? (p.isNewActive ? 56 : 32) : (p.isNewActive ? 32 : 8), left: 8,
                        child: _badge('-$discount%', const Color(0xFFE53935))),
                      if (p.isFreeShipping) Positioned(bottom: 8, left: 8,
                        child: _badge(loc.filterFreeShip, const Color(0xFF43A047))),
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
                      const Text('2FIT KOREA', style: TextStyle(fontSize: 10, color: Color(0xFF999999), letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      if (p.isGroupOnly) ...[  
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(context.loc.t('단체주문 전용', '단체주문 전용'),
                            style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                        ),
                      ],
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
                                style: const TextStyle(fontSize: 10, color: Color(0xFF666666), decoration: TextDecoration.lineThrough)),
                          Row(
                            children: [
                              if (discount > 0) ...[
                                Text('$discount%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFE53935))),
                                const SizedBox(width: 4),
                              ],
                              Text('${_fmt(p.price)}${loc.wonUnit}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFB300)),
                          const SizedBox(width: 1),
                          Text('${p.rating}', style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
                        ],
                      ),
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
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                ),
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
          border: Border.all(color: const Color(0xFFEEEEEE)),
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
                        ? NetImage(p.images.first, fit: BoxFit.cover)
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
                      if (p.isGroupOnly) _badge(context.loc.t('단체전용', '단체전용'), Color(0xFF555555)),
                      if (p.isGroupOnly) const SizedBox(width: 4),
                      if (p.isNewActive) _badge('NEW', const Color(0xFF1A1A2E)),
                      if (p.isNewActive) const SizedBox(width: 4),
                      if (p.isFreeShipping) _badge(loc.filterFreeShip, const Color(0xFF43A047)),
                    ]),
                    if (p.isGroupOnly || p.isNewActive || p.isFreeShipping) const SizedBox(height: 4),
                    Text(p.localizedName(_lang), maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 6),
                    if (p.originalPrice != null)
                      Text('${_fmt(p.originalPrice!)}${loc.wonUnit}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF666666), decoration: TextDecoration.lineThrough)),
                    Row(
                      children: [
                        if (discount > 0) ...[
                          Text('$discount%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFE53935))),
                          const SizedBox(width: 4),
                        ],
                        Text('${_fmt(p.price)}${loc.wonUnit}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text('${p.rating} (${p.reviewCount})', style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
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
          const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? loc.searchNoResult(_searchQuery) : loc.noCategoryProduct,
            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () { setState(() { _selectedCategory = loc.catAll; _searchQuery = ''; }); context.read<ProductProvider>().setCategory(loc.catAll); },
            child: Text(loc.homeAllProducts, style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
