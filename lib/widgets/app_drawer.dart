import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../screens/products/category_detail_screen.dart';
import '../screens/orders/group_order_landing_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/support/brand_story_screen.dart';
import '../screens/support/notices_screen.dart';
import '../services/category_service.dart';
import '../services/in_app_update_service.dart';

import '../utils/theme.dart';
import '../utils/constants.dart';

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
  final String name; // 표시 이름 (= Firestore subCategory 값과 동일)
  final String filter; // 메인 카테고리 (Firestore category 값)
  final String? tag;

  const SubCategory({required this.name, required this.filter, this.tag});
}

// ── 메인 카테고리별 아이콘·색상 매핑 ──────────────
IconData _iconFor(String cat) {
  switch (cat) {
    case '상의':
      return Icons.dry_cleaning_rounded;
    case '하의':
      return Icons.style_rounded;
    case '세트':
      return Icons.checkroom_rounded;
    case '아우터':
      return Icons.layers_rounded;
    case '스킨슈트':
      return Icons.accessibility_new_rounded;
    case '악세사리':
      return Icons.backpack_rounded;
    case '이벤트':
      return Icons.local_offer_rounded;
    case '단체주문':
      return Icons.groups_rounded;
    default:
      return Icons.category_rounded;
  }
}

Color _colorFor(String cat) {
  // 쇼핑몰 전체 무드를 싱글렛 상세페이지처럼 블랙·오프화이트 중심으로 통일합니다.
  if (cat == '이벤트') return const Color(0xFFD86442);
  return const Color(0xFF161616);
}

/// CategoryService 기반 동적 카테고리 목록 생성
/// - 메인: CategoryService.mainCategories
/// - 서브: CategoryService.subCatsFor(mainCat)
/// - 첫 번째 탭은 항상 "전체 {mainCat}" (전체탭)
List<CategoryData> getCategories(AppLocalizations loc) {
  return CategoryService.mainCategories.map((mainCat) {
    final subs = CategoryService.subCatsFor(mainCat);
    // 카테고리명 번역 적용
    final translatedMain = loc.t(mainCat, mainCat);
    final allTabName = loc.t('전체 $mainCat', '전체 $mainCat');
    final subList = <SubCategory>[
      SubCategory(name: allTabName, filter: mainCat), // 전체탭
      ...subs.map((s) => SubCategory(name: loc.t(s, s), filter: mainCat)),
    ];
    return CategoryData(
      name: translatedMain,
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
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 언어 변경 시 번역 트리거
      context.read<LanguageProvider>().triggerTranslation();
    });
    // 드로어를 열 때마다 Firestore의 최신 카테고리를 확인합니다.
    // 관리자에서 하위 카테고리 순서·추가·삭제를 변경한 뒤에도
    // 앱을 완전히 재시작하지 않고 다음 드로어 오픈 시 반영됩니다.
    CategoryService.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkForUpdates() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    final result = await InAppUpdateService.checkManually(context);
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    final message = switch (result) {
      ManualUpdateResult.started => '업데이트를 시작했습니다.',
      ManualUpdateResult.noUpdate =>
        'Google Play에서 현재 제공되는 업데이트가 없습니다. 내부 테스트 참여와 Play Store 계정을 확인해 주세요.',
      ManualUpdateResult.storeOpened =>
        'Google Play 앱 페이지를 열었습니다. 업데이트 버튼을 확인해 주세요.',
      ManualUpdateResult.unavailable =>
        'Google Play에서 설치한 Android 앱에서만 업데이트할 수 있습니다.',
      ManualUpdateResult.failed =>
        '업데이트 확인에 실패했습니다. Play Store에서 직접 확인해 주세요.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                  label: loc.t('단체주문방법', '단체주문방법'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GroupOrderLandingScreen()));
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
                  icon: Icons.campaign_outlined,
                  label: '공지사항',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NoticesScreen()));
                  },
                ),
                _buildMenuTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: loc.brandInfo,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BrandStoryScreen()));
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
        color: AppColors.border,
      );

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.textHint,
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
                  color: isExpanded ? cat.color : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isExpanded ? FontWeight.w800 : FontWeight.w500,
                      color: isExpanded
                          ? AppColors.textPrimary
                          : AppColors.textPrimary,
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
                      color: AppColors.textHint,
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
                    color: isExpanded
                        ? AppColors.textSecondary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: _buildSubCategories(context, cat),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildSubCategories(BuildContext context, CategoryData cat) {
    return Container(
      color: AppColors.background,
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
                        : AppColors.border,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sub.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isAllTab ? FontWeight.w700 : FontWeight.w500,
                        color: isAllTab
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
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
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
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
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.border),
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
            const Icon(Icons.admin_panel_settings_rounded,
                color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.adminDashboard,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.adminManageDesc,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: AppColors.textPrimary, size: 16),
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
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 22),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Consumer<LanguageProvider>(
                        builder: (_, lp, __) => Text(
                          lp.loc.navMyPage,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textSecondary, size: 14),
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
                        color: AppColors.textPrimary,
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
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
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
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
                          color: AppColors.primary,
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
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 13),
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
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Text(
                AppConstants.copyright,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.border,
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
                      color: AppColors.textHint,
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

  // 고객 메뉴 연결은 현재 브랜드 소개 라우트로 통합됨.
  // ignore: unused_element
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
                width: 36,
                height: 3,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              '2FIT KOREA',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            const Text(
              'SPORTS & FITNESS WEAR',
              style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 20),
            Consumer<LanguageProvider>(
                builder: (_, lp, __) => Text(
                      lp.loc.brandDescription,
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.8,
                          color: AppColors.textSecondary),
                    )),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(AppConstants.kakaoChannelUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 8),
                  Text(
                    context.loc.t('카카오채널 문의하기', 'Contact Kakao Channel'),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.open_in_new_rounded,
                      size: 13, color: AppColors.textHint),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.email_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text(AppConstants.customerServiceEmail,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 8),
                Text(
                    context.loc.t('평일 10001800    토·일·공휴일 휴무',
                        '평일 10:00-18:00  |  토·일·공휴일 휴무'),
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 22),
                Text(context.loc.t('점심시간 12001400 제외', '점심시간 12:00-14:00 제외'),
                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checkingUpdate ? null : _checkForUpdates,
                icon: _checkingUpdate
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_rounded, size: 17),
                label: Text(
                  _checkingUpdate ? '업데이트 확인 중...' : '업데이트 확인',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
