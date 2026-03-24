import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/app_localizations.dart';
import 'home/home_screen.dart';
import 'products/product_list_screen.dart';
import 'products/category_detail_screen.dart';
import 'cart/cart_screen.dart';
import 'mypage/mypage_screen.dart';
import '../widgets/app_drawer.dart';
import 'orders/order_guide_screen.dart';
import 'chat/chat_screen.dart';
import 'auth/login_screen.dart';

// PC 기준 breakpoint
const double kPcBreakpoint = 900;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void navigateToMyPage() => setState(() => _currentIndex = 3);
  void navigateTo(int index) => setState(() => _currentIndex = index);

  @override
  void initState() {
    super.initState();
    // 공지사항 팝업 - MainScreen 레벨에서 표시 (가장 안정적)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Firestore에서 공지사항 로드 (번역 없으면 자동 번역)
      context.read<NoticeProvider>().loadFromFirestore();
      Future.delayed(const Duration(milliseconds: 1500), _showNoticePopup);
    });
  }

  void _showNoticePopup() {
    if (!mounted) return;
    final noticeProv = context.read<NoticeProvider>();
    if (!noticeProv.shouldShow) return;
    final notices = noticeProv.activeNotices;
    if (notices.isEmpty) return;
    final langProv = context.read<LanguageProvider>();
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      builder: (_) => _NoticePopupDialog(
        notices: notices,
        language: langProv.language,
        loc: langProv.loc,
        onDismissToday: () => noticeProv.dismissToday(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final loc = context.watch<LanguageProvider>().loc;
    final width = MediaQuery.of(context).size.width;
    final isPc = kIsWeb && width >= kPcBreakpoint;
    final userProvider = context.watch<UserProvider>();

    // 로그아웃 감지: user가 null이 되면 로그인 화면으로 이동
    if (userProvider.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isPc) {
      return _PcLayout(
        currentIndex: _currentIndex,
        onTabChanged: (i) => setState(() => _currentIndex = i),
      );
    }

    // ── 모바일 레이아웃 (BottomNav 제거) ──
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        onNavigateToMyPage: () => setState(() => _currentIndex = 3),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            scaffoldKey: _scaffoldKey,
            onNavigate: navigateTo,
          ),
          const ProductListScreen(),
          const CartScreen(),
          MyPageScreen(
            onBack: () => setState(() => _currentIndex = 0),
          ),
        ],
      ),
      // bottomNavigationBar 제거 — 로고 클릭으로 홈, 앱바 아이콘으로 이동
    );
  }
}

// ─────────────────────────────────────────
// PC 레이아웃 (상단 GNB + 본문)
// ─────────────────────────────────────────
class _PcLayout extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const _PcLayout({required this.currentIndex, required this.onTabChanged});

  static const _icons = [
    Icons.home_rounded,
    Icons.grid_view_rounded,
    Icons.shopping_bag_rounded,
    Icons.person_rounded,
  ];

  @override
  State<_PcLayout> createState() => _PcLayoutState();
}

class _PcLayoutState extends State<_PcLayout> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  final GlobalKey<ScaffoldState> _pcScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final tabs = [loc.navHome, loc.navProducts, loc.navCart, loc.pcMyPage];
    return Scaffold(
      key: _pcScaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildPcCategoryDrawer(context, loc),
      floatingActionButton: widget.currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
              backgroundColor: const Color(0xFF4CAF50),
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
              label: Text(loc.pcKakaoChannel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      body: Column(
        children: [
          _PcTopBar(
            currentIndex: widget.currentIndex,
            onTabChanged: widget.onTabChanged,
            tabs: tabs,
            icons: _PcLayout._icons,
            scaffoldKey: _pcScaffoldKey,
          ),
          Expanded(
            child: IndexedStack(
              index: widget.currentIndex,
              children: [
                HomeScreen(onNavigate: widget.onTabChanged),
                const ProductListScreen(),
                const CartScreen(),
                MyPageScreen(
                  onBack: () => widget.onTabChanged(0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPcCategoryDrawer(BuildContext context, AppLocalizations loc) {
    return Drawer(
      width: 300,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 헤더
          Container(
            color: const Color(0xFF111111),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20, right: 8, bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category_rounded, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(loc.categoryLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 마이페이지 버튼
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onTabChanged(3);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(loc.myPageLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 전체 상품 링크
          ListTile(
            leading: const Icon(Icons.grid_view_rounded, size: 20, color: Color(0xFF1A1A1A)),
            title: Text(loc.allProducts,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProductListScreen()));
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // 카테고리 목록
          Expanded(
            child: ListView.builder(
              itemCount: getCategories(loc).length,
              itemBuilder: (_, i) {
                final cat = getCategories(loc)[i];
                return _PcDrawerCategoryTile(
                  cat: cat,
                  onClose: () => Navigator.pop(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// PC 상단 GNB (쇼핑몰 스타일 헤더)
// ─────────────────────────────────────────
class _PcTopBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final List<String> tabs;
  final List<IconData> icons;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const _PcTopBar({
    required this.currentIndex,
    required this.onTabChanged,
    required this.tabs,
    required this.icons,
    this.scaffoldKey,
  });

  @override
  State<_PcTopBar> createState() => _PcTopBarState();
}

// ─── PC 언어 선택 버튼 (독립 위젯) ───
class _PcLanguageBtn extends StatelessWidget {
  const _PcLanguageBtn();

  void _showSheet(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: context.read<LanguageProvider>(),
        child: const _LangDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (_, lp, __) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lp.language.flagEmoji,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(lp.language.code,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 15, color: Color(0xFF777777)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 언어 선택 다이얼로그 (Consumer 분리) ───
class _LangDialog extends StatelessWidget {
  const _LangDialog();

  @override
  Widget build(BuildContext context) {
    final langProv = context.watch<LanguageProvider>();
    final loc = langProv.loc;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: Offset(0, 8))
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 헤더 ──
              Row(
                children: [
                  const Icon(Icons.language_rounded,
                      size: 18, color: Color(0xFF1A1A1A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(loc.mainLanguageSelect,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A))),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF999999)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── 언어 목록 ──
              ...AppLanguage.values.map((lang) {
                final isSel = langProv.language == lang;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        langProv.setLanguage(lang);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFE8E8E8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(lang.flagEmoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(lang.nativeName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSel
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                  )),
                            ),
                            Text(lang.code,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? Colors.white70
                                      : const Color(0xFFAAAAAA),
                                )),
                            if (isSel) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PcTopBarState extends State<_PcTopBar> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ══════════════════════════════════════════
          // 줄 1: 최상단 유틸바 (검정 배경)
          // ══════════════════════════════════════════
          Container(
            height: 36,
            color: const Color(0xFF111111),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Colors.white38, size: 13),
                      const SizedBox(width: 6),
                      Text(loc.pcFreeShipping,
                          style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      const Spacer(),
                      _utilBtn(loc.pcCustomerCenter, Icons.headset_mic_outlined,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ChatScreen()))),
                      const SizedBox(width: 24),
                      _utilBtn(loc.pcOrderLookup, Icons.receipt_long_outlined,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const OrderGuideScreen()))),
                      const SizedBox(width: 24),
                      _utilBtn(loc.pcKakaoChannel, Icons.chat_bubble_outline_rounded,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ChatScreen()))),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ══════════════════════════════════════════
          // 줄 2: 햄버거 + 로고 + 검색창 + 마이페이지/장바구니
          // ══════════════════════════════════════════
          Container(
            height: 80,
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── 햄버거 메뉴 (로고 왼쪽) ──
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => widget.scaffoldKey?.currentState?.openDrawer(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.menu_rounded, size: 20, color: Color(0xFF1A1A1A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // ── 로고 ──
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => widget.onTabChanged(0),
                          child: SizedBox(
                            height: 44,
                            child: Image.asset(
                              'assets/images/logo_2fit.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text(
                                '2FIT\nKOREA',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    height: 1.1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),

                      // ── 검색창 (중앙 확장) ──
                      Expanded(
                        child: _SearchBar(loc: loc),
                      ),
                      const SizedBox(width: 20),

                      // ── 마이페이지 아이콘 ──
                      _topIcon(
                        icon: Icons.person_outline_rounded,
                        label: loc.pcMyPage,
                        onTap: () => widget.onTabChanged(3),
                      ),
                      const SizedBox(width: 8),

                      // ── 장바구니 (뱃지) ──
                      Consumer<CartProvider>(
                        builder: (_, cart, __) => _topIconBadge(
                          icon: Icons.shopping_bag_outlined,
                          label: loc.pcCartLabel,
                          badge: cart.itemCount,
                          onTap: () => widget.onTabChanged(2),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // ── 구분선 ──
                      Container(
                        width: 1,
                        height: 28,
                        color: const Color(0xFFE0E0E0),
                      ),
                      const SizedBox(width: 16),

                      // ── 언어 선택 버튼 ──
                      const _PcLanguageBtn(),
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

  // ─── 유틸바 버튼 ───
  Widget _utilBtn(String label, IconData icon, {VoidCallback? onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 12),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  // ─── 2줄 아이콘 (아이콘 + 라벨) ───
  Widget _topIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF1A1A1A)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─── 2줄 아이콘 + 뱃지 ───
  Widget _topIconBadge({
    required IconData icon,
    required String label,
    required int badge,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: const Color(0xFF1A1A1A)),
                if (badge > 0)
                  Positioned(
                    top: -6, right: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE53935), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────
// PC 검색창 위젯
// ─────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final AppLocalizations loc;
  const _SearchBar({required this.loc});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  final _ctrl = TextEditingController();

  void _search() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(searchQuery: q),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF999999)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: widget.loc.pcSearchHint,
                hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _search,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.loc.pcSearchBtn,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// PC 하단 푸터
// ─────────────────────────────────────────
// ignore: unused_element
class _PcFooter extends StatelessWidget {
  final ValueChanged<int>? onTabChanged;
  // ignore: unused_element_parameter
  const _PcFooter({this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
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
                            onTap: () => onTabChanged?.call(0),
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
                            loc.footerBrandDesc,
                            style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.7),
                          ),
                          const SizedBox(height: 20),
                          _footerInfoRow('🏢 주식회사 2FIT Korea'),
                          _footerInfoRow('📞 010-7227-6914'),
                          _footerInfoRow('✉ chw243527@gmail.com'),
                          _footerInfoRow('💬 카카오톡 @2fitkorea'),
                          _footerInfoRow('🕐 평일 10:00 - 18:00 (점심 12:00 - 14:00)'),
                          _footerInfoRow('🚫 토·일·공휴일 휴무'),
                          const SizedBox(height: 16),
                          // 소셜 링크 버튼
                          Row(
                            children: [
                              _socialBtn(loc.footerKakao, const Color(0xFFFFE000), Colors.black,
                                  () => Navigator.pushNamed(context, '/chat')),
                              const SizedBox(width: 8),
                              _socialBtn(loc.pcCustomerCenter, const Color(0xFF1A1A1A), Colors.white,
                                  () => Navigator.pushNamed(context, '/chat')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    // 링크 그룹들
                    _footerLinkCol(
                      loc.footerShopGuide,
                      [
                        _FooterLink(loc.footerProductList, () => onTabChanged?.call(1)),
                        _FooterLink(loc.footerDeliveryGuide, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderGuideScreen()))),
                        _FooterLink(loc.footerReturnPolicy, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderGuideScreen()))),
                        _FooterLink(loc.footerSizeGuide, () => onTabChanged?.call(1)),
                      ],
                    ),
                    const SizedBox(width: 40),
                    _footerLinkCol(
                      loc.footerOrderService,
                      [
                        _FooterLink(loc.footerGroupOrder, () => Navigator.pushNamed(context, '/group-guide')),
                        _FooterLink(loc.footerOrderStatus, () => onTabChanged?.call(3)),
                        _FooterLink(loc.navCart, () => onTabChanged?.call(2)),
                      ],
                    ),
                    const SizedBox(width: 40),
                    _footerLinkCol(
                      loc.footerSupport,
                      [
                        _FooterLink(loc.footerInquiry, () => Navigator.pushNamed(context, '/chat')),
                        _FooterLink(loc.footerFaq, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderGuideScreen()))),
                        _FooterLink(loc.pcMyPage, () => onTabChanged?.call(3)),
                        _FooterLink(loc.footerKakaoChannel, () => Navigator.pushNamed(context, '/chat')),
                      ],
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
                        Text(loc.footerTerms, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(width: 16),
                        Text(loc.footerPrivacy, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _footerInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
    );
  }

  Widget _socialBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _footerLinkCol(String title, List<_FooterLink> links) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 14),
          ...links.map((link) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: link.onTap != null
                    ? MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: link.onTap,
                          child: Text(
                            link.label,
                            style: const TextStyle(
                              color: Color(0xFFBBBBBB),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : Text(link.label,
                        style: const TextStyle(color: Colors.white38, fontSize: 13)),
              )),
        ],
      ),
    );
  }
}

class _FooterLink {
  final String label;
  final VoidCallback? onTap;
  const _FooterLink(this.label, this.onTap);
}

// _MobileBottomNav 제거됨 — 하단 네비게이션바 사용하지 않음

// ─────────────────────────────────────────
// 공지사항 팝업 다이얼로그 (MainScreen 레벨에서 표시)
// ─────────────────────────────────────────
class _NoticePopupDialog extends StatefulWidget {
  final List<NoticeModel> notices;
  final AppLanguage language;
  final AppLocalizations loc;
  final VoidCallback onDismissToday;

  const _NoticePopupDialog({
    required this.notices,
    required this.language,
    required this.loc,
    required this.onDismissToday,
  });

  @override
  State<_NoticePopupDialog> createState() => _NoticePopupDialogState();
}

class _NoticePopupDialogState extends State<_NoticePopupDialog> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final notice  = widget.notices[_page];
    final title   = notice.localizedTitle(widget.language);
    final content = notice.localizedContent(widget.language);
    final total   = widget.notices.length;
    final sw      = MediaQuery.of(context).size.width;
    final dialogW = sw > 600 ? 460.0 : (sw - 48.0).clamp(280.0, 460.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: sw > 600 ? (sw - dialogW) / 2 : 24,
        vertical: 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogW),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 헤더 ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                  color: const Color(0xFF1A1A2E),
                  child: Row(
                    children: [
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (total > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_page + 1} / $total',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 30, height: 30,
                          alignment: Alignment.center,
                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── 본문 ──
                Container(
                  color: Colors.white,
                  constraints: const BoxConstraints(maxHeight: 280),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
                // ── 페이지 인디케이터 ──
                if (total > 1)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _page ? 22 : 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _page ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                  ),
                // ── 구분선 ──
                Container(height: 1, color: const Color(0xFFEEEEEE)),
                // ── 하단 버튼 ──
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            widget.onDismissToday();
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF999999),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFEEEEEE)),
                            ),
                          ),
                          child: Text(
                            widget.loc.noticeDontShowToday,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (total > 1 && _page < total - 1)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => _page++),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A2E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(widget.loc.noticeNext, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A2E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(widget.loc.noticeConfirm, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
}

// ─────────────────────────────────────────
// PC 드로어 카테고리 타일 (아코디언)
// ─────────────────────────────────────────
class _PcDrawerCategoryTile extends StatefulWidget {
  final CategoryData cat;
  final VoidCallback onClose;
  const _PcDrawerCategoryTile({required this.cat, required this.onClose});

  @override
  State<_PcDrawerCategoryTile> createState() => _PcDrawerCategoryTileState();
}

class _PcDrawerCategoryTileState extends State<_PcDrawerCategoryTile> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final loc = context.watch<LanguageProvider>().loc;
    final cat = widget.cat;
    return Column(
      children: [
        ListTile(
          leading: Icon(cat.icon, size: 20, color: cat.color),
          title: Text(cat.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          trailing: cat.subCategories.isNotEmpty
              ? Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18, color: const Color(0xFF999999))
              : const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
          onTap: () {
            if (cat.subCategories.isNotEmpty) {
              setState(() => _expanded = !_expanded);
            } else {
              widget.onClose();
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
            }
          },
        ),
        if (_expanded && cat.subCategories.isNotEmpty)
          ...cat.subCategories.map((sub) => ListTile(
                contentPadding: const EdgeInsets.only(left: 56, right: 16),
                title: Text(sub.name,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
                trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCCCCCC)),
                dense: true,
                onTap: () {
                  widget.onClose();
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
              )),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
