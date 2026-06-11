import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../screens/products/category_detail_screen.dart';
import '../screens/orders/group_order_landing_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../services/category_service.dart';

// ──────────────────────────────────────────────
// 카테고리 데이터 모델
// ──────────────────────────────────────────────
class CategoryData {
  final String name;
  final IconData icon;
  final Color color;
  final List<SubCategory> subCategories;

  const CategoryData({
    required this.name,
    required this.icon,
    required this.color,
    required this.subCategories,
  });
}

class SubCategory {
  final String name;   // 표시 이름 (= Firestore subCategory 값과 동일)
  final String filter; // 메인 카테고리 (Firestore category 값)
  final String? tag;

  const SubCategory({required this.name, required this.filter, this.tag});
}

// ── 메인 카테고리별 아이콘·색상 매핑 ──────────────
IconData _iconFor(String cat) {
  switch (cat) {
    case '상의':    return Icons.dry_cleaning_rounded;
    case '하의':    return Icons.style_rounded;
    case '세트':    return Icons.checkroom_rounded;
    case '아우터':  return Icons.layers_rounded;
    case '스킨슈트': return Icons.accessibility_new_rounded;
    case '악세사리': return Icons.backpack_rounded;
    case '이벤트':  return Icons.local_offer_rounded;
    case '단체주문': return Icons.groups_rounded;
    default:        return Icons.category_rounded;
  }
}

Color _colorFor(String cat) {
  switch (cat) {
    case '상의':    return const Color(0xFF1565C0);
    case '하의':    return const Color(0xFF2E7D32);
    case '세트':    return const Color(0xFFE53935);
    case '아우터':  return const Color(0xFF37474F);
    case '스킨슈트': return const Color(0xFF00838F);
    case '악세사리': return const Color(0xFF6A1B9A);
    case '이벤트':  return const Color(0xFFFF6B35);
    case '단체주문': return const Color(0xFF1A237E);
    default:        return const Color(0xFF555555);
  }
}

/// CategoryService 기반 동적 카테고리 목록 생성
/// - 메인: CategoryService.mainCategories
/// - 서브: CategoryService.subCatsFor(mainCat)
/// - 첫 번째 탭은 항상 "전체 {mainCat}" (전체탭)
List<CategoryData> getCategories(AppLocalizations loc) {
  return CategoryService.mainCategories.map((mainCat) {
    final subs = CategoryService.subCatsFor(mainCat);
    // 전체탭 (subName=null 역할 → name을 "전체 {mainCat}"로 세팅)
    final allTabName = '전체 $mainCat';
    final subList = <SubCategory>[
      SubCategory(name: allTabName, filter: mainCat), // 전체탭
      ...subs.expand((s) {
        // 타이즈 탭 클릭 시 하위에 남성 5부 / 여성 2.5부 탭 추가
        if (s == '타이즈' && mainCat == '하의') {
          return [
            SubCategory(name: '타이즈', filter: mainCat),
            SubCategory(name: '남성 5부', filter: mainCat),
            SubCategory(name: '여성 2.5부', filter: mainCat),
          ];
        }
        return [SubCategory(name: s, filter: mainCat)];
      }),
    ];
    return CategoryData(
      name: mainCat,
      icon: _iconFor(mainCat),
      color: _colorFor(mainCat),
      subCategories: subList,
    );
  }).toList();
}

// ──────────────────────────────────────────────
// AppDrawer
// ──────────────────────────────────────────────
class AppDrawer extends StatefulWidget {
  final VoidCallback? onNavigateToMyPage;

  const AppDrawer({super.key, this.onNavigateToMyPage});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    // CategoryService가 아직 로드되지 않은 경우 로드 후 rebuild
    if (CategoryService.mainCategories == CategoryService.defaultMainCategories &&
        CategoryService.mainCategories.length == CategoryService.defaultMainCategories.length) {
      // 이미 기본값이라도 Firestore에서 최신값 확인
      CategoryService.load().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<UserProvider>().isAdmin;
    final categories = getCategories(loc);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _sectionLabel('SHOP'),
                ...categories.asMap().entries.map(
                  (e) => _buildCategoryTile(context, e.key, e.value),
                ),
                _nikeRule(),
                _sectionLabel('ORDERS'),
                _buildMenuTile(
                  context,
                  icon: Icons.edit_note_rounded,
                  label: '단체주문하기',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GroupOrderLandingScreen()));
                  },
                ),
                _nikeRule(),
                _sectionLabel('SUPPORT'),
                _buildMenuTile(
                  context,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: loc.chatTitle,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()));
                  },
                ),
                _buildMenuTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: loc.brandInfo,
                  onTap: () {
                    Navigator.pop(context);
                    _showBrandInfo(context);
                  },
                ),
                if (isAdmin) ...[
                  _nikeRule(),
                  _sectionLabel('ADMIN'),
                  _buildAdminTile(context),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _nikeRule() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        color: const Color(0xFFEEEEEE),
      );

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFFAAAAAA),
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, int index, CategoryData cat) {
    final isExpanded = _expandedIndex == index;
    return Column(
      children: [
        InkWell(
          splashColor: const Color(0x0F111111),
          highlightColor: const Color(0x07111111),
          onTap: () => setState(() {
            _expandedIndex = isExpanded ? null : index;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(
                  cat.icon,
                  size: 18,
                  color: isExpanded ? cat.color : const Color(0xFF888888),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isExpanded ? FontWeight.w800 : FontWeight.w500,
                      color: isExpanded ? const Color(0xFF111111) : const Color(0xFF333333),
                      letterSpacing: isExpanded ? 0.3 : 0,
                    ),
                  ),
                ),
                // ALL 버튼 → 전체탭(0번)으로 진입
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
                          initialTabIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'ALL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFBBBBBB),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isExpanded ? const Color(0xFF555555) : const Color(0xFFBBBBBB),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: _buildSubCategories(context, cat),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildSubCategories(BuildContext context, CategoryData cat) {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: Column(
        children: cat.subCategories.asMap().entries.map((entry) {
          final tabIndex = entry.key;
          final sub = entry.value;
          final isAllTab = tabIndex == 0; // 전체탭
          return InkWell(
            splashColor: const Color(0x0F111111),
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
                    initialTabIndex: tabIndex,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(52, 12, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 2,
                    height: 14,
                    color: isAllTab
                        ? cat.color.withValues(alpha: 0.5)
                        : const Color(0xFFDDDDDD),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sub.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isAllTab ? FontWeight.w700 : FontWeight.w500,
                        color: isAllTab ? const Color(0xFF333333) : const Color(0xFF555555),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      splashColor: const Color(0x0F111111),
      highlightColor: const Color(0x07111111),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF888888)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF111111), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.adminDashboard,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.adminManageDesc,
                    style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Color(0xFF111111), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 12,
            bottom: 20,
          ),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 36,
                    child: Image.asset(
                      'assets/images/logo_2fit.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/2fit_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text(
                          '2FIT',
                          style: TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF555555), size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigateToMyPage?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, color: Color(0xFF1A1A1A), size: 18),
                      const SizedBox(width: 10),
                      Consumer<LanguageProvider>(
                        builder: (_, lp, __) => Text(
                          lp.loc.navMyPage,
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF999999), size: 14),
                    ],
                  ),
                ),
              ),
              if (user != null) ...[
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF111111),
                        border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  child: Row(
                    children: [
                      Text(
                        loc.loginSignup,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF111111),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).padding.bottom + 14,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              const Text(
                '© 2024 2FIT KOREA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFCCCCCC),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (userProvider.isLoggedIn)
                GestureDetector(
                  onTap: () {
                    userProvider.logout();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'LOG OUT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFAAAAAA),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showBrandInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 3,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              '2FIT KOREA',
              style: TextStyle(color: Color(0xFF111111), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            const Text(
              'SPORTS & FITNESS WEAR',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFEEEEEE), height: 1),
            const SizedBox(height: 20),
            Consumer<LanguageProvider>(builder: (_, lp, __) => Text(
              lp.loc.brandDescription,
              style: const TextStyle(fontSize: 13, height: 1.8, color: Color(0xFF555555)),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.phone_rounded, size: 14, color: Color(0xFFAAAAAA)),
                const SizedBox(width: 8),
                const Text('010-7227-6914', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const Spacer(),
                const Icon(Icons.email_rounded, size: 14, color: Color(0xFFAAAAAA)),
                const SizedBox(width: 8),
                const Text('chw243527@gmail.com', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFAAAAAA)),
                const SizedBox(width: 8),
                const Text('평일 10:00-18:00  |  토·일·공휴일 휴무', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 22),
                const Text('점심시간 12:00-14:00 제외', style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA))),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
