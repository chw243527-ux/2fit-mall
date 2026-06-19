import 'package:flutter/material.dart';
import '../../widgets/net_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/email_service.dart';
import '../../services/order_excel_service.dart';
import '../../utils/web_utils.dart' if (dart.library.html) '../../utils/web_utils_html.dart';
import '../products/product_detail_screen.dart';
import '../cart/cart_screen.dart';
import '../admin/admin_screen.dart';
import '../auth/login_screen.dart';
import '../orders/group_order_form_screen.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/pc_layout.dart';
import '../../services/order_service.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_service.dart';
import '../../widgets/address_search_widget.dart';
import '../../utils/navigation_helper.dart';

// ══════════════════════════════════════════════════════════════
// MyPageScreen — 오늘의집 스타일 마이페이지
// ══════════════════════════════════════════════════════════════

class MyPageScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MyPageScreen({super.key, this.onBack});
  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── 진행중인 주문 카운트 (상태별)
  Map<OrderStatus, int> get _statusCounts {
    final orders = context.read<OrderProvider>().orders;
    final map = <OrderStatus, int>{};
    for (final s in OrderStatus.values) map[s] = 0;
    for (final o in orders) map[o.status] = (map[o.status] ?? 0) + 1;
    return map;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null) context.read<OrderProvider>().loadUserOrders(user.id);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── 시트 열기 헬퍼 ──────────────────────
  void _openSheet(Widget sheet) => showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => sheet);

  void _openAdditionalOrder(OrderModel o) => _openSheet(_AdditionalOrderSheet(order: o));
  void _openColorEdit(OrderModel o) => _openSheet(_ColorEditSheet(order: o));
  void _openDesignRevision(OrderModel o) => _openSheet(_DesignRevisionSheet(order: o));

  // 헤더 통계칩 → 바텀시트 열기
  void _openOrderListFiltered(BuildContext ctx, OrderStatus status) {
    final all = context.read<OrderProvider>().orders;
    final filtered = all.where((o) => o.status == status).toList();
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('${status.label} 상태의 주문이 없습니다.')));
      return;
    }
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => _OrderListScreen(
      orders: filtered,
      onAdditional: _openAdditionalOrder,
      onColorEdit: _openColorEdit,
      onDesignRevision: _openDesignRevision,
      onExcelDownload: _exportExcel,
    )));
  }

  void _openOrderList(BuildContext ctx) {
    final orders = context.read<OrderProvider>().orders;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('주문 내역이 없습니다.')));
      return;
    }
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => _OrderListScreen(
      orders: orders,
      onAdditional: _openAdditionalOrder,
      onColorEdit: _openColorEdit,
      onDesignRevision: _openDesignRevision,
      onExcelDownload: _exportExcel,
    )));
  }

  void _openWishlist(BuildContext ctx, UserModel user) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bsCtx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: Column(children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Text('찜 목록', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bsCtx)),
            ]),
          ),
          Expanded(child: _WishlistContent(user: user)),
        ]),
      ),
    );
  }

  void _openCouponSheet(BuildContext ctx) {
    final coupons = context.read<CouponProvider>().validCoupons;
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bsCtx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('쿠폰 ${coupons.length}장', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bsCtx)),
            ]),
          ),
          if (coupons.isEmpty)
            const Expanded(child: Center(
              child: Text('사용 가능한 쿠폰이 없습니다.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ))
          else
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: coupons.length,
              itemBuilder: (_, i) {
                final c = coupons[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                  ),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                        decoration: const BoxDecoration(color: Color(0xFFE8EEF8), shape: BoxShape.circle),
                        child: const Icon(Icons.local_offer_rounded, color: Color(0xFF1C62B9), size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(c.typeLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF1C62B9), fontWeight: FontWeight.w600)),
                      Text(
                        '~${c.expiresAt.year}.${c.expiresAt.month.toString().padLeft(2, '0')}.${c.expiresAt.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ])),
                  ]),
                );
              },
            )),
        ]),
      ),
    );
  }

  void _openProfileEdit(BuildContext ctx, UserModel u) =>
      showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => _ProfileEditSheet(user: u));

  void _openAddressManager(BuildContext ctx) {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddressManagerSheet(
        user: user,
        onUpdated: (a) => context.read<UserProvider>().updateAddresses(a),
      ),
    );
  }

  void _openLogout(BuildContext ctx, UserProvider up) {
    if (up.user == null) {
      Navigator.of(ctx).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      return;
    }
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('로그아웃', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('로그아웃 하시겠습니까?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              up.logout();
              if (ctx.mounted) {
                ctx.read<SizeProfileProvider>().clear();
                ctx.read<CartProvider>().clearCart();
                ctx.read<CouponProvider>().clear();
                Navigator.of(ctx).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            child: const Text('로그아웃', style: TextStyle(color: Color(0xFF1C62B9), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openChangePassword(BuildContext ctx) {
    final cur = TextEditingController(), nw = TextEditingController(), nw2 = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _pwField(cur, '현재 비밀번호'),
          const SizedBox(height: 10),
          _pwField(nw, '새 비밀번호'),
          const SizedBox(height: 10),
          _pwField(nw2, '새 비밀번호 확인'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              if (nw.text != nw2.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')));
                return;
              }
              final user = context.read<UserProvider>().user;
              final ok = await AuthService.updateProfile(
                email: user?.email ?? '',
                currentPassword: cur.text,
                newPassword: nw.text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ok ? '비밀번호가 변경되었습니다.' : '현재 비밀번호가 올바르지 않습니다.'),
                ));
              }
            },
            child: const Text('변경', style: TextStyle(color: Color(0xFF1C62B9), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  TextField _pwField(TextEditingController c, String label) => TextField(
      controller: c, obscureText: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true));

  void _openDeleteAccount(BuildContext ctx, UserProvider up) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('회원 탈퇴', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
        content: const Text('탈퇴 시 모든 데이터가 삭제됩니다.\n정말 탈퇴하시겠습니까?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final user = up.user;
              if (user == null) return;
              await AuthService.deleteUserDocument(user.id);
              await AuthService.logout();
              up.logout();
              if (ctx.mounted) {
                ctx.read<CartProvider>().clearCart();
                ctx.read<CouponProvider>().clear();
                ctx.read<SizeProfileProvider>().clear();
                Navigator.pop(ctx);
                Navigator.of(ctx).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            child: const Text('탈퇴', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel(BuildContext ctx, OrderModel order) async {
    const mime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    final date = '${order.createdAt.year}${order.createdAt.month.toString().padLeft(2,'0')}${order.createdAt.day.toString().padLeft(2,'0')}';
    final team = (order.customOptions?['teamName'] as String? ?? order.groupName ?? '').replaceAll(' ', '_');
    final name = '2FIT_${team.isNotEmpty ? '${team}_' : ''}${order.id}_$date.xlsx';
    showDialog(context: ctx, barrierDismissible: false,
        builder: (_) => const Center(child: Card(child: Padding(padding: EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Color(0xFF1C62B9)), SizedBox(height: 16),
              Text('엑셀 생성 중...'),
            ])))));
    try {
      final bytes = await OrderExcelService.generateSelectedOrdersExcel([order], DateTime.now());
      if (!ctx.mounted) return;
      Navigator.pop(ctx);
      if (kIsWeb) {
        downloadFileWeb(bytes, name, mime);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: '주문서 엑셀');
      }
    } catch (e) {
      if (ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('오류: $e'))); }
    }
  }

  // 검색 바텀시트
  void _openSearch(BuildContext ctx) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (bsCtx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: ctrl, autofocus: true,
                decoration: InputDecoration(
                  hintText: '상품명, 카테고리 검색',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1A1A1A)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => ctrl.clear(),
                  ),
                  filled: true, fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (q) {
                  Navigator.pop(bsCtx);
                  if (q.trim().isNotEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('"${q.trim()}" 검색 결과를 표시합니다.')));
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('최근 검색어', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))),
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                '2FIT 티셔츠', '라운드넥', '단체주문', '조거팬츠', '크롭탑',
              ].map((tag) => GestureDetector(
                onTap: () { ctrl.text = tag; },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD0DEFF)),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 13, color: Color(0xFF1C62B9))),
                ),
              )).toList()),
            ),
          ]),
        ),
      ),
    );
  }

  // 설정 바텀시트
  void _openSettings(BuildContext ctx, UserProvider up) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bsCtx) {
        final user = up.user;
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('설정', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF1C62B9)),
              title: const Text('프로필 수정'),
              onTap: () { Navigator.pop(bsCtx); if (user != null) _openProfileEdit(ctx, user); },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined, color: Color(0xFF1C62B9)),
              title: const Text('배송지 관리'),
              onTap: () { Navigator.pop(bsCtx); _openAddressManager(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1C62B9)),
              title: const Text('비밀번호 변경'),
              onTap: () { Navigator.pop(bsCtx); _openChangePassword(ctx); },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.orange),
              title: const Text('로그아웃', style: TextStyle(color: Colors.orange)),
              onTap: () { Navigator.pop(bsCtx); _openLogout(ctx, up); },
            ),
          ]),
        );
      },
    );
  }

  // ── 로그인 전 화면 ─────────────────────
  Widget _buildNotLoggedIn() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.person_outline_rounded, size: 64, color: Color(0xFFCCCCCC)),
    const SizedBox(height: 16),
    const Text('로그인이 필요합니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('로그인하고 다양한 혜택을 받아보세요', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
    const SizedBox(height: 24),
    SizedBox(width: 200, height: 44,
      child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1C62B9), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
        child: const Text('로그인', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    ),
  ]));

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();
    final user = up.user;
    if (user == null) return wrapWithPopScope(context, Scaffold(appBar: _buildAppBar(null), body: _buildNotLoggedIn()));
    return isPcWeb(context) ? _buildPc(context, user, up) : _buildMobile(context, user, up);
  }

  AppBar _buildAppBar(UserModel? user) => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: widget.onBack != null
        ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87), onPressed: widget.onBack)
        : null,
    title: const Text('마이페이지', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 17)),
    bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: Colors.grey[200])),
    actions: [
      if (user?.isAdmin == true)
        IconButton(icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.black54),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen()))),
    ],
  );

  // ════════════════════════════════════════
  // 모바일 레이아웃
  // ════════════════════════════════════════
  Widget _buildMobile(BuildContext context, UserModel user, UserProvider up) {
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildMobileAppBar(user, up),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerScrolled) => [
          // 프로필 + 통계칩
          SliverToBoxAdapter(child: _MobileHeader(
            user: user, up: up,
            onProfileEdit: () => _openProfileEdit(context, user),
            onLogout: () => _openLogout(context, up),
            onOrderTap: () => _openOrderList(context),
            onWishlistTap: () => _openWishlist(context, user),
            onCouponTap: () => _openCouponSheet(context),
            onStatusTap: (st) => _openOrderListFiltered(context, st),
          )),
          // 탭바 핀고정
          SliverPersistentHeader(
            pinned: true,
            delegate: _OhouseTabDelegate(
              TabBar(
                controller: _tabCtrl,
                tabs: const [Tab(text: '쇼핑'), Tab(text: '활동')],
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                indicatorColor: Colors.black87,
                indicatorWeight: 2,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _ShoppingTab(
              user: user, up: up,
              onAdditional: _openAdditionalOrder,
              onColorEdit: _openColorEdit,
              onDesignRevision: _openDesignRevision,
              onExcelDownload: _exportExcel,
              onAddressManager: () => _openAddressManager(context),
              onChangePassword: () => _openChangePassword(context),
              onLogout: () => _openLogout(context, up),
              onDeleteAccount: () => _openDeleteAccount(context, up),
            ),
            _ActivityTab(user: user),
          ],
        ),
      ),
    ));
  }

  AppBar _buildMobileAppBar(UserModel user, UserProvider up) => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: widget.onBack != null
        ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87), onPressed: widget.onBack)
        : null,
    title: Row(children: [
      GestureDetector(
        onTap: () => _tabCtrl.animateTo(1),
        child: const Text('프로필', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w400)),
      ),
      const SizedBox(width: 12),
      Row(children: [
        const Text('쇼핑', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w800)),
        const SizedBox(width: 2),
        Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle)),
      ]),
    ]),
    bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: Colors.grey[200])),
    actions: [
      if (user.isAdmin)
        IconButton(icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.black54, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen()))),
      IconButton(icon: const Icon(Icons.search, color: Colors.black87, size: 22),
          onPressed: () => _openSearch(context)),
      IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.black87, size: 22),
          onPressed: () => _openSettings(context, up)),
      Stack(children: [
        IconButton(icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))),
        Builder(builder: (ctx) {
          final count = ctx.watch<CartProvider>().items.length;
          if (count == 0) return const SizedBox.shrink();
          return Positioned(top: 6, right: 6,
            child: Container(width: 14, height: 14,
              decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
              child: Center(child: Text('$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))));
        }),
      ]),
    ],
  );

  // ════════════════════════════════════════
  // PC 레이아웃
  // ════════════════════════════════════════
  Widget _buildPc(BuildContext context, UserModel user, UserProvider up) {
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(children: [
        // 좌측 프로필 패널 (260px)
        Container(
          width: 260, color: Colors.white,
          child: _PcSidebar(
            user: user, up: up,
            onProfileEdit: () => _openProfileEdit(context, user),
            onAddressManager: () => _openAddressManager(context),
            onChangePassword: () => _openChangePassword(context),
            onLogout: () => _openLogout(context, up),
            onDeleteAccount: () => _openDeleteAccount(context, up),
          ),
        ),
        Container(width: 1, color: Colors.grey[200]),
        // 우측 콘텐츠
        Expanded(child: _ShoppingTab(
          user: user, up: up,
          onAdditional: _openAdditionalOrder,
          onColorEdit: _openColorEdit,
          onDesignRevision: _openDesignRevision,
          onExcelDownload: _exportExcel,
          onAddressManager: () => _openAddressManager(context),
          onChangePassword: () => _openChangePassword(context),
          onLogout: () => _openLogout(context, up),
          onDeleteAccount: () => _openDeleteAccount(context, up),
        )),
      ]),
    ));
  }
}

// ════════════════════════════════════════════════════════════════
// 모바일 헤더 (프로필 + 주문 통계)
// ════════════════════════════════════════════════════════════════
class _MobileHeader extends StatelessWidget {
  final UserModel user;
  final UserProvider up;
  final VoidCallback onProfileEdit;
  final VoidCallback onLogout;
  final VoidCallback onOrderTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onCouponTap;
  final void Function(OrderStatus)? onStatusTap;
  const _MobileHeader({
    required this.user, required this.up,
    required this.onProfileEdit, required this.onLogout,
    required this.onOrderTap, required this.onWishlistTap, required this.onCouponTap,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;
    final statusCounts = <OrderStatus, int>{};
    for (final s in OrderStatus.values) statusCounts[s] = 0;
    for (final o in orders) statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;

    final coupons = context.watch<CouponProvider>().validCoupons.length;
    final wishlistCount = context.watch<UserProvider>().user?.wishlist.length ?? 0;

    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 프로필 행
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            _ProfileAvatar(user: user, radius: 28),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(user.email, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              if (user.points > 0) ...[ const SizedBox(height: 4),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3ED), borderRadius: BorderRadius.circular(4)),
                      child: Text('P ${user.points}', style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B35), fontWeight: FontWeight.w700))),
                ]),
              ],
            ])),
            GestureDetector(onTap: onProfileEdit,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFBDBDBD)), borderRadius: BorderRadius.circular(4)),
                child: const Text('프로필 수정', style: TextStyle(fontSize: 12, color: Colors.black54)))),
          ]),
        ),
        // 빠른 통계 바
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            _StatChip(label: '주문', value: orders.length, onTap: onOrderTap),
            const SizedBox(width: 8),
            _StatChip(label: '찜', value: wishlistCount, onTap: onWishlistTap),
            const SizedBox(width: 8),
            _StatChip(label: '쿠폰', value: coupons, onTap: onCouponTap),
          ]),
        ),
        // 진행중인 주문 스텝
        _OrderProgressBar(statusCounts: statusCounts, onStatusTap: onStatusTap),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label; final int value; final VoidCallback onTap;
  const _StatChip({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
        const SizedBox(width: 4),
        Text('$value', style: const TextStyle(fontSize: 12, color: Color(0xFF1C62B9), fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

// 주문 진행 스텝 바 (오늘의집 스타일)
class _OrderProgressBar extends StatelessWidget {
  final Map<OrderStatus, int> statusCounts;
  final void Function(OrderStatus)? onStatusTap;
  const _OrderProgressBar({required this.statusCounts, this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (OrderStatus.pending, '입금\n대기'),
      (OrderStatus.confirmed, '결제\n완료'),
      (OrderStatus.processing, '배송\n준비'),
      (OrderStatus.shipped, '배송중'),
      (OrderStatus.delivered, '배송\n완료'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 10),
          child: Text('진행중인 주문 (최근 3개월)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
        ),
        Row(children: steps.asMap().entries.map((e) {
          final st = e.value.$1;
          final label = e.value.$2;
          final count = statusCounts[st] ?? 0;
          final isActive = count > 0;
          return Expanded(child: GestureDetector(
            onTap: () => onStatusTap?.call(st),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFF0F4FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: [
                Text('$count',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                        color: isActive ? const Color(0xFF1C62B9) : const Color(0xFFBBBBBB))),
                const SizedBox(height: 4),
                Text(label, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10,
                        color: isActive ? const Color(0xFF1C62B9) : const Color(0xFF888888),
                        height: 1.3,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ),
          ));
        }).expand((w) sync* {
          yield w;
        }).toList()),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PC 사이드바
// ════════════════════════════════════════════════════════════════
class _PcSidebar extends StatelessWidget {
  final UserModel user; final UserProvider up;
  final VoidCallback onProfileEdit, onAddressManager, onChangePassword, onLogout, onDeleteAccount;
  const _PcSidebar({required this.user, required this.up,
      required this.onProfileEdit, required this.onAddressManager,
      required this.onChangePassword, required this.onLogout, required this.onDeleteAccount});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders.length;
    final wishlist = user.wishlist.length;
    final coupons = context.watch<CouponProvider>().validCoupons.length;
    return SingleChildScrollView(
      child: Column(children: [
        // 프로필
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 12),
            _ProfileAvatar(user: user, radius: 32),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(user.email, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
            const SizedBox(height: 10),
            if (user.points > 0)
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3ED), borderRadius: BorderRadius.circular(4)),
                  child: Text('P ${user.points}', style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B35), fontWeight: FontWeight.w700))),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 36,
              child: OutlinedButton(onPressed: onProfileEdit,
                style: OutlinedButton.styleFrom(side: BorderSide(color: const Color(0xFFBDBDBD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                child: const Text('프로필 수정', style: TextStyle(fontSize: 13, color: Colors.black54)))),
          ]),
        ),
        Divider(height: 1, color: Colors.grey[200]),
        // 통계
        Row(children: [
          _PcStatItem(label: '주문', value: orders),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _PcStatItem(label: '찜', value: wishlist),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _PcStatItem(label: '쿠폰', value: coupons),
        ]),
        Divider(height: 1, color: Colors.grey[200]),
        const SizedBox(height: 8),
        // 메뉴
        _SideItem(icon: Icons.location_on_outlined, label: '배송지 관리', onTap: onAddressManager),
        _SideItem(icon: Icons.lock_outline_rounded, label: '비밀번호 변경', onTap: onChangePassword),
        if (user.isAdmin)
          _SideItem(icon: Icons.admin_panel_settings_rounded, label: '관리자',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen()))),
        Divider(height: 1, color: Colors.grey[100]),
        _SideItem(icon: Icons.logout_rounded, label: '로그아웃', onTap: onLogout, color: Colors.orange),
        _SideItem(icon: Icons.delete_forever_outlined, label: '회원 탈퇴', onTap: onDeleteAccount, color: Colors.red),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _PcStatItem extends StatelessWidget {
  final String label; final int value;
  const _PcStatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
            color: value > 0 ? const Color(0xFF1C62B9) : Colors.black54)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
      ])),
  );
}

class _SideItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final Color? color;
  const _SideItem({required this.icon, required this.label, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 18, color: color ?? Colors.grey[600]),
    title: Text(label, style: TextStyle(fontSize: 13, color: color ?? Colors.black87)),
    onTap: onTap, dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  );
}

// ════════════════════════════════════════════════════════════════
// Tab Delegate
// ════════════════════════════════════════════════════════════════
class _OhouseTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _OhouseTabDelegate(this.tabBar);
  @override double get minExtent => 46;
  @override double get maxExtent => 46;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
    Container(color: Colors.white,
      child: Column(children: [tabBar, Divider(height: 1, color: Colors.grey[200])]));
  @override bool shouldRebuild(_OhouseTabDelegate old) => old.tabBar != tabBar;
}

// ════════════════════════════════════════════════════════════════
// 쇼핑 탭 (주문목록 + 메뉴 리스트)
// ════════════════════════════════════════════════════════════════
class _ShoppingTab extends StatelessWidget {
  final UserModel user; final UserProvider up;
  final void Function(OrderModel) onAdditional, onColorEdit, onDesignRevision;
  final Future<void> Function(BuildContext, OrderModel) onExcelDownload;
  final VoidCallback onAddressManager, onChangePassword, onLogout, onDeleteAccount;
  const _ShoppingTab({
    required this.user, required this.up,
    required this.onAdditional, required this.onColorEdit, required this.onDesignRevision,
    required this.onExcelDownload, required this.onAddressManager,
    required this.onChangePassword, required this.onLogout, required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;
    final statusCounts = <OrderStatus, int>{};
    for (final s in OrderStatus.values) statusCounts[s] = 0;
    for (final o in orders) statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;
    final deliveryCount = (statusCounts[OrderStatus.shipped] ?? 0) +
        (statusCounts[OrderStatus.processing] ?? 0) + (statusCounts[OrderStatus.confirmed] ?? 0);

    return ListView(
      physics: const ClampingScrollPhysics(),
      children: [
        // ── 주문/배송 조회 ──────────────────
        _OhouseMenuTile(
          label: '주문/배송 조회',
          badge: deliveryCount > 0 ? '$deliveryCount' : null,
          onTap: () => _showOrderList(context, orders, onAdditional, onColorEdit, onDesignRevision, onExcelDownload),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),

        // ── 최근 본 상품 ──────────────────
        _OhouseMenuTile(label: '최근 본 상품', onTap: () =>
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('최근 본 상품 기능은 준비 중입니다.')))),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),

        // ── 상품 스크랩북 (찜) ──────────────
        _OhouseMenuTile(
          label: '상품 스크랩북',
          badge: user.wishlist.isNotEmpty ? '${user.wishlist.length}' : null,
          onTap: () => _showWishlist(context, user),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),

        // ── 쿠폰함 ──────────────────
        Builder(builder: (ctx) {
          final coupons = ctx.watch<CouponProvider>().validCoupons;
          return _OhouseMenuTile(
            label: '쿠폰함',
            badge: coupons.isNotEmpty ? '${coupons.length}' : null,
            onTap: () => _showCoupons(context, coupons),
          );
        }),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),

        // ── 포인트 ──────────────────
        _OhouseMenuTile(
          label: '포인트',
          badge: user.points > 0 ? '${user.points}P' : null,
          badgeColor: const Color(0xFFFF6B35),
          onTap: () => _showPointsSheet(context, user),
        ),
        Container(height: 8, color: const Color(0xFFF5F5F5)),

        // ── 설정 섹션 ──────────────────
        _OhouseMenuTile(label: '배송지 관리', onTap: onAddressManager),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
        _OhouseMenuTile(label: '비밀번호 변경', onTap: onChangePassword),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
        _OhouseMenuTile(label: '고객센터', onTap: () => _showCS(context)),
        Container(height: 8, color: const Color(0xFFF5F5F5)),

        // ── 계정 ──────────────────
        _OhouseMenuTile(label: '로그아웃', onTap: onLogout, textColor: Colors.orange),
        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
        _OhouseMenuTile(label: '회원 탈퇴', onTap: onDeleteAccount, textColor: Colors.red),
        const SizedBox(height: 40),
      ],
    );
  }

  void _showPointsSheet(BuildContext context, UserModel user) => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (bsCtx) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('포인트', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bsCtx)),
        ]),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFFF6B35), size: 28),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('보유 포인트', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
              const SizedBox(height: 2),
              Text('${user.points} P',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFF6B35))),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('• 포인트는 주문 시 할인에 사용할 수 있습니다.',
            style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
        const SizedBox(height: 6),
        const Text('• 포인트 사용 문의: 카카오톡 @2fitkorea',
            style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
        const SizedBox(height: 20),
      ]),
    ),
  );

  void _showCS(BuildContext context) => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (bsCtx) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('고객센터', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bsCtx)),
        ]),
        const SizedBox(height: 16),
        const Text('• 카카오톡: @2fitkorea'),
        const Text('• 전화: 010-7227-6914'),
        const Text('• 이메일: chw243527@gmail.com'),
        const SizedBox(height: 6),
        const Text('운영시간: 평일 09:00 ~ 18:00', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 20),
      ]),
    ),
  );

  void _showWishlist(BuildContext context, UserModel user) => showModalBottomSheet(
    context: context, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (bsCtx) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(children: [
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Text('찜 목록', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bsCtx)),
          ])),
        Expanded(child: _WishlistContent(user: user)),
      ]),
    ),
  );

  void _showCoupons(BuildContext context, List<CouponModel> coupons) => showModalBottomSheet(
    context: context, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (bsCtx) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(children: [
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('쿠폰 ${coupons.length}장', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bsCtx)),
          ])),
        if (coupons.isEmpty)
          const Expanded(child: Center(
            child: Text('사용 가능한 쿠폰이 없습니다.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ))
        else
          Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: coupons.length,
          itemBuilder: (_, i) {
            final c = coupons[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200] ?? const Color(0xFFEEEEEE)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
              child: Row(children: [
                Container(width: 44, height: 44,
                    decoration: const BoxDecoration(color: Color(0xFFE8EEF8), shape: BoxShape.circle),
                    child: const Icon(Icons.local_offer_rounded, color: Color(0xFF1C62B9), size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(c.typeLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF1C62B9), fontWeight: FontWeight.w600)),
                  Text('~${c.expiresAt.year}.${c.expiresAt.month.toString().padLeft(2,'0')}.${c.expiresAt.day.toString().padLeft(2,'0')}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ])),
              ]),
            );
          },
        )),
      ]),
    ),
  );

  void _showOrderList(BuildContext context, List<OrderModel> orders,
      void Function(OrderModel) onAdd, void Function(OrderModel) onCol,
      void Function(OrderModel) onDes, Future<void> Function(BuildContext, OrderModel) onXls) {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('주문 내역이 없습니다.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => _OrderListScreen(
      orders: orders,
      onAdditional: onAdd, onColorEdit: onCol, onDesignRevision: onDes, onExcelDownload: onXls,
    )));
  }
}

// ════════════════════════════════════════════════════════════════
// 메뉴 타일 (오늘의집 스타일)
// ════════════════════════════════════════════════════════════════
class _OhouseMenuTile extends StatelessWidget {
  final String label; final String? badge; final Color? badgeColor;
  final Color? textColor; final VoidCallback onTap;
  const _OhouseMenuTile({required this.label, required this.onTap,
      this.badge, this.badgeColor, this.textColor});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 14, color: textColor ?? Colors.black87,
            fontWeight: textColor != null ? FontWeight.w600 : FontWeight.w400)),
        if (badge != null) ...[ const SizedBox(width: 6),
          Text(badge!, style: TextStyle(fontSize: 14, color: badgeColor ?? const Color(0xFF1C62B9),
              fontWeight: FontWeight.w700)),
        ],
        const Spacer(),
        Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// 활동 탭 (찜, 리뷰 등)
// ════════════════════════════════════════════════════════════════
class _ActivityTab extends StatelessWidget {
  final UserModel user;
  const _ActivityTab({required this.user});
  @override
  Widget build(BuildContext context) => ListView(children: [
    _OhouseMenuTile(
      label: '찜한 상품',
      badge: user.wishlist.isNotEmpty ? '${user.wishlist.length}' : null,
      onTap: () => _showWishlistSheet(context),
    ),
    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
    _OhouseMenuTile(label: '나의 리뷰', onTap: () =>
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰 기능은 준비 중입니다.')))),
    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
    _OhouseMenuTile(label: '나의 문의내역', onTap: () =>
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('문의내역은 카카오톡 @2fitkorea에서 확인하세요.')))),
    const SizedBox(height: 40),
  ]);

  void _showWishlistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bsCtx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Text('찜한 상품', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bsCtx)),
            ]),
          ),
          Expanded(child: _WishlistContent(user: user)),
        ]),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════
// 찜 목록 콘텐츠
// ════════════════════════════════════════════════════════════════
class _WishlistContent extends StatefulWidget {
  final UserModel user;
  const _WishlistContent({required this.user});
  @override
  State<_WishlistContent> createState() => _WishlistContentState();
}

class _WishlistContentState extends State<_WishlistContent> {
  List<ProductModel>? _products;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = widget.user.wishlist;
    if (ids.isEmpty) {
      if (mounted) setState(() => _products = []);
      return;
    }
    // 1) 동기 캐시
    final synced = ids.map(ProductService.getProductByIdSync).whereType<ProductModel>().toList();
    if (synced.isNotEmpty && mounted) setState(() => _products = synced);

    // 2) 누락분 비동기 보완
    final all = List<ProductModel>.from(synced);
    final cached = synced.map((p) => p.id).toSet();
    for (final id in ids.where((id) => !cached.contains(id))) {
      try {
        final p = await ProductService.getProductById(id);
        if (p != null) all.add(p);
      } catch (_) {}
    }
    if (mounted) setState(() => _products = all);
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    if (products == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1C62B9)));
    }
    if (products.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.favorite_border_rounded, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text('찜한 상품이 없습니다', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        final p = products[i];
        final imgUrl = p.images.firstWhere((u) => u.isNotEmpty, orElse: () => '');
        return GestureDetector(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: p))),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 상품 이미지
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: imgUrl.isNotEmpty
                    ? NetImage(imgUrl,
                        width: double.infinity, height: 140,
                        fit: BoxFit.cover,
                        backgroundColor: const Color(0xFFEEEEEE))
                    : Container(
                        height: 140, color: const Color(0xFFEEEEEE),
                        child: const Center(
                            child: Icon(Icons.checkroom_rounded, color: Colors.grey, size: 36))),
              ),
              // 상품 정보
              Expanded(child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name.isNotEmpty ? p.name : '상품',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.price.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}원',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                  ],
                ),
              )),
            ]),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 주문배송목록 화면
// ════════════════════════════════════════════════════════════════
class _OrderListScreen extends StatefulWidget {
  final List<OrderModel> orders;
  final void Function(OrderModel) onAdditional, onColorEdit, onDesignRevision;
  final Future<void> Function(BuildContext, OrderModel) onExcelDownload;
  const _OrderListScreen({
    required this.orders,
    required this.onAdditional, required this.onColorEdit,
    required this.onDesignRevision, required this.onExcelDownload,
  });
  @override
  State<_OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<_OrderListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<OrderModel> get _filtered {
    if (_query.isEmpty) return widget.orders;
    final q = _query.toLowerCase();
    return widget.orders.where((o) {
      final names = o.items.map((i) => i.productName.toLowerCase()).join(' ');
      return names.contains(q)
          || o.id.toLowerCase().contains(q)
          || (o.groupName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('주문배송목록',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey[200]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ],
      ),
      body: Column(children: [
        // 검색바
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '상품명, 옵션명, 브랜드명으로 검색하세요',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF888888), size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                  : null,
              filled: true, fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
            ),
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
        // 주문 목록
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    _query.isEmpty ? '주문 내역이 없습니다' : '검색 결과가 없습니다',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _OrderCard(
                    order: filtered[i],
                    onDetail: () => _showDetail(context, filtered[i]),
                    onAdditional: widget.onAdditional,
                    onColorEdit: widget.onColorEdit,
                    onDesignRevision: widget.onDesignRevision,
                    onExcelDownload: widget.onExcelDownload,
                  ),
                ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 주문 카드
// ════════════════════════════════════════════════════════════════
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onDetail;
  final void Function(OrderModel) onAdditional, onColorEdit, onDesignRevision;
  final Future<void> Function(BuildContext, OrderModel) onExcelDownload;
  const _OrderCard({
    required this.order, required this.onDetail,
    required this.onAdditional, required this.onColorEdit,
    required this.onDesignRevision, required this.onExcelDownload,
  });

  String _fmt(double v) =>
      '${v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}원';
  String _fmtDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.pending:    return '입금 대기';
      case OrderStatus.confirmed:  return '결제 완료';
      case OrderStatus.processing: return '배송 준비';
      case OrderStatus.shipped:    return '배송중';
      case OrderStatus.delivered:  return '구매확정';
      case OrderStatus.cancelled:  return '주문 취소';
      case OrderStatus.refunded:   return '환불 완료';
    }
  }

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:    return Colors.orange;
      case OrderStatus.confirmed:  return const Color(0xFF1C62B9);
      case OrderStatus.processing: return const Color(0xFF7B1FA2);
      case OrderStatus.shipped:    return const Color(0xFF1C62B9);
      case OrderStatus.delivered:  return Colors.green;
      case OrderStatus.cancelled:  return Colors.grey;
      case OrderStatus.refunded:   return Colors.grey;
    }
  }

  String? get _eta {
    DateTime? d;
    if (order.status == OrderStatus.shipped) {
      d = order.createdAt.add(const Duration(days: 8));
    } else if (order.status == OrderStatus.confirmed ||
               order.status == OrderStatus.processing) {
      d = order.createdAt.add(const Duration(days: 10));
    }
    if (d == null) return null;
    if (d.difference(DateTime.now()).inDays < 0) return null;
    final wd = ['월','화','수','목','금','토','일'][d.weekday - 1];
    return '${d.month}/${d.day}($wd) 이내 도착';
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = order.orderType == 'group' || order.orderType == 'additional'
        || order.id.startsWith('GRP_') || order.id.startsWith('GROUP-');
    final isActive = order.status != OrderStatus.cancelled && order.status != OrderStatus.refunded;
    final canCancel = isActive && (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed);
    final canDesign    = isGroup && isActive && order.canDesignRevision;
    final canAdditional = isGroup && isActive && order.canOrderAdditionalFree;
    final canColor     = isGroup && isActive && order.canEditColor;
    final safeTotal    = order.totalAmount.isFinite && order.totalAmount > 0 ? order.totalAmount : 0.0;
    final eta = _eta;

    // 첫 번째 상품 — items가 비어있어도 표시하기 위해 fallback 정보 준비
    final hasItems = order.items.isNotEmpty;
    final firstItem = hasItems ? order.items.first : null;

    // 표시할 상품명
    final displayName = firstItem != null && firstItem.productName.isNotEmpty
        ? firstItem.productName
        : (order.groupName?.isNotEmpty == true ? order.groupName! : (isGroup ? '단체주문' : '주문 상품'));

    // 표시할 금액
    final displayAmt = firstItem != null && firstItem.price > 0
        ? firstItem.price * firstItem.quantity
        : (safeTotal > 0 ? safeTotal : order.totalAmount);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 날짜 + 주문상세 링크 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Text(_fmtDate(order.createdAt),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: onDetail,
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('주문상세', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFF888888)),
                ]),
              ),
            ]),
          ),
          Divider(height: 1, color: Colors.grey[100]),

          // ── 상태 + 예정일 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Text(_statusLabel,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _statusColor)),
              if (eta != null) ...[
                const Text('  ·  ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text(eta, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
              const Spacer(),
              if (order.status == OrderStatus.shipped)
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('배송조회는 카카오톡 @2fitkorea로 문의해 주세요.'))),
                  child: const Text('배송조회 >',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1C62B9), fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── 상품 이미지 + 정보 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: firstItem != null
                    ? _OrderItemImage(item: firstItem, size: 80)
                    : Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          isGroup ? Icons.groups_rounded : Icons.shopping_bag_outlined,
                          color: const Color(0xFFAAAAAA), size: 36,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // 텍스트 정보
              Expanded(child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  // 옵션
                  if (firstItem != null) ...[
                    if (firstItem.color.isNotEmpty || (firstItem.size.isNotEmpty && firstItem.size != '단체'))
                      Text(
                        [
                          if (firstItem.color.isNotEmpty) firstItem.color,
                          if (firstItem.size.isNotEmpty && firstItem.size != '단체') firstItem.size,
                        ].join(' / '),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                      ),
                    const SizedBox(height: 2),
                  ],
                  // 금액 + 수량
                  Row(children: [
                    Text(_fmt(displayAmt),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text('· ${firstItem?.quantity ?? 1}개',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  ]),
                  if (order.items.length > 1) ...[
                    const SizedBox(height: 2),
                    Text('외 ${order.items.length - 1}개 상품',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                  ],
                  if (order.groupCount != null && firstItem == null) ...[
                    const SizedBox(height: 4),
                    Text('총 ${order.groupCount}벌',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  ],
                ],
              )),
            ]),
          ),

          // ── 액션 버튼 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _buildButtons(context, isGroup, isActive, canCancel, canDesign, canAdditional, canColor),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, bool isGroup, bool isActive,
      bool canCancel, bool canDesign, bool canAdditional, bool canColor) {
    final List<Widget> buttons = [];

    void addBtn(String label, VoidCallback onTap, {bool primary = false}) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 6));
      buttons.add(Expanded(
        child: primary
            ? ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              )
            : OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFFBDBDBD)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
      ));
    }

    if (order.status == OrderStatus.delivered) {
      addBtn('리뷰쓰기', () => _showReviewSheet(context, order), primary: true);
      addBtn('문의', () => _contact(context, '문의'));
      addBtn('재구매', () => _repurchase(context, order));
    } else if (order.status == OrderStatus.shipped) {
      addBtn('문의', () => _contact(context, '배송 문의'));
      addBtn('반품·교환', () => _contact(context, '반품·교환 신청'));
      addBtn('구매확정', () => _confirmPurchase(context), primary: true);
    } else if (canCancel) {
      addBtn('주문상세', onDetail);
      addBtn('주문취소', () => _doCancel(context, isGroup));
    } else {
      addBtn('주문상세', onDetail);
      if (canDesign)    addBtn('디자인수정', () => onDesignRevision(order));
      if (canAdditional) addBtn('추가제작', () => onAdditional(order));
      if (canColor)     addBtn('색상변경', () => onColorEdit(order));
    }

    if (buttons.isEmpty) addBtn('주문상세', onDetail);

    return Row(children: buttons);
  }

  void _contact(BuildContext context, String title) => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('주문번호: ${order.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1C62B9).withValues(alpha: 0.2)),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('고객센터', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1C62B9))),
            SizedBox(height: 6),
            Text('• 카카오톡: @2fitkorea'),
            Text('• 전화: 010-7227-6914'),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    ),
  );

  Future<void> _doCancel(BuildContext context, bool isGroup) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('주문 취소', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(isGroup
            ? '단체주문을 취소하시겠습니까?\n제작 시작 전에만 취소 가능합니다.'
            : '주문을 취소하시겠습니까?\n결제 취소는 1~3 영업일 내 처리됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('아니오', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('취소하기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await OrderService.updateOrderStatus(order.id, OrderStatus.cancelled);
      NotificationService.sendCancelled(order: order, reason: '고객 직접 취소').catchError((_) {});
      FcmService.sendOrderStatusNotification(order: order, newStatus: OrderStatus.cancelled).catchError((_) {});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주문이 취소되었습니다.')));
    }
  }

  Future<void> _confirmPurchase(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('구매확정', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('구매를 확정하시겠습니까?\n확정 후에는 취소/반품이 불가합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('확정', style: TextStyle(color: Color(0xFF1C62B9), fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await OrderService.updateOrderStatus(order.id, OrderStatus.delivered);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구매가 확정되었습니다.')));
    }
  }
}

// ════════════════════════════════════════════════════════════════
// 주문 상품 이미지 (3단계 로딩)
// ════════════════════════════════════════════════════════════════
class _OrderItemImage extends StatefulWidget {
  final OrderItem item;
  final double size;
  const _OrderItemImage({required this.item, required this.size});
  @override
  State<_OrderItemImage> createState() => _OrderItemImageState();
}

class _OrderItemImageState extends State<_OrderItemImage> {
  String? _url;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  void _resolve() {
    if (!mounted) return;
    // 1) item에 직접 URL
    final direct = widget.item.imageUrl;
    if (direct != null && direct.isNotEmpty) {
      setState(() => _url = direct);
      return;
    }
    // 2) productId 없으면 중단
    if (widget.item.productId.isEmpty) return;
    // 3) 동기 캐시
    final cached = ProductService.getProductByIdSync(widget.item.productId);
    if (cached != null) {
      final img = cached.images.firstWhere((u) => u.isNotEmpty, orElse: () => '');
      if (img.isNotEmpty) { setState(() => _url = img); return; }
    }
    // 4) 비동기 조회
    ProductService.getProductById(widget.item.productId).then((p) {
      if (!mounted) return;
      final img = p?.images.firstWhere((u) => u.isNotEmpty, orElse: () => '') ?? '';
      if (img.isNotEmpty) setState(() => _url = img);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    if (_url != null && _url!.isNotEmpty) {
      return NetImage(_url!, width: s, height: s, fit: BoxFit.cover,
          backgroundColor: const Color(0xFFEEEEEE));
    }
    return Container(
      width: s, height: s,
      color: const Color(0xFFEEEEEE),
      child: const Icon(Icons.checkroom_rounded, color: Colors.grey, size: 28),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 주문 상세 화면
// ════════════════════════════════════════════════════════════════
void _showDetail(BuildContext context, OrderModel order) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => _OrderDetailScreen(order: order),
  ));
}

class _OrderDetailScreen extends StatelessWidget {
  final OrderModel order;
  const _OrderDetailScreen({required this.order});

  String _fmt(double v) =>
      '${v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}원';
  String _fmtDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')}';

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.pending:    return '입금 대기';
      case OrderStatus.confirmed:  return '결제 완료';
      case OrderStatus.processing: return '배송 준비';
      case OrderStatus.shipped:    return '배송중';
      case OrderStatus.delivered:  return '구매확정';
      case OrderStatus.cancelled:  return '주문 취소';
      case OrderStatus.refunded:   return '환불 완료';
    }
  }

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:    return Colors.orange;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
      case OrderStatus.shipped:    return const Color(0xFF1C62B9);
      case OrderStatus.delivered:  return Colors.green;
      default:                     return Colors.grey;
    }
  }

  String? get _eta {
    DateTime? d;
    if (order.status == OrderStatus.shipped) {
      d = order.createdAt.add(const Duration(days: 8));
    } else if (order.status == OrderStatus.confirmed ||
               order.status == OrderStatus.processing) {
      d = order.createdAt.add(const Duration(days: 10));
    }
    if (d == null) return null;
    if (d.difference(DateTime.now()).inDays < 0) return null;
    final wd = ['월','화','수','목','금','토','일'][d.weekday - 1];
    return '${d.month}/${d.day}($wd) 이내 도착';
  }

  @override
  Widget build(BuildContext context) {
    final opts       = order.customOptions ?? {};
    final isGroup    = order.orderType == 'group' || order.orderType == 'additional'
        || order.id.startsWith('GRP_') || order.id.startsWith('GROUP-');
    final canCancel  = order.status == OrderStatus.pending || order.status == OrderStatus.confirmed;
    final safeTotal  = order.totalAmount.isFinite && order.totalAmount > 0 ? order.totalAmount : 0.0;
    final productAmt = safeTotal - order.shippingFee;
    final discountAmt = (opts['discountAmount'] as num?)?.toDouble() ?? 0.0;
    final eta = _eta;
    final dt = order.createdAt;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('주문상세',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey[200]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 주문번호 서브헤더
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              '${_fmtDate(dt)} 주문 (주문번호 ${order.id})',
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ),
          const SizedBox(height: 8),

          // ── 배송지정보 ──
          _detailSection('배송지정보', Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('받는 사람', order.userName),
              if (order.userPhone.isNotEmpty) _row('연락처', order.userPhone),
              if (order.userAddress.isNotEmpty) _row('주소', order.userAddress),
              if ((order.memo ?? '').isNotEmpty) _row('배송메모', order.memo!),
            ],
          )),
          const SizedBox(height: 8),

          // ── 주문상품 ──
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('주문상품', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              // 배송상태 + 예정일
              Row(children: [
                Text(_statusLabel,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _statusColor)),
                if (eta != null) ...[
                  const Text('  ·  ', style: TextStyle(color: Colors.grey)),
                  Text(eta, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
                if (order.status == OrderStatus.shipped) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('배송조회는 카카오톡 @2fitkorea로 문의해 주세요.'))),
                    child: const Text('배송조회 >',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1C62B9), fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              const SizedBox(height: 14),
              // 상품 목록
              ..._buildItems(context, isGroup, safeTotal),
              const SizedBox(height: 14),
              // 액션 버튼
              _buildDetailButtons(context, canCancel),
              const SizedBox(height: 10),
              // 배송비
              Text('배송비  ${order.shippingFee == 0 ? "착불 (업체직접배송)" : _fmt(order.shippingFee)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            ]),
          ),
          const SizedBox(height: 8),

          // ── 결제정보 ──
          _detailSection('결제정보', Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _amtRow('상품금액', _fmt(productAmt > 0 ? productAmt : safeTotal)),
              _amtRow('배송비', order.shippingFee == 0 ? '0원' : _fmt(order.shippingFee)),
              if (discountAmt > 0)
                _amtRow('할인금액', '-${_fmt(discountAmt)}', valueColor: Colors.red),
              Divider(height: 20, color: Colors.grey[200]),
              _amtRow('주문금액', _fmt(safeTotal), bold: true, fontSize: 15),
              const SizedBox(height: 6),
              _amtRow(
                order.paymentMethod.isNotEmpty ? order.paymentMethod : '결제수단',
                _fmt(safeTotal),
                valueColor: Colors.black54,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('영수증 발급은 고객센터로 문의해 주세요.\n주문번호: ${order.id}'))),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('결제 영수증', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          )),
          const SizedBox(height: 8),

          // ── 주문자정보 ──
          _detailSection('주문자정보', Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('주문자', order.userName),
              if (order.userPhone.isNotEmpty) _row('연락처', order.userPhone),
              if ((opts['email'] ?? '').toString().isNotEmpty)
                _row('이메일', opts['email'].toString()),
            ],
          )),
          const SizedBox(height: 8),

          // ── 고객센터 버튼 ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('카카오톡: @2fitkorea  |  010-7227-6914'))),
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: const Text('2FIT 고객센터', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context, bool isGroup, double safeTotal) {
    if (order.items.isEmpty) {
      // fallback: items 없을 때
      final name = order.groupName?.isNotEmpty == true
          ? order.groupName!
          : (isGroup ? '단체주문' : '주문 상품');
      return [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(isGroup ? Icons.groups_rounded : Icons.shopping_bag_outlined,
              color: const Color(0xFFAAAAAA), size: 36),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            if (order.groupCount != null)
              Text('총 ${order.groupCount}벌',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            const SizedBox(height: 4),
            Text(_fmt(safeTotal > 0 ? safeTotal : order.totalAmount),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        )),
      ])];
    }

    return order.items.map((item) {
      final sz = (item.size == '단체' || item.size.isEmpty) ? '' : item.size;
      final opts = [if (sz.isNotEmpty) sz, if (item.color.isNotEmpty) item.color].join(' / ');
      final name = item.productName.isNotEmpty ? item.productName
          : (order.groupName?.isNotEmpty == true ? order.groupName! : (isGroup ? '단체주문 상품' : '주문 상품'));
      final price = item.price > 0 ? item.price * item.quantity : (safeTotal > 0 ? safeTotal : order.totalAmount);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _OrderItemImage(item: item, size: 80),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.35),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              if (opts.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(opts, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              ],
              const SizedBox(height: 4),
              Row(children: [
                Text(_fmt(price),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text('· ${item.quantity}개',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              ]),
            ],
          )),
        ]),
      );
    }).toList();
  }

  Widget _buildDetailButtons(BuildContext context, bool canCancel) {
    final List<Widget> btns = [];

    void add(String label, VoidCallback onTap, {bool primary = false}) {
      if (btns.isNotEmpty) btns.add(const SizedBox(width: 6));
      btns.add(Expanded(
        child: primary
            ? ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              )
            : OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFFBDBDBD)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
      ));
    }

    void snack(String msg) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));

    if (order.status == OrderStatus.delivered) {
      add('리뷰쓰기', () { Navigator.pop(context); _showReviewSheet(context, order); }, primary: true);
      add('문의', () => snack('카카오톡: @2fitkorea  |  010-7227-6914'));
      add('재구매', () { Navigator.pop(context); _repurchase(context, order); });
    } else if (order.status == OrderStatus.shipped) {
      add('문의', () => snack('카카오톡: @2fitkorea  |  010-7227-6914'));
      add('반품·교환', () => snack('반품·교환은 카카오톡 @2fitkorea로 접수해 주세요.'));
      add('구매확정', () => _confirmDetail(context), primary: true);
    } else if (canCancel) {
      add('주문취소', () => _cancelDetail(context));
    } else {
      add('문의', () => snack('카카오톡: @2fitkorea  |  010-7227-6914'));
    }

    if (btns.isEmpty) return const SizedBox.shrink();
    return Row(children: btns);
  }

  Future<void> _cancelDetail(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('주문 취소', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('주문을 취소하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('아니오', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('취소하기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await OrderService.updateOrderStatus(order.id, OrderStatus.cancelled);
      NotificationService.sendCancelled(order: order, reason: '고객 직접 취소').catchError((_) {});
      FcmService.sendOrderStatusNotification(order: order, newStatus: OrderStatus.cancelled).catchError((_) {});
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('주문이 취소되었습니다.')));
      }
    }
  }

  Future<void> _confirmDetail(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('구매확정', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('구매를 확정하시겠습니까?\n확정 후에는 취소/반품이 불가합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('확정', style: TextStyle(color: Color(0xFF1C62B9), fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await OrderService.updateOrderStatus(order.id, OrderStatus.delivered);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('구매가 확정되었습니다.')));
      }
    }
  }
}

// 섹션 박스
Widget _detailSection(String title, Widget child) => Container(
  color: Colors.white,
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    const SizedBox(height: 12),
    child,
  ]),
);

// 라벨-값 행
Widget _row(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 72,
        child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF888888)))),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
  ]),
);

// 금액 행
Widget _amtRow(String label, String value,
    {Color? valueColor, bool bold = false, double fontSize = 13}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: fontSize, color: const Color(0xFF555555))),
        Text(value, style: TextStyle(
          fontSize: fontSize,
          color: valueColor ?? Colors.black87,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
        )),
      ]),
    );

class _ProfileEditSheet extends StatefulWidget {
  final UserModel user;
  const _ProfileEditSheet({required this.user});

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(loc.mypageEditProfile, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 20),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: '연락처', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final userProvider = context.read<UserProvider>();
                  await userProvider.updateUserProfile(name: _nameCtrl.text, phone: _phoneCtrl.text);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(loc.save, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════════
// 추가제작 바텀시트 (단체커스텀 전용)
// ════════════════════════════════════════════════
class _AdditionalOrderSheet extends StatefulWidget {
  final OrderModel order;
  const _AdditionalOrderSheet({required this.order});

  @override
  State<_AdditionalOrderSheet> createState() => _AdditionalOrderSheetState();
}

class _AdditionalOrderSheetState extends State<_AdditionalOrderSheet> {
  AppLocalizations get _loc => context.watch<LanguageProvider>().loc;

  // 색상 선택
  String? _selectedColor;
  // ignore: unused_field
  Color? _selectedColorValue;

  // 사이즈 입력
  final _sizeCtrl = TextEditingController();

  // 수량 입력
  int _quantity = 1;

  final List<Map<String, dynamic>> _twoFitColors = AppConstants.twoFitColors;

  @override
  void dispose() {
    _sizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // 헤더
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF795548).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF795548), size: 22),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_loc.additionalProduction, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                Text(_loc.groupCustomOnly, style: const TextStyle(fontSize: 11, color: Color(0xFF795548))),
              ]),
            ]),
            const SizedBox(height: 14),

            // 주문 정보
            _infoBox([
              _infoRow(loc.mypageOrderNumber, widget.order.id),
              _infoRow(loc.mypageOrderDate, '${widget.order.createdAt.year}.${widget.order.createdAt.month.toString().padLeft(2,'0')}.${widget.order.createdAt.day.toString().padLeft(2,'0')}'),
              _infoRow(loc.mypageOriginalQty, '${widget.order.groupCount ?? widget.order.items.fold<int>(0, (s, i) => s + i.quantity)}장'),
            ]),
            const SizedBox(height: 14),

            // ── 색상 선택 ──
            Text(_loc.colorSelect, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _twoFitColors.length,
                itemBuilder: (_, i) {
                  final c = _twoFitColors[i];
                  final cName = c['name'] as String;
                  final cHex = c['hex'] as int;
                  final cVal = Color(cHex);
                  final isSel = _selectedColor == cName;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedColor = cName;
                      _selectedColorValue = cVal;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cVal,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? const Color(0xFF6A1B9A) : const Color(0xFFDDDDDD),
                          width: isSel ? 2.5 : 1,
                        ),
                        boxShadow: isSel ? [BoxShadow(color: const Color(0xFF6A1B9A).withValues(alpha: 0.3), blurRadius: 6)] : [],
                      ),
                      child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  );
                },
              ),
            ),
            if (_selectedColor != null) ...[
              const SizedBox(height: 6),
              Text(loc.mypageSelectedColor(_selectedColor!),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6A1B9A), fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 14),

            // ── 사이즈 입력 ──
            Text(_loc.sizeInput, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _sizeCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: loc.mypageAdditionalSizeHint,
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF795548), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── 수량 ──
            Row(
              children: [
                Text(_loc.additionalQty, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _quantity > 1 ? const Color(0xFF795548).withValues(alpha: 0.1) : const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.remove, size: 16, color: _quantity > 1 ? const Color(0xFF795548) : const Color(0xFFCCCCCC)),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _quantity++),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF795548).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 16, color: Color(0xFF795548)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 안내
            _noticeBox(
              color: const Color(0xFF795548),
              title: loc.mypageAdditionalGuide,
              items: [
                loc.mypageAdditionalNote1,
                loc.mypageAdditionalNote2,
                loc.mypageAdditionalNote3,
                loc.additionalShipNote,
              ],
            ),
            const SizedBox(height: 16),

            // 버튼
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_loc.cancel, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => GroupOrderFormScreen(
                        product: null,
                        isAdditionalOrder: true,
                        originalOrder: widget.order,
                        initialCount: 5,
                      ),
                    ));
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: Text(_loc.writeAdditionalOrder, style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF795548),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(List<Widget> rows) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Column(children: rows),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF888888)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _noticeBox({required Color color, required String title, required List<String> items}) =>
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 6),
          ...items.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(t, style: const TextStyle(fontSize: 12, height: 1.4)),
          )),
        ],
      ),
    );
}

// ════════════════════════════════════════════════
// 컬러·단체명 수정요청 바텀시트
// ════════════════════════════════════════════════
class _ColorEditSheet extends StatefulWidget {
  final OrderModel order;
  const _ColorEditSheet({required this.order});

  @override
  State<_ColorEditSheet> createState() => _ColorEditSheetState();
}

class _ColorEditSheetState extends State<_ColorEditSheet> {
  AppLocalizations get _loc => context.watch<LanguageProvider>().loc;

  final _teamNameCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  bool _submitted = false;

  // 선택된 컬러
  String? _selectedColorName;
  Color? _selectedColor;

  // 사이즈/컬러표 펼침 상태
  bool _showSizeChart = false;
  bool _showColorChart = false;

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_selectedColorName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loc.selectColor2)),
      );
      return;
    }
    if (widget.order.remainingColorEdits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정 가능 횟수를 모두 사용했습니다.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final success = await OrderService.submitColorNameChangeRequest(
        orderId: widget.order.id,
        newColorName: _selectedColorName,
        newTeamName: _teamNameCtrl.text.trim().isNotEmpty ? _teamNameCtrl.text.trim() : null,
        memo: _memoCtrl.text.trim().isNotEmpty ? _memoCtrl.text.trim() : null,
      );
      if (!mounted) return;
      if (success) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
        // 마이페이지 주문 목록 새로고침
        final user = context.read<UserProvider>().user;
        if (user != null) {
          context.read<OrderProvider>().loadUserOrders(user.id);
        }
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정 요청 저장에 실패했습니다. 다시 시도해주세요.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.order.remainingColorEdits;
    const blueColor = Color(0xFF1565C0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // 헤더 + 남은 횟수
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: blueColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.palette_outlined, color: blueColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_loc.colorNameModify, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  Text(_loc.mypageEditCount(remaining), style: TextStyle(
                    fontSize: 11,
                    color: remaining > 0 ? blueColor : Colors.red,
                    fontWeight: FontWeight.w700,
                  )),
                ]),
              ),
              // 횟수 원형 표시
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: remaining > 0 ? blueColor.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: remaining > 0 ? blueColor : Colors.red, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      color: remaining > 0 ? blueColor : Colors.red,
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            if (_submitted) ...[
              // 제출 완료 화면
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                  const SizedBox(height: 10),
                  Text(_loc.modifyAccepted, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  if (_selectedColor != null)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 16, height: 16,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFCCCCCC)),
                        ),
                      ),
                      Text(_loc.mypageSelectedColorLabel(_selectedColorName ?? ''),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  const SizedBox(height: 4),
                  Text(_loc.mypageRemainingEdits(remaining - 1), style: TextStyle(fontSize: 13, color: Colors.green.shade700)),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(_loc.confirm, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ] else ...[
              // 입력 폼
              // 주문 정보 요약
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(children: [
                  _infoRow(_loc.mypageOrderNumber, widget.order.id),
                  _infoRow(_loc.mypageCurrentGroupName, widget.order.groupName ?? '(없음)'),
                ]),
              ),
              const SizedBox(height: 14),

              // 유의사항
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  _loc.modifyWarning,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7A5000), height: 1.5),
                ),
              ),
              const SizedBox(height: 14),

              // 변경 컬러 선택 *
              Text(_loc.colorModify, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // 컬러 선택 버튼
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ColorPickerWidget(
                      selectedColorName: _selectedColorName,
                      selectedColor: _selectedColor,
                      onColorSelected: (name, color) {
                        setState(() {
                          _selectedColorName = name;
                          _selectedColor = color;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedColor != null
                        ? _selectedColor!.withValues(alpha: 0.06)
                        : blueColor.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedColor != null
                          ? blueColor.withValues(alpha: 0.6)
                          : const Color(0xFFCCCCCC),
                      width: _selectedColor != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_selectedColor != null) ...[
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedColorName ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.palette_outlined, size: 18, color: Color(0xFF888888)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_loc.selectColor2,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                        ),
                      ],
                      Icon(Icons.chevron_right_rounded,
                          size: 18,
                          color: _selectedColor != null ? blueColor : const Color(0xFFBBBBBB)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── 컬러표 토글 ──
              _toggleChartButton(
                label: '🎨 컬러 코드표 보기',
                expanded: _showColorChart,
                onTap: () => setState(() => _showColorChart = !_showColorChart),
                color: blueColor,
              ),
              if (_showColorChart) ...[
                const SizedBox(height: 8),
                _buildColorTable(),
              ],
              const SizedBox(height: 12),

              // ── 사이즈표 토글 ──
              _toggleChartButton(
                label: '📐 사이즈표 보기',
                expanded: _showSizeChart,
                onTap: () => setState(() => _showSizeChart = !_showSizeChart),
                color: const Color(0xFF1A1A1A),
              ),
              if (_showSizeChart) ...[
                const SizedBox(height: 8),
                _buildSizeTable(),
              ],
              const SizedBox(height: 12),

              // 변경 단체명 입력
              Text(_loc.groupNameModify, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _teamNameCtrl,
                decoration: InputDecoration(
                  hintText: _loc.mypageChangeIfNeeded,
                  prefixIcon: const Icon(Icons.groups_outlined, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: blueColor, width: 1.5)),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                ),
              ),
              const SizedBox(height: 12),

              // 기타 메모
              Text(_loc.additionalRequest, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _memoCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _loc.mypageOtherRequest,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: blueColor, width: 1.5)),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                ),
              ),
              const SizedBox(height: 16),

              // 버튼
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(_loc.cancel, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(_loc.modifyRequest, style: const TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF888888)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
    ]),
  );

  // ── 표 토글 버튼 ──
  Widget _toggleChartButton({
    required String label,
    required bool expanded,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            const Spacer(),
            Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 18, color: color),
          ],
        ),
      ),
    );
  }

  // ── 컬러 코드표 ──
  Widget _buildColorTable() {
    const colors = AppColorPalette.registeredColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(4)),
              child: const Text('2FIT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 6),
            Text(_loc.mypageColorCodeChart, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          // 5열 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.78,
            ),
            itemCount: colors.length,
            itemBuilder: (_, i) {
              final c = colors[i];
              final hexColor = Color(c['hex'] as int);
              final code = c['code'] as String;
              final isLight = hexColor.computeLuminance() > 0.6;
              final isSelected = _selectedColorName != null &&
                  (_selectedColorName!.contains(code));
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorName = c['name'] as String;
                    _selectedColor = hexColor;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: hexColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : (isLight ? const Color(0xFFCCCCCC) : Colors.transparent),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.4), blurRadius: 4)]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            size: 14,
                            color: isLight ? const Color(0xFF1565C0) : Colors.white),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                        ),
                        child: Text(
                          code,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(_loc.mypageColorNote,
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
        ],
      ),
    );
  }

  // ── 사이즈표 ──
  Widget _buildSizeTable() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(4)),
              child: const Text('2FIT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 6),
            Text(_loc.mypageSizeChartTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text(_loc.mypageStandardFit, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
          ]),
          const SizedBox(height: 10),
          // 성인
          _sizeLabel(_loc.adultSizeLabel, const Color(0xFF1565C0)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: const Color(0xFFDDDDDD), width: 0.8),
              children: [
                _sizeHeaderRow([_loc.sizeLabel, 'XS(85)', 'S(90)', 'M(95)', 'L(100)', 'XL(105)', '2XL(110)', '3XL(115)']),
                _sizeRow('${_loc.measureHeight}(cm)', ['154~159', '160~165', '166~172', '172~177', '177~182', '182~187', '187~191']),
                _sizeRow('${_loc.measureWeight}(kg)', ['44~51', '52~60', '61~71', '72~78', '79~85', '86~91', '91~96']),
                _sizeRow('${_loc.measureChest}(cm)', ['85', '90', '95', '100', '105', '110', '115']),
                _sizeRow('${_loc.measureWaist}(inch)', ['26~28', '28~30', '30~32', '32~34', '34~36', '36~38', '38~40']),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 주니어
          _sizeLabel(_loc.juniorSizeLabel, const Color(0xFF2E7D32)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: const Color(0xFFDDDDDD), width: 0.8),
              children: [
                _sizeHeaderRow([_loc.sizeLabel, 'J-S(60)', 'J-M(65)', 'J-L(70)', 'J-XL(75)', 'J-2XL(80)']),
                _sizeRow('${_loc.measureHeight}(cm)', ['112~117', '118~122', '123~133', '130~139', '140~153']),
                _sizeRow('${_loc.measureWeight}(kg)', ['19~21', '22~24', '25~28', '26~34', '35~43']),
                _sizeRow(_loc.mypageSizeAgeLabel, ['6~7', '7~8', '8~9', '10~11', '-']),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(_loc.mypageFitNote,
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
        ],
      ),
    );
  }

  Widget _sizeLabel(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
  );

  TableRow _sizeHeaderRow(List<String> labels) => TableRow(
    decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
    children: labels.map((l) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Text(l, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center),
    )).toList(),
  );

  TableRow _sizeRow(String label, List<String> values) => TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF444444)), textAlign: TextAlign.center),
      ),
      ...values.map((v) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Text(v, style: const TextStyle(fontSize: 9, color: Color(0xFF555555)), textAlign: TextAlign.center),
      )),
    ],
  );
}


// ═══════════════════════════════════════════════════════════
// 배송지 관리 바텀시트
// ═══════════════════════════════════════════════════════════
class _AddressManagerSheet extends StatefulWidget {
  final UserModel user;
  final void Function(List<AddressModel>) onUpdated;
  const _AddressManagerSheet({required this.user, required this.onUpdated});

  @override
  State<_AddressManagerSheet> createState() => _AddressManagerSheetState();
}

class _AddressManagerSheetState extends State<_AddressManagerSheet> {
  AppLocalizations get _loc => context.watch<LanguageProvider>().loc;

  late List<AddressModel> _addresses;

  @override
  void initState() {
    super.initState();
    _addresses = List<AddressModel>.from(widget.user.addresses);
  }

  void _setDefault(String id) {
    setState(() {
      for (final a in _addresses) {
        a.isDefault = a.id == id;
      }
    });
    widget.onUpdated(_addresses);
  }

  void _delete(String id) {
    setState(() => _addresses.removeWhere((a) => a.id == id));
    widget.onUpdated(_addresses);
  }

  void _addOrEdit([AddressModel? existing]) async {
    final result = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(existing: existing, userName: widget.user.name, userPhone: widget.user.phone),
    );
    if (result != null) {
      setState(() {
        if (existing != null) {
          final idx = _addresses.indexWhere((a) => a.id == existing.id);
          if (idx != -1) _addresses[idx] = result;
        } else {
          if (_addresses.isEmpty) result.isDefault = true;
          _addresses.add(result);
        }
      });
      widget.onUpdated(_addresses);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(_loc.mypageShippingManage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          // 배송지 목록
          Expanded(
            child: _addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off_rounded, size: 48, color: Color(0xFFCCCCCC)),
                        const SizedBox(height: 12),
                        Text(_loc.mypageNoAddress, style: const TextStyle(color: Color(0xFF999999))),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addOrEdit,
                          icon: const Icon(Icons.add),
                          label: Text(_loc.mypageAddAddress),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final a = _addresses[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        title: Row(
                          children: [
                            Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(width: 8),
                            if (a.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(_loc.mypageDefault, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${a.recipient} · ${a.phone}', style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('[${a.zipCode}] ${a.address1}', style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                              if (a.address2.isNotEmpty)
                                Text(a.address2, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'default') _setDefault(a.id);
                            if (v == 'edit') _addOrEdit(a);
                            if (v == 'delete') _delete(a.id);
                          },
                          itemBuilder: (_) => [
                            if (!a.isDefault)
                              PopupMenuItem(value: 'default', child: Text(_loc.mypageSetDefault)),
                            PopupMenuItem(value: 'edit', child: Text(_loc.mypageEdit)),
                            PopupMenuItem(value: 'delete', child: Text(_loc.mypageDelete, style: const TextStyle(color: Colors.red))),
                          ],
                          child: const Icon(Icons.more_vert_rounded, color: Color(0xFF888888)),
                        ),
                      );
                    },
                  ),
          ),
          // 추가 버튼
          if (_addresses.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addOrEdit,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: Text(_loc.mypageAddNewAddress, style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 배송지 추가/수정 폼
// ═══════════════════════════════════════════════════════════
class _AddressFormSheet extends StatefulWidget {
  final AddressModel? existing;
  final String userName;
  final String userPhone;
  const _AddressFormSheet({this.existing, required this.userName, required this.userPhone});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  AppLocalizations get _loc => context.watch<LanguageProvider>().loc;

  final _labelCtrl    = TextEditingController();
  final _recipientCtrl= TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _zipCtrl      = TextEditingController();
  final _addr1Ctrl    = TextEditingController();
  final _addr2Ctrl    = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl.text     = e?.label ?? _loc.addrLabelHome;
    _recipientCtrl.text = e?.recipient ?? widget.userName;
    _phoneCtrl.text     = e?.phone ?? widget.userPhone;
    _zipCtrl.text       = e?.zipCode ?? '';
    _addr1Ctrl.text     = e?.address1 ?? '';
    _addr2Ctrl.text     = e?.address2 ?? '';
    _isDefault          = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelCtrl.dispose(); _recipientCtrl.dispose(); _phoneCtrl.dispose();
    _zipCtrl.dispose(); _addr1Ctrl.dispose(); _addr2Ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_addr1Ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loc.mypageEnterAddress)));
      return;
    }
    if (_recipientCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loc.mypageEnterRecipient)));
      return;
    }
    final addr = AddressModel(
      id: widget.existing?.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
      label:     _labelCtrl.text.trim().isEmpty ? _loc.addrLabelHome : _labelCtrl.text.trim(),
      recipient: _recipientCtrl.text.trim(),
      phone:     _phoneCtrl.text.trim(),
      zipCode:   _zipCtrl.text.trim(),
      address1:  _addr1Ctrl.text.trim(),
      address2:  _addr2Ctrl.text.trim(),
      isDefault: _isDefault,
    );
    Navigator.pop(context, addr);
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: type,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(widget.existing == null ? _loc.mypageAddressAdd : _loc.mypageAddressEdit,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _field(_loc.mypageShippingLabelField, _labelCtrl, hint: _loc.mypageShippingLabelHint),
                    _field(_loc.recipientLabel, _recipientCtrl, hint: _loc.recipientHint),
                    _field(_loc.phoneLabel, _phoneCtrl, hint: '010-0000-0000', type: TextInputType.phone),
                    // ── 주소 검색 버튼 ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await showAddressSearch(context);
                            if (result != null) {
                              setState(() {
                                _zipCtrl.text   = result.zonecode;
                                _addr1Ctrl.text = result.address;
                              });
                            }
                          },
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: Text(_loc.mypageAddressSearch,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A1A1A),
                            side: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                    _field(_loc.zipLabel, _zipCtrl, hint: _loc.zipHint, type: TextInputType.number),
                    _field(_loc.addr1Label, _addr1Ctrl, hint: _loc.addr1Hint),
                    _field(_loc.addr2Label, _addr2Ctrl, hint: _loc.addr2Hint),
                    // 기본 배송지 체크
                    GestureDetector(
                      onTap: () => setState(() => _isDefault = !_isDefault),
                      child: Row(
                        children: [
                          Icon(_isDefault ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              color: _isDefault ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA), size: 22),
                          const SizedBox(width: 8),
                          Text(_loc.mypageSetDefaultAddress, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(widget.existing == null ? _loc.mypageAddressAdd : _loc.mypageAddressComplete,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
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
}

// ════════════════════════════════════════════════
// 디자인 수정 요청 바텀시트
// ════════════════════════════════════════════════
class _DesignRevisionSheet extends StatefulWidget {
  final OrderModel order;
  const _DesignRevisionSheet({required this.order});

  @override
  State<_DesignRevisionSheet> createState() => _DesignRevisionSheetState();
}

class _DesignRevisionSheetState extends State<_DesignRevisionSheet> {
  final _memoCtrl = TextEditingController();
  bool _submitted = false;
  bool _isSubmitting = false;
  String? _selectedColorName;
  // ignore: unused_field
  Color? _selectedColor;

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  // 인쇄타입에 따른 수정 가능 항목
  int get _printType => (widget.order.customOptions?['printType'] as num?)?.toInt() ?? 0;
  bool get _canChangeColor => _printType == 0 || _printType == 2 || _printType == 3 || _printType == 4;
  bool get _canChangeTeamName => _printType == 1 || _printType == 2 || _printType == 3 || _printType == 4;
  bool get _canChangeDesign => _printType == 3 || _printType == 4;

  // 3일 자동확정 안내
  String get _deadlineText {
    final deadline = widget.order.designRevisionDeadline;
    if (deadline == null) return '';
    final diff = deadline.difference(DateTime.now()).inDays;
    if (diff <= 0) return '오늘 자정 확정 예정';
    return '$diff일 후 자동 확정';
  }

  Future<void> _submit() async {
    if (_memoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정 요청 내용을 입력해주세요.')),
      );
      return;
    }
    if (!widget.order.canDesignRevision) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('디자인 수정 가능 횟수를 모두 사용했습니다.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final db = FirebaseFirestore.instance;
      final deadline = DateTime.now().add(const Duration(days: 3));
      await db.collection('orders').doc(widget.order.id).update({
        'designRevisionCount': FieldValue.increment(1),
        'designRevisionDeadline': deadline.toIso8601String(),
        'designRevisionRequest': {
          'memo': _memoCtrl.text.trim(),
          'colorName': _selectedColorName,
          'requestedAt': DateTime.now().toIso8601String(),
          'status': 'pending', // pending / confirmed / rejected
        },
      });
      // 관리자 알림 (FCM/이메일)
      try {
        await EmailService.sendAdminAlert(
          subject: '[2FIT] 디자인 수정 요청 - 주문 ${widget.order.id}',
          body: '주문번호: ${widget.order.id}\n'
              '고객: ${widget.order.userName}\n'
              '남은횟수: ${widget.order.remainingDesignRevisions - 1}회\n'
              '요청내용: ${_memoCtrl.text.trim()}\n'
              '응답기한: ${deadline.year}.${deadline.month}.${deadline.day} (3일 이내)',
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
      final user = context.read<UserProvider>().user;
      if (user != null) context.read<OrderProvider>().loadUserOrders(user.id);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.85;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Center(child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          )),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF7B1FA2), size: 22),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('디자인 수정 요청', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                Text('주문번호: ${widget.order.id}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${widget.order.remainingDesignRevisions}회 남음',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7B1FA2))),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: _submitted ? _buildSuccess() : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // 주문 정보 요약
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0FF)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('선택된 인쇄타입: ${_getPrintTypeLabel()}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, children: [
                      if (_canChangeColor) _chip('색상 변경 가능', const Color(0xFF1565C0)),
                      if (_canChangeTeamName) _chip('단체명 변경 가능', const Color(0xFF2E7D32)),
                      if (_canChangeDesign) _chip('디자인 변경 가능', const Color(0xFF7B1FA2)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
                // 3일 자동확정 안내
                if (widget.order.designRevisionDeadline != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCC02)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        '관리자 미응답 시 $_deadlineText 디자인이 자동 확정됩니다.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), height: 1.4),
                      )),
                    ]),
                  ),
                // 수정 요청 내용 입력
                const Text('수정 요청 내용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _memoCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '원하시는 수정 내용을 자세히 입력해주세요.\n예) 색상을 네이비로 변경, 단체명 "2FIT 팀"으로 변경',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF7B1FA2)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 색상 선택 (색상변경 가능한 경우)
                if (_canChangeColor) ...[
                  const Text('희망 색상 (선택)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      {'name': '블랙', 'hex': 0xFF1A1A1A}, {'name': '네이비', 'hex': 0xFF0D1B4F},
                      {'name': '화이트', 'hex': 0xFFF5F5F5}, {'name': '그레이', 'hex': 0xFF9E9E9E},
                      {'name': '스카이블루', 'hex': 0xFF90CAF9}, {'name': '블루', 'hex': 0xFF1A4DB3},
                      {'name': '레드', 'hex': 0xFFE53935}, {'name': '그린', 'hex': 0xFF2E7D32},
                    ].map((c) {
                      final isSelected = _selectedColorName == c['name'];
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedColorName = c['name'] as String;
                          _selectedColor = Color(c['hex'] as int);
                        }),
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: Color(c['hex'] as int),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF7B1FA2) : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedColorName != null) ...[
                    const SizedBox(height: 6),
                    Text('선택: $_selectedColorName',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7B1FA2), fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 16),
                ],
                // 안내 문구
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200] ?? const Color(0xFFEEEEEE)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF888888)),
                      SizedBox(width: 6),
                      Text('안내사항', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                    ]),
                    const SizedBox(height: 6),
                    _infoRow('디자인 수정은 총 2회까지 가능합니다.'),
                    _infoRow('요청 후 3일 이내 관리자 미응답 시 현재 디자인으로 자동 확정됩니다.'),
                    _infoRow('확정 후에는 변경이 불가합니다.'),
                  ]),
                ),
                const SizedBox(height: 24),
                // 제출 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('수정 요청 제출', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF7B1FA2)),
        const SizedBox(height: 16),
        const Text('수정 요청 완료!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('주문번호 ${widget.order.id}\n관리자가 확인 후 3일 이내 응답드립니다.\n미응답 시 현재 디자인으로 자동 확정됩니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B1FA2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('닫기', style: TextStyle(color: Colors.white)),
        ),
      ]),
    ),
  );

  String _getPrintTypeLabel() {
    const labels = ['색상 변경', '단체명 변경(전면)', '단체명+색상 변경', '디자인+단체명+색상', '전체 변경+이름(후면)'];
    return _printType < labels.length ? labels[_printType] : '알 수 없음';
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _infoRow(String text) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), height: 1.4))),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════
// 프로필 아바타 위젯 (이미지 있으면 NetImage, 없으면 이니셜)
// ════════════════════════════════════════════════════════════════
class _ProfileAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  const _ProfileAvatar({required this.user, required this.radius});

  @override
  Widget build(BuildContext context) {
    final hasImage = user.profileImageUrl.isNotEmpty;
    if (hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE8EEF8),
        child: ClipOval(
          child: NetImage(
            user.profileImageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    // 이니셜 아바타
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
    final fontSize = radius * 0.72;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8EEF8),
      child: Text(initial,
          style: TextStyle(
            color: const Color(0xFF1C62B9),
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          )),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 주문 아이템 이미지 위젯
// imageUrl 있으면 NetImage, 없으면 ProductService 캐시에서 조회
// ════════════════════════════════════════════════════════════════
void _showReviewSheet(BuildContext context, OrderModel order) {
  if (order.items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰를 작성할 상품이 없습니다.')));
    return;
  }
  final item = order.items.first;
  double rating = 5.0;
  final ctrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (bsCtx) => StatefulBuilder(builder: (ctx, setSt) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('리뷰 작성', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(bsCtx)),
            ]),
            const SizedBox(height: 4),
            Text(item.productName,
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            // 별점
            const Text('만족도', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: List.generate(5, (i) => GestureDetector(
              onTap: () => setSt(() => rating = (i + 1).toDouble()),
              child: Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFFFB300), size: 32),
            ))),
            const SizedBox(height: 14),
            // 내용
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '상품 사용 후기를 작성해 주세요.',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                filled: true, fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('리뷰 내용을 입력해 주세요.')));
                    return;
                  }
                  Navigator.pop(bsCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                        '리뷰가 등록되었습니다. (★${rating.toInt()} "${ctrl.text.trim().length > 20 ? ctrl.text.trim().substring(0, 20) + "..." : ctrl.text.trim()}")')));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C62B9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('리뷰 등록', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════════
// 재구매 — 첫 번째 상품의 상세 페이지로 이동
// ════════════════════════════════════════════════════════════════
void _repurchase(BuildContext context, OrderModel order) {
  if (order.items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 정보를 불러올 수 없습니다.')));
    return;
  }
  final item = order.items.first;
  // 동기 캐시 우선
  final cached = ProductService.getProductByIdSync(item.productId);
  if (cached != null) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: cached)));
    return;
  }
  // 비동기 로딩 중 스낵바
  ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('상품 정보를 불러오는 중...')));
  ProductService.getProductById(item.productId).then((p) {
    if (p != null && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: p)));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품 정보를 불러올 수 없습니다.')));
    }
  }).catchError((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품 정보를 불러올 수 없습니다.')));
    }
  });
}
