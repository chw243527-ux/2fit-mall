import 'dart:convert';
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
import '../admin/admin_screen.dart';
import '../auth/login_screen.dart';
import '../orders/group_order_form_screen.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/pc_layout.dart';
import '../../services/order_service.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_service.dart';
import '../../widgets/address_search_widget.dart';
import 'size_profile_screen.dart';
import '../../utils/navigation_helper.dart';

// ══════════════════════════════════════════════════════════════
// MyPageScreen — 네이버페이 스타일 완전 재작성
// ══════════════════════════════════════════════════════════════

class MyPageScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MyPageScreen({super.key, this.onBack});
  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int _tab = 0; // 0:내주문 1:찜목록 2:쿠폰함 3:설정

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null) context.read<OrderProvider>().loadUserOrders(user.id);
    });
  }

  // ── 시트/다이얼로그 열기 ─────────────────────
  void _openAdditionalOrder(OrderModel o) => showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _AdditionalOrderSheet(order: o));

  void _openColorEdit(OrderModel o) => showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _ColorEditSheet(order: o));

  void _openDesignRevision(OrderModel o) => showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _DesignRevisionSheet(order: o));

  void _openProfileEdit(BuildContext ctx, UserModel u) => showModalBottomSheet(
        context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
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
      Navigator.of(ctx).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      return;
    }
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: Colors.orange, size: 22),
          SizedBox(width: 8),
          Text('로그아웃', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              up.logout();
              if (ctx.mounted) {
                ctx.read<SizeProfileProvider>().clear();
                ctx.read<CartProvider>().clearCart();
                ctx.read<CouponProvider>().clear();
                Navigator.of(ctx).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            child: const Text('로그아웃'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: cur, obscureText: true, decoration: const InputDecoration(labelText: '현재 비밀번호')),
          const SizedBox(height: 8),
          TextField(controller: nw, obscureText: true, decoration: const InputDecoration(labelText: '새 비밀번호')),
          const SizedBox(height: 8),
          TextField(controller: nw2, obscureText: true, decoration: const InputDecoration(labelText: '새 비밀번호 확인')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E)),
            onPressed: () async {
              if (nw.text != nw2.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')));
                return;
              }
              try {
                await AuthService.changePassword(currentPassword: cur.text, newPassword: nw.text);
                if (ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('비밀번호가 변경되었습니다.'))); }
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('오류: $e')));
              }
            },
            child: const Text('변경', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openDeleteAccount(BuildContext ctx, UserProvider up) {
    final pw = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('회원 탈퇴', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('탈퇴 시 모든 데이터가 삭제됩니다.\n비밀번호를 입력하세요.', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: '비밀번호')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await AuthService.deleteAccount(password: pw.text);
                up.logout();
                if (ctx.mounted) Navigator.of(ctx).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('오류: $e')));
              }
            },
            child: const Text('탈퇴'),
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
              CircularProgressIndicator(color: Color(0xFF6A1B9A)), SizedBox(height: 16),
              Text('엑셀 생성 중...'),
            ])))));
    try {
      final bytes = await OrderExcelService.generateGroupOrderExcelAsync(order);
      if (ctx.mounted) Navigator.pop(ctx);
      if (kIsWeb) {
        downloadFileWeb(bytes, name, mime);
        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('엑셀 다운로드 완료'), backgroundColor: Color(0xFF6A1B9A)));
      } else {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/$name';
        await File(path).writeAsBytes(bytes, flush: true);
        if (ctx.mounted) await SharePlus.instance.share(ShareParams(
            files: [XFile(path, mimeType: mime, name: name)], subject: '2FIT 단체주문 내역', text: name));
      }
    } catch (e) {
      if (ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red)); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();
    final user = up.user;
    if (user == null) return _buildNotLoggedIn();
    return isPcWeb(context) ? _buildPc(context, user, up) : _buildMobile(context, user, up);
  }

  // ── 비로그인 화면 ──────────────────────────────
  Widget _buildNotLoggedIn() => Scaffold(
    backgroundColor: const Color(0xFFF4F4F4),
    appBar: AppBar(title: const Text('마이페이지'), backgroundColor: Colors.white, elevation: 0,
        foregroundColor: Colors.black87),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.person_outline, size: 64, color: Colors.grey),
      const SizedBox(height: 16),
      const Text('로그인이 필요합니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('로그인하기'),
      ),
    ])),
  );

  // ════════════════════════════════════════════════
  // PC 레이아웃
  // ════════════════════════════════════════════════
  Widget _buildPc(BuildContext context, UserModel user, UserProvider up) {
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Row(children: [
        // 좌측 프로필 패널
        Container(
          width: 280,
          color: Colors.white,
          child: Column(children: [
            _PcProfilePanel(user: user, up: up,
              onEdit: () => _openProfileEdit(context, user),
              onLogout: () => _openLogout(context, up),
              onAddressManager: () => _openAddressManager(context),
            ),
            const Divider(height: 1),
            ...[
              (0, Icons.receipt_long_outlined, '내 주문'),
              (1, Icons.favorite_border_rounded, '찜 목록'),
              (2, Icons.local_offer_outlined, '쿠폰함'),
              (3, Icons.settings_outlined, '설정'),
            ].map((t) => _PcNavItem(icon: t.$2, label: t.$3, selected: _tab == t.$1,
                onTap: () => setState(() => _tab = t.$1))),
          ]),
        ),
        // 우측 콘텐츠
        Expanded(child: _buildPcContent(context, user, up)),
      ]),
    ));
  }

  Widget _buildPcContent(BuildContext context, UserModel user, UserProvider up) {
    switch (_tab) {
      case 0: return _OrdersTab(user: user,
          onAdditional: _openAdditionalOrder, onColorEdit: _openColorEdit,
          onDesignRevision: _openDesignRevision, onExcelDownload: _exportExcel);
      case 1: return _WishlistTab(user: user);
      case 2: return _CouponTab(user: user);
      case 3: return _SettingsTab(user: user, up: up,
          onProfileEdit: () => _openProfileEdit(context, user),
          onAddressManager: () => _openAddressManager(context),
          onChangePassword: () => _openChangePassword(context),
          onDeleteAccount: () => _openDeleteAccount(context, up),
          onLogout: () => _openLogout(context, up));
      default: return const SizedBox();
    }
  }

  // ════════════════════════════════════════════════
  // 모바일 레이아웃
  // ════════════════════════════════════════════════
  Widget _buildMobile(BuildContext context, UserModel user, UserProvider up) {
    return wrapWithPopScope(context, Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: CustomScrollView(
        slivers: [
          // ── 앱바 + 프로필 헤더 ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            leading: widget.onBack != null
                ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: widget.onBack)
                : null,
            title: const Text('마이페이지', style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              if (user.isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen())),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openProfileEdit(context, user),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _MobileProfileHeader(user: user, up: up,
                onLogout: () => _openLogout(context, up)),
            ),
          ),

          // ── 퀵 통계 ──
          SliverToBoxAdapter(child: _QuickStats(user: user, onTabChange: (t) => setState(() => _tab = t))),

          // ── 탭 바 ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: _buildTabBar(),
            ),
          ),

          // ── 탭 콘텐츠 ──
          SliverFillRemaining(
            hasScrollBody: true,
            child: _buildMobileContent(context, user, up),
          ),
        ],
      ),
    ));
  }

  Widget _buildTabBar() {
    final tabs = ['내 주문', '찜 목록', '쿠폰함', '설정'];
    return Container(
      color: Colors.white,
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = _tab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                      color: sel ? const Color(0xFF1A1A2E) : Colors.transparent, width: 2.5)),
                ),
                child: Text(e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13, fontWeight: sel ? FontWeight.w800 : FontWeight.w400,
                    color: sel ? const Color(0xFF1A1A2E) : Colors.grey[500],
                  )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context, UserModel user, UserProvider up) {
    switch (_tab) {
      case 0: return _OrdersTab(user: user, isMobile: true,
          onAdditional: _openAdditionalOrder, onColorEdit: _openColorEdit,
          onDesignRevision: _openDesignRevision, onExcelDownload: _exportExcel);
      case 1: return _WishlistTab(user: user, isMobile: true);
      case 2: return _CouponTab(user: user, isMobile: true);
      case 3: return _SettingsTab(user: user, up: up, isMobile: true,
          onProfileEdit: () => _openProfileEdit(context, user),
          onAddressManager: () => _openAddressManager(context),
          onChangePassword: () => _openChangePassword(context),
          onDeleteAccount: () => _openDeleteAccount(context, up),
          onLogout: () => _openLogout(context, up));
      default: return const SizedBox();
    }
  }
}

// ════════════════════════════════════════════════════════════════
// PC: 좌측 프로필 패널
// ════════════════════════════════════════════════════════════════
class _PcProfilePanel extends StatelessWidget {
  final UserModel user;
  final UserProvider up;
  final VoidCallback onEdit;
  final VoidCallback onLogout;
  final VoidCallback onAddressManager;
  const _PcProfilePanel({required this.user, required this.up, required this.onEdit, required this.onLogout, required this.onAddressManager});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        Row(children: [
          CircleAvatar(radius: 28, backgroundColor: const Color(0xFF1A1A2E),
              child: Text(user.name.isNotEmpty ? user.name[0] : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(user.email, style: TextStyle(fontSize: 11, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
          ])),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit),
        ]),
        const SizedBox(height: 16),
        _GradeChip(grade: user.grade),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text('${user.points} P', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _PcProfileBtn(label: '주소 관리', icon: Icons.location_on_outlined, onTap: onAddressManager)),
          const SizedBox(width: 8),
          Expanded(child: _PcProfileBtn(label: '로그아웃', icon: Icons.logout_rounded, onTap: onLogout, danger: true)),
        ]),
      ]),
    );
  }
}

class _PcProfileBtn extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap; final bool danger;
  const _PcProfileBtn({required this.label, required this.icon, required this.onTap, this.danger = false});
  @override
  Widget build(BuildContext context) {
    final c = danger ? Colors.red : const Color(0xFF1A1A2E);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: c),
      label: Text(label, style: TextStyle(fontSize: 12, color: c)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: c.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    );
  }
}

class _PcNavItem extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  const _PcNavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 20, color: selected ? const Color(0xFF1A1A2E) : Colors.grey[400]),
    title: Text(label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
        color: selected ? const Color(0xFF1A1A2E) : Colors.grey[600])),
    selected: selected,
    selectedTileColor: const Color(0xFFF0F0F5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    onTap: onTap,
  );
}

// ════════════════════════════════════════════════════════════════
// 모바일: 플렉시블 헤더 (SliverAppBar 내부)
// ════════════════════════════════════════════════════════════════
class _MobileProfileHeader extends StatelessWidget {
  final UserModel user;
  final UserProvider up;
  final VoidCallback onLogout;
  const _MobileProfileHeader({required this.user, required this.up, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D2D5E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        CircleAvatar(radius: 30, backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(user.name.isNotEmpty ? user.name[0] : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            _GradeChip(grade: user.grade, dark: true),
          ]),
          const SizedBox(height: 3),
          Text(user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
            const SizedBox(width: 4),
            Text('${user.points} P', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ])),
        GestureDetector(
          onTap: onLogout,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text('로그아웃', style: TextStyle(color: Colors.white, fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── 등급 칩 ──────────────────────────────────────
class _GradeChip extends StatelessWidget {
  final String grade; final bool dark;
  const _GradeChip({required this.grade, this.dark = false});
  Color get _color {
    switch (grade.toLowerCase()) {
      case 'vip': return const Color(0xFFFFD700);
      case 'gold': return const Color(0xFFFFA000);
      case 'silver': return Colors.blueGrey;
      default: return const Color(0xFFCD7F32);
    }
  }
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: dark ? _color.withValues(alpha: 0.2) : _color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _color.withValues(alpha: 0.5)),
    ),
    child: Text(grade, style: TextStyle(fontSize: 10, color: dark ? Colors.white : _color, fontWeight: FontWeight.w800)),
  );
}

// ════════════════════════════════════════════════════════════════
// 퀵 통계 (모바일 전용)
// ════════════════════════════════════════════════════════════════
class _QuickStats extends StatelessWidget {
  final UserModel user;
  final void Function(int) onTabChange;
  const _QuickStats({required this.user, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().userOrders.length;
    final wishlist = context.watch<UserProvider>().user?.wishlist.length ?? 0;
    final coupons = context.watch<CouponProvider>().validCoupons.length;
    final points = user.points;
    final items = [
      (orders, '내 주문', 0),
      (wishlist, '찜 목록', 1),
      (coupons, '쿠폰함', 2),
      (points, '포인트', -1),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          return Expanded(
            child: GestureDetector(
              onTap: item.$3 >= 0 ? () => onTabChange(item.$3) : null,
              child: Column(children: [
                Text('${item.$1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text(item.$2, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// SliverPersistentHeader 델리게이트
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  const _TabBarDelegate({required this.tabBar});
  @override double get minExtent => 45;
  @override double get maxExtent => 45;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => tabBar;
  @override bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar;
}

// ════════════════════════════════════════════════════════════════
// 내 주문 탭
// ════════════════════════════════════════════════════════════════
class _OrdersTab extends StatelessWidget {
  final UserModel user;
  final bool isMobile;
  final void Function(OrderModel) onAdditional;
  final void Function(OrderModel) onColorEdit;
  final void Function(OrderModel) onDesignRevision;
  final Future<void> Function(BuildContext, OrderModel) onExcelDownload;
  const _OrdersTab({required this.user, this.isMobile = false,
    required this.onAdditional, required this.onColorEdit,
    required this.onDesignRevision, required this.onExcelDownload});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().userOrders;
    if (orders.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text('주문 내역이 없습니다', style: TextStyle(fontSize: 15, color: Colors.grey[400])),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _OrderCard(
        order: orders[i],
        onAdditional: onAdditional,
        onColorEdit: onColorEdit,
        onDesignRevision: onDesignRevision,
        onExcelDownload: onExcelDownload,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 주문 카드 (네이버페이 스타일)
// ════════════════════════════════════════════════════════════════
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final void Function(OrderModel) onAdditional;
  final void Function(OrderModel) onColorEdit;
  final void Function(OrderModel) onDesignRevision;
  final Future<void> Function(BuildContext, OrderModel) onExcelDownload;
  const _OrderCard({required this.order, required this.onAdditional, required this.onColorEdit,
      required this.onDesignRevision, required this.onExcelDownload});

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:   return Colors.orange;
      case OrderStatus.confirmed: return const Color(0xFF1565C0);
      case OrderStatus.processing:return const Color(0xFF7B1FA2);
      case OrderStatus.shipped:   return const Color(0xFF00838F);
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      case OrderStatus.refunded:  return Colors.brown;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';
  String _fmtAmt(double v) =>
      '${v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}원';

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(order.status);
    final isGroup = order.orderType == 'group' || order.orderType == 'additional'
        || order.id.startsWith('GRP_') || order.id.startsWith('GROUP-');
    final isActive = order.status != OrderStatus.cancelled && order.status != OrderStatus.refunded;
    final canCancel = isActive && (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed);
    final canExRet = !isGroup && order.status == OrderStatus.delivered;
    final cancelBlocked = isGroup && order.status == OrderStatus.processing;
    final canDesign = isGroup && isActive && order.canDesignRevision;
    final canAdditional = isGroup && isActive && order.canOrderAdditionalFree;
    final canColor = isGroup && isActive && order.canEditColor;

    final item = order.items.isNotEmpty ? order.items.first : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 날짜 + 주문번호 + 상태 ──
        GestureDetector(
          onTap: () => _showDetail(context, order),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_fmtDate(order.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Row(children: [
                  if (isGroup) Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.purple.withValues(alpha:0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text('단체', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(child: Text(order.id,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)),
                      overflow: TextOverflow.ellipsis)),
                ]),
              ])),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: sc.withValues(alpha:0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(order.status.label,
                    style: TextStyle(fontSize: 12, color: sc, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
            ]),
          ),
        ),
        Divider(height: 1, color: Colors.grey[100]),
        // ── 상품 정보 ──
        GestureDetector(
          onTap: () => _showDetail(context, order),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 상품 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item?.imageUrl != null && item!.imageUrl!.isNotEmpty
                    ? NetImage(item.imageUrl!, width: 72, height: 72, fit: BoxFit.cover)
                    : Container(width: 72, height: 72,
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.checkroom_rounded, color: Colors.grey)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // 판매자(상품명 라인)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(order.status.label,
                      style: TextStyle(fontSize: 10, color: sc, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                Text(item?.productName ?? '주문 상품',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (item != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (item.size.isNotEmpty && item.size != '단체') item.size,
                      if (item.color.isNotEmpty) item.color,
                      '${item.quantity}개',
                    ].join(' / '),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
                if (order.items.length > 1)
                  Text('외 ${order.items.length - 1}개 상품',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0))),
                const SizedBox(height: 6),
                Text(_fmtAmt(order.totalAmount),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
              ])),
            ]),
          ),
        ),
        // ── 버튼 행 (네이버페이 스타일: 상품 하단에 직접 노출) ──
        Builder(builder: (btnCtx) {
          Future<void> doCancel() async {
            final ok = await showDialog<bool>(
              context: btnCtx,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: const Text('주문 취소', style: TextStyle(fontWeight: FontWeight.w800)),
                content: Text(isGroup
                    ? '단체주문을 취소하시겠습니까?\n제작 시작 전에만 취소 가능합니다.\n결제 취소는 1~3 영업일 내 처리됩니다.'
                    : '주문을 취소하시겠습니까?\n발송 전에만 취소 가능합니다.\n결제 취소는 1~3 영업일 내 처리됩니다.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(btnCtx, false), child: const Text('아니오')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(btnCtx, true),
                    child: const Text('취소하기', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (ok == true && btnCtx.mounted) {
              await OrderService.updateOrderStatus(order.id, OrderStatus.cancelled);
              NotificationService.sendCancelled(order: order, reason: '고객 직접 취소').catchError((_){});
              FcmService.sendOrderStatusNotification(order: order, newStatus: OrderStatus.cancelled).catchError((_){});
              if (btnCtx.mounted) ScaffoldMessenger.of(btnCtx).showSnackBar(
                  const SnackBar(content: Text('주문이 취소되었습니다.'), backgroundColor: Color(0xFF1A1A2E)));
            }
          }

          void showContact(String subject) {
            showModalBottomSheet(
              context: btnCtx,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(subject, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('주문번호: ${order.id}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: const Color(0xFFF3F8FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3))),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('고객센터 문의', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                      SizedBox(height: 6),
                      Text('• 카카오톡: @2fitkorea'),
                      Text('• 전화: 010-7227-6914'),
                      Text('• 이메일: chw243527@gmail.com'),
                      SizedBox(height: 6),
                      Text('배송 완료 후 7일 이내 접수해 주세요.\n(상품 하자의 경우 3개월 이내)',
                          style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.5)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[100]!))),
            child: Column(children: [
              // 배송완료 시 초록 배송조회 버튼 (네이버 스타일)
              if (order.status == OrderStatus.shipped || order.status == OrderStatus.delivered)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(btnCtx).showSnackBar(
                        const SnackBar(content: Text('배송조회는 카카오톡 @2fitkorea로 문의해 주세요.'))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03C75A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('배송조회', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              // 아이콘 버튼 행
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                child: Row(children: [
                  _CardBtn(icon: Icons.receipt_long_rounded, label: '주문상세',
                      onTap: () => _showDetail(btnCtx, order)),
                  if (canCancel) _CardBtn(icon: Icons.cancel_outlined, label: isGroup ? '취소(제작전)' : '주문취소',
                      color: Colors.red, onTap: doCancel),
                  if (cancelBlocked) _CardBtn(icon: Icons.lock_outline_rounded, label: '취소불가',
                      color: Colors.red.shade300,
                      onTap: () => ScaffoldMessenger.of(btnCtx).showSnackBar(
                          const SnackBar(content: Text('디자인 수정이 시작되어 취소가 불가합니다. 고객센터로 문의해 주세요.')))),
                  if (canExRet) ...[
                    _CardBtn(icon: Icons.swap_horiz_rounded, label: '교환신청',
                        color: const Color(0xFF1565C0), onTap: () => showContact('교환 신청')),
                    _CardBtn(icon: Icons.assignment_return_outlined, label: '반품신청',
                        color: Colors.orange, onTap: () => showContact('반품 신청')),
                  ],
                  if (canDesign) _CardBtn(icon: Icons.edit_note_rounded, label: '디자인수정',
                      color: const Color(0xFF7B1FA2), badge: '${order.remainingDesignRevisions}',
                      onTap: () => onDesignRevision(order)),
                  if (canAdditional) _CardBtn(icon: Icons.add_circle_outline_rounded, label: '추가제작',
                      color: const Color(0xFF2E7D32), badge: '무료', onTap: () => onAdditional(order)),
                  if (canColor) _CardBtn(icon: Icons.palette_outlined, label: '색상변경',
                      color: const Color(0xFF1565C0), badge: '${order.remainingColorEdits}',
                      onTap: () => onColorEdit(order)),
                  if (isGroup) Builder(builder: (ctx2) => _CardBtn(
                      icon: Icons.file_download_outlined, label: '엑셀',
                      color: const Color(0xFF00695C),
                      onTap: () => onExcelDownload(ctx2, order))),
                ].asMap().entries.map((e) {
                  final w = Expanded(child: e.value);
                  if (e.key == 0) return w;
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 1, height: 32, color: Colors.grey[100]), w]);
                }).toList()),
              ),
            ]),
          );
        }),
        Container(height: 6, color: const Color(0xFFF4F4F4)),
      ]),
    );
  }
}

// ── 카드 버튼 (아이콘+텍스트) ────────────────────
class _CardBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  final String? badge; final VoidCallback onTap;
  const _CardBtn({required this.icon, required this.label, this.color = const Color(0xFF555555),
      this.badge, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          Icon(icon, size: 22, color: color),
          if (badge != null) Positioned(top: -4, right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Text(badge!, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
              )),
        ]),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// 찜 목록 탭
// ════════════════════════════════════════════════════════════════
class _WishlistTab extends StatefulWidget {
  final UserModel user; final bool isMobile;
  const _WishlistTab({required this.user, this.isMobile = false});
  @override
  State<_WishlistTab> createState() => _WishlistTabState();
}
class _WishlistTabState extends State<_WishlistTab> {
  List<ProductModel>? _products;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final wishIds = widget.user.wishlist;
    if (wishIds.isEmpty) { setState(() => _products = []); return; }
    final all = <ProductModel>[];
    for (final id in wishIds) {
      try {
        final p = await ProductService.getProductById(id);
        if (p != null) all.add(p);
      } catch (_) {}
    }
    if (mounted) setState(() => _products = all);
  }

  @override
  Widget build(BuildContext context) {
    if (_products == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A2E)));
    final items = _products!;
    if (items.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.favorite_border_rounded, size: 56, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('찜한 상품이 없습니다', style: TextStyle(fontSize: 15, color: Colors.grey[400])),
    ]));
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.isMobile ? 2 : 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final p = items[i];
        return GestureDetector(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 6, offset: const Offset(0,2))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: p.images.isNotEmpty
                    ? NetImage(p.images.first, width: double.infinity, height: 140, fit: BoxFit.cover)
                    : Container(height: 140, color: Colors.grey[100],
                        child: const Icon(Icons.checkroom_rounded, color: Colors.grey)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${p.price.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}원',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 쿠폰함 탭
// ════════════════════════════════════════════════════════════════
class _CouponTab extends StatelessWidget {
  final UserModel user; final bool isMobile;
  const _CouponTab({required this.user, this.isMobile = false});
  @override
  Widget build(BuildContext context) {
    final coupons = context.watch<CouponProvider>().validCoupons;
    if (coupons.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.local_offer_outlined, size: 56, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('사용 가능한 쿠폰이 없습니다', style: TextStyle(fontSize: 15, color: Colors.grey[400])),
    ]));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: coupons.length,
      itemBuilder: (_, i) {
        final c = coupons[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 6, offset: const Offset(0,2))],
          ),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha:0.1), shape: BoxShape.circle),
              child: const Icon(Icons.local_offer_rounded, color: Color(0xFF1565C0), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(c.discount > 0 && c.discount <= 100 ? '${c.discount.toInt()}% 할인' : '${c.discount.toInt()}원 할인',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
              if (c.expiresAt != null)
                Text('~${c.expiresAt!.year}.${c.expiresAt!.month.toString().padLeft(2,'0')}.${c.expiresAt!.day.toString().padLeft(2,'0')}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ])),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 설정 탭
// ════════════════════════════════════════════════════════════════
class _SettingsTab extends StatelessWidget {
  final UserModel user; final UserProvider up; final bool isMobile;
  final VoidCallback onProfileEdit, onAddressManager, onChangePassword, onLogout;
  final void Function(BuildContext, UserProvider) onDeleteAccount;
  const _SettingsTab({required this.user, required this.up, this.isMobile = false,
    required this.onProfileEdit, required this.onAddressManager,
    required this.onChangePassword, required this.onLogout,
    required this.onDeleteAccount});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 계정 섹션
        _SettGroup(title: '계정', items: [
          _SettItem(icon: Icons.person_outline, label: '프로필 수정', onTap: onProfileEdit),
          _SettItem(icon: Icons.location_on_outlined, label: '배송지 관리', onTap: onAddressManager),
          _SettItem(icon: Icons.lock_outline_rounded, label: '비밀번호 변경', onTap: onChangePassword),
        ]),
        const SizedBox(height: 12),
        // 앱 섹션
        _SettGroup(title: '앱 정보', items: [
          _SettItem(icon: Icons.info_outline, label: '앱 버전', trailing: '1.0.0', onTap: (){}),
          _SettItem(icon: Icons.help_outline, label: '고객센터', onTap: () {
            showModalBottomSheet(context: context, builder: (_) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('고객센터', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                const Text('• 카카오톡: @2fitkorea'),
                const Text('• 전화: 010-7227-6914'),
                const Text('• 이메일: chw243527@gmail.com'),
                const SizedBox(height: 6),
                const Text('운영시간: 평일 09:00 ~ 18:00', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 20),
              ]),
            ));
          }),
          if (user.isAdmin) _SettItem(icon: Icons.admin_panel_settings_rounded, label: '관리자 페이지',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen()))),
        ]),
        const SizedBox(height: 12),
        // 계정 관리
        _SettGroup(title: '계정 관리', items: [
          _SettItem(icon: Icons.logout_rounded, label: '로그아웃', color: Colors.orange, onTap: onLogout),
          _SettItem(icon: Icons.delete_forever_outlined, label: '회원 탈퇴', color: Colors.red,
              onTap: () => onDeleteAccount(context, up)),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SettGroup extends StatelessWidget {
  final String title; final List<Widget> items;
  const _SettGroup({required this.title, required this.items});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500])),
    ),
    Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 6, offset: const Offset(0,2))]),
      child: Column(children: items.asMap().entries.map((e) => Column(children: [
        e.value,
        if (e.key < items.length - 1) Divider(height: 1, indent: 48, color: Colors.grey[100]),
      ])).toList()),
    ),
  ]);
}

class _SettItem extends StatelessWidget {
  final IconData icon; final String label; final String? trailing;
  final Color? color; final VoidCallback onTap;
  const _SettItem({required this.icon, required this.label, this.trailing, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, size: 20, color: color ?? Colors.grey[600]),
    title: Text(label, style: TextStyle(fontSize: 14, color: color ?? Colors.black87)),
    trailing: trailing != null
        ? Text(trailing!, style: TextStyle(fontSize: 13, color: Colors.grey[400]))
        : Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[300]),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    dense: true,
  );
}

// ════════════════════════════════════════════════════════════════
// 주문 상세 다이얼로그/바텀시트 (네이버페이 스타일)
// ════════════════════════════════════════════════════════════════
void _showDetail(BuildContext context, OrderModel order) {
  String fmtAmt(double v) =>
      '${v.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}원';

  Color sc(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:   return Colors.orange;
      case OrderStatus.confirmed: return const Color(0xFF1565C0);
      case OrderStatus.processing:return const Color(0xFF7B1FA2);
      case OrderStatus.shipped:   return const Color(0xFF00838F);
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      case OrderStatus.refunded:  return Colors.brown;
    }
  }

  final opts    = order.customOptions ?? {};
  final isGroup = order.orderType == 'group' || order.orderType == 'additional'
      || order.id.startsWith('GRP_') || order.id.startsWith('GROUP-');
  final statusColor = sc(order.status);
  final dt = order.createdAt;
  final dtStr =
      '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')}  '
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
  final productAmt  = order.totalAmount - order.shippingFee;
  final discountAmt = (opts['discountAmount'] as num?)?.toDouble() ?? 0.0;

  final isMobile = !isPcWeb(context);

  Widget buildContent(BuildContext sheetCtx, {bool isSheet = false}) {
    // 버튼 조건
    final canCancel = order.status == OrderStatus.pending || order.status == OrderStatus.confirmed;
    final cancelBlocked = isGroup && order.status == OrderStatus.processing;
    final canExRet = !isGroup && order.status == OrderStatus.delivered;

    // 디자인 이미지
    final imgs = <String>[];
    for (final k in ['refImageBase64','designLogoBase64','waistbandLogoBase64']) {
      final v = opts[k]?.toString() ?? '';
      if (v.isNotEmpty) imgs.add(v);
    }
    imgs.addAll((opts['waistbandRefImages'] as List?)?.cast<String>() ?? []);

    Future<void> doCancel() async {
      final ok = await showDialog<bool>(
        context: sheetCtx,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('주문 취소', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text(isGroup
              ? '단체주문을 취소하시겠습니까?\n제작 시작 전에만 취소 가능합니다.\n결제 취소는 1~3 영업일 내 처리됩니다.'
              : '주문을 취소하시겠습니까?\n발송 전에만 취소 가능합니다.\n결제 취소는 1~3 영업일 내 처리됩니다.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(sheetCtx, false), child: const Text('아니오')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(sheetCtx, true),
              child: const Text('취소하기', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (ok == true && sheetCtx.mounted) {
        await OrderService.updateOrderStatus(order.id, OrderStatus.cancelled);
        NotificationService.sendCancelled(order: order, reason: '고객 직접 취소').catchError((_){});
        FcmService.sendOrderStatusNotification(order: order, newStatus: OrderStatus.cancelled).catchError((_){});
        if (sheetCtx.mounted) {
          Navigator.pop(sheetCtx);
          ScaffoldMessenger.of(sheetCtx).showSnackBar(
              const SnackBar(content: Text('주문이 취소되었습니다.'), backgroundColor: Color(0xFF1A1A2E)));
        }
      }
    }

    void showContact(String subj) {
      Navigator.pop(sheetCtx);
      showModalBottomSheet(
        context: sheetCtx,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(subj, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('주문번호: ${order.id}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF3F8FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3))),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('고객센터 문의', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                SizedBox(height: 6), Text('• 카카오톡: @2fitkorea'), Text('• 전화: 010-7227-6914'), Text('• 이메일: chw243527@gmail.com'),
                SizedBox(height: 6),
                Text('배송 완료 후 7일 이내 접수해 주세요.\n(상품 하자의 경우 3개월 이내)',
                    style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.5)),
              ]),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      );
    }

    return Column(
      mainAxisSize: isSheet ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // ── 헤더 ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            borderRadius: isSheet ? const BorderRadius.vertical(top: Radius.circular(16)) : BorderRadius.zero,
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dtStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 3),
              Row(children: [
                const Text('주문번호  ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Expanded(child: Text(order.id,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            const SizedBox(width: 8),
            Builder(builder: (rcCtx) => OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(rcCtx).showSnackBar(
                  SnackBar(content: Text('영수증 발급은 고객센터로 문의해 주세요.\n주문번호: ${order.id}'),
                      action: SnackBarAction(label: '닫기', onPressed: () {}))),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87, side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('영수증', style: TextStyle(fontSize: 12)),
            )),
            const SizedBox(width: 6),
            GestureDetector(onTap: () => Navigator.pop(sheetCtx),
                child: Icon(Icons.close, size: 20, color: Colors.grey[500])),
          ]),
        ),

        // ── 스크롤 콘텐츠 ──
        Flexible(
          child: SingleChildScrollView(
            child: Column(children: [
              // [주문상품]
              _npSec('주문상품', Icons.shopping_bag_outlined,
                order.items.isEmpty
                  ? Container(padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Text('상품 정보를 불러올 수 없습니다.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400])))
                  : Column(children: order.items.map((item) {
                      final sz = (item.size == '단체' || item.size.isEmpty) ? null : item.size;
                      final optStr = [if (sz != null) sz, if (item.color.isNotEmpty) item.color].join(' / ');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ClipRRect(borderRadius: BorderRadius.circular(8),
                              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                  ? NetImage(item.imageUrl!, width: 72, height: 72, fit: BoxFit.cover)
                                  : Container(width: 72, height: 72, color: Colors.grey[100],
                                      child: const Icon(Icons.checkroom_rounded, color: Colors.grey))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(order.status.label, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 4),
                              Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (optStr.isNotEmpty)
                                Text('옵션: $optStr  ${item.quantity}개', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              const SizedBox(height: 4),
                              Text(fmtAmt(item.price * item.quantity),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                            ])),
                          ]),
                          const SizedBox(height: 10),
                          // 액션 버튼 행
                          Row(children: [
                            if (order.status == OrderStatus.shipped || order.status == OrderStatus.delivered)
                              Expanded(child: _detailBtn('배송조회', isPrimary: true,
                                  onTap: () => ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                      const SnackBar(content: Text('배송조회는 카카오톡 @2fitkorea로 문의해 주세요.'))))),
                            if (canCancel) ...[
                              Expanded(child: _detailBtn(isGroup ? '취소(제작전)' : '주문취소', onTap: doCancel)),
                            ],
                            if (canExRet) ...[
                              Expanded(child: _detailBtn('교환신청', onTap: () => showContact('교환 신청'))),
                              const SizedBox(width: 6),
                              Expanded(child: _detailBtn('반품신청', onTap: () => showContact('반품 신청'))),
                            ],
                            if (!canCancel && !canExRet && order.status != OrderStatus.shipped && order.status != OrderStatus.delivered)
                              Expanded(child: _detailBtn('문의하기',
                                  onTap: () => ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                      const SnackBar(content: Text('카카오톡: @2fitkorea  |  전화: 010-7227-6914'))))),
                          ]),
                          if (cancelBlocked) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200)),
                              child: Row(children: [
                                Icon(Icons.lock_outline_rounded, size: 13, color: Colors.red.shade600),
                                const SizedBox(width: 6),
                                Expanded(child: Text('디자인 수정이 시작되어 취소가 불가합니다.',
                                    style: TextStyle(fontSize: 11, color: Colors.red.shade700))),
                              ]),
                            ),
                          ],
                          if (isGroup && imgs.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(width: double.infinity, child: OutlinedButton.icon(
                              onPressed: () => showDialog(context: sheetCtx, builder: (_) => Dialog(
                                backgroundColor: Colors.black87, insetPadding: const EdgeInsets.all(12),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                                    const Icon(Icons.design_services_outlined, color: Colors.white70, size: 16),
                                    const SizedBox(width: 8),
                                    const Expanded(child: Text('디자인 참고 이미지', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                                    GestureDetector(onTap: () => Navigator.pop(sheetCtx),
                                        child: const Icon(Icons.close, color: Colors.white70, size: 20)),
                                  ])),
                                  SizedBox(height: 300, child: PageView.builder(
                                    itemCount: imgs.length,
                                    itemBuilder: (_, i) {
                                      try {
                                        final b = base64Decode(imgs[i].contains(',') ? imgs[i].split(',').last : imgs[i]);
                                        return InteractiveViewer(child: Center(child: Image.memory(b, fit: BoxFit.contain)));
                                      } catch (_) { return const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)); }
                                    },
                                  )),
                                  Padding(padding: const EdgeInsets.all(8),
                                      child: Text('총 ${imgs.length}장 · 좌우로 스와이프', style: const TextStyle(color: Colors.white54, fontSize: 11))),
                                ]),
                              )),
                              icon: const Icon(Icons.image_search_rounded, size: 15),
                              label: Text('디자인 이미지 확인 (${imgs.length}장)', style: const TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7B1FA2),
                                  side: const BorderSide(color: Color(0xFF7B1FA2)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            )),
                          ],
                        ]),
                      );
                    }).toList()),
              ),

              // [배송지]
              _npSec('배송지', Icons.location_on_outlined,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  if (order.userPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(order.userPhone, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                  if (order.userAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(order.userAddress, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ]),
              ),

              // [단체주문 정보]
              if (isGroup && opts.isNotEmpty)
                _npSec('단체주문 정보', Icons.groups_outlined,
                  Column(children: [
                    if ((opts['teamName'] ?? '').toString().isNotEmpty)
                      _npRow('단체명', opts['teamName'].toString()),
                    if ((opts['totalCount'] ?? order.groupCount) != null)
                      _npRow('총 인원', '${opts['totalCount'] ?? order.groupCount}명'),
                    if ((opts['printTypeLabel'] ?? opts['printType'] ?? '').toString().isNotEmpty)
                      _npRow('인쇄 옵션', (opts['printTypeLabel'] ?? opts['printType']).toString()),
                    if ((opts['mainColor'] ?? '').toString().isNotEmpty)
                      _npRow('주요 색상', opts['mainColor'].toString()),
                  ]),
                ),

              // [결제정보]
              _npSec('결제정보', Icons.payment_rounded,
                Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('주문금액', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('총 ${fmtAmt(order.totalAmount)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
                  ]),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 10),
                  _npAmt('상품금액', fmtAmt(productAmt)),
                  if (discountAmt > 0) _npAmt('할인금액', '-${fmtAmt(discountAmt)}', valueColor: Colors.red),
                  _npAmt('배송비', order.shippingFee == 0 ? '무료' : fmtAmt(order.shippingFee)),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: Colors.grey.shade200),
                  const SizedBox(height: 10),
                  _npAmt('결제수단', order.paymentMethod, labelColor: Colors.black54),
                  if ((order.memo ?? '').isNotEmpty) _npAmt('메모', order.memo!, labelColor: Colors.black54),
                ]),
              ),

              // [영수증 / 현금영수증]
              _npSec('영수증 / 현금영수증', Icons.receipt_outlined,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Builder(builder: (rcCtx) => OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(rcCtx).showSnackBar(
                          SnackBar(content: Text('영수증 발급은 고객센터로 문의해 주세요.\n주문번호: ${order.id}'),
                              action: SnackBarAction(label: '닫기', onPressed: () {}))),
                      icon: const Icon(Icons.receipt_long_outlined, size: 14),
                      label: const Text('영수증 조회', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.black54,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ))),
                    const SizedBox(width: 8),
                    Expanded(child: Builder(builder: (rcCtx) => OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(rcCtx).showSnackBar(
                          const SnackBar(content: Text('현금영수증은 현금/계좌이체 결제 시 발급 가능합니다.\n문의: 010-7227-6914'),
                              )),
                      icon: const Icon(Icons.assignment_outlined, size: 14),
                      label: const Text('현금영수증', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1565C0),
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ))),
                  ]),
                  const SizedBox(height: 6),
                  Text('* 영수증·현금영수증은 결제 완료 후 고객센터로 문의해 주세요.',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400], height: 1.4)),
                ]),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),

        // ── 하단 닫기 버튼 ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 8, 16, isSheet ? 16 + MediaQuery.of(sheetCtx).padding.bottom : 16),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(sheetCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E), elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('닫기', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  if (isMobile) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.92,
        decoration: const BoxDecoration(color: Color(0xFFF4F4F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: buildContent(ctx, isSheet: true),
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFF4F4F4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Container(constraints: const BoxConstraints(maxWidth: 480, maxHeight: 820),
            child: buildContent(ctx)),
      ),
    );
  }
}

// 헬퍼 위젯들
Widget _npSec(String title, IconData icon, Widget child) => Container(
  width: double.infinity,
  decoration: BoxDecoration(color: Colors.white,
      border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 6))),
  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Icon(icon, size: 15, color: Colors.black87), const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
    ]),
    const SizedBox(height: 14),
    child,
  ]),
);

Widget _npRow(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(children: [
    SizedBox(width: 72, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
  ]),
);

Widget _npAmt(String label, String value, {Color? valueColor, Color? labelColor}) => Padding(
  padding: const EdgeInsets.only(bottom: 7),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 13, color: labelColor ?? Colors.grey[600])),
    Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? Colors.black87, fontWeight: FontWeight.w600)),
  ]),
);

Widget _detailBtn(String label, {required VoidCallback onTap, bool isPrimary = false}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF03C75A) : Colors.white,
          border: Border.all(color: isPrimary ? const Color(0xFF03C75A) : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : Colors.black87)),
      ),
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
                    border: Border.all(color: Colors.grey[200]!),
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
