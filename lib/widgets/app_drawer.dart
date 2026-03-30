import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/products/category_detail_screen.dart';
import '../screens/orders/group_order_landing_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_screen.dart';

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
  final String name;
  final String filter;
  final String? tag;

  const SubCategory({required this.name, required this.filter, this.tag});
}

// ──────────────────────────────────────────────
// 전체 카테고리 트리 (런타임 loc 적용)
// ──────────────────────────────────────────────
List<CategoryData> getCategories(AppLocalizations loc) => [
  CategoryData(
    name: loc.catTop,
    icon: Icons.dry_cleaning_rounded,
    color: const Color(0xFF1565C0),
    subCategories: [
      SubCategory(name: loc.catTopAll, filter: '상의'),
      SubCategory(name: loc.catSingletA, filter: '상의', tag: 'NEW'),
      SubCategory(name: loc.catSingletB, filter: '상의'),
      SubCategory(name: loc.catRoundTee, filter: '상의'),
      SubCategory(name: loc.catCropTop, filter: '상의'),
      SubCategory(name: loc.catLongSleeve, filter: '상의'),
      SubCategory(name: loc.catSweatshirt, filter: '상의'),
      SubCategory(name: loc.catHoodZip, filter: '상의'),
      SubCategory(name: loc.catCollarTee, filter: '상의'),
    ],
  ),
  CategoryData(
    name: loc.catBottom,
    icon: Icons.style_rounded,
    color: const Color(0xFF2E7D32),
    subCategories: [
      SubCategory(name: loc.catBottomAll, filter: '하의'),
      SubCategory(name: loc.catTights9, filter: '하의', tag: 'BEST'),
      SubCategory(name: loc.catTights5, filter: '하의'),
      SubCategory(name: loc.catTights4, filter: '하의'),
      SubCategory(name: loc.catTights3, filter: '하의'),
      SubCategory(name: loc.catTights25, filter: '하의'),
      SubCategory(name: loc.catShortShorts, filter: '하의'),
      SubCategory(name: loc.catTrainingPants, filter: '하의'),
      SubCategory(name: loc.catShorts, filter: '하의', tag: 'NEW'),
    ],
  ),
  CategoryData(
    name: loc.catSet,
    icon: Icons.checkroom_rounded,
    color: const Color(0xFFE53935),
    subCategories: [
      SubCategory(name: loc.catSetAll, filter: '세트'),
      SubCategory(name: loc.catSingletASet, filter: '세트', tag: 'NEW'),
      SubCategory(name: loc.catTrainingSet, filter: '세트'),
    ],
  ),
  CategoryData(
    name: loc.catOuter,
    icon: Icons.layers_rounded,
    color: const Color(0xFF37474F),
    subCategories: [
      SubCategory(name: loc.catOuterAll, filter: '아우터'),
      SubCategory(name: loc.catWindbreaker, filter: '아우터', tag: 'BEST'),
      SubCategory(name: loc.catTrainingZip, filter: '아우터'),
      SubCategory(name: loc.catDownPadding, filter: '아우터'),
      SubCategory(name: loc.catDownVest, filter: '아우터'),
      SubCategory(name: loc.catLongPadding, filter: '아우터'),
    ],
  ),
  CategoryData(
    name: loc.catSkinsuit,
    icon: Icons.accessibility_new_rounded,
    color: const Color(0xFF00838F),
    subCategories: [
      SubCategory(name: loc.catSkinsuitAll, filter: '스킨슈트'),
      SubCategory(name: loc.catSkinsuitItem, filter: '스킨슈트', tag: 'NEW'),
    ],
  ),
  CategoryData(
    name: loc.catAccessory,
    icon: Icons.backpack_rounded,
    color: const Color(0xFF6A1B9A),
    subCategories: [
      SubCategory(name: loc.catAccessoryAll, filter: '악세사리'),
      SubCategory(name: loc.catHat, filter: '악세사리'),
      SubCategory(name: loc.catBackpack, filter: '악세사리'),
    ],
  ),
  CategoryData(
    name: loc.catEvent,
    icon: Icons.local_offer_rounded,
    color: const Color(0xFFFF6B35),
    subCategories: [
      SubCategory(name: loc.catEventAll, filter: '이벤트'),
      SubCategory(name: loc.catSeasonSale, filter: '이벤트', tag: 'SALE'),
      SubCategory(name: loc.catNewSpecial, filter: '신상품', tag: 'NEW'),
    ],
  ),
];

// ──────────────────────────────────────────────
// AppDrawer — Nike-inspired Design
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
  Widget build(BuildContext context) {
    final isAdmin = context.watch<UserProvider>().isAdmin;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: const Color(0xFF111111), // Nike black
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── SHOP 섹션 레이블 ──
                _sectionLabel('SHOP'),
                ...getCategories(loc).asMap().entries.map(
                  (e) => _buildCategoryTile(context, e.key, e.value),
                ),
                _nikeRule(),
                // ── ORDERS ──
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
                // ── SUPPORT ──
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

                // ── ADMIN ──
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

  // 얇은 구분선
  Widget _nikeRule() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        color: Colors.white.withValues(alpha: 0.08),
      );

  // ── 헤더: 순수 블랙 배경, 흰 로고/텍스트 ──
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
          color: const Color(0xFF111111),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 로고 + X버튼
              Row(
                children: [
                  // 로고 텍스트 (나이키처럼 볼드 wordmark)
                  SizedBox(
                    height: 36,
                    child: Image.asset(
                      'assets/images/logo_2fit_white.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/logo_2fit.png',
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/2fit_logo.png',
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (_, __, ___) => const Text(
                            '2FIT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 유저 섹션
              // ── 마이페이지 버튼 (로그인/비로그인 모두 표시) ──
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigateToMyPage?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Consumer<LanguageProvider>(
                        builder: (_, lp, __) => Text(
                          lp.loc.navMyPage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              if (user != null) ...[
                Row(
                  children: [
                    // 아바타 — 흰 테두리 원
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // 비로그인 — Nike 스타일 버튼
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
                          color: Colors.white,
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF111111),
                          size: 13,
                        ),
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

  // ── 섹션 레이블 (ALLCAPS, 흰색, 작은 회색) ──
  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: 0.35),
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  // ── 카테고리 타일 (Expansion) — 나이키 올블랙 스타일 ──
  Widget _buildCategoryTile(BuildContext context, int index, CategoryData cat) {
    final isExpanded = _expandedIndex == index;
    return Column(
      children: [
        InkWell(
          splashColor: Colors.white.withValues(alpha: 0.04),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          onTap: () => setState(() {
            _expandedIndex = isExpanded ? null : index;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // 작은 점 대신 아이콘을 흰/회색으로
                Icon(
                  cat.icon,
                  size: 18,
                  color: isExpanded
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isExpanded ? FontWeight.w800 : FontWeight.w500,
                      color: isExpanded
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.75),
                      letterSpacing: isExpanded ? 0.3 : 0,
                    ),
                  ),
                ),
                // 전체보기 텍스트 버튼
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
                      ),
                    );
                  },
                  child: Text(
                    'ALL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.35),
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
                    color: Colors.white.withValues(alpha: isExpanded ? 0.9 : 0.35),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 서브카테고리
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

  // ── 서브 카테고리 (인덴트, 밑줄 없음) ──
  Widget _buildSubCategories(BuildContext context, CategoryData cat) {
    return Container(
      color: const Color(0xFF1A1A1A), // 살짝 밝은 블랙
      child: Column(
        children: cat.subCategories.map((sub) {
          return InkWell(
            splashColor: Colors.white.withValues(alpha: 0.04),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProductListScreen(initialCategory: sub.filter),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(52, 12, 20, 12),
              child: Row(
                children: [
                  // 가는 선 accent
                  Container(
                    width: 2,
                    height: 14,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sub.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.65),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (sub.tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: sub.tag == 'NEW'
                            ? Colors.white
                            : sub.tag == 'SALE'
                                ? const Color(0xFFFF0000)
                                : const Color(0xFF00A651),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        sub.tag!,
                        style: TextStyle(
                          color: sub.tag == 'NEW'
                              ? const Color(0xFF111111)
                              : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
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

  // ── 일반 메뉴 타일 ──
  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      splashColor: Colors.white.withValues(alpha: 0.04),
      highlightColor: Colors.white.withValues(alpha: 0.03),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.white.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
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
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }

  // ── 관리자 타일 ──
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
            const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFF111111),
              size: 20,
            ),
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
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF111111),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ── 하단 푸터 ──
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
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              Text(
                '© 2024 2FIT KOREA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.25),
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
                  child: Text(
                    'LOG OUT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.45),
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
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 36, height: 3,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              '2FIT KOREA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SPORTS & FITNESS WEAR',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 20),
            Consumer<LanguageProvider>(builder: (_, lp, __) => Text(
              lp.loc.brandDescription,
              style: const TextStyle(
                fontSize: 13,
                height: 1.8,
                color: Color(0x99FFFFFF),
              ),
            )),
            const SizedBox(height: 16),
            // 전화 / 이메일
            Row(
              children: [
                Icon(Icons.phone_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Text(
                  '010-7227-6914',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const Spacer(),
                Icon(Icons.email_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Text(
                  'chw243527@gmail.com',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // CS 운영시간
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Text(
                  '평일 10:00-18:00  |  토·일·공휴일 휴무',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 점심시간 안내
            Row(
              children: [
                const SizedBox(width: 22),
                Text(
                  '점심시간 12:00-14:00 제외',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
