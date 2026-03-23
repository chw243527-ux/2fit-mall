import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../products/product_detail_screen.dart';
import '../admin/admin_screen.dart';
import '../auth/login_screen.dart';
import '../orders/group_order_form_screen.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/pc_layout.dart';
import '../../widgets/kakao_address_search.dart';

class MyPageScreen extends StatefulWidget {
  final VoidCallback? onBack; // 홈(탭0)으로 돌아가는 콜백
  const MyPageScreen({super.key, this.onBack});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  AppLocalizations get _loc => context.watch<LanguageProvider>().loc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    if (isPcWeb(context)) {
      return _PcMyPage(
        tabController: _tabController,
        userProvider: userProvider,
        onShowAdditionalOrder: _showAdditionalOrderSheet,
        onShowColorEdit: _showColorEditSheet,
        onShowProfileEdit: _showProfileEdit,
        onShowAddressManager: _showAddressManager,
        onShowLogout: _showLogoutDialog,
        onShowChangePassword: _showChangePasswordDialog,
        onShowDeleteAccount: _showDeleteAccountDialog,
      );
    }
    return _MobileMyPage(
      tabController: _tabController,
      userProvider: userProvider,
      onBack: widget.onBack,
      onShowAdditionalOrder: _showAdditionalOrderSheet,
      onShowColorEdit: _showColorEditSheet,
      onShowProfileEdit: _showProfileEdit,
      onShowAddressManager: _showAddressManager,
      onShowLogout: _showLogoutDialog,
      onShowChangePassword: _showChangePasswordDialog,
      onShowDeleteAccount: _showDeleteAccountDialog,
    );
  }

  void _showAdditionalOrderSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdditionalOrderSheet(order: order),
    );
  }

  void _showColorEditSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ColorEditSheet(order: order),
    );
  }

  void _showProfileEdit(BuildContext ctx, UserModel user) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditSheet(user: user),
    );
  }

  void _showAddressManager(BuildContext ctx) {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressManagerSheet(
        user: user,
        onUpdated: (addresses) {
          context.read<UserProvider>().updateAddresses(addresses);
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext ctx, UserProvider up) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(context.read<LanguageProvider>().loc.mypageLogout),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.read<LanguageProvider>().loc.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              up.logout();
              if (ctx.mounted) {
                Navigator.of(ctx).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(context.read<LanguageProvider>().loc.mypageLogout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext ctx) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMsg;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.lock_rounded, color: Color(0xFF1A1A2E), size: 22),
            SizedBox(width: 8),
            Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '현재 비밀번호',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '새 비밀번호 (6자 이상)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '새 비밀번호 확인',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading ? null : () async {
                if (newCtrl.text != confirmCtrl.text) {
                  setD(() => errorMsg = '새 비밀번호가 일치하지 않습니다.');
                  return;
                }
                if (newCtrl.text.length < 6) {
                  setD(() => errorMsg = '비밀번호는 6자 이상이어야 합니다.');
                  return;
                }
                setD(() { isLoading = true; errorMsg = null; });
                final user = context.read<UserProvider>().user;
                final result = await AuthService.updateProfile(
                  email: user?.email ?? '',
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (result) {
                  if (ctx.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('비밀번호가 변경되었습니다.'), backgroundColor: Color(0xFF1A1A2E)),
                    );
                  }
                } else {
                  setD(() { isLoading = false; errorMsg = '현재 비밀번호가 올바르지 않습니다.'; });
                }
              },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('변경'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext ctx, UserProvider up) {
    final passwordCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMsg;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('회원 탈퇴', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.red)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('탈퇴하시면 모든 데이터가 삭제되며 복구할 수 없습니다.\n비밀번호를 입력하여 탈퇴를 확인해주세요.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading ? null : () async {
                setD(() { isLoading = true; errorMsg = null; });
                final user2 = up.user;
                if (user2 == null) return;
                try {
                  final result = await AuthService.updateProfile(
                    email: user2.email,
                    currentPassword: passwordCtrl.text,
                  );
                  if (result) {
                    await AuthService.deleteUserDocument(user2.id);
                    await AuthService.logout();
                    if (ctx.mounted) {
                      up.logout();
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.'), backgroundColor: Colors.red),
                      );
                    }
                  } else {
                    setD(() { isLoading = false; errorMsg = '비밀번호가 올바르지 않습니다.'; });
                  }
                } catch (e) {
                  setD(() { isLoading = false; errorMsg = '탈퇴 처리 중 오류가 발생했습니다.'; });
                }
              },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('탈퇴하기'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PC 버전 마이페이지
// ═══════════════════════════════════════════════════════════════════
class _PcMyPage extends StatelessWidget {
  final TabController tabController;
  final UserProvider userProvider;
  final void Function(OrderModel) onShowAdditionalOrder;
  final void Function(OrderModel) onShowColorEdit;
  final void Function(BuildContext, UserModel) onShowProfileEdit;
  final void Function(BuildContext) onShowAddressManager;
  final void Function(BuildContext, UserProvider) onShowLogout;
  final void Function(BuildContext) onShowChangePassword;
  final void Function(BuildContext, UserProvider) onShowDeleteAccount;

  const _PcMyPage({
    required this.tabController,
    required this.userProvider,
    required this.onShowAdditionalOrder,
    required this.onShowColorEdit,
    required this.onShowProfileEdit,
    required this.onShowAddressManager,
    required this.onShowLogout,
    required this.onShowChangePassword,
    required this.onShowDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final user = userProvider.user;
    final screenH = MediaQuery.of(context).size.height;
    const sideW = 260.0;

    final menuItems = [
      (Icons.receipt_long_rounded,   loc.myOrders),
      (Icons.payment_rounded,        loc.mypagePaymentHistory),
      (Icons.favorite_rounded,       loc.wishlist),
      (Icons.local_activity_rounded, loc.mypageCouponBox),
      (Icons.settings_rounded,       loc.settings),
    ];

    return Container(
      color: const Color(0xFFF2F4F8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 사이드바 ──
                SizedBox(
                  width: sideW,
                  child: Column(
                    children: [
                      _PcProfileCard(user: user, loc: loc,
                        onShowProfileEdit: onShowProfileEdit),
                      const SizedBox(height: 12),
                      _PcQuickStats(user: user, loc: loc, tabController: tabController),
                      const SizedBox(height: 12),
                      // 메뉴
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: AnimatedBuilder(
                          animation: tabController,
                          builder: (_, __) => Column(
                            children: List.generate(menuItems.length, (i) {
                              final sel = tabController.index == i;
                              final isLast = i == menuItems.length - 1;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.vertical(
                                    top: i == 0 ? const Radius.circular(16) : Radius.zero,
                                    bottom: isLast ? const Radius.circular(16) : Radius.zero,
                                  ),
                                  onTap: () => tabController.animateTo(i),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: sel ? const Color(0xFF1565C0).withValues(alpha:0.08) : Colors.transparent,
                                      borderRadius: BorderRadius.vertical(
                                        top: i == 0 ? const Radius.circular(16) : Radius.zero,
                                        bottom: isLast ? const Radius.circular(16) : Radius.zero,
                                      ),
                                      border: Border(
                                        left: BorderSide(
                                          color: sel ? const Color(0xFF1565C0) : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(menuItems[i].$1,
                                          size: 20,
                                          color: sel ? const Color(0xFF1565C0) : Colors.grey[600]),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(menuItems[i].$2,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                              color: sel ? const Color(0xFF1565C0) : Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                        if (sel) const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF1565C0)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      if (user?.isAdmin == true) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935).withValues(alpha:0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE53935).withValues(alpha:0.3)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.admin_panel_settings_rounded, size: 18, color: Color(0xFFE53935)),
                                  SizedBox(width: 8),
                                  Text('관리자 페이지', style: TextStyle(fontSize: 13, color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // 로그아웃
                      if (user != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => onShowLogout(context, userProvider),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8)],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout_rounded, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(loc.mypageLogout, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // ── 콘텐츠 ──
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(minHeight: screenH - 120),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedBuilder(
                        animation: tabController,
                        builder: (_, __) {
                          switch (tabController.index) {
                            case 0: return _PcOrderHistoryTab(userProvider: userProvider, loc: loc,
                                onAdditionalOrder: onShowAdditionalOrder, onColorEdit: onShowColorEdit);
                            case 1: return _PcPaymentHistoryTab(userProvider: userProvider, loc: loc);
                            case 2: return _PcWishlistTab(userProvider: userProvider, loc: loc);
                            case 3: return _PcCouponTab(userProvider: userProvider, loc: loc);
                            case 4: return _PcSettingsTab(userProvider: userProvider, loc: loc,
                                onShowProfileEdit: onShowProfileEdit,
                                onShowAddressManager: onShowAddressManager,
                                onShowLogout: onShowLogout,
                                onShowChangePassword: onShowChangePassword,
                                onShowDeleteAccount: onShowDeleteAccount);
                            default: return const SizedBox();
                          }
                        },
                      ),
                    ),
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

// ── PC 프로필 카드 ──
class _PcProfileCard extends StatelessWidget {
  final UserModel? user;
  final AppLocalizations loc;
  final void Function(BuildContext, UserModel) onShowProfileEdit;

  const _PcProfileCard({required this.user, required this.loc, required this.onShowProfileEdit});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle),
              child: const Icon(Icons.person_outline_rounded, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(loc.mypageLoginPrompt, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final tier = _tierLabel(user!.memberTier ?? 'bronze', loc);
    final tierColor = _tierColor(user!.memberTier ?? 'bronze');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user!.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: tierColor.withValues(alpha:0.3), borderRadius: BorderRadius.circular(10)),
                      child: Text(tier, style: TextStyle(color: tierColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onShowProfileEdit(context, user!),
                icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: Colors.amber[300]),
                const SizedBox(width: 6),
                Text('${_fmt(user!.points ?? 0)} P',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(loc.mypagePointsTotal, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tierLabel(String tier, AppLocalizations loc) {
    switch (tier) {
      case 'silver': return loc.mypageTierSilver;
      case 'gold': return loc.mypageTierGold;
      case 'vip': return loc.mypageTierVip;
      default: return loc.mypageTierBronze;
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'silver': return Colors.blueGrey[200]!;
      case 'gold': return Colors.amber[400]!;
      case 'vip': return Colors.purple[300]!;
      default: return Colors.brown[300]!;
    }
  }

  String _fmt(int n) {
    return n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]},');
  }
}

// ── PC 빠른 통계 ──
class _PcQuickStats extends StatelessWidget {
  final UserModel? user;
  final AppLocalizations loc;
  final TabController tabController;

  const _PcQuickStats({required this.user, required this.loc, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = user != null ? orderProvider.getUserOrders(user!.id) : <OrderModel>[];
    final wishCount = user?.wishlist.length ?? 0;
    final couponCount = user?.coupons.where((c) => c.isValid).length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _StatItem(label: loc.myOrders, count: orders.length, onTap: () => tabController.animateTo(0)),
          _Divider(),
          _StatItem(label: loc.wishlist, count: wishCount, onTap: () => tabController.animateTo(2)),
          _Divider(),
          _StatItem(label: loc.mypageCouponBox, count: couponCount, onTap: () => tabController.animateTo(3)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  const _StatItem({required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, height: 28, color: Colors.grey[200]);
}

// ── PC 탭 헤더 ──
class _PcTabHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String? badge;
  final VoidCallback? onRefresh;

  const _PcTabHeader({required this.icon, required this.title, required this.color, this.badge, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha:0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(badge!, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
            ),
          ],
          const Spacer(),
          if (onRefresh != null)
            IconButton(onPressed: onRefresh, icon: Icon(Icons.refresh_rounded, color: color)),
        ],
      ),
    );
  }
}

// ── PC 빈 상태 ──
class _PcEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const _PcEmptyState({required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: TextStyle(fontSize: 13, color: Colors.grey[400]), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// PC 주문 내역 탭
// ═══════════════════════════════════════════════════════
class _PcOrderHistoryTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  final void Function(OrderModel) onAdditionalOrder;
  final void Function(OrderModel) onColorEdit;

  const _PcOrderHistoryTab({
    required this.userProvider, required this.loc,
    required this.onAdditionalOrder, required this.onColorEdit,
  });

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;
    if (user == null) {
      return Column(children: [
        _PcTabHeader(icon: Icons.receipt_long_rounded, title: loc.myOrders, color: const Color(0xFF1565C0)),
        Expanded(child: _PcEmptyState(icon: Icons.login_rounded, message: loc.mypageLoginPrompt)),
      ]);
    }

    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.getUserOrders(user.id);

    return Column(
      children: [
        _PcTabHeader(
          icon: Icons.receipt_long_rounded, title: loc.myOrders,
          color: const Color(0xFF1565C0), badge: '${orders.length}',
          onRefresh: () => orderProvider.loadUserOrders(user.id),
        ),
        Expanded(
          child: orders.isEmpty
            ? _PcEmptyState(icon: Icons.receipt_long_outlined, message: loc.mypageNoOrders, subtitle: loc.mypageFirstOrder)
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: orders.length,
                itemBuilder: (_, i) => _PcOrderCard(
                  order: orders[i], loc: loc,
                  onAdditionalOrder: onAdditionalOrder,
                  onColorEdit: onColorEdit,
                ),
              ),
        ),
      ],
    );
  }
}

class _PcOrderCard extends StatelessWidget {
  final OrderModel order;
  final AppLocalizations loc;
  final void Function(OrderModel) onAdditionalOrder;
  final void Function(OrderModel) onColorEdit;

  const _PcOrderCard({required this.order, required this.loc, required this.onAdditionalOrder, required this.onColorEdit});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final isGroup = order.orderType == 'group_custom';
    final isActive = order.status != OrderStatus.cancelled && order.status != OrderStatus.refunded;
    final canColorEdit = isGroup && isActive && (order.colorEditCount ?? 0) < 3;
    final canAdditional = isGroup && isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Text(order.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                const SizedBox(width: 8),
                if (isGroup)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.purple.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(loc.groupCustom, style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600)),
                  ),
                const Spacer(),
                Text(_fmtDate(order.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(order.status.label, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 상품 목록
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...order.items.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.grey[100], borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.checkroom_rounded, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${item.size ?? ""} / ${item.color ?? ""} / ${item.quantity}개', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      Text(_fmtPrice(item.price * item.quantity), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
                if (order.items.length > 2)
                  Text(loc.mypageMoreItems.replaceAll('{n}', '${order.items.length - 2}'),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          // 금액 합계
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey[50],
            child: Row(
              children: [
                Text('${loc.mypagePaymentMethod}: ${order.paymentMethod ?? '-'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const Spacer(),
                Text('${loc.mypageOrderTotal}: ', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                Text(_fmtPrice(order.totalAmount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
              ],
            ),
          ),
          // 버튼
          if (isActive)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canAdditional) _PcBtn(
                    label: loc.mypageAdditionalProduction,
                    icon: Icons.add_circle_outline_rounded,
                    color: const Color(0xFF2E7D32),
                    onTap: () => onAdditionalOrder(order),
                  ),
                  if (canAdditional) const SizedBox(width: 8),
                  if (canColorEdit) _PcBtn(
                    label: loc.mypageColorGroupEdit,
                    icon: Icons.palette_outlined,
                    color: const Color(0xFF1565C0),
                    badge: '${3 - (order.colorEditCount ?? 0)}',
                    onTap: () => onColorEdit(order),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.processing: return const Color(0xFF7B1FA2);
      case OrderStatus.shipped: return const Color(0xFF00838F);
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      case OrderStatus.refunded: return Colors.brown;
    }
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y.$m.$dd';
  }
  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf원';
  }
}

class _PcBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _PcBtn({required this.label, required this.icon, required this.color, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(child: Text(badge!, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// PC 결제 내역 탭
// ═══════════════════════════════════════════════════════
class _PcPaymentHistoryTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;

  const _PcPaymentHistoryTab({required this.userProvider, required this.loc});

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;
    final orderProvider = context.watch<OrderProvider>();
    final orders = user != null ? orderProvider.getUserOrders(user.id) : <OrderModel>[];

    return Column(
      children: [
        _PcTabHeader(icon: Icons.payment_rounded, title: loc.mypagePaymentHistory, color: const Color(0xFF00796B), badge: '${orders.length}'),
        Expanded(
          child: orders.isEmpty
            ? _PcEmptyState(icon: Icons.payment_outlined, message: loc.mypageNoPayment)
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: orders.length,
                itemBuilder: (_, i) {
                  final o = orders[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(o.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF00796B)))),
                            Text(_fmtDate(o.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.credit_card_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(o.paymentMethod ?? '-', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                          const Spacer(),
                          Text(_fmtPrice(o.totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF00796B))),
                        ]),
                        if ((o.shippingFee ?? 0) > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${loc.mypageShipping}: ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              Text(_fmtPrice(o.shippingFee.toDouble() ?? 0), style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y.$m.$dd';
  }
  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf원';
  }
}

// ═══════════════════════════════════════════════════════
// PC 찜 목록 탭
// ═══════════════════════════════════════════════════════
class _PcWishlistTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;

  const _PcWishlistTab({required this.userProvider, required this.loc});

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;
    final wishIds = user?.wishlist ?? [];
    final products = wishIds
        .map((id) => ProductService.getProductById(id))
        .where((p) => p != null)
        .cast<ProductModel>()
        .toList();

    return Column(
      children: [
        _PcTabHeader(icon: Icons.favorite_rounded, title: loc.wishlist, color: Colors.pinkAccent, badge: '${products.length}'),
        Expanded(
          child: products.isEmpty
            ? _PcEmptyState(icon: Icons.favorite_border_rounded, message: loc.mypageNoWishlist, subtitle: loc.mypageNoWishlistSub)
            : GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 0.72, crossAxisSpacing: 16, mainAxisSpacing: 16),
                itemCount: products.length,
                itemBuilder: (_, i) {
                  final p = products[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(p.images.first, width: double.infinity, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.checkroom_rounded))),
                                ),
                                Positioned(top: 8, right: 8,
                                  child: GestureDetector(
                                    onTap: () => userProvider.toggleWishlist(p.id),
                                    child: Container(width: 28, height: 28,
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: const Icon(Icons.favorite_rounded, size: 16, color: Colors.pinkAccent)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const Spacer(),
                                  Text(_fmtPrice(p.price.toDouble()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf원';
  }
}

// ═══════════════════════════════════════════════════════
// PC 쿠폰함 탭
// ═══════════════════════════════════════════════════════
class _PcCouponTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;

  const _PcCouponTab({required this.userProvider, required this.loc});

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;
    final coupons = user?.coupons ?? [];
    final valid = coupons.where((c) => c.isValid).toList();
    final used = coupons.where((c) => c.isUsed).toList();
    final expired = coupons.where((c) => !c.isValid && !c.isUsed).toList();

    return Column(
      children: [
        _PcTabHeader(icon: Icons.local_activity_rounded, title: loc.mypageCouponBox,
          color: const Color(0xFFE65100), badge: '${valid.length}'),
        Expanded(
          child: coupons.isEmpty
            ? _PcEmptyState(icon: Icons.local_activity_outlined, message: loc.mypageNoCoupons)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (valid.isNotEmpty) ...[
                      _CouponSectionTitle(title: loc.mypageAvailableCoupon, count: valid.length, color: const Color(0xFF2E7D32)),
                      const SizedBox(height: 8),
                      ...valid.map((c) => _PcCouponCard(coupon: c, loc: loc, color: const Color(0xFF2E7D32))),
                      const SizedBox(height: 20),
                    ],
                    if (used.isNotEmpty) ...[
                      _CouponSectionTitle(title: loc.mypageUsedCoupon, count: used.length, color: Colors.grey),
                      const SizedBox(height: 8),
                      ...used.map((c) => _PcCouponCard(coupon: c, loc: loc, color: Colors.grey, dimmed: true)),
                      const SizedBox(height: 20),
                    ],
                    if (expired.isNotEmpty) ...[
                      _CouponSectionTitle(title: loc.mypageExpiredCoupon, count: expired.length, color: Colors.red),
                      const SizedBox(height: 8),
                      ...expired.map((c) => _PcCouponCard(coupon: c, loc: loc, color: Colors.red, dimmed: true)),
                    ],
                  ],
                ),
              ),
        ),
      ],
    );
  }
}

class _CouponSectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _CouponSectionTitle({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: color, margin: const EdgeInsets.only(right: 8)),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 6),
        Text('($count)', style: TextStyle(fontSize: 13, color: color.withValues(alpha:0.7))),
      ],
    );
  }
}

class _PcCouponCard extends StatelessWidget {
  final CouponModel coupon;
  final AppLocalizations loc;
  final Color color;
  final bool dimmed;

  const _PcCouponCard({required this.coupon, required this.loc, required this.color, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final discountText = coupon.type == 'percent'
        ? '${coupon.value.toInt()}% OFF'
        : '${coupon.value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]},')}원 할인';

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dimmed ? Colors.grey[300]! : color.withValues(alpha:0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: dimmed ? Colors.grey[200] : color.withValues(alpha:0.1),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  Icon(Icons.local_activity_rounded, color: dimmed ? Colors.grey : color, size: 24),
                  const SizedBox(height: 4),
                  Text(discountText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: dimmed ? Colors.grey : color), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coupon.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (coupon.minOrderAmount > 0)
                      Text('${loc.mypageMinOrder}: ${coupon.minOrderAmount.toInt()}원 이상',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text('${loc.mypageCouponExpiry}: ${_fmtDate(coupon.expiresAt)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: dimmed ? Colors.grey[100] : color.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dimmed ? Colors.grey[300]! : color.withValues(alpha:0.3)),
              ),
              child: Text(
                dimmed ? (coupon.isUsed ? loc.mypageUsedCoupon : loc.mypageExpiredCoupon) : loc.mypageAvailableCoupon,
                style: TextStyle(fontSize: 11, color: dimmed ? Colors.grey : color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y.$m.$dd';
  }
}

// ═══════════════════════════════════════════════════════
// PC 설정 탭
// ═══════════════════════════════════════════════════════
class _PcSettingsTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  final void Function(BuildContext, UserModel) onShowProfileEdit;
  final void Function(BuildContext) onShowAddressManager;
  final void Function(BuildContext, UserProvider) onShowLogout;
  final void Function(BuildContext) onShowChangePassword;
  final void Function(BuildContext, UserProvider) onShowDeleteAccount;

  const _PcSettingsTab({
    required this.userProvider, required this.loc,
    required this.onShowProfileEdit, required this.onShowAddressManager, required this.onShowLogout,
    required this.onShowChangePassword, required this.onShowDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;

    return Column(
      children: [
        _PcTabHeader(icon: Icons.settings_rounded, title: loc.settings, color: Colors.blueGrey),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PcSettingSection(
                  title: loc.mypageProfileSection,
                  items: [
                    _PcSettingItem(icon: Icons.person_rounded, title: loc.mypageEditProfile,
                      onTap: user != null ? () => onShowProfileEdit(context, user) : null),
                    _PcSettingItem(icon: Icons.location_on_rounded, title: loc.mypageAddressBook,
                      onTap: () => onShowAddressManager(context)),
                  ],
                ),
                const SizedBox(height: 20),
                _PcSettingSection(
                  title: loc.mypageNotificationSection,
                  items: [
                    _PcSettingItem(icon: Icons.notifications_rounded, title: loc.mypageNotifOrder,
                      trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: const Color(0xFF1565C0))),
                    _PcSettingItem(icon: Icons.campaign_rounded, title: loc.mypageNotifMarketing,
                      trailing: Switch(value: false, onChanged: (_) {}, activeThumbColor: const Color(0xFF1565C0))),
                  ],
                ),
                const SizedBox(height: 20),
                _PcSettingSection(
                  title: loc.mypageAppSection,
                  items: [
                    _PcSettingItem(icon: Icons.language_rounded, title: loc.mypageLanguageSetting,
                      trailing: _LanguageDropdown()),
                    const _PcSettingItem(icon: Icons.info_outline_rounded, title: '앱 정보', subtitle: 'v1.0.0'),
                  ],
                ),
                const SizedBox(height: 20),
                _PcSettingSection(
                  title: '약관 및 정책',
                  items: [
                    _PcSettingItem(
                      icon: Icons.privacy_tip_outlined,
                      title: '개인정보처리방침',
                      onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                    ),
                    _PcSettingItem(
                      icon: Icons.description_outlined,
                      title: '이용약관',
                      onTap: () => Navigator.pushNamed(context, '/terms-of-service'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (user != null)
                  _PcSettingSection(
                    title: loc.mypageSecuritySection,
                    items: [
                      _PcSettingItem(icon: Icons.lock_rounded, title: loc.mypageChangePassword,
                        onTap: () => onShowChangePassword(context)),
                      _PcSettingItem(icon: Icons.logout_rounded, title: loc.mypageLogout,
                        onTap: () => onShowLogout(context, userProvider), color: Colors.orange),
                      _PcSettingItem(icon: Icons.delete_outline_rounded, title: loc.mypageDeleteAccount,
                        onTap: () => onShowDeleteAccount(context, userProvider), color: Colors.red),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return DropdownButton<AppLanguage>(
      value: lang.language,
      underline: const SizedBox(),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      items: AppLanguage.values.map((l) {
        final labels = {AppLanguage.korean: '한국어', AppLanguage.english: 'English', AppLanguage.japanese: '日本語', AppLanguage.chinese: '中文', AppLanguage.mongolian: 'Монгол'};
        return DropdownMenuItem(value: l, child: Text(labels[l] ?? l.name));
      }).toList(),
      onChanged: (v) { if (v != null) lang.setLanguage(v); },
    );
  }
}

class _PcSettingSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _PcSettingSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: List.generate(items.length, (i) => Column(
              children: [
                items[i],
                if (i < items.length - 1) Divider(height: 1, indent: 52, color: Colors.grey[100]),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

class _PcSettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const _PcSettingItem({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[800]!;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: (color ?? Colors.blueGrey).withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: c),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, color: c, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]) : null),
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 모바일 버전 마이페이지
// ═══════════════════════════════════════════════════════════════════
class _MobileMyPage extends StatelessWidget {
  final TabController tabController;
  final UserProvider userProvider;
  final VoidCallback? onBack; // 탭0(홈)으로 돌아가기 콜백
  final void Function(OrderModel) onShowAdditionalOrder;
  final void Function(OrderModel) onShowColorEdit;
  final void Function(BuildContext, UserModel) onShowProfileEdit;
  final void Function(BuildContext) onShowAddressManager;
  final void Function(BuildContext, UserProvider) onShowLogout;
  final void Function(BuildContext) onShowChangePassword;
  final void Function(BuildContext, UserProvider) onShowDeleteAccount;

  const _MobileMyPage({
    required this.tabController,
    required this.userProvider,
    this.onBack,
    required this.onShowAdditionalOrder,
    required this.onShowColorEdit,
    required this.onShowProfileEdit,
    required this.onShowAddressManager,
    required this.onShowLogout,
    required this.onShowChangePassword,
    required this.onShowDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1A1A1A)),
                onPressed: onBack,
                tooltip: '이전으로',
              )
            : Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1A1A1A)),
                    onPressed: () => Navigator.pop(context),
                    tooltip: '이전으로',
                  )
                : null,
        automaticallyImplyLeading: false,
        title: const Text('마이페이지', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 프로필 헤더
            _MobileProfileHeader(user: user, loc: loc, userProvider: userProvider,
              onShowProfileEdit: onShowProfileEdit, onShowLogout: onShowLogout),
            // 빠른 통계
            _MobileQuickStats(user: user, loc: loc, tabController: tabController),
            // 탭바
            Container(
              color: Colors.white,
              child: TabBar(
                controller: tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: const Color(0xFF1565C0),
                labelColor: const Color(0xFF1565C0),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: loc.myOrders),
                  Tab(text: loc.mypagePaymentHistory),
                  Tab(text: loc.wishlist),
                  Tab(text: loc.mypageCouponBox),
                  Tab(text: loc.settings),
                ],
              ),
            ),
            // 콘텐츠
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _MobileOrderHistoryTab(userProvider: userProvider, loc: loc,
                    onAdditionalOrder: onShowAdditionalOrder, onColorEdit: onShowColorEdit),
                  _MobilePaymentHistoryTab(userProvider: userProvider, loc: loc),
                  _MobileWishlistTab(userProvider: userProvider, loc: loc),
                  _MobileCouponTab(userProvider: userProvider, loc: loc),
                  _MobileSettingsTab(userProvider: userProvider, loc: loc,
                    onShowProfileEdit: onShowProfileEdit,
                    onShowAddressManager: onShowAddressManager,
                    onShowLogout: onShowLogout,
                    onShowChangePassword: onShowChangePassword,
                    onShowDeleteAccount: onShowDeleteAccount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 모바일 프로필 헤더 ──
class _MobileProfileHeader extends StatelessWidget {
  final UserModel? user;
  final AppLocalizations loc;
  final UserProvider userProvider;
  final void Function(BuildContext, UserModel) onShowProfileEdit;
  final void Function(BuildContext, UserProvider) onShowLogout;

  const _MobileProfileHeader({
    required this.user, required this.loc, required this.userProvider,
    required this.onShowProfileEdit, required this.onShowLogout,
  });

  @override
  Widget build(BuildContext context) {
    final tier = user?.memberTier ?? 'bronze';
    final tierColor = _tierColor(tier);
    final tierLabel = _tierLabel(tier, loc);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: user == null
                  ? Text(loc.mypageLoginPrompt, style: const TextStyle(color: Colors.white70, fontSize: 14))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(user!.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: tierColor.withValues(alpha:0.3), borderRadius: BorderRadius.circular(10)),
                              child: Text(tierLabel, style: TextStyle(color: tierColor, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        Text(user!.email, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
              ),
              if (user != null)
                IconButton(
                  onPressed: () => onShowProfileEdit(context, user!),
                  icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
                ),
            ],
          ),
          if (user != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _InfoChip(icon: Icons.star_rounded, label: '${_fmt(user!.points ?? 0)} P', color: Colors.amber)),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => onShowLogout(context, userProvider),
                  child: _InfoChip(icon: Icons.logout_rounded, label: loc.mypageLogout, color: Colors.red[300]!),
                )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _tierLabel(String tier, AppLocalizations loc) {
    switch (tier) {
      case 'silver': return loc.mypageTierSilver;
      case 'gold': return loc.mypageTierGold;
      case 'vip': return loc.mypageTierVip;
      default: return loc.mypageTierBronze;
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'silver': return Colors.blueGrey[200]!;
      case 'gold': return Colors.amber[400]!;
      case 'vip': return Colors.purple[300]!;
      default: return Colors.brown[300]!;
    }
  }

  String _fmt(int n) =>
    n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]},');
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.12), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── 모바일 빠른 통계 ──
class _MobileQuickStats extends StatelessWidget {
  final UserModel? user;
  final AppLocalizations loc;
  final TabController tabController;

  const _MobileQuickStats({required this.user, required this.loc, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = user != null ? orderProvider.getUserOrders(user!.id) : <OrderModel>[];
    final wishCount = user?.wishlist.length ?? 0;
    final couponCount = user?.coupons.where((c) => c.isValid).length ?? 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _MobileStatItem(label: loc.myOrders, count: orders.length, onTap: () => tabController.animateTo(0)),
          _VertDiv(),
          _MobileStatItem(label: loc.wishlist, count: wishCount, onTap: () => tabController.animateTo(2)),
          _VertDiv(),
          _MobileStatItem(label: loc.mypageCouponBox, count: couponCount, onTap: () => tabController.animateTo(3)),
          _VertDiv(),
          _MobileStatItem(label: loc.mypagePoints, count: user?.points ?? 0, onTap: () => tabController.animateTo(4)),
        ],
      ),
    );
  }
}

class _MobileStatItem extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  const _MobileStatItem({required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _VertDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, height: 24, color: Colors.grey[200]);
}

// ═══════════════════════════════════════════════════════
// 모바일 주문 내역 탭
// ═══════════════════════════════════════════════════════
class _MobileOrderHistoryTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  final void Function(OrderModel) onAdditionalOrder;
  final void Function(OrderModel) onColorEdit;

  const _MobileOrderHistoryTab({
    required this.userProvider, required this.loc,
    required this.onAdditionalOrder, required this.onColorEdit,
  });

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;
    if (user == null) return _MobileEmptyState(icon: Icons.login_rounded, message: loc.mypageLoginPrompt);

    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.getUserOrders(user.id);

    if (orders.isEmpty) {
      return _MobileEmptyState(icon: Icons.receipt_long_outlined, message: loc.mypageNoOrders, subtitle: loc.mypageFirstOrder);
    }

    return RefreshIndicator(
      onRefresh: () => orderProvider.loadUserOrders(user.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (_, i) => _MobileOrderCard(
          order: orders[i], loc: loc,
          onAdditionalOrder: onAdditionalOrder, onColorEdit: onColorEdit,
        ),
      ),
    );
  }
}

class _MobileOrderCard extends StatelessWidget {
  final OrderModel order;
  final AppLocalizations loc;
  final void Function(OrderModel) onAdditionalOrder;
  final void Function(OrderModel) onColorEdit;

  const _MobileOrderCard({required this.order, required this.loc, required this.onAdditionalOrder, required this.onColorEdit});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final isGroup = order.orderType == 'group_custom';
    final isActive = order.status != OrderStatus.cancelled && order.status != OrderStatus.refunded;
    final canColorEdit = isGroup && isActive && (order.colorEditCount ?? 0) < 3;
    final canAdditional = isGroup && isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(child: Text(order.id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)))),
                if (isGroup) Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.purple.withValues(alpha:0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(loc.groupCustom, style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(order.status.label, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 상품
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.checkroom_rounded, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.items.isNotEmpty)
                        Text(order.items.first.productName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (order.items.length > 1)
                        Text(loc.mypageMoreItems.replaceAll('{n}', '${order.items.length - 1}'),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      const SizedBox(height: 4),
                      Text(_fmtPrice(order.totalAmount),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
                      Text(_fmtDate(order.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 버튼
          if (isActive && (canAdditional || canColorEdit))
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (canAdditional) Expanded(child: _MobileBtn(
                    label: loc.mypageAdditionalProduction,
                    color: const Color(0xFF2E7D32),
                    onTap: () => onAdditionalOrder(order),
                  )),
                  if (canAdditional && canColorEdit) const SizedBox(width: 8),
                  if (canColorEdit) Expanded(child: _MobileBtn(
                    label: loc.mypageColorGroupEdit,
                    color: const Color(0xFF1565C0),
                    badge: '${3 - (order.colorEditCount ?? 0)}',
                    onTap: () => onColorEdit(order),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.processing: return const Color(0xFF7B1FA2);
      case OrderStatus.shipped: return const Color(0xFF00838F);
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      case OrderStatus.refunded: return Colors.brown;
    }
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y.$m.$dd';
  }
  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf원';
  }
}

class _MobileBtn extends StatelessWidget {
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _MobileBtn({required this.label, required this.color, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                width: 16, height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(child: Text(badge!, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 모바일 결제 내역 탭
// ═══════════════════════════════════════════════════════
class _MobilePaymentHistoryTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;

  const _MobilePaymentHistoryTab({required this.userProvider, required this.loc});

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;
    final orderProvider = context.watch<OrderProvider>();
    final orders = user != null ? orderProvider.getUserOrders(user.id) : <OrderModel>[];

    if (orders.isEmpty) return _MobileEmptyState(icon: Icons.payment_outlined, message: loc.mypageNoPayment);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFF00796B).withValues(alpha:0.1), shape: BoxShape.circle),
                child: const Icon(Icons.payment_rounded, size: 22, color: Color(0xFF00796B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(o.paymentMethod ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(_fmtDate(o.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Text(_fmtPrice(o.totalAmount),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF00796B))),
            ],
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y.$m.$dd';
  }
  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf원';
  }
}

// ═══════════════════════════════════════════════════════
// 모바일 찜 목록 탭
// ═══════════════════════════════════════════════════════
class _MobileWishlistTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;

  const _MobileWishlistTab({required this.userProvider, required this.loc});

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;
    final wishIds = user?.wishlist ?? [];
    final products = wishIds
        .map((id) => ProductService.getProductById(id))
        .where((p) => p != null)
        .cast<ProductModel>()
        .toList();

    if (products.isEmpty) {
      return _MobileEmptyState(icon: Icons.favorite_border_rounded, message: loc.mypageNoWishlist, subtitle: loc.mypageNoWishlistSub);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 8)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(p.images.first, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.checkroom_rounded))),
                      ),
                      Positioned(top: 6, right: 6,
                        child: GestureDetector(
                          onTap: () => userProvider.toggleWishlist(p.id),
                          child: Container(width: 26, height: 26,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.favorite_rounded, size: 14, color: Colors.pinkAccent)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Text(_fmtPrice(p.price.toDouble()), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1565C0))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '$buf원';
  }
}

// ═══════════════════════════════════════════════════════
// 모바일 쿠폰함 탭
// ═══════════════════════════════════════════════════════
class _MobileCouponTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;

  const _MobileCouponTab({required this.userProvider, required this.loc});

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;
    final coupons = user?.coupons ?? [];

    if (coupons.isEmpty) return _MobileEmptyState(icon: Icons.local_activity_outlined, message: loc.mypageNoCoupons);

    final valid = coupons.where((c) => c.isValid).toList();
    final used = coupons.where((c) => c.isUsed).toList();
    final expired = coupons.where((c) => !c.isValid && !c.isUsed).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (valid.isNotEmpty) ...[
          _MobileCouponSectionTitle(title: loc.mypageAvailableCoupon, count: valid.length, color: const Color(0xFF2E7D32)),
          const SizedBox(height: 8),
          ...valid.map((c) => _MobileCouponCard(coupon: c, loc: loc, color: const Color(0xFF2E7D32))),
          const SizedBox(height: 16),
        ],
        if (used.isNotEmpty) ...[
          _MobileCouponSectionTitle(title: loc.mypageUsedCoupon, count: used.length, color: Colors.grey),
          const SizedBox(height: 8),
          ...used.map((c) => _MobileCouponCard(coupon: c, loc: loc, color: Colors.grey, dimmed: true)),
          const SizedBox(height: 16),
        ],
        if (expired.isNotEmpty) ...[
          _MobileCouponSectionTitle(title: loc.mypageExpiredCoupon, count: expired.length, color: Colors.red),
          const SizedBox(height: 8),
          ...expired.map((c) => _MobileCouponCard(coupon: c, loc: loc, color: Colors.red, dimmed: true)),
        ],
      ],
    );
  }
}

class _MobileCouponSectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _MobileCouponSectionTitle({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: color, margin: const EdgeInsets.only(right: 6)),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Text('($count)', style: TextStyle(fontSize: 12, color: color.withValues(alpha:0.7))),
      ],
    );
  }
}

class _MobileCouponCard extends StatelessWidget {
  final CouponModel coupon;
  final AppLocalizations loc;
  final Color color;
  final bool dimmed;

  const _MobileCouponCard({required this.coupon, required this.loc, required this.color, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final discountText = coupon.type == 'percent'
        ? '${coupon.value.toInt()}%'
        : '${coupon.value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]},')}원';

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: dimmed ? Colors.grey[100] : color.withValues(alpha:0.1),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  Icon(Icons.local_activity_rounded, color: dimmed ? Colors.grey : color, size: 20),
                  const SizedBox(height: 4),
                  Text(discountText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: dimmed ? Colors.grey : color)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coupon.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${loc.mypageCouponExpiry}: ${_fmtDate(coupon.expiresAt)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y.$m.$dd';
  }
}

// ═══════════════════════════════════════════════════════
// 모바일 설정 탭
// ═══════════════════════════════════════════════════════
class _MobileSettingsTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  final void Function(BuildContext, UserModel) onShowProfileEdit;
  final void Function(BuildContext) onShowAddressManager;
  final void Function(BuildContext, UserProvider) onShowLogout;
  final void Function(BuildContext) onShowChangePassword;
  final void Function(BuildContext, UserProvider) onShowDeleteAccount;

  const _MobileSettingsTab({
    required this.userProvider, required this.loc,
    required this.onShowProfileEdit, required this.onShowAddressManager, required this.onShowLogout,
    required this.onShowChangePassword, required this.onShowDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MobileSettingGroup(title: loc.mypageProfileSection, items: [
          _MobileSettingItem(icon: Icons.person_rounded, title: loc.mypageEditProfile,
            onTap: user != null ? () => onShowProfileEdit(context, user) : null),
          _MobileSettingItem(icon: Icons.location_on_rounded, title: loc.mypageAddressBook,
            onTap: () => onShowAddressManager(context)),
        ]),
        const SizedBox(height: 16),
        _MobileSettingGroup(title: loc.mypageNotificationSection, items: [
          _MobileSwitchItem(icon: Icons.notifications_rounded, title: loc.mypageNotifOrder, value: true, onChanged: (_) {}),
          _MobileSwitchItem(icon: Icons.campaign_rounded, title: loc.mypageNotifMarketing, value: false, onChanged: (_) {}),
        ]),
        const SizedBox(height: 16),
        _MobileSettingGroup(title: loc.mypageAppSection, items: [
          _MobileSettingItem(icon: Icons.language_rounded, title: loc.mypageLanguageSetting,
            trailing: _LanguageDropdown()),
          const _MobileSettingItem(icon: Icons.info_outline_rounded, title: '앱 정보', subtitle: 'v1.0.0'),
        ]),
        const SizedBox(height: 16),
        _MobileSettingGroup(title: '약관 및 정책', items: [
          _MobileSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보처리방침',
            onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
          ),
          _MobileSettingItem(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () => Navigator.pushNamed(context, '/terms-of-service'),
          ),
        ]),
        if (user != null) ...[          const SizedBox(height: 16),
          _MobileSettingGroup(title: loc.mypageSecuritySection, items: [
            _MobileSettingItem(icon: Icons.lock_rounded, title: loc.mypageChangePassword,
              onTap: () => onShowChangePassword(context)),
            _MobileSettingItem(icon: Icons.logout_rounded, title: loc.mypageLogout,
              onTap: () => onShowLogout(context, userProvider), color: Colors.orange),
            _MobileSettingItem(icon: Icons.delete_outline_rounded, title: loc.mypageDeleteAccount,
              onTap: () => onShowDeleteAccount(context, userProvider), color: Colors.red),
          ]),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

class _MobileSettingGroup extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _MobileSettingGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8)],
          ),
          child: Column(
            children: List.generate(items.length, (i) => Column(
              children: [
                items[i],
                if (i < items.length - 1) const Divider(height: 1, indent: 50),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

class _MobileSettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const _MobileSettingItem({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[800]!;
    return ListTile(
      dense: true,
      leading: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: (color ?? Colors.blueGrey).withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: c),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, color: c)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[400]) : null),
      onTap: onTap,
    );
  }
}

class _MobileSwitchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _MobileSwitchItem({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: Colors.blueGrey),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: const Color(0xFF1565C0), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 공통 빈 상태 (모바일)
// ═══════════════════════════════════════════════════════
class _MobileEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const _MobileEmptyState({required this.icon, required this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey[400]), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 프로필 수정 시트
// ═══════════════════════════════════════════════════════
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
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
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
                      builder: (_) => const GroupOrderFormScreen(
                        product: null,
                        isAdditionalOrder: true,
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

  void _submit() {
    if (_selectedColorName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loc.selectColor2)),
      );
      return;
    }
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
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
                    onPressed: _submit,
                    icon: const Icon(Icons.send_rounded, size: 16),
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
    final loc = context.watch<LanguageProvider>().loc;
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
    final loc = context.watch<LanguageProvider>().loc;
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
                            final result = await showKakaoAddressSearch(context);
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
