import 'package:flutter/material.dart';
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
import '../utils/responsive.dart';

// PC 기준 breakpoint
const double kPcBreakpoint = 900;

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _lastUid; // 유저 변경 감지용

  void navigateToMyPage() => setState(() => _currentIndex = 3);
  void navigateTo(int index) => setState(() => _currentIndex = index);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final noticeProv  = context.read<NoticeProvider>();
      final userProv    = context.read<UserProvider>();
      final uid         = userProv.user?.id;
      _lastUid = uid;
      // UID 기반으로 dismiss 상태 복원
      await noticeProv.onUserChanged(uid);
      noticeProv.loadFromFirestore();
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
    final isPc = MediaQuery.of(context).size.width >= kPcBreakpoint;

    final popupWidget = _NoticePopupDialog(
      notices: notices,
      language: langProv.language,
      loc: langProv.loc,
      onDismissToday: () { noticeProv.dismissToday(); },
      isPc: isPc,
    );

    if (isPc) {
      // PC: 화면 중앙 다이얼로그
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        barrierDismissible: true,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: r.w(40), vertical: r.h(60)),
          child: popupWidget,
        ),
      );
    } else {
      // 모바일: 하단 슬라이드 시트
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        useRootNavigator: false,
        builder: (_) => popupWidget,
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    // ignore: unused_local_variable
    final loc = context.watch<LanguageProvider>().loc;
    final width = MediaQuery.of(context).size.width;
    final isPc = width >= kPcBreakpoint;
    final userProvider = context.watch<UserProvider>();
    final uid = userProvider.user?.id;

    // 유저 변경 감지 → 새 유저 dismiss 상태 로드 + 팝업 재표시
    if (uid != _lastUid) {
      _lastUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final noticeProv = context.read<NoticeProvider>();
        await noticeProv.onUserChanged(uid);
        _showNoticePopup();
      });
    }

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
    // PopScope: 안드로이드 뒤로가기 처리
    //  - 서브탭(1~3)에서 → 홈탭(0)으로 이동
    //  - 홈탭(0)에서 → canPop:false 로 앱 종료 완전 차단
    return PopScope(
      canPop: false, // 항상 false → OS 종료 완전 차단
      onPopInvokedWithResult: (didPop, result) {
        // didPop이 true면 이미 다른 곳에서 처리됨 (서브화면 pop)
        if (didPop) return;
        // MainScreen 자체에 도달한 뒤로가기
        if (_currentIndex != 0) {
          // 서브탭 → 홈탭으로 이동
          setState(() => _currentIndex = 0);
        }
        // 홈탭(0): 아무것도 안 함 → 앱 유지
      },
      child: Scaffold(
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
            ProductListScreen(
              onBack: () => setState(() => _currentIndex = 0),
            ),
            CartScreen(
              onBack: () => setState(() => _currentIndex = 0),
            ),
            MyPageScreen(
              onBack: () => setState(() => _currentIndex = 0),
            ),
          ],
        ),
        // bottomNavigationBar 제거 — 로고 클릭으로 홈, 앱바 아이콘으로 이동
      ),
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
    final r = Responsive.of(context);
    // ignore: unused_local_variable
    final loc = context.watch<LanguageProvider>().loc;
    final tabs = [loc.navHome, loc.navProducts, loc.navCart, loc.pcMyPage];
    // PopScope: 태블릿/PC에서도 안드로이드 뒤로가기 처리
    // 서브탭 → 홈탭, 홈탭에서는 아무 동작 안 함 (홈이 마지막 종착지)
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.currentIndex != 0) {
          widget.onTabChanged(0);
        }
        // 홈탭(0)에서는 아무것도 하지 않음 → 홈이 마지막 종착지
      },
      child: Scaffold(
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
                  ProductListScreen(
                    onBack: () => widget.onTabChanged(0),
                  ),
                  CartScreen(
                    onBack: () => widget.onTabChanged(0),
                  ),
                  MyPageScreen(
                    onBack: () => widget.onTabChanged(0),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            color: Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20, right: 8, bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category_rounded, color: Color(0xFF888888), size: 18),
                    SizedBox(width: r.w(8)),
                    Text(loc.categoryLabel,
                        style: TextStyle(color: Color(0xFF111111), fontSize: r.sp(16), fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF555555), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: r.h(12)),
                // 마이페이지 버튼
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onTabChanged(3);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(10)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: Color(0xFF555555), size: 16),
                        SizedBox(width: r.w(8)),
                        Text(loc.myPageLabel,
                            style: TextStyle(color: Color(0xFF1A1A1A), fontSize: r.sp(13), fontWeight: FontWeight.w700)),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFBBBBBB), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // 전체 상품 링크
          ListTile(
            leading: const Icon(Icons.grid_view_rounded, size: 20, color: Color(0xFF1A1A1A)),
            title: Text(loc.allProducts,
                style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProductListScreen(initialCategory: '전체')));
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
    final r = Responsive.of(context);
    return Consumer<LanguageProvider>(
      builder: (_, lp, __) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showSheet(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: r.w(12), vertical: r.h(7)),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lp.language.flagEmoji,
                    style: TextStyle(fontSize: r.sp(16))),
                SizedBox(width: r.w(6)),
                Text(lp.language.code,
                    style: TextStyle(
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                SizedBox(width: r.w(4)),
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
    final r = Responsive.of(context);
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
          padding: EdgeInsets.all(r.w(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 헤더 ──
              Row(
                children: [
                  const Icon(Icons.language_rounded,
                      size: 18, color: Color(0xFF1A1A1A)),
                  SizedBox(width: r.w(8)),
                  Expanded(
                    child: Text(loc.mainLanguageSelect,
                        style: TextStyle(
                            fontSize: r.sp(15),
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
              SizedBox(height: r.h(16)),
              // ── 언어 목록 ──
              ...AppLanguage.values.map((lang) {
                final isSel = langProv.language == lang;
                return Padding(
                  padding: EdgeInsets.only(bottom: r.h(8)),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        langProv.setLanguage(lang);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(12)),
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
                                style: TextStyle(fontSize: r.sp(20))),
                            SizedBox(width: r.w(12)),
                            Expanded(
                              child: Text(lang.nativeName,
                                  style: TextStyle(
                                    fontSize: r.sp(14),
                                    fontWeight: FontWeight.w700,
                                    color: isSel
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                  )),
                            ),
                            Text(lang.code,
                                style: TextStyle(
                                  fontSize: r.sp(11),
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? Colors.white70
                                      : const Color(0xFFAAAAAA),
                                )),
                            if (isSel) ...[
                              SizedBox(width: r.w(6)),
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
    final r = Responsive.of(context);
    // ignore: unused_local_variable
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
                  padding: EdgeInsets.symmetric(horizontal: r.w(24)),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: Colors.white38, size: 13),
                      SizedBox(width: r.w(6)),
                      Text(loc.pcFreeShipping,
                          style: TextStyle(color: Colors.white60, fontSize: r.sp(12))),
                      const Spacer(),
                      _utilBtn(loc.pcCustomerCenter, Icons.headset_mic_outlined,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ChatScreen()))),
                      SizedBox(width: r.w(24)),
                      _utilBtn(loc.pcOrderLookup, Icons.receipt_long_outlined,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const OrderGuideScreen()))),
                      SizedBox(width: r.w(24)),
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
                  padding: EdgeInsets.symmetric(horizontal: r.w(24)),
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
                      SizedBox(width: r.w(16)),

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
                              errorBuilder: (_, __, ___) => Text(
                                '2FIT\nKOREA',
                                style: TextStyle(
                                    fontSize: r.sp(18),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    height: 1.1),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: r.w(32)),

                      // ── 검색창 (중앙 확장) ──
                      Expanded(
                        child: _SearchBar(loc: loc),
                      ),
                      SizedBox(width: r.w(20)),

                      // ── 마이페이지 아이콘 ──
                      _topIcon(
                        icon: Icons.person_outline_rounded,
                        label: loc.pcMyPage,
                        onTap: () => widget.onTabChanged(3),
                      ),
                      SizedBox(width: r.w(8)),

                      // ── 장바구니 (뱃지) ──
                      Consumer<CartProvider>(
                        builder: (_, cart, __) => _topIconBadge(
                          icon: Icons.shopping_bag_outlined,
                          label: loc.pcCartLabel,
                          badge: cart.itemCount,
                          onTap: () => widget.onTabChanged(2),
                        ),
                      ),
                      SizedBox(width: r.w(16)),

                      // ── 구분선 ──
                      Container(
                        width: 1,
                        height: 28,
                        color: const Color(0xFFE0E0E0),
                      ),
                      SizedBox(width: r.w(16)),

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
            SizedBox(width: r.w(4)),
            Text(label, style: TextStyle(color: Colors.white60, fontSize: r.sp(11.5))),
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
            SizedBox(height: r.h(2)),
            Text(label,
                style: TextStyle(
                    fontSize: r.sp(10),
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
                      padding: EdgeInsets.all(r.w(2)),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE53935), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          badge > 9 ? '9+' : '$badge',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: r.sp(9),
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: r.h(2)),
            Text(label,
                style: TextStyle(
                    fontSize: r.sp(10),
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
    final r = Responsive.of(context);
    // ignore: unused_local_variable
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
          SizedBox(width: r.w(14)),
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF999999)),
          SizedBox(width: r.w(8)),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: widget.loc.pcSearchHint,
                hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: r.sp(13)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: r.sp(13), color: Color(0xFF1A1A1A)),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _search,
              child: Container(
                margin: EdgeInsets.all(r.w(4)),
                padding: EdgeInsets.symmetric(horizontal: r.w(20), vertical: r.h(8)),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.loc.pcSearchBtn,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: r.sp(12),
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
    final r = Responsive.of(context);
    // ignore: unused_local_variable
    final loc = context.watch<LanguageProvider>().loc;
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: EdgeInsets.symmetric(vertical: r.h(40)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r.w(24)),
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
                            child: Text(
                              '2FIT MALL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: r.sp(22),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          SizedBox(height: r.h(10)),
                          Text(
                            loc.footerBrandDesc,
                            style: TextStyle(color: Colors.white54, fontSize: r.sp(13), height: 1.7),
                          ),
                          SizedBox(height: r.h(20)),
                          _footerInfoRow('🏢 주식회사 2FIT Korea'),
                          _footerInfoRow('📞 010-7227-6914'),
                          _footerInfoRow('✉ chw243527@gmail.com'),
                          _footerInfoRow('💬 카카오톡 @2fitkorea'),
                          _footerInfoRow('🕐 평일 10:00 - 18:00 (점심 12:00 - 14:00)'),
                          _footerInfoRow('🚫 토·일·공휴일 휴무'),
                          SizedBox(height: r.h(16)),
                          // 소셜 링크 버튼
                          Row(
                            children: [
                              _socialBtn(loc.footerKakao, const Color(0xFFFFE000), Colors.black,
                                  () => Navigator.pushNamed(context, '/chat')),
                              SizedBox(width: r.w(8)),
                              _socialBtn(loc.pcCustomerCenter, const Color(0xFF1A1A1A), Colors.white,
                                  () => Navigator.pushNamed(context, '/chat')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: r.w(40)),
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
                    SizedBox(width: r.w(40)),
                    _footerLinkCol(
                      loc.footerOrderService,
                      [
                        _FooterLink(loc.footerGroupOrder, () => Navigator.pushNamed(context, '/group-guide')),
                        _FooterLink(loc.footerOrderStatus, () => onTabChanged?.call(3)),
                        _FooterLink(loc.navCart, () => onTabChanged?.call(2)),
                      ],
                    ),
                    SizedBox(width: r.w(40)),
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
                SizedBox(height: r.h(28)),
                const Divider(color: Colors.white12),
                SizedBox(height: r.h(16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '© 2025 2FIT Korea Co., Ltd. All rights reserved.',
                      style: TextStyle(color: Colors.white30, fontSize: r.sp(12)),
                    ),
                    Row(
                      children: [
                        Text(loc.footerTerms, style: TextStyle(color: Colors.white38, fontSize: r.sp(12))),
                        SizedBox(width: r.w(16)),
                        Text(loc.footerPrivacy, style: TextStyle(color: Colors.white38, fontSize: r.sp(12), fontWeight: FontWeight.w600)),
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
      padding: EdgeInsets.only(bottom: r.h(5)),
      child: Text(text, style: TextStyle(color: Colors.white54, fontSize: r.sp(12.5))),
    );
  }

  Widget _socialBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(7)),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: fg, fontSize: r.sp(12), fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _footerLinkCol(String title, List<_FooterLink> links) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: r.sp(14))),
          SizedBox(height: r.h(14)),
          ...links.map((link) => Padding(
                padding: EdgeInsets.only(bottom: r.h(10)),
                child: link.onTap != null
                    ? MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: link.onTap,
                          child: Text(
                            link.label,
                            style: TextStyle(
                              color: Color(0xFFBBBBBB),
                              fontSize: r.sp(13),
                            ),
                          ),
                        ),
                      )
                    : Text(link.label,
                        style: TextStyle(color: Colors.white38, fontSize: r.sp(13))),
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
  final bool isPc;

  const _NoticePopupDialog({
    required this.notices,
    required this.language,
    required this.loc,
    required this.onDismissToday,
    this.isPc = false,
  });

  @override
  State<_NoticePopupDialog> createState() => _NoticePopupDialogState();
}

class _NoticePopupDialogState extends State<_NoticePopupDialog> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  int _page = 0;
  // 실제 이미지 비율 (로드 후 동적 업데이트)
  double? _imageAspectRatio;

  // ── 테마별 그라디언트 (이미지 없을 때 배너 배경) ──
  static const Map<String, List<Color>> _themeGradients = {
    'general':  [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
    'event':    [Color(0xFF8E24AA), Color(0xFFE040FB)],
    'delivery': [Color(0xFF1565C0), Color(0xFF42A5F5)],
    'warning':  [Color(0xFFBF360C), Color(0xFFFF7043)],
    'update':   [Color(0xFF1B5E20), Color(0xFF43A047)],
    'promo':    [Color(0xFFC62828), Color(0xFFE57373)],
    'holiday':  [Color(0xFF00695C), Color(0xFF26A69A)],
    'newitem':  [Color(0xFF01579B), Color(0xFF29B6F6)],
    'weather':  [Color(0xFF0277BD), Color(0xFF81D4FA)],
    'review':   [Color(0xFFE65100), Color(0xFFFFCC02)],
  };

  List<Color> _gradientColors(String theme) =>
      _themeGradients[theme] ?? _themeGradients['general']!;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final notice     = widget.notices[_page];
    final title      = notice.localizedTitle(widget.language);
    final content    = notice.localizedContent(widget.language);
    final total      = widget.notices.length;
    final sw         = MediaQuery.of(context).size.width;
    final sh         = MediaQuery.of(context).size.height;
    final hasImage   = notice.imageUrl.isNotEmpty;
    final gradColors = _gradientColors(notice.theme);
    final emoji      = NoticeThemeHelper.themeEmoji[notice.theme] ?? '📢';

    // 하단 시트 최대 너비 (PC 대응)
    final sheetW = sw > 600 ? 480.0 : sw;
    // 이미지 높이: 실제 비율 기반 (없으면 sh*35% 기본값)
    final imgH = _imageAspectRatio != null
        ? (sheetW / _imageAspectRatio!).clamp(160.0, sh * 0.55)
        : (sh * 0.35).clamp(180.0, 300.0);

    // PC: 전체 둥근 모서리 / 모바일: 상단만 둥근 모서리
    final borderRadius = widget.isPc
        ? BorderRadius.circular(20)
        : const BorderRadius.vertical(top: Radius.circular(20));

    return Container(
      width: sheetW,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── 드래그 핸들: 모바일만 표시 ──
            if (!widget.isPc)
            Container(
              margin: EdgeInsets.only(top: r.h(10), bottom: r.h(6)),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // ① 이미지 / 그라디언트 배너
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: double.infinity,
              height: imgH,
              child: Stack(
                fit: StackFit.expand,
                children: [

                  // 배경: 이미지 or 그라디언트
                  if (hasImage)
                    Image.network(
                      notice.imageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      frameBuilder: (_, child, frame, __) {
                        if (frame != null) {
                          // 이미지 로드 완료 → 실제 해상도로 비율 계산
                          final provider = NetworkImage(notice.imageUrl);
                          provider.resolve(ImageConfiguration.empty)
                              .addListener(ImageStreamListener((info, _) {
                            final w = info.image.width.toDouble();
                            final h = info.image.height.toDouble();
                            if (h > 0 && mounted) {
                              setState(() => _imageAspectRatio = w / h);
                            }
                          }));
                        }
                        return child;
                      },
                      errorBuilder: (_, __, ___) =>
                          _buildGradientBg(gradColors, emoji, title),
                    )
                  else
                    _buildGradientBg(gradColors, emoji, title),

                  // 이미지 있을 때: 하단 흰 배경 텍스트 영역
                  if (hasImage)
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.fromLTRB(r.w(20), r.h(16), r.w(20), r.h(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: Color(0xFF111111),
                                fontSize: r.sp(17),
                                fontWeight: FontWeight.w800,
                                height: 1.4,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (content.isNotEmpty) ...[
                              SizedBox(height: r.h(6)),
                              Text(
                                content,
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: r.sp(13),
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // 우상단 X 닫기 버튼
                  Positioned(
                    top: 12, right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),

                  // 좌하단 '01 / 01' 캡슐
                  Positioned(
                    left: 16,
                    bottom: hasImage ? _bottomTextHeight(content) + 12 : 14,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: r.w(11), vertical: r.h(5)),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(_page + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.sp(11),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // ② 이미지 없을 때 / 이미지 있을 때 공통: 본문 텍스트
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            if (content.isNotEmpty && (!hasImage))
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(r.w(20), r.h(14), r.w(20), r.h(14)),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: r.sp(13),
                    color: const Color(0xFF555555),
                    height: 1.7,
                  ),
                ),
              ),

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // ③ 하단 버튼 바
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              widget.onDismissToday();
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF888888),
                              padding: EdgeInsets.zero,
                              shape: const RoundedRectangleBorder(),
                              minimumSize: const Size(0, 52),
                            ),
                            child: Text(
                              widget.loc.noticeDontShowToday,
                              style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w400),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: total > 1 && _page < total - 1
                                ? () => setState(() => _page++)
                                : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF111111),
                              padding: EdgeInsets.zero,
                              shape: const RoundedRectangleBorder(),
                              minimumSize: const Size(0, 52),
                            ),
                            child: Text(
                              total > 1 && _page < total - 1
                                  ? widget.loc.noticeNext
                                  : widget.loc.noticeConfirm,
                              style: TextStyle(fontSize: r.sp(13), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // iOS 홈 인디케이터 여백 (모바일만)
                  if (!widget.isPc)
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // 이미지 위에 올라오는 텍스트박스의 높이 (인디케이터 위치 계산용)
  double _bottomTextHeight(String content) {
    // 제목 약 50px + 내용 있으면 +40px + 패딩 34px
    return content.isNotEmpty ? 124.0 : 84.0;
  }

  // 테마 그라디언트 배너 (이미지 없을 때)
  Widget _buildGradientBg(List<Color> colors, String emoji, String title) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 그라디언트 배경
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // 장식용 반투명 원
        Positioned(
          right: -40, top: -40,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          left: -30, bottom: -30,
          child: Container(
            width: 150, height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        // 이모지 + 제목 (하단 왼쪽 정렬)
        Positioned(
          left: 22, right: 22, bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: TextStyle(fontSize: r.sp(52))),
              SizedBox(height: r.h(12)),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: r.sp(20),
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  letterSpacing: -0.3,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ],
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
    final r = Responsive.of(context);
    // ignore: unused_local_variable
    // ignore: unused_local_variable
    final loc = context.watch<LanguageProvider>().loc;
    final cat = widget.cat;
    return Column(
      children: [
        ListTile(
          leading: Icon(cat.icon, size: 20, color: cat.color),
          title: Text(cat.name,
              style: TextStyle(fontSize: r.sp(14), fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
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
                contentPadding: EdgeInsets.only(left: r.w(56), right: r.w(16)),
                title: Text(sub.name,
                    style: TextStyle(fontSize: r.sp(13), color: Color(0xFF555555))),
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
