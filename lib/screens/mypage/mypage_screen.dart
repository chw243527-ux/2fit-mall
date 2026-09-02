import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/net_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/account_deletion_service.dart';
import '../../services/email_service.dart';
import '../../services/wishlist_coupon_service.dart';
import '../../services/point_service.dart';
import '../../utils/theme.dart';
import '../../widgets/design_revision_countdown.dart';
// order_excel_service: 마이페이지 엑셀 기능 제거 — 관리자 대시보드에서만 관리
import '../../utils/web_utils.dart'
    if (dart.library.html) '../../utils/web_utils_html.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MyPageScreen extends StatefulWidget {
  final VoidCallback? onBack; // 홈(탭0)으로 돌아가는 콜백
  const MyPageScreen({super.key, this.onBack});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ignore: unused_element
  AppLocalizations get _loc => context.watch<LanguageProvider>().loc;

  /// 마이페이지 탭을 "내 주문"(index=0)으로 리셋.
  /// IndexedStack 구조에서 탭 전환 시 main_screen이 호출.
  void resetToFirstTab() {
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
    // 이전 화면에서 남아있는 스낵바 제거
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // 앱 시작 시 실제 주문 데이터 로드 + 이전 화면의 스낵바 큐 클리어
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 언어 변경 시 번역 트리거
      context.read<LanguageProvider>().triggerTranslation();

      if (!mounted) return;
      // 이전 화면(결제 완료 등)에서 남아있는 스낵바 제거
      ScaffoldMessenger.of(context).clearSnackBars();
      final user = context.read<UserProvider>().user;
      if (user != null) {
        context.read<OrderProvider>().loadUserOrders(user.id);
      }
    });
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
        onShowProfileEdit: _showProfileEdit,
        onShowAddressManager: _showAddressManager,
        onShowLogout: _showLogoutDialog,
        onShowChangePassword: _showChangePasswordDialog,
        onShowDeleteAccount: _showDeleteAccountDialog,
        onShowDesignRevision: _showDesignRevisionSheet,
        onShowDesignConfirm: _showDesignConfirmSheet,
      );
    }
    return _MobileMyPage(
      tabController: _tabController,
      userProvider: userProvider,
      onBack: widget.onBack,
      onShowAdditionalOrder: _showAdditionalOrderSheet,
      onShowProfileEdit: _showProfileEdit,
      onShowAddressManager: _showAddressManager,
      onShowLogout: _showLogoutDialog,
      onShowChangePassword: _showChangePasswordDialog,
      onShowDeleteAccount: _showDeleteAccountDialog,
      onShowDesignRevision: _showDesignRevisionSheet,
      onShowDesignConfirm: _showDesignConfirmSheet,
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

  void _showDesignRevisionSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DesignRevisionSheet(order: order),
    );
  }

  void _showDesignConfirmSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DesignConfirmSheet(order: order),
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
    // 이미 비로그인 상태면 바로 로그인 화면으로 이동
    if (up.user == null) {
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.logout_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 8),
          Text(context.read<LanguageProvider>().loc.mypageLogout,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
        content: Text(context.loc.t('로그아웃_하시겠습니까', '로그아웃 하시겠습니까?'),
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.read<LanguageProvider>().loc.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              up.logout();
              if (ctx.mounted) {
                ctx.read<SizeProfileProvider>().clear();
                ctx.read<CartProvider>().clearCart();
                ctx.read<CouponProvider>().clear();
                ctx.read<PointProvider>().clear();
                Navigator.of(ctx).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(context.read<LanguageProvider>().loc.mypageLogout),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.lock_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(context.loc.t('비밀번호_변경', '비밀번호 변경'),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.loc.t('현재_비밀번호', '현재 비밀번호'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.loc.t('새_비밀번호__6자_이상', '새 비밀번호 (6자 이상)'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.loc.t('새_비밀번호_확인', '새 비밀번호 확인'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(errorMsg!,
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: Text(context.loc.t('취소', '취소')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        setD(() => errorMsg = context.loc
                            .t('새_비밀번호가_일치하지_않습니다', '새 비밀번호가 일치하지 않습니다.'));
                        return;
                      }
                      if (newCtrl.text.length < 6) {
                        setD(() => errorMsg = context.loc
                            .t('비밀번호는_6자_이상이어야_합니다', '비밀번호는 6자 이상이어야 합니다.'));
                        return;
                      }
                      setD(() {
                        isLoading = true;
                        errorMsg = null;
                      });
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
                            SnackBar(
                                content: Text(context.loc
                                    .t('비밀번호가 변경되었습니다', '비밀번호가 변경되었습니다.')),
                                backgroundColor: AppColors.primary),
                          );
                        }
                      } else {
                        setD(() {
                          isLoading = false;
                          errorMsg = context.loc
                              .t('현재_비밀번호가_올바르지_않습니다', '현재 비밀번호가 올바르지 않습니다.');
                        });
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(context.loc.t('변경', '변경')),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext ctx, UserProvider up) {
    bool isLoading = false;
    String? errorMsg;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.warning_rounded, color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text(context.loc.t('회원_탈퇴', '회원 탈퇴'),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.error)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc.t('계정_삭제_안내',
                    '탈퇴하면 로그인 계정, 채팅, 알림, 리뷰, 사이즈 정보와 개인 설정이 삭제되며 복구할 수 없습니다.'),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 10),
              Text(
                context.loc.t('계정_삭제_보존_안내',
                    '주문·결제 및 교환·반품 기록은 관련 법령과 분쟁 처리 목적에 따라 필요한 항목만 익명화하여 보관될 수 있습니다.'),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(errorMsg!,
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
              child: Text(context.loc.t('취소', '취소')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setD(() {
                        isLoading = true;
                        errorMsg = null;
                      });

                      final result =
                          await AccountDeletionService.deleteCurrentAccount();
                      if (!dialogCtx.mounted) return;

                      if (!result.success) {
                        setD(() {
                          isLoading = false;
                          errorMsg = result.errorMessage ??
                              dialogCtx.loc.t(
                                  '탈퇴_처리_중_오류가_발생했습니다', '탈퇴 처리 중 오류가 발생했습니다.');
                        });
                        return;
                      }

                      Navigator.pop(dialogCtx);
                      await AuthService.logout();
                      if (!ctx.mounted) return;
                      up.logout();
                      ctx.read<CartProvider>().clearCart();
                      ctx.read<SizeProfileProvider>().clear();
                      ctx.read<CouponProvider>().clear();
                      ctx.read<PointProvider>().clear();
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(ctx.loc
                              .t('회원 탈퇴가 완료되었습니다', '회원 탈퇴가 완료되었습니다.')),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(context.loc.t('탈퇴하기', '탈퇴하기')),
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
  final void Function(BuildContext, UserModel) onShowProfileEdit;
  final void Function(BuildContext) onShowAddressManager;
  final void Function(BuildContext, UserProvider) onShowLogout;
  final void Function(BuildContext) onShowChangePassword;
  final void Function(BuildContext, UserProvider) onShowDeleteAccount;
  final void Function(OrderModel)? onShowDesignRevision;
  final void Function(OrderModel)? onShowDesignConfirm;

  const _PcMyPage({
    required this.tabController,
    required this.userProvider,
    required this.onShowAdditionalOrder,
    required this.onShowProfileEdit,
    required this.onShowAddressManager,
    required this.onShowLogout,
    required this.onShowChangePassword,
    required this.onShowDeleteAccount,
    this.onShowDesignRevision,
    this.onShowDesignConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final user = userProvider.user;
    final screenH = MediaQuery.of(context).size.height;
    const sideW = 260.0;

    final menuItems = [
      (Icons.receipt_long_rounded, loc.myOrders),
      (Icons.favorite_rounded, loc.wishlist),
      (Icons.local_activity_rounded, context.loc.t('쿠폰함', '쿠폰함')),
      (Icons.stars_rounded, context.loc.t('포인트', '포인트')),
      (Icons.settings_rounded, loc.settings),
    ];

    return Container(
      color: const Color(0xFFF3F0F7),
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
                      _PcProfileCard(
                          user: user,
                          loc: loc,
                          onShowProfileEdit: onShowProfileEdit),
                      const SizedBox(height: 12),
                      _PcQuickStats(
                          user: user, loc: loc, tabController: tabController),
                      const SizedBox(height: 12),
                      // 메뉴
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
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
                                    top: i == 0
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                    bottom: isLast
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                  ),
                                  onTap: () => tabController.animateTo(i),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.primary
                                              .withValues(alpha: 0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.vertical(
                                        top: i == 0
                                            ? const Radius.circular(16)
                                            : Radius.zero,
                                        bottom: isLast
                                            ? const Radius.circular(16)
                                            : Radius.zero,
                                      ),
                                      border: Border(
                                        left: BorderSide(
                                          color: sel
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(menuItems[i].$1,
                                            size: 20,
                                            color: sel
                                                ? AppColors.primary
                                                : Colors.grey[600]),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            menuItems[i].$2,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: sel
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: sel
                                                  ? AppColors.primary
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                        if (sel)
                                          const Icon(
                                              Icons.chevron_right_rounded,
                                              size: 16,
                                              color: AppColors.primary),
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
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminScreen())),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.admin_panel_settings_rounded,
                                      size: 18, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text(context.loc.t('관리자_페이지', '관리자 페이지'),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // 로그아웃 (항상 표시)
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
                              border: Border.all(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.4)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8)
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout_rounded,
                                    size: 18, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Text(loc.mypageLogout,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600)),
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
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedBuilder(
                        animation: tabController,
                        builder: (_, __) {
                          switch (tabController.index) {
                            case 0:
                              return _PcOrderHistoryTab(
                                  userProvider: userProvider,
                                  loc: loc,
                                  onAdditionalOrder: onShowAdditionalOrder,
                                  onDesignRevision: onShowDesignRevision,
                                  onDesignConfirm: onShowDesignConfirm);
                            case 1:
                              return _PcWishlistTab(
                                  userProvider: userProvider, loc: loc);
                            case 2:
                              return _PcCouponTab(
                                  userProvider: userProvider, loc: loc);
                            case 3:
                              return _PcPointTab(
                                  userProvider: userProvider, loc: loc);
                            case 4:
                              return _PcSettingsTab(
                                  userProvider: userProvider,
                                  loc: loc,
                                  onShowProfileEdit: onShowProfileEdit,
                                  onShowAddressManager: onShowAddressManager,
                                  onShowLogout: onShowLogout,
                                  onShowChangePassword: onShowChangePassword,
                                  onShowDeleteAccount: onShowDeleteAccount);
                            default:
                              return const SizedBox();
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

  const _PcProfileCard(
      {required this.user, required this.loc, required this.onShowProfileEdit});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF2D2B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: const Icon(Icons.person_outline_rounded,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(loc.mypageLoginPrompt,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final tier = _tierLabel(user!.memberTier, loc);
    final tierColor = _tierColor(user!.memberTier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2D2B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded,
                    size: 32, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user!.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: tierColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(tier,
                          style: TextStyle(
                              color: tierColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onShowProfileEdit(context, user!),
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _tierLabel(String tier, AppLocalizations loc) {
    switch (tier) {
      case 'silver':
        return loc.mypageTierSilver;
      case 'gold':
        return loc.mypageTierGold;
      case 'vip':
        return loc.mypageTierVip;
      default:
        return loc.mypageTierBronze;
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'silver':
        return AppColors.textSecondary.withValues(alpha: 0.20);
      case 'gold':
        return Colors.amber[400]!;
      case 'vip':
        return AppColors.primary.withValues(alpha: 0.30);
      default:
        return Colors.brown[300]!;
    }
  }

  String _fmt(int n) {
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '\${m[1]},');
  }
}

// ── PC 빠른 통계 ──
class _PcQuickStats extends StatelessWidget {
  final UserModel? user;
  final AppLocalizations loc;
  final TabController tabController;

  const _PcQuickStats(
      {required this.user, required this.loc, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders =
        user != null ? orderProvider.getUserOrders(user!.id) : <OrderModel>[];
    final wishCount = user?.wishlist.length ?? 0;
    final couponCount = context.watch<CouponProvider>().validCoupons.length;
    final pointBalance = context.watch<PointProvider>().balance;

    String _fmtNum(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          _StatItem(
              label: loc.myOrders,
              count: orders.length,
              onTap: () => tabController.animateTo(0)),
          _Divider(),
          _StatItem(
              label: loc.wishlist,
              count: wishCount,
              onTap: () => tabController.animateTo(1)),
          _Divider(),
          _StatItem(
            label: context.loc.t('쿠폰', '쿠폰'),
            countLabel: '$couponCount장',
            onTap: () => tabController.animateTo(2),
          ),
          _Divider(),
          _StatItem(
            label: context.loc.t('포인트', '포인트'),
            countLabel: '${_fmtNum(pointBalance)}P',
            onTap: () => tabController.animateTo(3),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int? count;
  final String? countLabel; // count 대신 직접 문자열 지정 (쿠폰: '3장', 포인트: '1,200P')
  final VoidCallback onTap;
  const _StatItem(
      {required this.label, this.count, this.countLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final display = countLabel ?? '${count ?? 0}';
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text(display,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

  const _PcTabHeader(
      {required this.icon,
      required this.title,
      required this.color,
      this.badge,
      this.onRefresh});

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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(badge!,
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w700)),
            ),
          ],
          const Spacer(),
          if (onRefresh != null)
            IconButton(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh_rounded, color: color)),
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

  const _PcEmptyState(
      {required this.icon, required this.message, this.subtitle});

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
            Text(message,
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

enum _OrderHistoryFilter { all, readyMade, group, additional }

bool _isAdditionalOrder(OrderModel order) => order.isAdditionalOrder;

bool _isGroupOrderForFilter(OrderModel order) =>
    order.isGroupOrder && !_isAdditionalOrder(order);

bool _isReadyMadeOrderForFilter(OrderModel order) =>
    !_isGroupOrderForFilter(order) && !_isAdditionalOrder(order);

List<OrderModel> _filterOrderHistory(
    List<OrderModel> orders, _OrderHistoryFilter filter) {
  switch (filter) {
    case _OrderHistoryFilter.readyMade:
      return orders.where(_isReadyMadeOrderForFilter).toList();
    case _OrderHistoryFilter.group:
      return orders.where(_isGroupOrderForFilter).toList();
    case _OrderHistoryFilter.additional:
      return orders.where(_isAdditionalOrder).toList();
    case _OrderHistoryFilter.all:
      return orders;
  }
}

class _OrderHistoryFilterBar extends StatelessWidget {
  final List<OrderModel> orders;
  final _OrderHistoryFilter selected;
  final ValueChanged<_OrderHistoryFilter> onChanged;

  const _OrderHistoryFilterBar({
    required this.orders,
    required this.selected,
    required this.onChanged,
  });

  int _count(_OrderHistoryFilter filter) =>
      _filterOrderHistory(orders, filter).length;

  @override
  Widget build(BuildContext context) {
    final filters = <(_OrderHistoryFilter, String)>[
      (_OrderHistoryFilter.all, '전체'),
      (_OrderHistoryFilter.readyMade, '일반 기성품'),
      (_OrderHistoryFilter.group, '단체주문'),
      (_OrderHistoryFilter.additional, '추가제작'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${filter.$2} ${_count(filter.$1)}'),
                selected: selected == filter.$1,
                onSelected: (_) => onChanged(filter.$1),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected == filter.$1
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected == filter.$1
                      ? AppColors.primary
                      : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// PC 주문 내역 탭
// ═══════════════════════════════════════════════════════
class _PcOrderHistoryTab extends StatefulWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  final void Function(OrderModel) onAdditionalOrder;
  final void Function(OrderModel)? onDesignRevision;
  final void Function(OrderModel)? onDesignConfirm;

  const _PcOrderHistoryTab({
    required this.userProvider,
    required this.loc,
    required this.onAdditionalOrder,
    this.onDesignRevision,
    this.onDesignConfirm,
  });

  @override
  State<_PcOrderHistoryTab> createState() => _PcOrderHistoryTabState();
}

class _PcOrderHistoryTabState extends State<_PcOrderHistoryTab> {
  bool _initialLoadDone = false;
  _OrderHistoryFilter _selectedFilter = _OrderHistoryFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = widget.userProvider.user;
      if (user != null) {
        context.read<OrderProvider>().loadUserOrders(user.id).then((_) {
          if (mounted) setState(() => _initialLoadDone = true);
        });
      } else {
        setState(() => _initialLoadDone = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userProvider.user;
    if (user == null) {
      return Column(children: [
        _PcTabHeader(
            icon: Icons.receipt_long_rounded,
            title: widget.loc.myOrders,
            color: AppColors.primary),
        Expanded(
            child: _PcEmptyState(
                icon: Icons.login_rounded,
                message: widget.loc.mypageLoginPrompt)),
      ]);
    }

    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.getUserOrders(user.id);
    final filteredOrders = _filterOrderHistory(orders, _selectedFilter);

    return Column(
      children: [
        _PcTabHeader(
          icon: Icons.receipt_long_rounded,
          title: widget.loc.myOrders,
          color: AppColors.primary,
          badge: _selectedFilter == _OrderHistoryFilter.all
              ? '${orders.length}'
              : '${filteredOrders.length}/${orders.length}',
          onRefresh: () => orderProvider.loadUserOrders(user.id),
        ),
        if (orders.isNotEmpty)
          _OrderHistoryFilterBar(
            orders: orders,
            selected: _selectedFilter,
            onChanged: (filter) => setState(() => _selectedFilter = filter),
          ),
        Expanded(
          child: !_initialLoadDone && orders.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
                  : orders.isEmpty
                  ? _PcEmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: widget.loc.mypageNoOrders,
                      subtitle: widget.loc.mypageFirstOrder)
                  : filteredOrders.isEmpty
                      ? _PcEmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          message: '선택한 주문 구분의 주문이 없습니다.',
                          subtitle: '다른 필터를 선택해 보세요.')
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredOrders.length,
                          itemBuilder: (_, i) => _PcOrderCard(
                            order: filteredOrders[i],
                        loc: widget.loc,
                        onAdditionalOrder: widget.onAdditionalOrder,
                        onDesignRevision: widget.onDesignRevision,
                        onDesignConfirm: widget.onDesignConfirm,
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
  final void Function(OrderModel)? onDesignRevision;
  final void Function(OrderModel)? onDesignConfirm;

  const _PcOrderCard(
      {required this.order,
      required this.loc,
      required this.onAdditionalOrder,
      this.onDesignRevision,
      this.onDesignConfirm});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final isGroup = order.orderType == 'group' ||
        order.orderType == 'additional' ||
        order.id.startsWith('GRP_') ||
        order.id.startsWith('GROUP-');
    final isActive = order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.refunded;
    // 추가제작: 취소/환불 아니면 배송완료 후에도 항상 가능 (같은 디자인 재주문)
    final canAdditional = isGroup && isActive;
    // 배송조회: 운송장 등록된 경우
    final trackingNumberMobile =
        (order.customOptions?['trackingNumber'] as String? ?? '').trim();
    final hasTrackingMobile = trackingNumberMobile.isNotEmpty;

    final canCancelReadyMade = !isGroup &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed);
    // 단체주문: 디자인 발송 전(designRevisionDeadline == null)이고 pending/confirmed 상태일 때만 취소 가능
    final canCancelGroup = isGroup &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed) &&
        order.designRevisionDeadline == null;
    final canCancel = canCancelReadyMade || canCancelGroup;
    // 단체주문 취소불가: 디자인이 이미 발송됐거나(designRevisionDeadline != null) processing 이상
    final cancelBlockedByDesign = isGroup &&
        !canCancelGroup &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.processing) &&
        !(order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.refunded);
    // 구매확정 여부 (수동 or 3일 자동)
    final isPurchaseConfirmed = order.isPurchaseConfirmed;
    // 배송완료 → 구매확정 버튼 표시 (운송장 유무 무관)
    final canConfirmPurchase =
        order.status == OrderStatus.delivered && !isPurchaseConfirmed;
    // 교환/반품 기간 체크: deliveredAt 기준 7일 이내 (null이면 createdAt 기준)
    final deliveredBase = order.deliveredAt ?? order.createdAt;
    final isWithin7Days =
        DateTime.now().isBefore(deliveredBase.add(const Duration(days: 7)));
    // 교환/반품: 배송완료면 7일 이내 + 구매확정 전
    //            배송중(shipped)은 운송장 있을 때만 활성 (기간 무관)
    final canExchangeReturn = !isGroup &&
        !isPurchaseConfirmed &&
        ((order.status == OrderStatus.delivered && isWithin7Days) ||
            (order.status == OrderStatus.shipped && hasTrackingMobile));
    // 리뷰쓰기: 구매확정 후
    final canWriteReview = !isGroup && isPurchaseConfirmed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── 헤더 ──
          GestureDetector(
            onTap: () {
              _showUserOrderDetail(context, order);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Text(order.id,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const SizedBox(width: 8),
                  if (isGroup)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(order.orderType == 'additional' ? '추가제작' : loc.groupCustom,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  const Spacer(),
                  Text(_fmtDate(order.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(order.status.label,
                        style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // ── 상품 목록 ──
          GestureDetector(
            onTap: () {
              _showUserOrderDetail(context, order);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...order.items.take(2).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: () {
                                final url = item.imageUrl?.isNotEmpty == true
                                    ? item.imageUrl!
                                    : (item.customOptions?['productImageUrl']
                                                    as String?)
                                                ?.isNotEmpty ==
                                            true
                                        ? item.customOptions!['productImageUrl']
                                            as String
                                        : (item.customOptions?['designFileUrl']
                                                        as String?)
                                                    ?.isNotEmpty ==
                                                true
                                            ? item.customOptions![
                                                'designFileUrl'] as String
                                            : null;
                                return url != null
                                    ? Image.network(url,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.contain)
                                    : const Icon(Icons.checkroom_rounded,
                                        color: Colors.grey, size: 28);
                              }(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                      '${item.size} / ${item.color} / ${item.quantity}개',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            Text(_fmtPrice(item.price * item.quantity),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      )),
                  if (order.items.length > 2)
                    Text(
                        loc.mypageMoreItems
                            .replaceAll('{n}', '${order.items.length - 2}'),
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
          // ── 금액 합계 ──
          GestureDetector(
            onTap: () {
              _showUserOrderDetail(context, order);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Text('${loc.mypagePaymentMethod}: ${order.paymentMethod}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  Text('${loc.mypageOrderTotal}: ',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  Text(_fmtPrice(order.totalAmount),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
          if (order.isGroupOrder && order.activeDesignRevisionDeadline != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: DesignRevisionCountdown(
                deadline: order.activeDesignRevisionDeadline,
                revisionCount: order.designRevisionCount,
                compact: true,
              ),
            ),
          ],
          // ── 버튼 행 (네이버 스타일) ──
          Container(height: 1, color: Colors.grey[100]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Builder(builder: (btnCtx) {
              Future<void> doCancel() async {
                final confirm = await showDialog<bool>(
                  context: btnCtx,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    title: Text(context.loc.t('주문_취소', '주문 취소'),
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    content: Text(isGroup
                        ? context.loc.t(
                            '단체주문을 취소하시겠습니까 디자인 수정 전에만 취소 가능합니다 결제 취소는 _6ab23e',
                            '단체주문을 취소하시겠습니까?\n디자인 수정 전에만 취소 가능합니다.\n결제 취소는 1~3 영업일 내 처리됩니다.')
                        : context.loc.t(
                            '주문을 취소하시겠습니까 발송 전에만 취소 가능합니다 결제 취소는 13 영업일_b22850',
                            '주문을 취소하시겠습니까?\n발송 전에만 취소 가능합니다.\n결제 취소는 1~3 영업일 내 처리됩니다.')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(btnCtx, false),
                          child: Text(context.loc.t('아니오', '아니오'))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(btnCtx, true),
                        child: Text(context.loc.t('취소하기', '취소하기'),
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && btnCtx.mounted) {
                  await OrderService.updateOrderStatus(
                      order.id, OrderStatus.cancelled);
                  NotificationService.sendCancelled(
                          order: order,
                          reason: context.loc.t('고객 직접 취소', '고객 직접 취소'))
                      .catchError((_) {});
                  FcmService.sendOrderStatusNotification(
                          order: order, newStatus: OrderStatus.cancelled)
                      .catchError((_) {});
                  if (btnCtx.mounted) {
                    ScaffoldMessenger.of(btnCtx).showSnackBar(
                      SnackBar(
                          content: Text(
                              context.loc.t('주문이 취소되었습니다', '주문이 취소되었습니다.')),
                          backgroundColor: AppColors.primary),
                    );
                  }
                }
              }

              Future<void> openKakaoChannel() async {
                final appUrl =
                    Uri.parse('kakaoplus://plusfriend/home/@2fit-mall');
                final webUrl = Uri.parse('https://pf.kakao.com/_MQxjXX/chat');
                if (await canLaunchUrl(appUrl)) {
                  await launchUrl(appUrl, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                }
              }

              void showContactSheet(String subject) {
                showModalBottomSheet(
                  context: btnCtx,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (sheetCtx) => Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEE500),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Center(
                                  child: Text('💬',
                                      style: TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(subject,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900)),
                                  Text('주문번호: ${order.id}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.black45),
                                      overflow: TextOverflow.ellipsis),
                                ])),
                          ]),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              openKakaoChannel();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEE500),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('💬', style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 8),
                                    Text(
                                        context.loc
                                            .t('카카오톡_채널_문의', '카카오톡 채널 문의'),
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF3A1D1D))),
                                  ]),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              launchUrl(Uri.parse('tel:01072276914'));
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF3F0F7),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone_outlined,
                                        size: 20, color: AppColors.textPrimary),
                                    SizedBox(width: 8),
                                    Text(
                                        context.loc.t('전화_문의__010_7227_140b47',
                                            '전화 문의  010-7227-6914'),
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                  ]),
                            ),
                          ),
                        ]),
                  ),
                );
              }

              final btns = <Widget>[];
              btns.add(_ActionBtn(
                  icon: Icons.receipt_long_rounded,
                  label: context.loc.t('주문상세', '주문상세'),
                  onTap: () {
                    _showUserOrderDetail(btnCtx, order);
                  }));

              // ── 배송조회 버튼 (항상 표시 — 운송장 없으면 회색, 있으면 활성) ──
              btns.add(_ActionBtn(
                icon: Icons.local_shipping_outlined,
                label: context.loc.t('배송조회', '배송조회'),
                color: hasTrackingMobile
                    ? const Color(0xFF00838F)
                    : Colors.grey[400]!,
                onTap: hasTrackingMobile
                    ? () {
                        final company = (order.customOptions?['shippingCompany']
                                    as String? ??
                                '')
                            .trim();
                        showDialog(
                          context: btnCtx,
                          barrierDismissible: true,
                          builder: (_) => _TrackingDialog(
                            trackingNumber: trackingNumberMobile,
                            companyName: company,
                          ),
                        );
                      }
                    : () => ScaffoldMessenger.of(btnCtx).showSnackBar(
                          SnackBar(
                              content: Text(context.loc.t(
                                  '배송 준비 중입니다 운송장 등록 후 조회 가능합니다',
                                  '배송 준비 중입니다. 운송장 등록 후 조회 가능합니다.'))),
                        ),
              ));

              if (canCancel)
                btns.add(_ActionBtn(
                    icon: Icons.cancel_outlined,
                    label:
                        isGroup ? context.loc.t('취소디자인전', '취소(디자인전)') : '주문취소',
                    color: AppColors.error,
                    onTap: doCancel));
              if (cancelBlockedByDesign)
                btns.add(_ActionBtn(
                    icon: Icons.lock_outline_rounded,
                    label: context.loc.t('취소불가', '취소불가'),
                    color: AppColors.error.withValues(alpha: 0.30),
                    onTap: () => ScaffoldMessenger.of(btnCtx).showSnackBar(SnackBar(
                        content: Text(context.loc.t(
                            '디자인 수정이 시작된 이후에는 취소가 불가합니다 고객센터로 문의해 주세요',
                            '디자인 수정이 시작된 이후에는 취소가 불가합니다.\n고객센터로 문의해 주세요.'))))));
              if (canConfirmPurchase)
                btns.add(_ActionBtn(
                  icon: Icons.check_circle_rounded,
                  label: context.loc.t('구매확정', '구매확정'),
                  color: AppColors.success,
                  onTap: () => _showConfirmPurchaseDialog(btnCtx, order),
                ));
              if (isPurchaseConfirmed)
                btns.add(_ActionBtn(
                  icon: Icons.verified_rounded,
                  label: context.loc.t('구매확정_완료', '구매확정 완료'),
                  color: Colors.grey,
                  onTap: null,
                ));
              if (canExchangeReturn) {
                btns.add(_ActionBtn(
                    icon: Icons.swap_horiz_rounded,
                    label: context.loc.t('교환신청', '교환신청'),
                    color: AppColors.primary,
                    onTap: () => _showExchangeRequestDialog(btnCtx, order)));
                btns.add(_ActionBtn(
                    icon: Icons.assignment_return_outlined,
                    label: context.loc.t('반품신청', '반품신청'),
                    color: AppColors.warning,
                    onTap: () => _showReturnRequestDialog(btnCtx, order)));
              }
              if (canWriteReview)
                btns.add(_ActionBtn(
                  icon: Icons.rate_review_rounded,
                  label: context.loc.t('리뷰쓰기', '리뷰쓰기'),
                  color: const Color(0xFFFF8F00),
                  onTap: () => _showWriteReviewFromOrder(btnCtx, order),
                ));
              // 단체주문 디자인수정요청 (단계별 7일 이내, 최대 2회 + 사용자 미확정)
              if (isGroup &&
                  order.canRequestDesignRevision &&
                  !order.userDesignApproved)
                btns.add(_ActionBtn(
                  icon: Icons.edit_note_rounded,
                  label: context.loc.t('디자인수정', '디자인수정'),
                  color: const Color(0xFF7B1FA2),
                  badge: '${order.remainingDesignRevisions}회',
                  onTap: () => onDesignRevision?.call(order),
                ));
              // 사용자가 디자인 확정 → 제작시작 표시
              if (isGroup && order.userDesignApproved)
                btns.add(_ActionBtn(
                  icon: Icons.precision_manufacturing_rounded,
                  label: context.loc.t('제작시작', '제작시작'),
                  color: AppColors.success,
                  onTap: null,
                ));
              // 추가제작
              if (canAdditional)
                btns.add(_ActionBtn(
                    icon: Icons.add_circle_outline_rounded,
                    label: context.loc.t('추가제작', '추가제작'),
                    color: AppColors.success,
                    onTap: () => onAdditionalOrder(order)));
              // 단체주문 디자인 확인 버튼 (단체주문이면 항상 표시)
              if (isGroup && !order.userDesignApproved)
                btns.add(_ActionBtn(
                  icon: Icons.image_search_rounded,
                  label: context.loc.t('디자인확인', '디자인확인'),
                  color: const Color(0xFF0277BD),
                  onTap: () => onDesignConfirm?.call(order),
                ));
              // 단체주문 디자인 확정 표시 (현재 단계 7일 경과 또는 배송 이상)
              if (isGroup &&
                  order.isDesignConfirmed &&
                  !order.canRequestDesignRevision)
                btns.add(_ActionBtn(
                  icon: Icons.check_circle_outline_rounded,
                  label: context.loc.t('디자인확정', '디자인확정'),
                  color: Colors.grey,
                  onTap: null,
                ));

              return Row(
                children: btns.asMap().entries.map((e) {
                  final w = Expanded(child: e.value);
                  if (e.key == 0) return w;
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 1, height: 32, color: Colors.grey[200]),
                    w
                  ]);
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.processing:
        return const Color(0xFF7B1FA2);
      case OrderStatus.shipped:
        return const Color(0xFF00838F);
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.purchaseConfirmed:
        return const Color(0xFF1B5E20);
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.refunded:
        return Colors.brown;
    }
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y.$m.$dd $hh:$min';
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

  const _PcBtn(
      {required this.label,
      required this.icon,
      required this.color,
      this.badge,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                    child: Text(badge!,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700))),
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
    final orders =
        user != null ? orderProvider.getUserOrders(user.id) : <OrderModel>[];

    return Column(
      children: [
        _PcTabHeader(
            icon: Icons.payment_rounded,
            title: loc.mypagePaymentHistory,
            color: const Color(0xFF00796B),
            badge: '${orders.length}'),
        Expanded(
          child: orders.isEmpty
              ? _PcEmptyState(
                  icon: Icons.payment_outlined, message: loc.mypageNoPayment)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(o.id,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF00796B)))),
                              Text(_fmtDate(o.createdAt),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.credit_card_rounded,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(o.paymentMethod,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700])),
                            const Spacer(),
                            Text(_fmtPrice(o.totalAmount),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF00796B))),
                          ]),
                          if ((o.shippingFee) > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('${loc.mypageShipping}: ',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[500])),
                                Text(_fmtPrice(o.shippingFee),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
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
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y.$m.$dd $hh:$min';
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
        .map((id) => ProductService.getProductByIdSync(id))
        .where((p) => p != null)
        .cast<ProductModel>()
        .toList();

    return Column(
      children: [
        _PcTabHeader(
            icon: Icons.favorite_rounded,
            title: loc.wishlist,
            color: Colors.pinkAccent,
            badge: '${products.length}'),
        Expanded(
          child: products.isEmpty
              ? _PcEmptyState(
                  icon: Icons.favorite_border_rounded,
                  message: loc.mypageNoWishlist,
                  subtitle: loc.mypageNoWishlistSub)
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16),
                  itemCount: products.length,
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: p))),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8)
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: NetImage(p.images.first,
                                        width: double.infinity,
                                        fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          userProvider.toggleWishlist(p.id),
                                      child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle),
                                          child: const Icon(
                                              Icons.favorite_rounded,
                                              size: 16,
                                              color: Colors.pinkAccent)),
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
                                    Text(p.name,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const Spacer(),
                                    Text(_fmtPrice(p.price.toDouble()),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary)),
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
class _PcSettingsTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  final void Function(BuildContext, UserModel) onShowProfileEdit;
  final void Function(BuildContext) onShowAddressManager;
  final void Function(BuildContext, UserProvider) onShowLogout;
  final void Function(BuildContext) onShowChangePassword;
  final void Function(BuildContext, UserProvider) onShowDeleteAccount;

  const _PcSettingsTab({
    required this.userProvider,
    required this.loc,
    required this.onShowProfileEdit,
    required this.onShowAddressManager,
    required this.onShowLogout,
    required this.onShowChangePassword,
    required this.onShowDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;

    return Column(
      children: [
        _PcTabHeader(
            icon: Icons.settings_rounded,
            title: loc.settings,
            color: AppColors.textSecondary),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PcSettingSection(
                  title: loc.mypageProfileSection,
                  items: [
                    _PcSettingItem(
                        icon: Icons.person_rounded,
                        title: loc.mypageEditProfile,
                        onTap: user != null
                            ? () => onShowProfileEdit(context, user)
                            : null),
                    _PcSettingItem(
                        icon: Icons.location_on_rounded,
                        title: loc.mypageAddressBook,
                        onTap: () => onShowAddressManager(context)),
                    _PcSettingItem(
                      icon: Icons.straighten_rounded,
                      title: context.loc.t('내_사이즈_관리', '내 사이즈 관리'),
                      subtitle: context.loc
                          .t('저장된_사이즈로_주문_시_빠_396e4b', '저장된 사이즈로 주문 시 빠르게 입력'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SizeProfileScreen()),
                      ),
                    ),
                    _PcSettingItem(
                      icon: Icons.receipt_long_rounded,
                      title: context.loc.t('현금영수증_번호', '현금영수증 번호'),
                      subtitle: user?.cashReceiptNum?.isNotEmpty == true
                          ? user!.cashReceiptNum!
                          : context.loc.t('미등록_결제_시_자동_발행', '미등록 — 결제 시 자동 발행'),
                      onTap: () =>
                          _showCashReceiptDialog(context, userProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _PcSettingSection(
                  title: loc.mypageNotificationSection,
                  items: [
                    _PcSettingItem(
                        icon: Icons.notifications_rounded,
                        title: loc.mypageNotifOrder,
                        trailing: Switch(
                            value: user?.orderNotificationsEnabled ?? true,
                            onChanged: user == null
                                ? null
                                : (value) => userProvider.updateUserProfile(
                                    orderNotificationsEnabled: value),
                            thumbColor: const WidgetStatePropertyAll(
                                AppColors.primary))),
                    _PcSettingItem(
                        icon: Icons.campaign_rounded,
                        title: loc.mypageNotifMarketing,
                        trailing: Switch(
                            value: user?.marketingNotificationsEnabled ?? false,
                            onChanged: user == null
                                ? null
                                : (value) => userProvider.updateUserProfile(
                                    marketingNotificationsEnabled: value),
                            thumbColor: const WidgetStatePropertyAll(
                                AppColors.primary))),
                  ],
                ),
                const SizedBox(height: 20),
                _PcSettingSection(
                  title: loc.mypageAppSection,
                  items: [
                    _PcSettingItem(
                        icon: Icons.language_rounded,
                        title: loc.mypageLanguageSetting,
                        trailing: _LanguageDropdown()),
                    _PcSettingItem(
                        icon: Icons.info_outline_rounded,
                        title: context.loc.t('앱_정보', '앱 정보'),
                        subtitle: 'v1.0.0'),
                  ],
                ),
                const SizedBox(height: 20),
                _PcSettingSection(
                  title: context.loc.t('약관_및_정책', '약관 및 정책'),
                  items: [
                    _PcSettingItem(
                      icon: Icons.privacy_tip_outlined,
                      title: context.loc.t('개인정보처리방침', '개인정보처리방침'),
                      onTap: () =>
                          Navigator.pushNamed(context, '/privacy-policy'),
                    ),
                    _PcSettingItem(
                      icon: Icons.description_outlined,
                      title: context.loc.t('이용약관', '이용약관'),
                      onTap: () =>
                          Navigator.pushNamed(context, '/terms-of-service'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (user != null)
                  _PcSettingSection(
                    title: loc.mypageSecuritySection,
                    items: [
                      _PcSettingItem(
                          icon: Icons.lock_rounded,
                          title: loc.mypageChangePassword,
                          onTap: () => onShowChangePassword(context)),
                      _PcSettingItem(
                          icon: Icons.logout_rounded,
                          title: loc.mypageLogout,
                          onTap: () => onShowLogout(context, userProvider),
                          color: AppColors.warning),
                      _PcSettingItem(
                          icon: Icons.delete_outline_rounded,
                          title: loc.mypageDeleteAccount,
                          onTap: () =>
                              onShowDeleteAccount(context, userProvider),
                          color: AppColors.error),
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

// ── 영수증 보기 다이얼로그 ──
void _showReceiptDialog(BuildContext context, OrderModel o) {
  String fmtPrice(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String fmtDateTime(DateTime dt) => '${dt.year}년 ${dt.month}월 ${dt.day}일 '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';

  final supplyAmt = (o.totalAmount / 1.1).roundToDouble();
  final vatAmt = (o.totalAmount - supplyAmt).roundToDouble();

  // 현금영수증 용도 판별 (10자리=사업자→지출증빙, 그 외→소득공제)
  String cashReceiptType = context.loc.t('소득공제', '소득공제');
  if ((o.cashReceiptNum ?? '').isNotEmpty) {
    final digits = o.cashReceiptNum!.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) cashReceiptType = context.loc.t('지출증빙', '지출증빙');
  }

  // 주문 ID 뒤 8자리를 승인번호로 표시
  final approvalNum = o.id.length >= 8
      ? o.id.substring(o.id.length - 8).toUpperCase()
      : o.id.toUpperCase();

  Widget row(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
    bool multiLine = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment:
              multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? AppColors.primary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );

  Widget divider() =>
      const Divider(height: 1, thickness: 1, color: AppColors.surfaceGray);

  Widget sectionHeader(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary)),
      );

  final isGroupOrder = o.isGroupOrder;
  final isAdditionalOrder = o.isAdditionalOrder;
  final orderTypeLabel = isAdditionalOrder
      ? context.loc.t('추가제작', '추가제작')
      : (isGroupOrder
          ? context.loc.t('단체주문', '단체주문')
          : context.loc.t('일반 기성품', '일반 기성품'));
  final orderTypeColor = isAdditionalOrder ? AppColors.warning : AppColors.primary;
  final orderOptions = o.customOptions ?? <String, dynamic>{};
  final teamName = (orderOptions['teamName']?.toString().trim().isNotEmpty == true
          ? orderOptions['teamName']?.toString()
          : o.groupName)
      ?.trim();
  final groupQuantity = o.groupCount ??
      (orderOptions['totalCount'] is num
          ? (orderOptions['totalCount'] as num).toInt()
          : null) ??
      (isGroupOrder
          ? o.items.fold<int>(0, (sum, item) => sum + item.quantity)
          : null);

  // 상품명 (여러 개면 첫 번째 + 외 N건)
  String itemSummary = '-';
  if (o.items.isNotEmpty) {
    itemSummary = o.items.first.productName;
    if (o.items.length > 1) itemSummary += ' 외 ${o.items.length - 1}건';
  }

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 700),
        child: Column(children: [
          // ── 헤더 ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.receipt_long_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.loc.t('거래_확인서', '거래 확인서'),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ]),
          ),

          // ── 콘텐츠 ────────────────────────────────────────
          Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── 승인 배지 ──
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 14),
                  SizedBox(width: 5),
                  Text(context.loc.t('승인', '승인'),
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w700)),
                ]),
              ),

              // ── 주문 유형 요약 ───────────────────────────────
              sectionHeader(context.loc.t('주문 구분', '주문 구분')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  row(context.loc.t('주문 유형', '주문 유형'), orderTypeLabel,
                      bold: true, valueColor: orderTypeColor),
                  if (isGroupOrder && teamName != null && teamName.isNotEmpty) ...[
                    divider(),
                    row(context.loc.t('단체명', '단체명'), teamName,
                        multiLine: true),
                  ],
                  if (isGroupOrder && groupQuantity != null) ...[
                    divider(),
                    row(context.loc.t('단체 수량', '단체 수량'), '${groupQuantity}개'),
                  ],
                ]),
              ),

              // ── 이용상점 ──────────────────────────────────
              sectionHeader(context.loc.t('이용상점', '이용상점')),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  row(context.loc.t('상호', '상호'), AppConstants.companyName),
                  divider(),
                  row(context.loc.t('대표자', '대표자'), AppConstants.ceoName),
                  divider(),
                  row(context.loc.t('사업자등록번호', '사업자등록번호'),
                      AppConstants.businessRegNumber),
                  divider(),
                  row(context.loc.t('전화번호', '전화번호'),
                      AppConstants.customerServicePhone),
                  divider(),
                  row('URL', 'www.2fit-mall.co.kr'),
                  divider(),
                  row(context.loc.t('주소', '주소'), AppConstants.companyAddress,
                      multiLine: true),
                ]),
              ),

              // ── 결제 정보 ─────────────────────────────────
              sectionHeader(context.loc.t('결제 정보', '결제 정보')),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  if (o.couponDiscount > 0) ...[
                    row('쿠폰 할인', '-${fmtPrice(o.couponDiscount)}원'),
                    divider(),
                  ],
                  if (o.usedPoints > 0) ...[
                    row('포인트 사용',
                        '-${fmtPrice(o.pointDiscount)}원 (${o.usedPoints}P)'),
                    divider(),
                  ],
                  row('결제 금액', '${fmtPrice(o.totalAmount)}원',
                      bold: true, valueColor: AppColors.error),
                  divider(),
                  row('공급가액', '${fmtPrice(supplyAmt)}원'),
                  divider(),
                  row('부가세', '${fmtPrice(vatAmt)}원'),
                  divider(),
                  row(context.loc.t('봉사료', '봉사료'), '0원'),
                  divider(),
                  row(context.loc.t('결제수단', '결제수단'),
                      o.paymentMethod.isNotEmpty ? o.paymentMethod : '-'),
                  divider(),
                  row(context.loc.t('구매자', '구매자'),
                      o.userName.isNotEmpty ? o.userName : '-'),
                  divider(),
                  row(context.loc.t('상품명', '상품명'), itemSummary,
                      multiLine: true),
                  divider(),
                  row(context.loc.t('거래일시_n_취소일시', '거래일시\n(취소일시)'),
                      fmtDateTime(o.createdAt),
                      multiLine: true),
                ]),
              ),

              // ── 안내문구 ──────────────────────────────────
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  Text(
                    context.loc.t('본_거래확인서는_세금계산서_대용으로_사용할_수_없습니다',
                        '본 거래확인서는 세금계산서 대용으로 사용할 수 없습니다.'),
                    style:
                        TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    context.loc.t('현금영수증_문의_126_1_1', '현금영수증 문의: 126-1-1'),
                    style:
                        TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ]),
          )),

          // ── 버튼 영역 ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // 현금영수증 보기 버튼 (항상 표시)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCashReceiptDetailDialog(context, o,
                        fmtDateTime: fmtDateTime,
                        approvalNum: approvalNum,
                        cashReceiptType: cashReceiptType);
                  },
                  icon: const Icon(Icons.receipt_outlined, size: 16),
                  label: Text(context.loc.t('현금영수증_보기', '현금영수증 보기'),
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side:
                        const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 닫기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(context.loc.t('닫기', '닫기'),
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ),
  );
}

// ── 현금영수증 상세 보기 다이얼로그 (오늘의집페이 스타일) ──
void _showCashReceiptDetailDialog(
  BuildContext context,
  OrderModel o, {
  required String Function(DateTime) fmtDateTime,
  required String approvalNum,
  required String cashReceiptType,
}) {
  final hasCashReceipt = (o.cashReceiptNum ?? '').isNotEmpty;

  Widget row(String label, String value,
          {bool bold = false, Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? AppColors.primary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );

  Widget divider() =>
      const Divider(height: 1, thickness: 1, color: AppColors.surfaceGray);

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── 헤더 ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.receipt_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.loc.t('현금영수증_정보', '현금영수증 정보'),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ]),
          ),

          // ── 콘텐츠 ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: hasCashReceipt
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // 현금영수증 발행 정보 카드
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: Column(children: [
                            row(context.loc.t('발행일시', '발행일시'),
                                fmtDateTime(o.createdAt)),
                            divider(),
                            row(context.loc.t('승인번호', '승인번호'), approvalNum,
                                bold: true,
                                valueColor: const Color(0xFF1B5E20)),
                            divider(),
                            row(context.loc.t('용도', '용도'), cashReceiptType),
                            divider(),
                            row(context.loc.t('발행정보', '발행정보'),
                                o.cashReceiptNum!),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        // 국세청 안내
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(children: [
                            Text(
                              context.loc.t(
                                  '현금영수증_승인번호는_국세청에서_n익일_13시_이후_확인됩니다',
                                  '현금영수증 승인번호는 국세청에서\n익일 13시 이후 확인됩니다.'),
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              context.loc
                                  .t('현금영수증_문의_126_1_1', '현금영수증 문의: 126-1-1'),
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),
                      ])
                // 현금영수증 번호 미등록 안내
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.textHint, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        context.loc
                            .t('현금영수증_번호가_등록되지_않았습니다', '현금영수증 번호가 등록되지 않았습니다.'),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.loc.t('마이페이지_현금영수증_번호_등록_후_n결제하시면_자동으로_발급됩니다',
                            '마이페이지 → 현금영수증 번호 등록 후\n결제하시면 자동으로 발급됩니다.'),
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
          ),

          // ── 닫기 버튼 ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(context.loc.t('확인', '확인'),
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ── 현금영수증 번호 등록/수정 다이얼로그 ──
void _showCashReceiptDialog(BuildContext context, UserProvider userProvider) {
  final ctrl =
      TextEditingController(text: userProvider.user?.cashReceiptNum ?? '');
  bool saving = false;
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                Icon(Icons.receipt_long_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(context.loc.t('현금영수증_번호', '현금영수증 번호'),
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        context.loc.t('결제_시_자동으로_현금영수증_1854d3',
                            '결제 시 자동으로 현금영수증이 발행됩니다.\n전화번호 또는 사업자번호를 입력하세요.'),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey, height: 1.5)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: context.loc.t(
                            '010_0000_0000_또_36bbd1', '010-0000-0000 또는 사업자번호'),
                        prefixIcon:
                            const Icon(Icons.phone_android_rounded, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        context.loc.t('소득공제용__전화번호_n___f4833f',
                            '· 소득공제용: 전화번호\n· 지출증빙용: 사업자번호'),
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.6)),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.loc.t('취소', '취소'))),
                if (userProvider.user?.cashReceiptNum?.isNotEmpty == true)
                  TextButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSt(() => saving = true);
                            await userProvider.updateUserProfile(
                                cashReceiptNum: '');
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    child: Text(context.loc.t('삭제', '삭제'),
                        style: TextStyle(color: AppColors.error)),
                  ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final num = ctrl.text.trim();
                          if (num.isEmpty) {
                            Navigator.pop(ctx);
                            return;
                          }
                          setSt(() => saving = true);
                          await userProvider.updateUserProfile(
                              cashReceiptNum: num);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(context.loc.t(
                                      '현금영수증 번호가 저장되었습니다',
                                      '현금영수증 번호가 저장되었습니다')),
                                  backgroundColor: AppColors.primary),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  child: saving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(context.loc.t('저장', '저장')),
                ),
              ],
            )),
  );
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
        final labels = {
          AppLanguage.korean: '한국어',
          AppLanguage.english: 'English',
          AppLanguage.japanese: '日本語',
          AppLanguage.chinese: '中文',
          AppLanguage.mongolian: 'Монгол'
        };
        return DropdownMenuItem(value: l, child: Text(labels[l] ?? l.name));
      }).toList(),
      onChanged: (v) {
        if (v != null) lang.setLanguage(v);
      },
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
        Text(title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: List.generate(
                items.length,
                (i) => Column(
                      children: [
                        items[i],
                        if (i < items.length - 1)
                          Divider(
                              height: 1, indent: 52, color: Colors.grey[100]),
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

  const _PcSettingItem(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.trailing,
      this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[800]!;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: (color ?? AppColors.textSecondary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: c),
      ),
      title: Text(title,
          style:
              TextStyle(fontSize: 14, color: c, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded,
                  size: 18, color: Colors.grey[400])
              : null),
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
  final void Function(BuildContext, UserModel) onShowProfileEdit;
  final void Function(BuildContext) onShowAddressManager;
  final void Function(BuildContext, UserProvider) onShowLogout;
  final void Function(BuildContext) onShowChangePassword;
  final void Function(BuildContext, UserProvider) onShowDeleteAccount;
  final void Function(OrderModel)? onShowDesignRevision;
  final void Function(OrderModel)? onShowDesignConfirm;

  const _MobileMyPage({
    required this.tabController,
    required this.userProvider,
    this.onBack,
    required this.onShowAdditionalOrder,
    required this.onShowProfileEdit,
    required this.onShowAddressManager,
    required this.onShowLogout,
    required this.onShowChangePassword,
    required this.onShowDeleteAccount,
    this.onShowDesignRevision,
    this.onShowDesignConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final user = userProvider.user;

    return wrapWithPopScope(
        context,
        Scaffold(
          backgroundColor: const Color(0xFFF3F0F7),
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: Colors.white),
              onPressed: onBack ?? () => goBackOrHome(context),
              tooltip: context.loc.t('이전으로', '이전으로'),
            ),
            automaticallyImplyLeading: false,
            title: Text(context.loc.t('마이페이지', '마이페이지'),
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 프로필 헤더
                _MobileProfileHeader(
                    user: user,
                    loc: loc,
                    userProvider: userProvider,
                    onShowProfileEdit: onShowProfileEdit,
                    onShowLogout: onShowLogout),
                // 빠른 통계
                _MobileQuickStats(
                    user: user, loc: loc, tabController: tabController),
                // 탭바
                Container(
                  color: AppColors.primary,
                  child: TabBar(
                    controller: tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: const Color(0xFFCE93D8),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: [
                      Tab(text: loc.myOrders),
                      Tab(text: loc.wishlist),
                      Tab(text: context.loc.t('쿠폰함', '쿠폰함')),
                      Tab(text: context.loc.t('포인트', '포인트')),
                      Tab(text: loc.settings),
                    ],
                  ),
                ),
                // 콘텐츠
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      _MobileOrderHistoryTab(
                          userProvider: userProvider,
                          loc: loc,
                          onAdditionalOrder: onShowAdditionalOrder,
                          onDesignRevision: onShowDesignRevision,
                          onDesignConfirm: onShowDesignConfirm),
                      _MobileWishlistTab(userProvider: userProvider, loc: loc),
                      _MobileCouponTab(userProvider: userProvider, loc: loc),
                      _MobilePointTab(userProvider: userProvider, loc: loc),
                      _MobileSettingsTab(
                          userProvider: userProvider,
                          loc: loc,
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
        ));
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
    required this.user,
    required this.loc,
    required this.userProvider,
    required this.onShowProfileEdit,
    required this.onShowLogout,
  });

  @override
  Widget build(BuildContext context) {
    final tier = user?.memberTier ?? 'bronze';
    final tierColor = _tierColor(tier);
    final tierLabel = _tierLabel(tier, loc);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF2D2B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded,
                    size: 32, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: user == null
                    ? Text(loc.mypageLoginPrompt,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user!.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: tierColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(tierLabel,
                                    style: TextStyle(
                                        color: tierColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          Text(user!.email,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ],
                      ),
              ),
              if (user != null)
                IconButton(
                  onPressed: () => onShowProfileEdit(context, user!),
                  icon: const Icon(Icons.edit_rounded,
                      color: Colors.white70, size: 20),
                ),
            ],
          ),
          if (user != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                    child: GestureDetector(
                  onTap: () => onShowLogout(context, userProvider),
                  child: _InfoChip(
                      icon: Icons.logout_rounded,
                      label: loc.mypageLogout,
                      color: AppColors.error.withValues(alpha: 0.30)!),
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
      case 'silver':
        return loc.mypageTierSilver;
      case 'gold':
        return loc.mypageTierGold;
      case 'vip':
        return loc.mypageTierVip;
      default:
        return loc.mypageTierBronze;
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'silver':
        return AppColors.textSecondary.withValues(alpha: 0.20);
      case 'gold':
        return Colors.amber[400]!;
      case 'vip':
        return AppColors.primary.withValues(alpha: 0.30);
      default:
        return Colors.brown[300]!;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
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

  const _MobileQuickStats(
      {required this.user, required this.loc, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders =
        user != null ? orderProvider.getUserOrders(user!.id) : <OrderModel>[];
    final wishCount = user?.wishlist.length ?? 0;
    final couponCount = context.watch<CouponProvider>().validCoupons.length;
    final pointBalance = context.watch<PointProvider>().balance;

    String _fmtNum(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _MobileStatItem(
              label: loc.myOrders,
              count: orders.length,
              onTap: () => tabController.animateTo(0)),
          _VertDiv(),
          _MobileStatItem(
              label: loc.wishlist,
              count: wishCount,
              onTap: () => tabController.animateTo(1)),
          _VertDiv(),
          _MobileStatItem(
            label: context.loc.t('쿠폰', '쿠폰'),
            countLabel: '$couponCount장',
            onTap: () => tabController.animateTo(2),
          ),
          _VertDiv(),
          _MobileStatItem(
            label: context.loc.t('포인트', '포인트'),
            countLabel: '${_fmtNum(pointBalance)}P',
            onTap: () => tabController.animateTo(3),
          ),
        ],
      ),
    );
  }
}

class _MobileStatItem extends StatelessWidget {
  final String label;
  final int? count;
  final String? countLabel;
  final VoidCallback onTap;
  const _MobileStatItem(
      {required this.label, this.count, this.countLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final display = countLabel ?? '${count ?? 0}';
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text(display,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}

class _VertDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 24, color: Colors.white24);
}

// ═══════════════════════════════════════════════════════
// 모바일 주문 내역 탭
// ═══════════════════════════════════════════════════════
class _MobileOrderHistoryTab extends StatefulWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  final void Function(OrderModel) onAdditionalOrder;
  final void Function(OrderModel)? onDesignRevision;
  final void Function(OrderModel)? onDesignConfirm;

  const _MobileOrderHistoryTab({
    required this.userProvider,
    required this.loc,
    required this.onAdditionalOrder,
    this.onDesignRevision,
    this.onDesignConfirm,
  });

  @override
  State<_MobileOrderHistoryTab> createState() => _MobileOrderHistoryTabState();
}

class _MobileOrderHistoryTabState extends State<_MobileOrderHistoryTab> {
  bool _initialLoadDone = false;
  _OrderHistoryFilter _selectedFilter = _OrderHistoryFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = widget.userProvider.user;
      if (user != null) {
        context.read<OrderProvider>().loadUserOrders(user.id).then((_) {
          if (mounted) setState(() => _initialLoadDone = true);
        });
      } else {
        setState(() => _initialLoadDone = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userProvider.user;
    if (user == null)
      return _MobileEmptyState(
          icon: Icons.login_rounded, message: widget.loc.mypageLoginPrompt);

    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.getUserOrders(user.id);
    final filteredOrders = _filterOrderHistory(orders, _selectedFilter);

    // 초기 로드 전이고 주문도 없으면 로딩 표시
    if (!_initialLoadDone && orders.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (orders.isEmpty) {
      return _MobileEmptyState(
          icon: Icons.receipt_long_outlined,
          message: widget.loc.mypageNoOrders,
          subtitle: widget.loc.mypageFirstOrder);
    }

    return Column(
      children: [
        _OrderHistoryFilterBar(
          orders: orders,
          selected: _selectedFilter,
          onChanged: (filter) => setState(() => _selectedFilter = filter),
        ),
        Expanded(
          child: filteredOrders.isEmpty
              ? _MobileEmptyState(
                  icon: Icons.filter_alt_off_rounded,
                  message: '선택한 주문 구분의 주문이 없습니다.',
                  subtitle: '다른 필터를 선택해 보세요.')
              : RefreshIndicator(
                  onRefresh: () => orderProvider.loadUserOrders(user.id),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: filteredOrders.length,
                    itemBuilder: (_, i) => _MobileOrderCard(
                      order: filteredOrders[i],
                      loc: widget.loc,
                      onAdditionalOrder: widget.onAdditionalOrder,
                      onDesignRevision: widget.onDesignRevision,
                      onDesignConfirm: widget.onDesignConfirm,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MobileOrderCard extends StatelessWidget {
  final OrderModel order;
  final AppLocalizations loc;
  final void Function(OrderModel) onAdditionalOrder;
  final void Function(OrderModel)? onDesignRevision;
  final void Function(OrderModel)? onDesignConfirm;

  const _MobileOrderCard(
      {required this.order,
      required this.loc,
      required this.onAdditionalOrder,
      this.onDesignRevision,
      this.onDesignConfirm});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final isGroup = order.orderType == 'group' ||
        order.orderType == 'additional' ||
        order.id.startsWith('GRP_') ||
        order.id.startsWith('GROUP-');
    final isActive = order.status != OrderStatus.cancelled &&
        order.status != OrderStatus.refunded;
    // 추가제작: 취소/환불 아니면 배송완료 후에도 항상 가능 (같은 디자인 재주문)
    final canAdditional = isGroup && isActive;

    // 운송장 등록 여부
    final trackingNumber =
        (order.customOptions?['trackingNumber'] as String? ?? '').trim();
    final hasTracking = trackingNumber.isNotEmpty;

    // 취소/교환/반품 조건
    final canCancelReadyMade = !isGroup &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed);
    // 단체주문: 디자인 발송 전(designRevisionDeadline == null)이고 pending/confirmed 상태일 때만 취소 가능
    final canCancelGroup = isGroup &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed) &&
        order.designRevisionDeadline == null;
    final canCancel = (canCancelReadyMade || canCancelGroup) && !hasTracking;
    // 단체주문 취소불가: 디자인이 이미 발송됐거나(designRevisionDeadline != null) processing 이상
    final cancelBlockedByDesign = isGroup &&
        !canCancelGroup &&
        (order.status == OrderStatus.pending ||
            order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.processing) &&
        !(order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.refunded);
    // 교환/반품 기간 체크: deliveredAt 기준 7일 이내 (null이면 createdAt 기준)
    final isPurchaseConfirmed = order.isPurchaseConfirmed;
    final deliveredBasePC = order.deliveredAt ?? order.createdAt;
    final isWithin7DaysPC =
        DateTime.now().isBefore(deliveredBasePC.add(const Duration(days: 7)));
    // 교환/반품: 배송완료면 7일 이내 + 구매확정 전
    //            배송중(shipped)은 운송장 있을 때만 활성 (기간 무관)
    final canExchangeReturn = !isGroup &&
        !isPurchaseConfirmed &&
        ((order.status == OrderStatus.delivered && isWithin7DaysPC) ||
            (order.status == OrderStatus.shipped && hasTracking));
    // 배송조회: 운송장 등록된 경우
    // 구매확정: 배송완료 상태이고 구매확정 전 (운송장 유무 무관)
    final canConfirmPurchase =
        order.status == OrderStatus.delivered && !isPurchaseConfirmed;
    // 리뷰쓰기: 구매확정 후 (개인주문만)
    final canWriteReview = !isGroup && isPurchaseConfirmed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── 헤더: 주문번호 + 날짜 + 상태 ──
          GestureDetector(
            onTap: () {
              _showUserOrderDetail(context, order);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  if (isGroup)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(order.orderType == 'additional' ? '추가제작' : loc.groupCustom,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.id,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(_fmtDate(order.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(order.status.label,
                        style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // ── 상품 정보 ──
          GestureDetector(
            onTap: () {
              _showUserOrderDetail(context, order);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: () {
                      if (order.items.isEmpty)
                        return const Icon(Icons.checkroom_rounded,
                            color: Colors.grey, size: 30);
                      final item = order.items.first;
                      final url = item.imageUrl?.isNotEmpty == true
                          ? item.imageUrl!
                          : (item.customOptions?['productImageUrl'] as String?)
                                      ?.isNotEmpty ==
                                  true
                              ? item.customOptions!['productImageUrl'] as String
                              : (item.customOptions?['designFileUrl']
                                              as String?)
                                          ?.isNotEmpty ==
                                      true
                                  ? item.customOptions!['designFileUrl']
                                      as String
                                  : null;
                      return url != null
                          ? Image.network(url,
                              width: 64,
                              height: 64,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.checkroom_rounded,
                                  color: Colors.grey,
                                  size: 30))
                          : const Icon(Icons.checkroom_rounded,
                              color: Colors.grey, size: 30);
                    }(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.items.isNotEmpty)
                          Text(order.items.first.productName,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        if (order.items.isNotEmpty)
                          Text(
                            '${order.items.first.size != context.loc.t('단체', '단체') && order.items.first.size.isNotEmpty ? order.items.first.size : ''}'
                            '${order.items.first.color.isNotEmpty ? ' / ${order.items.first.color}' : ''}'
                            ' · ${order.items.first.quantity}개',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (order.items.length > 1)
                          Text('외 ${order.items.length - 1}개 상품 더보기',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── 결제 금액 요약 ──
          GestureDetector(
            onTap: () {
              _showUserOrderDetail(context, order);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Text(context.loc.t('결제금액', '결제금액 '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(_fmtPrice(order.totalAmount),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary)),
                  const Spacer(),
                  Text('${order.paymentMethod}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
          if (order.isGroupOrder && order.activeDesignRevisionDeadline != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: DesignRevisionCountdown(
                deadline: order.activeDesignRevisionDeadline,
                revisionCount: order.designRevisionCount,
                compact: true,
              ),
            ),
          ],
          // ── 액션 버튼 구분선 ──
          Container(height: 1, color: Colors.grey[100]),
          // ── 버튼 행 (네이버 스타일: 항상 노출) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Builder(builder: (btnCtx) {
              Future<void> doCancel() async {
                final confirm = await showDialog<bool>(
                  context: btnCtx,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    title: Text(context.loc.t('주문_취소', '주문 취소'),
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    content: Text(isGroup
                        ? context.loc.t(
                            '단체주문을 취소하시겠습니까 디자인 수정 전에만 취소 가능합니다 결제 취소는 _6ab23e',
                            '단체주문을 취소하시겠습니까?\n디자인 수정 전에만 취소 가능합니다.\n결제 취소는 1~3 영업일 내 처리됩니다.')
                        : context.loc.t(
                            '주문을 취소하시겠습니까 발송 전에만 취소 가능합니다 결제 취소는 13 영업일_b22850',
                            '주문을 취소하시겠습니까?\n발송 전에만 취소 가능합니다.\n결제 취소는 1~3 영업일 내 처리됩니다.')),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(btnCtx, false),
                          child: Text(context.loc.t('아니오', '아니오'))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(btnCtx, true),
                        child: Text(context.loc.t('취소하기', '취소하기'),
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && btnCtx.mounted) {
                  await OrderService.updateOrderStatus(
                      order.id, OrderStatus.cancelled);
                  NotificationService.sendCancelled(
                          order: order,
                          reason: context.loc.t('고객 직접 취소', '고객 직접 취소'))
                      .catchError((_) {});
                  FcmService.sendOrderStatusNotification(
                          order: order, newStatus: OrderStatus.cancelled)
                      .catchError((_) {});
                  if (btnCtx.mounted) {
                    ScaffoldMessenger.of(btnCtx).showSnackBar(
                      SnackBar(
                          content: Text(
                              context.loc.t('주문이 취소되었습니다', '주문이 취소되었습니다.')),
                          backgroundColor: AppColors.primary),
                    );
                  }
                }
              }

              Future<void> openKakaoChannel() async {
                final appUrl =
                    Uri.parse('kakaoplus://plusfriend/home/@2fit-mall');
                final webUrl = Uri.parse('https://pf.kakao.com/_MQxjXX/chat');
                if (await canLaunchUrl(appUrl)) {
                  await launchUrl(appUrl, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                }
              }

              void showContactSheet(String subject) {
                showModalBottomSheet(
                  context: btnCtx,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (sheetCtx) => Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEE500),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Center(
                                  child: Text('💬',
                                      style: TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(subject,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900)),
                                  Text('주문번호: ${order.id}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.black45),
                                      overflow: TextOverflow.ellipsis),
                                ])),
                          ]),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              openKakaoChannel();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEE500),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('💬', style: TextStyle(fontSize: 20)),
                                    SizedBox(width: 8),
                                    Text(
                                        context.loc
                                            .t('카카오톡_채널_문의', '카카오톡 채널 문의'),
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF3A1D1D))),
                                  ]),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              launchUrl(Uri.parse('tel:01072276914'));
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF3F0F7),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone_outlined,
                                        size: 20, color: AppColors.textPrimary),
                                    SizedBox(width: 8),
                                    Text(
                                        context.loc.t('전화_문의__010_7227_140b47',
                                            '전화 문의  010-7227-6914'),
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                  ]),
                            ),
                          ),
                        ]),
                  ),
                );
              }

              // ── 버튼 목록 구성 (행1: 주요, 행2: 단체전용) ──
              final row1 = <Widget>[];
              final row2 = <Widget>[];

              // ── 행1: 채팅문의 (항상 표시) ──
              row1.add(_ActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: context.loc.t('채팅문의', '채팅문의'),
                color: const Color(0xFFFF8F00),
                onTap: () => openKakaoChannel(),
              ));

              // ── 운송장 등록 전: 배송조회(회색) + 주문취소 or 취소불가 ──
              if (!hasTracking) {
                // 배송조회 (비활성 - 운송장 미등록)
                row1.add(_ActionBtn(
                  icon: Icons.local_shipping_outlined,
                  label: context.loc.t('배송조회', '배송조회'),
                  color: Colors.grey[400]!,
                  onTap: () => ScaffoldMessenger.of(btnCtx).showSnackBar(
                    SnackBar(
                        content: Text(context.loc.t(
                            '배송 준비 중입니다 운송장 등록 후 조회 가능합니다',
                            '배송 준비 중입니다. 운송장 등록 후 조회 가능합니다.'))),
                  ),
                ));
                // 주문취소
                if (canCancel) {
                  row1.add(_ActionBtn(
                    icon: Icons.cancel_outlined,
                    label:
                        isGroup ? context.loc.t('취소디자인전', '취소(디자인전)') : '주문취소',
                    color: AppColors.error,
                    onTap: doCancel,
                  ));
                }
                // 취소불가 (디자인 진행중)
                if (cancelBlockedByDesign) {
                  row1.add(_ActionBtn(
                    icon: Icons.lock_outline_rounded,
                    label: context.loc.t('취소불가', '취소불가'),
                    color: AppColors.error.withValues(alpha: 0.30),
                    onTap: () => ScaffoldMessenger.of(btnCtx).showSnackBar(
                      SnackBar(
                          content: Text(context.loc.t(
                              '디자인 수정이 시작된 이후에는 취소가 불가합니다 고객센터로 문의해 주세요',
                              '디자인 수정이 시작된 이후에는 취소가 불가합니다.\n고객센터로 문의해 주세요.'))),
                    ),
                  ));
                }
              }

              // ── 운송장 등록 후: 배송조회(활성) + 교환신청 + 반품신청 ──
              if (hasTracking) {
                // 배송조회 (활성)
                row1.add(_ActionBtn(
                  icon: Icons.local_shipping_outlined,
                  label: context.loc.t('배송조회', '배송조회'),
                  color: const Color(0xFF00838F),
                  onTap: () async {
                    final company =
                        (order.customOptions?['shippingCompany'] as String? ??
                                '')
                            .trim();
                    await _openTrackingPage(
                      context: btnCtx,
                      companyName: company,
                      trackingNumber: trackingNumber,
                    );
                  },
                ));
                // 구매확정 버튼 (배송완료 상태)
                if (canConfirmPurchase) {
                  row1.add(_ActionBtn(
                    icon: Icons.check_circle_rounded,
                    label: context.loc.t('구매확정', '구매확정'),
                    color: AppColors.success,
                    onTap: () => _showConfirmPurchaseDialog(btnCtx, order),
                  ));
                }
                if (isPurchaseConfirmed) {
                  row1.add(_ActionBtn(
                    icon: Icons.verified_rounded,
                    label: context.loc.t('구매확정됨', '구매확정됨'),
                    color: Colors.grey,
                    onTap: null,
                  ));
                }
                // 교환신청 + 반품신청 (운송장 등록 후, 구매확정 전)
                if (canExchangeReturn) {
                  row1.add(_ActionBtn(
                    icon: Icons.swap_horiz_rounded,
                    label: context.loc.t('교환신청', '교환신청'),
                    color: AppColors.primary,
                    onTap: () => _showExchangeRequestDialog(btnCtx, order),
                  ));
                  row1.add(_ActionBtn(
                    icon: Icons.assignment_return_outlined,
                    label: context.loc.t('반품신청', '반품신청'),
                    color: AppColors.warning,
                    onTap: () => _showReturnRequestDialog(btnCtx, order),
                  ));
                }
                // 리뷰쓰기 (구매확정 후, 개인주문만)
                if (canWriteReview) {
                  row1.add(_ActionBtn(
                    icon: Icons.rate_review_rounded,
                    label: context.loc.t('리뷰쓰기', '리뷰쓰기'),
                    color: const Color(0xFFFF8F00),
                    onTap: () => _showWriteReviewFromOrder(btnCtx, order),
                  ));
                }
              }

              // 행2: 단체주문 전용
              // 디자인수정요청 (3일 이내, 2회 미만 + 사용자 미확정)
              if (isGroup &&
                  order.canRequestDesignRevision &&
                  !order.userDesignApproved)
                row2.add(_ActionBtn(
                  icon: Icons.edit_note_rounded,
                  label: context.loc.t('디자인수정', '디자인수정'),
                  color: const Color(0xFF7B1FA2),
                  badge: '${order.remainingDesignRevisions}회',
                  onTap: () => onDesignRevision?.call(order),
                ));
              // 사용자가 디자인 확정 → 제작시작 표시
              if (isGroup && order.userDesignApproved)
                row2.add(_ActionBtn(
                  icon: Icons.precision_manufacturing_rounded,
                  label: context.loc.t('제작시작', '제작시작'),
                  color: AppColors.success,
                  onTap: null,
                ));
              // 추가제작
              if (canAdditional)
                row2.add(_ActionBtn(
                  icon: Icons.add_circle_outline_rounded,
                  label: context.loc.t('추가제작', '추가제작'),
                  color: AppColors.success,
                  onTap: () => onAdditionalOrder(order),
                ));
              // 디자인 확인 버튼 (단체주문이면 항상 표시)
              if (isGroup && !order.userDesignApproved)
                row2.add(_ActionBtn(
                  icon: Icons.image_search_rounded,
                  label: context.loc.t('디자인확인', '디자인확인'),
                  color: const Color(0xFF0277BD),
                  onTap: () => onDesignConfirm?.call(order),
                ));
              // 디자인 확정 표시 (3일 경과 or 배송 이상)
              if (isGroup &&
                  order.isDesignConfirmed &&
                  !order.canRequestDesignRevision)
                row2.add(_ActionBtn(
                  icon: Icons.check_circle_outline_rounded,
                  label: context.loc.t('디자인확정', '디자인확정'),
                  color: Colors.grey,
                  onTap: null,
                ));

              Widget buildRow(List<Widget> items) {
                final List<Widget> cells = [];
                for (int i = 0; i < items.length; i++) {
                  if (i > 0) {
                    cells.add(Container(
                        width: 1, height: 58, color: Colors.grey[200]));
                  }
                  cells.add(
                      Expanded(child: SizedBox(height: 58, child: items[i])));
                }
                return Row(children: cells);
              }

              return Column(
                children: [
                  buildRow(row1),
                  if (row2.isNotEmpty) ...[
                    Container(height: 1, color: Colors.grey[100]),
                    buildRow(row2),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.processing:
        return const Color(0xFF7B1FA2);
      case OrderStatus.shipped:
        return const Color(0xFF00838F);
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.purchaseConfirmed:
        return const Color(0xFF1B5E20);
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.refunded:
        return Colors.brown;
    }
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y.$m.$dd $hh:$min';
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

  const _MobileBtn(
      {required this.label,
      required this.color,
      this.badge,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w700)),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                    child: Text(badge!,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 네이버 스타일 아이콘+텍스트 액션 버튼 ──
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 22, color: color),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(8)),
                    child: Text(badge!,
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

  const _MobilePaymentHistoryTab(
      {required this.userProvider, required this.loc});

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;
    final orderProvider = context.watch<OrderProvider>();
    final orders =
        user != null ? orderProvider.getUserOrders(user.id) : <OrderModel>[];

    if (orders.isEmpty)
      return _MobileEmptyState(
          icon: Icons.payment_outlined, message: loc.mypageNoPayment);

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _showUserOrderDetail(context, o);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: const Color(0xFF00796B).withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.payment_rounded,
                        size: 22, color: Color(0xFF00796B)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.id,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(o.paymentMethod,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        Text(_fmtDate(o.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Text(_fmtPrice(o.totalAmount),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00796B))),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y.$m.$dd $hh:$min';
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
        .map((id) => ProductService.getProductByIdSync(id))
        .where((p) => p != null)
        .cast<ProductModel>()
        .toList();

    if (products.isEmpty) {
      return _MobileEmptyState(
          icon: Icons.favorite_border_rounded,
          message: loc.mypageNoWishlist,
          subtitle: loc.mypageNoWishlistSub);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: p))),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: NetImage(p.images.first,
                            width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => userProvider.toggleWishlist(p.id),
                          child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.favorite_rounded,
                                  size: 14, color: Colors.pinkAccent)),
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
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Text(_fmtPrice(p.price.toDouble()),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
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
class _MobileSettingsTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  final void Function(BuildContext, UserModel) onShowProfileEdit;
  final void Function(BuildContext) onShowAddressManager;
  final void Function(BuildContext, UserProvider) onShowLogout;
  final void Function(BuildContext) onShowChangePassword;
  final void Function(BuildContext, UserProvider) onShowDeleteAccount;

  const _MobileSettingsTab({
    required this.userProvider,
    required this.loc,
    required this.onShowProfileEdit,
    required this.onShowAddressManager,
    required this.onShowLogout,
    required this.onShowChangePassword,
    required this.onShowDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final user = userProvider.user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MobileSettingGroup(title: loc.mypageProfileSection, items: [
          _MobileSettingItem(
              icon: Icons.person_rounded,
              title: loc.mypageEditProfile,
              onTap:
                  user != null ? () => onShowProfileEdit(context, user) : null),
          _MobileSettingItem(
              icon: Icons.location_on_rounded,
              title: loc.mypageAddressBook,
              onTap: () => onShowAddressManager(context)),
          _MobileSettingItem(
            icon: Icons.straighten_rounded,
            title: context.loc.t('내_사이즈_관리', '내 사이즈 관리'),
            subtitle:
                context.loc.t('저장된_사이즈로_주문_시_빠_396e4b', '저장된 사이즈로 주문 시 빠르게 입력'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SizeProfileScreen()),
            ),
          ),
          _MobileSettingItem(
            icon: Icons.receipt_long_rounded,
            title: context.loc.t('현금영수증_번호', '현금영수증 번호'),
            subtitle: user?.cashReceiptNum?.isNotEmpty == true
                ? user!.cashReceiptNum!
                : context.loc.t('미등록_결제_시_자동_발행', '미등록 — 결제 시 자동 발행'),
            onTap: () => _showCashReceiptDialog(context, userProvider),
          ),
        ]),
        const SizedBox(height: 16),
        _MobileSettingGroup(title: loc.mypageNotificationSection, items: [
          _MobileSwitchItem(
              icon: Icons.notifications_rounded,
              title: loc.mypageNotifOrder,
              value: user?.orderNotificationsEnabled ?? true,
              onChanged: user == null
                  ? null
                  : (value) => userProvider.updateUserProfile(
                      orderNotificationsEnabled: value)),
          _MobileSwitchItem(
              icon: Icons.campaign_rounded,
              title: loc.mypageNotifMarketing,
              value: user?.marketingNotificationsEnabled ?? false,
              onChanged: user == null
                  ? null
                  : (value) => userProvider.updateUserProfile(
                      marketingNotificationsEnabled: value)),
        ]),
        const SizedBox(height: 16),
        _MobileSettingGroup(title: loc.mypageAppSection, items: [
          _MobileSettingItem(
              icon: Icons.language_rounded,
              title: loc.mypageLanguageSetting,
              trailing: _LanguageDropdown()),
          _MobileSettingItem(
              icon: Icons.info_outline_rounded,
              title: context.loc.t('앱_정보', '앱 정보'),
              subtitle: 'v1.0.0'),
        ]),
        const SizedBox(height: 16),
        _MobileSettingGroup(title: context.loc.t('약관_및_정책', '약관 및 정책'), items: [
          _MobileSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: context.loc.t('개인정보처리방침', '개인정보처리방침'),
            onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
          ),
          _MobileSettingItem(
            icon: Icons.description_outlined,
            title: context.loc.t('이용약관', '이용약관'),
            onTap: () => Navigator.pushNamed(context, '/terms-of-service'),
          ),
        ]),
        const SizedBox(height: 16),
        _MobileSettingGroup(title: loc.mypageSecuritySection, items: [
          if (user != null)
            _MobileSettingItem(
                icon: Icons.lock_rounded,
                title: loc.mypageChangePassword,
                onTap: () => onShowChangePassword(context)),
          _MobileSettingItem(
              icon: Icons.logout_rounded,
              title: loc.mypageLogout,
              onTap: () => onShowLogout(context, userProvider),
              color: AppColors.warning),
          if (user != null)
            _MobileSettingItem(
                icon: Icons.delete_outline_rounded,
                title: loc.mypageDeleteAccount,
                onTap: () => onShowDeleteAccount(context, userProvider),
                color: AppColors.error),
          if (user?.isAdmin == true)
            _MobileSettingItem(
              icon: Icons.admin_panel_settings_rounded,
              title: context.loc.t('관리자_페이지', '관리자 페이지'),
              subtitle: context.loc.t('관리자_대시보드_관리', '상품·주문·회원 관리 대시보드'),
              color: AppColors.error,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              ),
            ),
        ]),
        const SizedBox(height: 40),
        // ── 관리자 전용: 테스트 데이터 생성 ──
        if (user?.isAdmin == true) ...[
          const SizedBox(height: 8),
          _MobileSettingGroup(
              title: context.loc.t('개발자_도구__관리자_전용', '🔧 개발자 도구 (관리자 전용)'),
              items: [
                _MobileSettingItem(
                  icon: Icons.science_outlined,
                  title: context.loc
                      .t('테스트_주문_생성__배송조회_6c8665', '테스트 주문 생성 (배송조회 포함)'),
                  subtitle: context.loc
                      .t('운송장_등록된_shipped_e652bc', '운송장 등록된 shipped 상태 테스트 주문'),
                  color: const Color(0xFF7B1FA2),
                  onTap: () => _createTestOrder(context, user!),
                ),
              ]),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  Future<void> _createTestOrder(BuildContext context, UserModel user) async {
    final now = DateTime.now();
    final pad2 = (int v) => v.toString().padLeft(2, '0');
    final orderId =
        'ORD-TEST-${now.year}${pad2(now.month)}${pad2(now.day)}-SHIP';

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
        'id': orderId,
        'userId': user.id,
        'userName': user.name ?? '',
        'userEmail': user.email ?? '',
        'userPhone': user.phone ?? '',
        'userAddress': user.address ?? '',
        'status': 'shipped',
        'totalAmount': 72000.0,
        'shippingFee': 4000.0,
        'paymentMethod': '카카오페이',
        'orderType': 'personal',
        'createdAt': now.toIso8601String(),
        'trackingNumber': '1234567890123',
        'shippingCompany': '한진택배',
        'customOptions': {
          'trackingNumber': '1234567890123',
          'shippingCompany': '한진택배',
        },
        'items': [
          {
            'productId': 'test-001',
            'productName': '2.5부 숏 여성 골지 블랙',
            'size': 'M',
            'color': '블랙',
            'quantity': 2,
            'price': 34000.0,
            'imageUrl': '',
          }
        ],
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 테스트 주문 생성 완료\n주문번호: $orderId'),
            backgroundColor: const Color(0xFF7B1FA2),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 테스트 주문 생성 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
            ],
          ),
          child: Column(
            children: List.generate(
                items.length,
                (i) => Column(
                      children: [
                        items[i],
                        if (i < items.length - 1)
                          const Divider(height: 1, indent: 50),
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

  const _MobileSettingItem(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.trailing,
      this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[800]!;
    return ListTile(
      dense: true,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
            color: (color ?? AppColors.textSecondary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: c),
      ),
      isThreeLine: subtitle != null,
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14, color: c),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded,
                  size: 16, color: Colors.grey[400])
              : null),
      onTap: onTap,
    );
  }
}

class _MobileSwitchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _MobileSwitchItem(
      {required this.icon,
      required this.title,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14, color: Colors.black87)),
      trailing: Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: const WidgetStatePropertyAll(AppColors.primary),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
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

  const _MobileEmptyState(
      {required this.icon, required this.message, this.subtitle});

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
            Text(message,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  textAlign: TextAlign.center),
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
    _phoneCtrl = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(loc.mypageEditProfile,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 20),
            TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                    labelText: context.loc.t('이름', '이름'),
                    border: OutlineInputBorder())),
            const SizedBox(height: 14),
            TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                    labelText: context.loc.t('연락처', '연락처'),
                    border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final userProvider = context.read<UserProvider>();
                  await userProvider.updateUserProfile(
                      name: _nameCtrl.text, phone: _phoneCtrl.text);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child:
                    Text(loc.save, style: const TextStyle(color: Colors.white)),
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

  // 수량 입력
  int _quantity = 1;

  @override
  void dispose() {
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
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // 헤더
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF795548).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_circle_outline_rounded,
                    color: Color(0xFF795548), size: 22),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_loc.additionalProduction,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
                Text(_loc.groupCustomOnly,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF795548))),
              ]),
            ]),
            const SizedBox(height: 14),

            // 주문 정보
            _infoBox([
              _infoRow(loc.mypageOrderNumber, widget.order.id),
              _infoRow(loc.mypageOrderDate,
                  '${widget.order.createdAt.year}.${widget.order.createdAt.month.toString().padLeft(2, '0')}.${widget.order.createdAt.day.toString().padLeft(2, '0')}'),
              _infoRow(loc.mypageOriginalQty,
                  '${widget.order.groupCount ?? widget.order.items.fold<int>(0, (s, i) => s + i.quantity)}장'),
            ]),
            const SizedBox(height: 14),

            // ── 수량 ──
            Row(
              children: [
                Text(_loc.additionalQty,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _quantity > 1
                          ? const Color(0xFF795548).withValues(alpha: 0.1)
                          : AppColors.surfaceGray,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.remove,
                        size: 16,
                        color: _quantity > 1
                            ? const Color(0xFF795548)
                            : AppColors.border),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$_quantity',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _quantity++),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF795548).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add,
                        size: 16, color: Color(0xFF795548)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── 배송비 실시간 안내 ──
            Builder(builder: (_) {
              final isFreeShip = _quantity >= AppConstants.groupMinFreeShipping;
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isFreeShip
                      ? AppColors.success.withValues(alpha: 0.07)
                      : AppColors.warning.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFreeShip
                        ? AppColors.success.withValues(alpha: 0.35)
                        : AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 15,
                    color: isFreeShip ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, height: 1.5),
                        children: [
                          TextSpan(
                            text: isFreeShip
                                ? context.loc.t('무료배송', '무료배송')
                                : '배송비 4,000원',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isFreeShip
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          TextSpan(
                            text: isFreeShip
                                ? context.loc.t('k_5장_이상', '  (5장 이상)')
                                : context.loc
                                    .t('5장_이상_주문_시_무료', '  — 5장 이상 주문 시 무료'),
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 10),

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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_loc.cancel,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupOrderFormScreen(
                            product: null,
                            isAdditionalOrder: true,
                            originalOrder: widget.order,
                            initialCount: _quantity,
                          ),
                        ));
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                  label: Text(_loc.writeAdditionalOrder,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF795548),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: rows),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _noticeBox(
          {required Color color,
          required String title,
          required List<String> items}) =>
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
            Text(title,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 6),
            ...items.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(t,
                      style: const TextStyle(fontSize: 12, height: 1.4)),
                )),
          ],
        ),
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
      builder: (_) => _AddressFormSheet(
          existing: existing,
          userName: widget.user.name,
          userPhone: widget.user.phone),
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
                Text(_loc.mypageShippingManage,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
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
                        const Icon(Icons.location_off_rounded,
                            size: 48, color: AppColors.border),
                        const SizedBox(height: 12),
                        Text(_loc.mypageNoAddress,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addOrEdit,
                          icon: const Icon(Icons.add),
                          label: Text(_loc.mypageAddAddress),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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
                            Text(a.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(width: 8),
                            if (a.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(_loc.mypageDefault,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${a.recipient} · ${a.phone}',
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('[${a.zipCode}] ${a.address1}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              if (a.address2.isNotEmpty)
                                Text(a.address2,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
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
                              PopupMenuItem(
                                  value: 'default',
                                  child: Text(_loc.mypageSetDefault)),
                            PopupMenuItem(
                                value: 'edit', child: Text(_loc.mypageEdit)),
                            PopupMenuItem(
                                value: 'delete',
                                child: Text(_loc.mypageDelete,
                                    style: const TextStyle(
                                        color: AppColors.error))),
                          ],
                          child: const Icon(Icons.more_vert_rounded,
                              color: AppColors.textSecondary),
                        ),
                      );
                    },
                  ),
          ),
          // 추가 버튼
          if (_addresses.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addOrEdit,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: Text(_loc.mypageAddNewAddress,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
  const _AddressFormSheet(
      {this.existing, required this.userName, required this.userPhone});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  AppLocalizations get _loc => context.watch<LanguageProvider>().loc;

  final _labelCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl.text = e?.label ?? _loc.addrLabelHome;
    _recipientCtrl.text = e?.recipient ?? widget.userName;
    _phoneCtrl.text = e?.phone ?? widget.userPhone;
    _zipCtrl.text = e?.zipCode ?? '';
    _addr1Ctrl.text = e?.address1 ?? '';
    _addr2Ctrl.text = e?.address2 ?? '';
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _recipientCtrl.dispose();
    _phoneCtrl.dispose();
    _zipCtrl.dispose();
    _addr1Ctrl.dispose();
    _addr2Ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_addr1Ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_loc.mypageEnterAddress)));
      return;
    }
    if (_recipientCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_loc.mypageEnterRecipient)));
      return;
    }
    final addr = AddressModel(
      id: widget.existing?.id ??
          'addr_${DateTime.now().millisecondsSinceEpoch}',
      label: _labelCtrl.text.trim().isEmpty
          ? _loc.addrLabelHome
          : _labelCtrl.text.trim(),
      recipient: _recipientCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      address1: _addr1Ctrl.text.trim(),
      address2: _addr2Ctrl.text.trim(),
      isDefault: _isDefault,
    );
    Navigator.pop(context, addr);
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: type,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  Text(
                      widget.existing == null
                          ? _loc.mypageAddressAdd
                          : _loc.mypageAddressEdit,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _field(_loc.mypageShippingLabelField, _labelCtrl,
                        hint: _loc.mypageShippingLabelHint),
                    _field(_loc.recipientLabel, _recipientCtrl,
                        hint: _loc.recipientHint),
                    _field(_loc.phoneLabel, _phoneCtrl,
                        hint: '010-0000-0000', type: TextInputType.phone),
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
                                _zipCtrl.text = result.zonecode;
                                _addr1Ctrl.text = result.address;
                              });
                            }
                          },
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: Text(_loc.mypageAddressSearch,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                    _field(_loc.zipLabel, _zipCtrl,
                        hint: _loc.zipHint, type: TextInputType.number),
                    _field(_loc.addr1Label, _addr1Ctrl, hint: _loc.addr1Hint),
                    _field(_loc.addr2Label, _addr2Ctrl, hint: _loc.addr2Hint),
                    // 기본 배송지 체크
                    GestureDetector(
                      onTap: () => setState(() => _isDefault = !_isDefault),
                      child: Row(
                        children: [
                          Icon(
                              _isDefault
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: _isDefault
                                  ? AppColors.primary
                                  : AppColors.textHint,
                              size: 22),
                          const SizedBox(width: 8),
                          Text(_loc.mypageSetDefaultAddress,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                            widget.existing == null
                                ? _loc.mypageAddressAdd
                                : _loc.mypageAddressComplete,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
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

// ── 사용자 주문 상세 다이얼로그 ──────────────────────────────────────
Future<void> _showUserOrderDetail(
    BuildContext context, OrderModel order) async {
  // Firestore에서 최신 데이터 직접 조회 (items 보장)
  OrderModel freshOrder = order;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(order.id)
        .get();
    if (doc.exists && doc.data() != null) {
      freshOrder =
          OrderService.parseOrderFromFirestore(doc.data()!, docId: doc.id);
    }
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ 주문 상세 재조회 실패: $e');
  }
  if (!context.mounted) return;

  // ── 헬퍼 함수 ──
  String fmtPrice(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String fmtDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  Color statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return const Color(0xFFFF8F00);
      case OrderStatus.confirmed:
        return AppColors.primary;
      case OrderStatus.processing:
        return AppColors.primary;
      case OrderStatus.shipped:
        return const Color(0xFF00838F);
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.purchaseConfirmed:
        return const Color(0xFF1B5E20);
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.refunded:
        return AppColors.textSecondary;
    }
  }

  Widget miniTag(String text, Color color) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
      );

  Widget detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          SizedBox(
              width: 56,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary))),
        ]),
      );

  Widget sectionBox(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: rows),
          ),
        ],
      );

  final o = freshOrder;
  final sc = statusColor(o.status);
  final isGroup = o.orderType == 'group' ||
      o.orderType == 'additional' ||
      o.id.startsWith('GRP_') ||
      o.id.startsWith('GROUP-');

  showDialog(
    context: context,
    builder: (dlgCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2D2D5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.id,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(fmtDate(o.createdAt),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                )),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sc.withValues(alpha: 0.5)),
                  ),
                  child: Text(o.status.label,
                      style: TextStyle(
                          color: sc,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(dlgCtx),
                  child:
                      const Icon(Icons.close, color: Colors.white70, size: 22),
                ),
              ]),
            ),

            // ── 스크롤 콘텐츠 ─────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 주문자 정보
                    sectionBox(context.loc.t('주문자_정보', '주문자 정보'), [
                      detailRow(Icons.person_outline, context.loc.t('이름', '이름'),
                          o.userName.isNotEmpty ? o.userName : '-'),
                      detailRow(
                          Icons.phone_outlined,
                          context.loc.t('연락처', '연락처'),
                          o.userPhone.isNotEmpty ? o.userPhone : '-'),
                      detailRow(
                          Icons.email_outlined,
                          context.loc.t('이메일', '이메일'),
                          o.userEmail.isNotEmpty ? o.userEmail : '-'),
                      detailRow(
                          Icons.location_on_outlined,
                          context.loc.t('배송지', '배송지'),
                          o.userAddress.isNotEmpty ? o.userAddress : '-'),
                    ]),
                    if (o.isGroupOrder && o.activeDesignRevisionDeadline != null) ...[
                      const SizedBox(height: 14),
                      DesignRevisionCountdown(
                        deadline: o.activeDesignRevisionDeadline,
                        revisionCount: o.designRevisionCount,
                      ),
                    ],
                    const SizedBox(height: 14),

                    // 주문 상품
                    Text(context.loc.t('주문_상품', '주문 상품'),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const SizedBox(height: 8),
                    if (o.items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(context.loc.t('상품_정보_없음', '상품 정보 없음'),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ...o.items.map((item) {
                        final typeLabel = o.orderType == 'additional'
                            ? '추가제작'
                            : isGroup
                                ? context.loc.t('단체', '단체')
                                : context.loc.t('개인', '개인');
                        final typeColor = o.orderType == 'additional'
                            ? const Color(0xFFC62828)
                            : isGroup
                                ? AppColors.primary
                                : AppColors.primary;
                        final displaySize = (item.size == '단체' ||
                                item.size == 'GROUP' ||
                                item.size.isEmpty)
                            ? null
                            : item.size;
                        final imageUrl = item.imageUrl?.isNotEmpty == true
                            ? item.imageUrl!
                            : (item.customOptions?['productImageUrl']
                                            as String?)
                                        ?.isNotEmpty ==
                                    true
                                ? item.customOptions!['productImageUrl']
                                    as String
                                : (item.customOptions?['designFileUrl']
                                                as String?)
                                            ?.isNotEmpty ==
                                        true
                                    ? item.customOptions!['designFileUrl']
                                        as String
                                    : null;
                        final hasImage = imageUrl != null;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 디자인 이미지 (왼쪽)
                                if (hasImage) ...[
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: Image.network(
                                      imageUrl,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                        child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 28,
                                            color: AppColors.textHint),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                // 텍스트 정보 (오른쪽)
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          miniTag(typeLabel, typeColor),
                                          if (item.color.isNotEmpty)
                                            miniTag(
                                                item.color, AppColors.accent),
                                          if (displaySize != null) ...[
                                            const SizedBox(width: 2),
                                            miniTag(
                                                displaySize, AppColors.success),
                                          ],
                                        ]),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.quantity}개  ·  ${fmtPrice(item.price * item.quantity)}원',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ]),
                                ),
                              ]),
                        );
                      }),
                    const SizedBox(height: 14),

                    // ── 수정된 디자인 이미지 (관리자 응답 완료 시) ──
                    if (o.designConfirmedImageUrl?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF7B1FA2)
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 헤더
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B1FA2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.design_services_rounded,
                                      size: 14,
                                      color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            context.loc.t('수정된_디자인', '수정된 디자인'),
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.primaryLight)),
                                        Text(
                                            context.loc.t(
                                                '관리자가_수정_반영한_최신__549655',
                                                '관리자가 수정 반영한 최신 디자인입니다'),
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF7B1FA2))),
                                      ]),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B1FA2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(context.loc.t('수정_완료', '수정 완료'),
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              // 이미지
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    backgroundColor: Colors.black,
                                    insetPadding: const EdgeInsets.all(12),
                                    child: Stack(children: [
                                      InteractiveViewer(
                                        child: Image.network(
                                          o.designConfirmedImageUrl!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Center(
                                                  child: Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color: Colors.white54,
                                                      size: 60)),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle),
                                            child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.white,
                                                size: 18),
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(children: [
                                    Image.network(
                                      o.designConfirmedImageUrl!,
                                      width: double.infinity,
                                      height: 220,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (_, child, prog) =>
                                          prog == null
                                              ? child
                                              : Container(
                                                  height: 220,
                                                  color:
                                                      const Color(0xFFF3E5F5),
                                                  child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              color: Color(
                                                                  0xFF7B1FA2),
                                                              strokeWidth: 2)),
                                                ),
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 120,
                                        color: const Color(0xFFEDE7F6),
                                        child: const Center(
                                            child: Icon(
                                                Icons.broken_image_outlined,
                                                size: 40,
                                                color: Color(0xFF7B1FA2))),
                                      ),
                                    ),
                                    // 확대 힌트
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.zoom_in_rounded,
                                                  size: 12,
                                                  color: Colors.white),
                                              SizedBox(width: 3),
                                              Text(
                                                  context.loc
                                                      .t('탭하여_확대', '탭하여 확대'),
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white)),
                                            ]),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 요청 내용 요약
                              if (o.designRevisionRequest?['memo']
                                      ?.isNotEmpty ==
                                  true)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 13,
                                            color: Color(0xFF7B1FA2)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            o.designRevisionRequest!['memo']
                                                as String,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textPrimary,
                                                height: 1.5),
                                          ),
                                        ),
                                      ]),
                                ),
                            ]),
                      ),
                      const SizedBox(height: 14),
                    ] else if (o.designRevisionRequest != null &&
                        o.designRevisionRequest!['status'] == 'pending') ...[
                      // 수정 요청 대기 중 배너
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFFF9800)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.hourglass_top_rounded,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      context.loc.t(
                                          '디자인_수정_요청_검토_중', '디자인 수정 요청 검토 중'),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accent)),
                                  Text(
                                      context.loc.t('관리자가_요청을_확인하고_수_87c10f',
                                          '관리자가 요청을 확인하고 수정된 디자인을 업로드하면 여기에 표시됩니다.'),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFBF360C),
                                          height: 1.4)),
                                ]),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 결제 정보
                    sectionBox(context.loc.t('결제_정보', '결제 정보'), [
                      detailRow(
                          Icons.payments_outlined,
                          context.loc.t('결제방법', '결제방법'),
                          o.paymentMethod.isNotEmpty ? o.paymentMethod : '-'),
                      detailRow(
                          Icons.local_shipping_outlined,
                          context.loc.t('배송비', '배송비'),
                          o.shippingFee == 0
                              ? context.loc.t('무료', '무료')
                              : '${fmtPrice(o.shippingFee)}원'),
                      if (o.couponDiscount > 0)
                        detailRow(
                            Icons.local_offer_outlined,
                            context.loc.t('쿠폰할인', '쿠폰 할인'),
                            '-${fmtPrice(o.couponDiscount)}원'),
                      if (o.usedPoints > 0)
                        detailRow(
                            Icons.stars_outlined,
                            context.loc.t('포인트사용', '포인트 사용'),
                            '-${fmtPrice(o.pointDiscount)}원 (${o.usedPoints}P)'),
                      detailRow(Icons.receipt_outlined, '합계',
                          '${fmtPrice(o.totalAmount)}원'),
                      if ((o.cashReceiptNum ?? '').isNotEmpty)
                        detailRow(Icons.receipt_long_rounded,
                            context.loc.t('현금영수증', '현금영수증'), o.cashReceiptNum!),
                      if ((o.memo ?? '').isNotEmpty)
                        detailRow(Icons.notes_outlined,
                            context.loc.t('메모', '메모'), o.memo!),
                    ]),
                    // 영수증 보기 버튼 (항상 표시)
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showReceiptDialog(dlgCtx, o),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFEFF3FF),
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 15, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(context.loc.t('영수증_보기', '영수증 보기'),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 하단 닫기 버튼 ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(context.loc.t('닫기', '닫기'),
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── 네이버 스타일 섹션 컨테이너
Widget _npSection(
    {required String title, required IconData icon, required Widget child}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 0),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 6)),
    ),
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 15, color: Colors.black87),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

// ── 정보 행 (단체주문 정보 등)
Widget _npInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(
          width: 72,
          child: Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
      Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
  );
}

// ── 금액 행
Widget _npAmtRow(String label, String value,
    {Color? valueColor, Color? labelColor}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style:
              TextStyle(fontSize: 13, color: labelColor ?? Colors.grey[600])),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── 액션 버튼 (배송조회, 취소 등)
Widget _npActionButton(
    {required String label,
    required VoidCallback onTap,
    bool isPrimary = false}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF03C75A) : Colors.white,
        border: Border.all(
            color: isPrimary ? const Color(0xFF03C75A) : Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : Colors.black87,
          )),
    ),
  );
}

// ════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════
// 디자인 확인 바텀시트 (수정완료 이미지 전용)
// ═══════════════════════════════════════════════════════
class _DesignConfirmSheet extends StatefulWidget {
  final OrderModel order;
  const _DesignConfirmSheet({required this.order});

  @override
  State<_DesignConfirmSheet> createState() => _DesignConfirmSheetState();
}

class _DesignConfirmSheetState extends State<_DesignConfirmSheet> {
  bool _isApproving = false; // 확정 처리 중 로딩
  bool _approved = false; // 이 세션에서 방금 확정 완료됨

  Future<void> _approveDesign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
            SizedBox(width: 8),
            Text(context.loc.t('디자인_확정', '디자인 확정'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          context.loc.t('수정_완료_디자인을_확정하시겠습니까_n_n확정_후에는_디자인__cf9296',
              '수정 완료 디자인을 확정하시겠습니까?\n\n확정 후에는 디자인 수정 요청이 불가하며, 즉시 제작이 시작됩니다.'),
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.loc.t('취소', '취소'),
                style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(context.loc.t('확정하기', '확정하기'),
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isApproving = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'customOptions.userDesignApproved': true,
        'customOptions.userDesignApprovedAt': DateTime.now().toIso8601String(),
        'designRevisionDeadline': DateTime.now()
            .subtract(const Duration(seconds: 1))
            .toIso8601String(),
      });
      if (!mounted) return;
      setState(() {
        _isApproving = false;
        _approved = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApproving = false);
      // 시트 내부 ScaffoldMessenger 사용 (부모 SnackBar와 겹침 방지)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.loc.t('오류가 발생했습니다 _', '오류가 발생했습니다: $e')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final imageUrl = order.designConfirmedImageUrl;
    final req = order.designRevisionRequest;
    final memo = req?['memo'] as String?;
    final colorName = req?['colorName'] as String?;
    final colorHex = req?['adjustedColorHex'] as String?;
    final teamName = req?['teamName'] as String?;
    final fabricName = req?['fabricName'] as String?;
    final printType = req?['printType'] as String?;
    final personChanges = (req?['personChanges'] as List<dynamic>?) ?? [];
    final screenH = MediaQuery.of(context).size.height;
    final alreadyApproved = _approved || order.userDesignApproved;

    // 변경 항목 목록 구성
    final changeItems = <Map<String, String>>[];
    if (colorName?.isNotEmpty == true)
      changeItems
          .add({'label': context.loc.t('색상', '색상'), 'value': colorName!});
    if (teamName?.isNotEmpty == true)
      changeItems
          .add({'label': context.loc.t('단체명', '단체명'), 'value': teamName!});
    if (fabricName?.isNotEmpty == true)
      changeItems
          .add({'label': context.loc.t('원단', '원단'), 'value': fabricName!});
    if (printType?.isNotEmpty == true)
      changeItems
          .add({'label': context.loc.t('인쇄_방식', '인쇄 방식'), 'value': printType!});
    if (personChanges.isNotEmpty)
      changeItems
          .add({'label': '사이즈 변경', 'value': '${personChanges.length}명 변경'});
    if (memo?.isNotEmpty == true)
      changeItems
          .add({'label': context.loc.t('추가_메모', '추가 메모'), 'value': memo!});

    // ScaffoldMessenger로 감싸 SnackBar가 시트 내부에만 표시되도록
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ── 핸들 ──────────────────────────────
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
                // ── 헤더 ──────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0277BD), Color(0xFF01579B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_search_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            context.loc.t('수정_완료_디자인_확인', '수정 완료 디자인 확인'),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // ── 본문 ──────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ① 주문 정보 요약
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F8FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBDEFB)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.receipt_long_rounded,
                                color: Color(0xFF0277BD), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.items.isEmpty
                                      ? context.loc.t('주문 상품', '주문 상품')
                                      : order.items.first.productName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF01579B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text('주문번호: ${order.id}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600])),
                              ],
                            )),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // ② 수정 완료 디자인 이미지 (먼저 크게)
                        Text(context.loc.t('수정_완료_디자인', '수정 완료 디자인'),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF37474F))),
                        const SizedBox(height: 8),

                        if (imageUrl == null || imageUrl.isEmpty)
                          Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.hourglass_top_rounded,
                                      size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                      context.loc.t('아직_수정_완료_이미지가_준_379d1c',
                                          '아직 수정 완료 이미지가 준비 중입니다.'),
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500])),
                                ]),
                          )
                        else
                          // 이미지 카드 — 탭하면 풀스크린
                          GestureDetector(
                            onTap: () => _openFullscreen(context, imageUrl),
                            child: Container(
                              width: double.infinity,
                              constraints:
                                  BoxConstraints(maxHeight: screenH * 0.48),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFBBDEFB), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Image.network(
                                        imageUrl,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        loadingBuilder: (_, child, progress) {
                                          if (progress == null) return child;
                                          return SizedBox(
                                              height: 200,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: progress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? progress
                                                              .cumulativeBytesLoaded /
                                                          progress
                                                              .expectedTotalBytes!
                                                      : null,
                                                  color:
                                                      const Color(0xFF0277BD),
                                                ),
                                              ));
                                        },
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 200,
                                          color: Colors.grey[100],
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 48,
                                                    color: Colors.grey[400]),
                                                const SizedBox(height: 8),
                                                Text(
                                                    context.loc.t(
                                                        '이미지를_불러올_수_없습니다',
                                                        '이미지를 불러올 수 없습니다.'),
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color:
                                                            Colors.grey[500])),
                                              ]),
                                        ),
                                      ),
                                      // 확대 힌트
                                      Container(
                                        margin: const EdgeInsets.all(10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.65),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.zoom_in_rounded,
                                                  color: Colors.white,
                                                  size: 15),
                                              SizedBox(width: 4),
                                              Text(
                                                  context.loc
                                                      .t('탭하여_확대', '탭하여 확대'),
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ]),
                                      ),
                                    ]),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // ③ 수정 변경 내용 (항목이 있을 때)
                        if (changeItems.isNotEmpty) ...[
                          Text(context.loc.t('수정_요청_내용', '수정 요청 내용'),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF37474F))),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDE7),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFFFE082)),
                            ),
                            child: Column(
                              children: changeItems
                                  .map((item) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 72,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF8F00)
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(item['label']!,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.accent)),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(item['value']!,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color:
                                                            Color(0xFF4E342E),
                                                        height: 1.4))),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          // 인원별 사이즈 상세 (있으면)
                          if (personChanges.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${context.loc.t('인원별_사이즈', '인원별 사이즈')} 변경 상세 (${personChanges.length}명)',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[700])),
                                  const SizedBox(height: 6),
                                  ...personChanges.map((p) {
                                    final m = p as Map;
                                    final name = m['name'] as String? ?? '';
                                    final newVal = m['newValue'] as String? ??
                                        m['size'] as String? ??
                                        '';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Row(children: [
                                        const Icon(Icons.person_outline_rounded,
                                            size: 13, color: Color(0xFF7B1FA2)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                            child: Text(
                                          name.isNotEmpty
                                              ? '$name: $newVal'
                                              : newVal,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF37474F)),
                                        )),
                                      ]),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                          // 색상 헥스 프리뷰
                          if (colorHex?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.palette_rounded,
                                  size: 14, color: Color(0xFF7B1FA2)),
                              const SizedBox(width: 6),
                              Text('요청 색상 코드: $colorHex',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryLight)),
                              const SizedBox(width: 8),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _hexToColor(colorHex!),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                              ),
                            ]),
                          ],
                          const SizedBox(height: 16),
                        ],

                        // ④ 안내 or 확정 완료 배너
                        if (alreadyApproved)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Row(children: [
                              Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.loc.t('디자인_확정_완료', '디자인 확정 완료'),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1B5E20))),
                                  SizedBox(height: 2),
                                  Text(
                                      context.loc.t('제작이_시작되었습니다__완성_2af32d',
                                          '제작이 시작되었습니다. 완성까지 조금만 기다려 주세요!'),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF388E3C),
                                          height: 1.5)),
                                ],
                              )),
                            ]),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: Color(0xFF0277BD), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                    child: Text(
                                  context.loc.t(
                                      '이미지를_탭하면_핀치줌으로_확대확인할_수_있습니다_이상이_없으_e9c46b',
                                      '이미지를 탭하면 핀치줌으로 확대확인할 수 있습니다. 이상이 없으면 아래 디자인 확정하기를 눌러 제작을 시작해 주세요.'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF01579B),
                                      height: 1.5),
                                )),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // ⑤ 버튼 영역
                        if (alreadyApproved)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(context.loc.t('닫기', '닫기'),
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ),
                          )
                        else
                          Row(children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[700],
                                    side: BorderSide(color: Colors.grey[400]!),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: Text(context.loc.t('닫기', '닫기'),
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isApproving ? null : _approveDesign,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[300],
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  icon: _isApproving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 18),
                                  label: Text(
                                    _isApproving
                                        ? context.loc.t('처리 중', '처리 중...')
                                        : '디자인 확정하기',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ), // DraggableScrollableSheet
      ), // Scaffold body
    ); // ScaffoldMessenger
  }

  /// #RRGGBB 문자열 → Color
  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _openFullscreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              context.loc.t('수정_완료_디자인', '수정 완료 디자인'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 6.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (_, __, ___) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_outlined,
                        size: 64, color: Colors.white54),
                    const SizedBox(height: 12),
                    Text(context.loc.t('이미지를_불러올_수_없습니다', '이미지를 불러올 수 없습니다.'),
                        style: TextStyle(color: Colors.white60, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 디자인 수정 요청 바텀시트
// ════════════════════════════════════════════════
class _DesignRevisionSheet extends StatefulWidget {
  final OrderModel order;
  const _DesignRevisionSheet({required this.order});

  @override
  State<_DesignRevisionSheet> createState() => _DesignRevisionSheetState();
}

class _DesignRevisionSheetState extends State<_DesignRevisionSheet>
    with TickerProviderStateMixin {
  final _memoCtrl = TextEditingController();
  final _teamNameCtrl = TextEditingController();
  final _hexCtrl = TextEditingController();
  bool _submitted = false;
  bool _isSubmitting = false;

  // ── 기존 주문에서 읽어온 값
  late String _currentColor;
  late String _currentFabric;
  late String _currentPrintType; // 인쇄타입
  late String _currentTeamName;
  late List<Map<String, dynamic>> _persons;
  late List<TextEditingController> _personSizeCtrl;

  // ── 색상 선택 state
  String? _newColorName;
  Color? _newColorValue;
  double _colorLightness = 0.5;
  Color _hexPreview = AppColors.primary;
  String? _hexError;
  late TabController _colorTabCtrl;

  // ── 농도 조절된 최종 색상
  Color get _adjustedColor {
    if (_newColorValue == null) return Colors.grey;
    final hsl = HSLColor.fromColor(_newColorValue!);
    return hsl.withLightness(_colorLightness.clamp(0.05, 0.95)).toColor();
  }

  String get _lightnessLabel {
    if (_colorLightness < 0.25) return context.loc.t('매우 진하게', '매우 진하게');
    if (_colorLightness < 0.4) return context.loc.t('진하게', '진하게');
    if (_colorLightness < 0.6) return context.loc.t('기본', '기본');
    if (_colorLightness < 0.75) return context.loc.t('밝게', '밝게');
    return context.loc.t('매우 밝게', '매우 밝게');
  }

  @override
  void initState() {
    super.initState();
    _colorTabCtrl = TabController(length: 3, vsync: this);
    final opts = widget.order.customOptions ?? {};

    _currentColor = (opts['mainColor'] as String?) ?? '';
    _currentFabric = (opts['fabric'] as String?) ?? '';
    final ptRaw = opts['printType'];
    _currentPrintType = _printTypeLabel(ptRaw is int
        ? ptRaw
        : (ptRaw is String ? int.tryParse(ptRaw) ?? -1 : -1));
    _currentTeamName =
        (opts['teamName'] as String?) ?? widget.order.groupName ?? '';
    _teamNameCtrl.text = _currentTeamName;

    // 인원별 사이즈 목록
    final rawPersons = (opts['persons'] as List<dynamic>?) ?? [];
    _persons =
        rawPersons.map((p) => Map<String, dynamic>.from(p as Map)).toList();
    _personSizeCtrl = _persons.map((p) {
      final top = (p['topSize'] as String?) ?? '';
      final bottom = (p['bottomSize'] as String?) ?? '';
      final combined = [
        if (top.isNotEmpty) '상의 $top',
        if (bottom.isNotEmpty) '하의 $bottom'
      ].join(' / ');
      return TextEditingController(text: combined);
    }).toList();

    // 기존 색상 hex 로 Color 초기화
    // registeredColors (K (블랙) 형식) → twoFitColors (블랙 형식) 순으로 매칭
    if (_currentColor.isNotEmpty) {
      // ① AppColorPalette.registeredColors 에서 name 직접 매칭
      Map<String, dynamic> match = AppColorPalette.registeredColors.firstWhere(
        (c) => c['name'] == _currentColor,
        orElse: () => <String, dynamic>{},
      );
      // ② 매칭 안 되면 twoFitColors 한글명으로 매칭 후 hex 기반으로 AppColorPalette 재탐색
      if (match.isEmpty) {
        final legacy = AppConstants.twoFitColors.firstWhere(
          (c) => c['name'] == _currentColor,
          orElse: () => <String, dynamic>{},
        );
        if (legacy.isNotEmpty) {
          final targetHex = legacy['hex'] as int;
          match = AppColorPalette.registeredColors.firstWhere(
            (c) => (c['hex'] as int) == targetHex,
            orElse: () => <String, dynamic>{},
          );
        }
      }
      if (match.isNotEmpty) {
        _newColorName = match['name'] as String;
        _newColorValue = Color(match['hex'] as int);
        _colorLightness =
            HSLColor.fromColor(_newColorValue!).lightness.clamp(0.05, 0.95);
      } else {
        // ③ 그래도 없으면 그냥 currentColor 이름 그대로 유지
        _newColorName = _currentColor;
      }
    }
  }

  @override
  void dispose() {
    _colorTabCtrl.dispose();
    _memoCtrl.dispose();
    _teamNameCtrl.dispose();
    _hexCtrl.dispose();
    for (final c in _personSizeCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  // printType int → 라벨 문자열
  String _printTypeLabel(int id) {
    final labels = {
      0: context.loc.t('디자인_유지_색상_변경', '디자인 유지 + 색상 변경'),
      1: context.loc.t('디자인_유지_단체명_색상_변경', '디자인 유지 + 단체명 + 색상 변경'),
      2: context.loc.t('디자인_변경_단체명_색상_변경', '디자인 변경 + 단체명 + 색상 변경'),
      3: context.loc.t('디자인_유지_색상변경_단체명_이름_후면', '디자인 유지 + 색상변경 + 단체명 + 이름(후면)'),
      4: context.loc.t('디자인_변경_색상변경_단체명_이름_후면', '디자인 변경 + 색상변경 + 단체명 + 이름(후면)'),
    };
    return labels[id] ?? context.loc.t('정보 없음', '정보 없음');
  }

  // 현재 단계의 1주일 자동확정 안내
  String get _deadlineText {
    final deadline = widget.order.activeDesignRevisionDeadline;
    if (deadline == null) return '';
    final diff = deadline.difference(DateTime.now()).inDays;
    if (diff <= 0) return context.loc.t('수정 기간 종료', '수정 기간 종료');
    return '$diff일 후 자동 확정';
  }

  Future<void> _submit() async {
    if (!widget.order.canDesignRevision) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.loc
                .t('디자인 수정 가능 횟수를 모두 사용했습니다', '디자인 수정 가능 횟수를 모두 사용했습니다.'))),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final db = FirebaseFirestore.instance;
      final deadline = DateTime.now().add(const Duration(days: 7));

      // 변경된 인원별 사이즈 수집
      final personChanges = <Map<String, dynamic>>[];
      for (int i = 0; i < _persons.length; i++) {
        final p = _persons[i];
        final newVal = _personSizeCtrl[i].text.trim();
        final oldTop = (p['topSize'] as String?) ?? '';
        final oldBottom = (p['bottomSize'] as String?) ?? '';
        final oldCombined = [
          if (oldTop.isNotEmpty) '상의 $oldTop',
          if (oldBottom.isNotEmpty) '하의 $oldBottom'
        ].join(' / ');
        if (newVal != oldCombined) {
          personChanges.add({
            'index': p['index'] ?? (i + 1),
            'name': p['name'] ?? '',
            'gender': p['gender'] ?? '',
            'before': oldCombined,
            'after': newVal,
          });
        }
      }

      // 변경사항 요약 텍스트 생성
      final changeSummary = StringBuffer();
      // 색상 변경: _newColorValue가 _currentColor hex와 다른 경우에만
      if (_newColorName != null && _newColorValue != null) {
        // currentColor hex 찾기 (twoFitColors 또는 registeredColors 둘 다 체크)
        int? currentHex;
        final legacyMatch = AppConstants.twoFitColors.firstWhere(
            (c) => c['name'] == _currentColor,
            orElse: () => <String, dynamic>{});
        if (legacyMatch.isNotEmpty) {
          currentHex = legacyMatch['hex'] as int;
        } else {
          final regMatch = AppColorPalette.registeredColors.firstWhere(
              (c) => c['name'] == _currentColor,
              orElse: () => <String, dynamic>{});
          if (regMatch.isNotEmpty) currentHex = regMatch['hex'] as int;
        }
        final newHex = _newColorValue!.toARGB32() & 0x00FFFFFF |
            0xFF000000; // alpha 제거 후 비교용
        final curHexCmp =
            currentHex != null ? (currentHex & 0x00FFFFFF | 0xFF000000) : null;
        if (curHexCmp == null || newHex != curHexCmp) {
          changeSummary.writeln('■ 색상: $_currentColor → $_newColorName');
        }
      }
      final newTeamName = _teamNameCtrl.text.trim();
      if (newTeamName != _currentTeamName) {
        changeSummary.writeln('■ 단체명: $_currentTeamName → $newTeamName');
      }
      if (personChanges.isNotEmpty) {
        changeSummary.writeln('■ 사이즈 변경 (${personChanges.length}명):');
        for (final ch in personChanges) {
          final nameStr =
              (ch['name'] as String).isNotEmpty ? ' ${ch['name']}' : '';
          changeSummary.writeln(
              '  ${ch['index']}번$nameStr: ${ch['before']} → ${ch['after']}');
        }
      }
      if (_memoCtrl.text.trim().isNotEmpty) {
        changeSummary.writeln('■ 추가 요청: ${_memoCtrl.text.trim()}');
      }

      if (changeSummary.isEmpty) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(context.loc.t('변경할 내용을 입력해주세요', '변경할 내용을 입력해주세요.'))),
        );
        return;
      }

      await db.collection('orders').doc(widget.order.id).update({
        'designRevisionCount': FieldValue.increment(1),
        'designRevisionDeadline': deadline.toIso8601String(),
        'designRevisionRequest': {
          'memo': changeSummary.toString().trim(),
          'colorName': _newColorName,
          'adjustedColorHex': _newColorValue != null
              ? '#${_adjustedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}'
              : null,
          'colorLightness': _colorLightness,
          'fabricName': _currentFabric,
          'printType': _currentPrintType,
          'teamName': newTeamName,
          'personChanges': personChanges,
          'requestedAt': DateTime.now().toIso8601String(),
          'status': 'pending',
        },
      });

      try {
        await EmailService.sendAdminAlert(
          subject: '[2FIT] 디자인 수정 요청 - 주문 ${widget.order.id}',
          body:
              '주문번호: \${widget.order.id}\n고객: \${widget.order.userName}\n남은횟수: \${widget.order.remainingDesignRevisions - 1}회\n응답기한: \${deadline.year}.\${deadline.month}.\${deadline.day}\n\n변경 요청:\n\${changeSummary.toString()}',
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
          SnackBar(
              content: Text(context.loc.t('요청 실패 _', '요청 실패: $e')),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.92;
    const purple = Color(0xFF7B1FA2);

    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Center(
              child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          )),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              const Icon(Icons.edit_note_rounded, color: purple, size: 22),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(context.loc.t('디자인_수정_요청', '디자인 수정 요청'),
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w900)),
                    Text('주문번호: ${widget.order.id}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ])),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${widget.order.remainingDesignRevisions}회 남음',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: purple)),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: _submitted
                ? _buildSuccess()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── 단계별 1주일 자동확정 안내 ──
                          if (widget.order.activeDesignRevisionDeadline != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFFFCC02)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.timer_outlined,
                                    size: 16, color: AppColors.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                  '${widget.order.designRevisionCount == 0 ? '1차 수정' : '2차 수정'} 기간 종료 시 디자인이 자동 확정됩니다. ($_deadlineText)',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.accent,
                                      height: 1.4),
                                )),
                              ]),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ══ 1. 색상 변경 ══
                          _sectionLabel(Icons.palette_outlined,
                              context.loc.t('색상', '색상'), purple),
                          const SizedBox(height: 6),

                          // ── 선택된 색상 미리보기 패널 ──
                          if (_newColorValue != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        _adjustedColor.withValues(alpha: 0.4),
                                    width: 1.5),
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 색상 프리뷰 바
                                    Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: _adjustedColor,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(11)),
                                      ),
                                      child: Row(children: [
                                        const SizedBox(width: 14),
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: _newColorValue,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _newColorValue!
                                                          .computeLuminance() >
                                                      0.5
                                                  ? Colors.black26
                                                  : Colors.white38,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.arrow_forward_rounded,
                                            size: 13,
                                            color: _adjustedColor
                                                        .computeLuminance() >
                                                    0.5
                                                ? Colors.black38
                                                : Colors.white54),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: _adjustedColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _adjustedColor
                                                          .computeLuminance() >
                                                      0.5
                                                  ? Colors.black26
                                                  : Colors.white54,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(Icons.check_rounded,
                                              size: 18,
                                              color: _adjustedColor
                                                          .computeLuminance() >
                                                      0.5
                                                  ? Colors.black87
                                                  : Colors.white),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _newColorName ?? '',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w900,
                                                    color: _adjustedColor
                                                                .computeLuminance() >
                                                            0.5
                                                        ? Colors.black87
                                                        : Colors.white,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '#${_adjustedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}  ·  $_lightnessLabel',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: _adjustedColor
                                                                .computeLuminance() >
                                                            0.5
                                                        ? Colors.black54
                                                        : Colors.white70,
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      ]),
                                    ),
                                    // 농도 슬라이더
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 8, 14, 10),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                      context.loc.t('농도', '농도'),
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .textSecondary)),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: purple.withValues(
                                                          alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(_lightnessLabel,
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: purple)),
                                                  ),
                                                ]),
                                            const SizedBox(height: 4),
                                            Row(children: [
                                              Text(context.loc.t('진하게', '진하게'),
                                                  style: TextStyle(
                                                      fontSize: 9,
                                                      color: AppColors
                                                          .textSecondary)),
                                              Expanded(
                                                child: SliderTheme(
                                                  data: SliderTheme.of(context)
                                                      .copyWith(
                                                    thumbColor: purple,
                                                    activeTrackColor: purple,
                                                    inactiveTrackColor:
                                                        Colors.grey.shade200,
                                                    trackHeight: 3,
                                                    thumbShape:
                                                        const RoundSliderThumbShape(
                                                            enabledThumbRadius:
                                                                8),
                                                    overlayShape:
                                                        const RoundSliderOverlayShape(
                                                            overlayRadius: 14),
                                                  ),
                                                  child: Slider(
                                                    min: 0.05,
                                                    max: 0.95,
                                                    value: _colorLightness,
                                                    onChanged: (v) => setState(
                                                        () => _colorLightness =
                                                            v),
                                                  ),
                                                ),
                                              ),
                                              Text(context.loc.t('밝게', '밝게'),
                                                  style: TextStyle(
                                                      fontSize: 9,
                                                      color: AppColors
                                                          .textSecondary)),
                                            ]),
                                          ]),
                                    ),
                                  ]),
                            ),
                          ],

                          // ── 3탭 색상 선택 ──
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TabBar(
                              controller: _colorTabCtrl,
                              indicator: BoxDecoration(
                                color: purple,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: [
                                  BoxShadow(
                                      color: purple.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.black54,
                              labelStyle: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                              unselectedLabelStyle: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w500),
                              dividerColor: Colors.transparent,
                              padding: const EdgeInsets.all(3),
                              tabs: [
                                Tab(text: context.loc.t('기성_19색', '기성 19색')),
                                Tab(text: context.loc.t('추가_색상', '추가 색상')),
                                Tab(text: context.loc.t('hex_입력', 'HEX 입력')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ── 탭 콘텐츠 ──
                          SizedBox(
                            height: 300,
                            child: TabBarView(
                              controller: _colorTabCtrl,
                              children: [
                                // 탭1: 기성 19색
                                SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 10,
                                    children: AppColorPalette.registeredColors
                                        .map((c) {
                                      final name = c['name'] as String;
                                      final code = c['code'] as String;
                                      final cVal = Color(c['hex'] as int);
                                      final isSel = _newColorName == name;
                                      final isLight =
                                          cVal.computeLuminance() > 0.6;
                                      final displayName = name.contains('(')
                                          ? name.substring(
                                              name.indexOf('(') + 1,
                                              name.indexOf(')'))
                                          : name;
                                      return GestureDetector(
                                        onTap: () => setState(() {
                                          _newColorName = name;
                                          _newColorValue = cVal;
                                          _colorLightness =
                                              HSLColor.fromColor(cVal)
                                                  .lightness
                                                  .clamp(0.05, 0.95);
                                        }),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 130),
                                          width: 52,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 2),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? const Color(0xFFF3E5F5)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSel
                                                  ? purple
                                                  : Colors.grey.shade200,
                                              width: isSel ? 2 : 1,
                                            ),
                                          ),
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                RibColorSwatch(
                                                  color: cVal,
                                                  size: 38,
                                                  isSelected: isSel,
                                                  accentColor: purple,
                                                  isLight: isLight,
                                                  borderRadius: 10,
                                                  child: isSel
                                                      ? Icon(
                                                          Icons.check_rounded,
                                                          size: 18,
                                                          color: isLight
                                                              ? Colors.black87
                                                              : Colors.white)
                                                      : null,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  code,
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: isSel
                                                        ? purple
                                                        : Colors.black54,
                                                    letterSpacing: 0.3,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  displayName,
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w500,
                                                    color: isSel
                                                        ? purple.withValues(
                                                            alpha: 0.8)
                                                        : Colors.black38,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ]),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                                // 탭2: 추가 색상 (전체 스펙트럼)
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${AppColorPalette.extendedPalette.length}가지 확장 색상 팔레트 • 원하는 색상을 탭하세요',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 6),
                                      Expanded(
                                        child: GridView.builder(
                                          physics:
                                              const ClampingScrollPhysics(),
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 10,
                                            crossAxisSpacing: 2,
                                            mainAxisSpacing: 2,
                                            childAspectRatio: 1.0,
                                          ),
                                          itemCount: AppColorPalette
                                              .extendedPalette.length,
                                          itemBuilder: (_, i) {
                                            final color = AppColorPalette
                                                .extendedPalette[i];
                                            final hexStr =
                                                '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                                            final isSel =
                                                _newColorValue?.toARGB32() ==
                                                        color.toARGB32() &&
                                                    _newColorName != null &&
                                                    !AppColorPalette
                                                        .registeredColors
                                                        .any((c) =>
                                                            c['name'] ==
                                                            _newColorName);
                                            final isLight =
                                                color.computeLuminance() > 0.6;
                                            return GestureDetector(
                                              onTap: () => setState(() {
                                                _newColorName = '확장 ($hexStr)';
                                                _newColorValue = color;
                                                _colorLightness =
                                                    HSLColor.fromColor(color)
                                                        .lightness
                                                        .clamp(0.05, 0.95);
                                              }),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 100),
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: isSel
                                                        ? Colors.white
                                                        : Colors.transparent,
                                                    width: isSel ? 2.5 : 0,
                                                  ),
                                                  boxShadow: isSel
                                                      ? [
                                                          const BoxShadow(
                                                              color: Colors
                                                                  .black38,
                                                              blurRadius: 5,
                                                              spreadRadius: 1)
                                                        ]
                                                      : [],
                                                ),
                                                child: isSel
                                                    ? Icon(Icons.check_rounded,
                                                        size: 11,
                                                        color: isLight
                                                            ? Colors.black87
                                                            : Colors.white)
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ]),

                                // 탭3: HEX 직접 입력
                                SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 미리보기
                                        Container(
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: _hexPreview,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.grey.shade300),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '#${_hexPreview.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 2,
                                                color: _hexPreview
                                                            .computeLuminance() >
                                                        0.4
                                                    ? Colors.black87
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Text('#',
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.black54)),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: TextField(
                                              controller: _hexCtrl,
                                              textCapitalization:
                                                  TextCapitalization.characters,
                                              maxLength: 6,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 2),
                                              decoration: InputDecoration(
                                                hintText: context.loc.t(
                                                    'RRGGBB__예__FF6B_b87306',
                                                    'RRGGBB (예: FF6B35)'),
                                                hintStyle: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                    letterSpacing: 1),
                                                counterText: '',
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 9),
                                                errorText: _hexError,
                                                errorStyle: const TextStyle(
                                                    fontSize: 10),
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide: BorderSide(
                                                        color: Colors
                                                            .grey.shade300)),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        borderSide:
                                                            const BorderSide(
                                                                color: purple,
                                                                width: 1.5)),
                                              ),
                                              onChanged: (v) {
                                                if (v.length == 6) {
                                                  try {
                                                    final c = Color(int.parse(
                                                        'FF$v',
                                                        radix: 16));
                                                    setState(() {
                                                      _hexPreview = c;
                                                      _hexError = null;
                                                    });
                                                  } catch (_) {
                                                    setState(() => _hexError =
                                                        context.loc.t(
                                                            '올바른_hex_코드를_입력하세요',
                                                            '올바른 HEX 코드를 입력하세요'));
                                                  }
                                                } else {
                                                  setState(
                                                      () => _hexError = null);
                                                }
                                              },
                                              onSubmitted: (_) => _applyHex(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: _applyHex,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: purple,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 9),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                                context.loc.t('적용', '적용'),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800)),
                                          ),
                                        ]),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning
                                                .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: AppColors.warning
                                                    .withValues(alpha: 0.20)),
                                          ),
                                          child: Row(children: [
                                            Icon(Icons.info_outline,
                                                size: 13,
                                                color: AppColors.warning),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                context.loc.t(
                                                    '원하시는_색상의_HEX_코드를_6자리로_입력하세요_n예_빨강__bc66fc',
                                                    '원하시는 색상의 HEX 코드를 6자리로 입력하세요.\n예) 빨강: FF0000 / 파랑: 0000FF / 노랑: FFFF00'),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.warning,
                                                    height: 1.4),
                                              ),
                                            ),
                                          ]),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                            context.loc
                                                .t('자주_쓰는_색상', '자주 쓰는 색상'),
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black54)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            {
                                              'name': context.loc
                                                  .t('코발트블루', '코발트블루'),
                                              'hex': '0047AB'
                                            },
                                            {
                                              'name':
                                                  context.loc.t('라벤더', '라벤더'),
                                              'hex': 'E6CCFF'
                                            },
                                            {
                                              'name': context.loc.t('카멜', '카멜'),
                                              'hex': 'C19A6B'
                                            },
                                            {
                                              'name': context.loc.t('민트', '민트'),
                                              'hex': '26C9A0'
                                            },
                                            {
                                              'name':
                                                  context.loc.t('버건디', '버건디'),
                                              'hex': '6D0E19'
                                            },
                                            {
                                              'name': context.loc.t('골드', '골드'),
                                              'hex': 'D4AF37'
                                            },
                                          ].map((item) {
                                            final hexStr = item['hex']!;
                                            final c = Color(int.parse(
                                                'FF$hexStr',
                                                radix: 16));
                                            final isLight =
                                                c.computeLuminance() > 0.5;
                                            final isSel =
                                                _newColorName == item['name'];
                                            return GestureDetector(
                                              onTap: () {
                                                _hexCtrl.text = hexStr;
                                                setState(() {
                                                  _hexPreview = c;
                                                  _newColorName = item['name'];
                                                  _newColorValue = c;
                                                  _colorLightness =
                                                      HSLColor.fromColor(c)
                                                          .lightness
                                                          .clamp(0.05, 0.95);
                                                  _hexError = null;
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isSel
                                                      ? c
                                                      : c.withValues(
                                                          alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: isSel
                                                          ? purple
                                                          : c.withValues(
                                                              alpha: 0.4)),
                                                ),
                                                child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 14,
                                                        height: 14,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: c,
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                              color: Colors.grey
                                                                  .shade300),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(item['name']!,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: isSel
                                                                ? (isLight
                                                                    ? Colors
                                                                        .black87
                                                                    : Colors
                                                                        .white)
                                                                : Colors
                                                                    .black87,
                                                          )),
                                                    ]),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ══ 2. 원단 + 인쇄타입 (읽기 전용) ══
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 원단
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel(
                                            Icons.texture_rounded,
                                            context.loc.t('원단', '원단'),
                                            Color(0xFF757575)),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceGray,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: AppColors.border),
                                          ),
                                          child: Row(children: [
                                            const Icon(
                                                Icons.lock_outline_rounded,
                                                size: 13,
                                                color: Color(0xFF9E9E9E)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _currentFabric.isNotEmpty
                                                    ? _currentFabric
                                                    : context.loc
                                                        .t('정보_없음', '정보 없음'),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF424242)),
                                              ),
                                            ),
                                          ]),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.border,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                              context.loc.t('변경_불가', '변경 불가'),
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF757575))),
                                        ),
                                      ]),
                                ),
                                const SizedBox(width: 12),
                                // 인쇄타입
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel(
                                            Icons.print_rounded,
                                            context.loc.t('인쇄타입', '인쇄타입'),
                                            Color(0xFF757575)),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceGray,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: AppColors.border),
                                          ),
                                          child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                    Icons.lock_outline_rounded,
                                                    size: 13,
                                                    color: Color(0xFF9E9E9E)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    _currentPrintType.isNotEmpty
                                                        ? _currentPrintType
                                                        : context.loc.t(
                                                            '정보_없음', '정보 없음'),
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF424242)),
                                                    maxLines: 3,
                                                  ),
                                                ),
                                              ]),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.border,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                              context.loc.t('변경_불가', '변경 불가'),
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF757575))),
                                        ),
                                      ]),
                                ),
                              ]),
                          const SizedBox(height: 20),

                          // ══ 3. 단체명 변경 ══
                          _sectionLabel(Icons.groups_outlined,
                              context.loc.t('단체명', '단체명'), AppColors.success),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _teamNameCtrl,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText:
                                  context.loc.t('단체명을_입력하세요', '단체명을 입력하세요'),
                              prefixIcon: const Icon(Icons.groups_outlined,
                                  size: 18, color: AppColors.success),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: const Color(0xFFF1F8E9),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFC8E6C9))),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFC8E6C9))),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppColors.success, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ══ 4. 인원별 사이즈 수정 ══
                          if (_persons.isNotEmpty) ...[
                            _sectionLabel(
                                Icons.straighten_rounded,
                                context.loc.t('인원별_사이즈', '인원별 사이즈'),
                                Color(0xFF00695C)),
                            const SizedBox(height: 4),
                            Text(
                                context.loc.t('변경할_사이즈를_직접_수정해_e9e851',
                                    '변경할 사이즈를 직접 수정해주세요.'),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            ...List.generate(_persons.length, (i) {
                              final p = _persons[i];
                              final num = (p['index'] as int?) ?? (i + 1);
                              final name = (p['name'] as String?) ?? '';
                              final gender = (p['gender'] as String?) ?? '';
                              final gIcon = gender == 'female'
                                  ? '👩'
                                  : (gender == 'junior' ? '🧒' : '👨');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // ── 인원 번호 + 이름 ──
                                      SizedBox(
                                        width: 68,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(gIcon,
                                                style: const TextStyle(
                                                    fontSize: 18)),
                                            const SizedBox(height: 1),
                                            Text(
                                              '$num번',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF00695C),
                                              ),
                                            ),
                                            if (name.isNotEmpty) ...[
                                              const SizedBox(height: 1),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFE0F2F1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF00695C),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // ── 사이즈 TextField ──
                                      Expanded(
                                        child: TextField(
                                          controller: _personSizeCtrl[i],
                                          style: const TextStyle(fontSize: 12),
                                          decoration: InputDecoration(
                                            hintText: context.loc.t(
                                                '예__상의_L___하의_M',
                                                '예) 상의 L / 하의 M'),
                                            hintStyle: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textHint),
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10),
                                            filled: true,
                                            fillColor: const Color(0xFFE0F2F1),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFB2DFDB)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFFB2DFDB)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF00695C),
                                                  width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],

                          // ══ 5. 추가 요청사항 ══
                          _sectionLabel(
                              Icons.chat_bubble_outline_rounded,
                              context.loc.t('추가_요청사항', '추가 요청사항'),
                              Color(0xFF616161)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _memoCtrl,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: context.loc.t('디자인_패턴__로고_위치_등_60ba6d',
                                  '디자인 패턴, 로고 위치 등 위 항목 외 수정 요청 사항을 입력해주세요.'),
                              hintStyle: TextStyle(
                                  fontSize: 12, color: Colors.grey[400]),
                              filled: true,
                              fillColor: const Color(0xFFF9F9F9),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: purple),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── 안내사항 ──
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                    SizedBox(width: 6),
                                    Text(context.loc.t('안내사항', '안내사항'),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary)),
                                  ]),
                                  const SizedBox(height: 6),
                                  _infoRow(context.loc.t(
                                      '인쇄타입승화나염 등은 기존 주문과 동일하게 유지됩니다',
                                      '인쇄타입(승화/나염 등)은 기존 주문과 동일하게 유지됩니다.')),
                                  _infoRow(context.loc.t(
                                      '디자인 수정 요청은 총 2회까지 가능합니다',
                                      '디자인 수정 요청은 총 2회까지 가능합니다.')),
                                  _infoRow(context.loc.t(
                                      '각 수정 단계의 기한 내 관리자 확인 후, 다음 단계는 1주일 동안 신청할 수 있습니다',
                                      '각 수정 단계의 기한 내 관리자 확인 후, 다음 단계는 1주일 동안 신청할 수 있습니다.')),
                                  _infoRow(context.loc.t('확정 후에는 추가 수정이 불가합니다',
                                      '확정 후에는 추가 수정이 불가합니다.')),
                                ]),
                          ),
                          const SizedBox(height: 24),

                          // ── 제출 버튼 ──
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: purple,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text(context.loc.t('수정_요청_제출', '수정 요청 제출'),
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
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
            const Icon(Icons.check_circle_rounded,
                size: 64, color: Color(0xFF7B1FA2)),
            const SizedBox(height: 16),
            Text(context.loc.t('수정_요청_완료', '수정 요청 완료!'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
                '주문번호 ${widget.order.id}\n관리자가 수정본을 확인하면 다음 수정 단계가 열립니다.\n각 단계의 1주일 기한이 지나면 현재 디자인으로 자동 확정됩니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(context.loc.t('닫기', '닫기'),
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      );

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _infoRow(String text) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4))),
        ]),
      );

  Widget _sectionLabel(IconData icon, String label, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ]),
      );

  void _applyHex() {
    final v = _hexCtrl.text.trim().replaceAll('#', '');
    if (v.length != 6) {
      setState(() => _hexError = context.loc
          .t('hex_코드는_6자리입니다_예_ff6b35', 'HEX 코드는 6자리입니다 (예: FF6B35)'));
      return;
    }
    try {
      final color = Color(int.parse('FF$v', radix: 16));
      setState(() {
        _hexPreview = color;
        _newColorName = '커스텀 (#${v.toUpperCase()})';
        _newColorValue = color;
        _colorLightness = HSLColor.fromColor(color).lightness.clamp(0.05, 0.95);
        _hexError = null;
      });
    } catch (_) {
      setState(() =>
          _hexError = context.loc.t('올바른_hex_코드를_입력하세요', '올바른 HEX 코드를 입력하세요'));
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 교환/반품 요청 다이얼로그
// 플로우: 1단계(사유선택) → 2단계(수거방법) → 3단계(결제/완료)
// ═══════════════════════════════════════════════════════════════

/// 주문내역에서 리뷰 작성 시트 열기
/// 상품이 여러 개면 선택 다이얼로그 → 선택한 상품의 실제 productId로 저장
void _showWriteReviewFromOrder(BuildContext context, OrderModel order) async {
  if (order.items.isEmpty) return;

  // 상품 1개면 바로 열기, 여러 개면 선택 다이얼로그
  OrderItem? selectedItem;
  if (order.items.length == 1) {
    selectedItem = order.items.first;
  } else {
    if (!context.mounted) return;
    selectedItem = await showDialog<OrderItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.loc.t('리뷰_작성할_상품_선택', '리뷰 작성할 상품 선택'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: order.items
                .map((item) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F0F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined,
                            size: 20, color: AppColors.primary),
                      ),
                      title: Text(item.productName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${item.size} · ${item.color} · ${item.quantity}개',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      onTap: () => Navigator.pop(ctx, item),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.loc.t('취소', '취소'))),
        ],
      ),
    );
    if (selectedItem == null) return;
  }

  // Firestore에서 실제 상품 정보 조회
  ProductModel? product;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(selectedItem.productId)
        .get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] ??= doc.id;
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] =
            (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      product = ProductModel.fromJson(data);
    }
  } catch (_) {}

  // Firestore 조회 실패 시 주문 정보로 최소 ProductModel 구성
  product ??= ProductModel(
    id: selectedItem.productId,
    name: selectedItem.productName,
    category: '',
    price: selectedItem.price,
    description: '',
    images: selectedItem.imageUrl != null && selectedItem.imageUrl!.isNotEmpty
        ? [selectedItem.imageUrl!]
        : [],
    sizes: [],
    colors: [],
    createdAt: DateTime.now(),
    rating: 0,
    reviewCount: 0,
    stockCount: 0,
    salesCount: 0,
    isActive: true,
    productCode: '',
    sectionImages: {},
    nameTranslations: {},
    descriptionTranslations: {},
    bottomLength: '',
    sizeStocks: {},
  );

  if (!context.mounted) return;
  // orderId를 hint로 전달해 리뷰 시트에서 주문번호 자동 입력
  showWriteReviewSheet(context, product,
      initialSize: selectedItem.size, initialColor: selectedItem.color);
}

void _showConfirmPurchaseDialog(BuildContext context, OrderModel order) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
        SizedBox(width: 8),
        Text(context.loc.t('구매_확정', '구매 확정'),
            style: TextStyle(fontWeight: FontWeight.w800)),
      ]),
      content: Text(
        context.loc.t('구매를_확정하시겠습니까_n_n확정_후에는_교환_반품_신청이_어_7ea6e9',
            '구매를 확정하시겠습니까?\n\n확정 후에는 교환/반품 신청이 어려울 수 있습니다.'),
        style: TextStyle(fontSize: 14, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.loc.t('취소', '취소'),
              style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            await OrderService.updateOrderStatus(
                order.id, OrderStatus.purchaseConfirmed);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.loc
                      .t('구매가 확정되었습니다 감사합니다', '구매가 확정되었습니다. 감사합니다!')),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          child: Text(context.loc.t('구매 확정', '구매 확정')),
        ),
      ],
    ),
  );
}

void _showExchangeRequestDialog(BuildContext context, OrderModel order) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ExchangeRequestDialog(order: order),
  );
}

void _showReturnRequestDialog(BuildContext context, OrderModel order) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ExchangeRequestDialog(order: order, isReturn: true),
  );
}

class _ExchangeRequestDialog extends StatefulWidget {
  final OrderModel order;
  final bool isReturn;
  const _ExchangeRequestDialog({required this.order, this.isReturn = false});

  @override
  State<_ExchangeRequestDialog> createState() => _ExchangeRequestDialogState();
}

class _ExchangeRequestDialogState extends State<_ExchangeRequestDialog> {
  // ── Step ──
  int _step = 1; // 1=사유선택, 2=수거방법, 3=결제/완료

  // ── 1단계: 사유 ──
  // static const → 런타임 번역 불가, 일반 getter로 대체
  List<String> get _selfReasons => [
        context.loc.t('색상_사이즈를_바꾸고_싶어요', '색상, 사이즈를 바꾸고 싶어요'),
        context.loc.t('다른_이유가_있어요', '다른 이유가 있어요'),
      ];
  List<String> get _sellerReasons => [
        context.loc.t('상품_정보와_실제_상품이_달라요', '상품 정보와 실제 상품이 달라요'),
        context.loc.t('구성품_부속품이_없어요', '구성품, 부속품이 없어요'),
        context.loc.t('파손된_상품을_받았어요', '파손된 상품을 받았어요'),
        context.loc.t('주문한_상품과_다른_상품을_받았어요', '주문한 상품과 다른 상품을 받았어요'),
        context.loc.t('상품에_문제가_있어요', '상품에 문제가 있어요'),
      ];
  String? _selectedReason;
  final _reasonCtrl = TextEditingController();

  // ── 2단계: 수거방법 ──
  // 0=미선택, 1=직접수거, 2=이미발송
  int _pickupMethod = 0;
  // 이미 발송한 경우 운송장번호
  final _trackingCtrl = TextEditingController();
  String? _trackingCompany; // 택배사

  // ── 3단계: 결제수단 ──
  String? _payMethod; // 'card' | 'kakao' | 'payco' | 'toss'

  bool get _isSelfFault => _selfReasons.contains(_selectedReason);
  bool get _shippingBySelf => _isSelfFault;

  String get _title => widget.isReturn
      ? context.loc.t('반품요청', '반품요청')
      : context.loc.t('교환요청', '교환요청');

  static const _shippingCompanies = [
    'CJ대한통운',
    '한진택배',
    '롯데택배',
    '우체국택배',
    'GS택배',
    'TD Logi',
    '대신택배',
    '경동택배',
    '일양로지스',
    '기타',
  ];

  // ── 사진 첨부 ──
  final List<XFile> _images = [];
  final List<String> _uploadedUrls = []; // Storage 업로드 후 URL
  bool _isUploading = false;

  static const _maxImages = 3;
  static const _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  Future<void> _pickImages() async {
    if (_images.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.loc
                .t('사진은 최대 3장까지 첨부할 수 있어요', '사진은 최대 3장까지 첨부할 수 있어요.')),
            duration: Duration(seconds: 2)),
      );
      return;
    }
    final picker = ImagePicker();
    final remaining = _maxImages - _images.length;
    try {
      List<XFile> picked = [];
      if (kIsWeb) {
        // 웹: 단일 선택 반복 or 다중 선택
        picked =
            await picker.pickMultiImage(imageQuality: 85, limit: remaining);
      } else {
        picked =
            await picker.pickMultiImage(imageQuality: 85, limit: remaining);
      }
      if (picked.isEmpty) return;
      // 용량 체크
      final oversized = <String>[];
      final valid = <XFile>[];
      for (final f in picked) {
        final bytes = await f.readAsBytes();
        if (bytes.length > _maxFileSizeBytes) {
          oversized.add(f.name);
        } else {
          valid.add(f);
        }
      }
      if (oversized.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${oversized.join(', ')} 파일이 10MB를 초과해 제외됐어요.'),
              duration: const Duration(seconds: 3)),
        );
      }
      if (valid.isNotEmpty && mounted) {
        setState(() => _images.addAll(valid.take(_maxImages - _images.length)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.loc
                  .t('사진 선택 중 오류가 발생했어요 _', '사진 선택 중 오류가 발생했어요: $e')),
              duration: Duration(seconds: 2)),
        );
      }
    }
  }

  Future<List<String>> _uploadImages(String requestId) async {
    final urls = <String>[];
    for (int i = 0; i < _images.length; i++) {
      final file = _images[i];
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';
      final ref = FirebaseStorage.instance.ref(
          'exchange_requests/${widget.order.userId}/$requestId/image_$i.$ext');
      final meta = SettableMetadata(contentType: 'image/$ext');
      await ref.putData(bytes, meta);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _trackingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().user;
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _step == 1
                    ? _buildStep1()
                    : _step == 2
                        ? _buildStep2(user)
                        : _buildStep3(user),
              ),
            ),
            _buildBottomBar(context, user),
          ],
        ),
      ),
    );
  }

  // ── 헤더 ──
  Widget _buildHeader() => Container(
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(_title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  // ── 스텝 인디케이터 ──
  Widget _buildStepIndicator() {
    final labels = [
      context.loc.t('교환_사유', '교환 사유'),
      context.loc.t('수거_방법', '수거 방법'),
      _shippingBySelf
          ? context.loc.t('비용_결제', '비용 결제')
          : context.loc.t('신청_확인', '신청 확인')
    ];
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final n = i + 1;
          final isActive = n == _step;
          final isDone = n < _step;
          return Row(children: [
            if (i > 0)
              Container(
                width: 32,
                height: 1,
                color: isDone ? AppColors.primary : Colors.grey[300],
              ),
            Column(children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isActive || isDone)
                      ? AppColors.primary
                      : Colors.grey[300],
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('$n',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : Colors.grey[500],
                          )),
                ),
              ),
              const SizedBox(height: 4),
              Text(labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? AppColors.primary : Colors.grey[400],
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  )),
            ]),
          ]);
        }),
      ),
    );
  }

  // ══════════════════════════════════════
  // STEP 1: 사유 선택
  // ══════════════════════════════════════
  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        widget.isReturn
            ? context.loc.t('반품 사유를 선택해주세요', '반품 사유를 선택해주세요')
            : '교환 사유를 선택해주세요',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 20),

      // 배송비 직접 부담
      _sectionHeader(context.loc.t('배송비 직접 부담', '배송비 직접 부담')),
      const SizedBox(height: 8),
      ..._selfReasons.map((r) => _reasonTile(r)),
      const SizedBox(height: 20),

      // 배송비 판매자 부담
      _sectionHeader(context.loc.t('배송비 판매자 부담', '배송비 판매자 부담')),
      const SizedBox(height: 8),
      ..._sellerReasons.map((r) => _reasonTile(r)),

      // 직접부담 선택 시 상세 입력
      if (_isSelfFault) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              context.loc.t('이유를_자세히_알려주면_더_빠르게_교환할_수_있어요_n_사진은_0ecbe2',
                  '· 이유를 자세히 알려주면 더 빠르게 교환할 수 있어요.\n· 사진은 3장까지 올릴 수 있어요. (각 10MB 이하)'),
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              maxLines: 4,
              maxLength: 100,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: context.loc
                    .t('교환이_필요한_이유를_적어주_f65962', '교환이 필요한 이유를 적어주세요. (선택사항)'),
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                counterStyle: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 10),
            // ── 사진 첨부 영역 ──
            _buildImagePicker(),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 미리보기 + 추가 버튼 가로 스크롤
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 추가된 이미지 미리보기
              ..._images.asMap().entries.map((entry) {
                final i = entry.key;
                final file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                file.path,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : Image.file(
                                File(file.path),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              ),
                      ),
                      // 삭제 버튼
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // 추가 버튼 (3장 미만일 때)
              if (_images.length < _maxImages)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              size: 24, color: Colors.grey[500]),
                          const SizedBox(height: 4),
                          Text(
                            '사진 올리기\n${_images.length}/$_maxImages',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 9, color: Colors.grey[500]),
                          ),
                        ]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.loc.t('사진은_최대_3장_각_10MB_이하', '· 사진은 최대 3장, 각 10MB 이하'),
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 72,
        height: 72,
        color: Colors.grey[100],
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );

  Widget _sectionHeader(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
      );

  Widget _reasonTile(String reason) {
    final sel = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          _radioCircle(sel),
          const SizedBox(width: 12),
          Text(reason,
              style: TextStyle(
                fontSize: 14,
                color: sel ? AppColors.primary : Colors.black87,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              )),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════
  // STEP 2: 수거 방법
  // ══════════════════════════════════════
  Widget _buildStep2(UserModel? user) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        widget.isReturn
            ? context.loc.t('반품 방법을 선택해주세요', '반품 방법을 선택해주세요')
            : '교환 방법을 선택해주세요',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 20),

      // 옵션 1: 직접 수거
      _pickupOption(
        value: 1,
        label: context.loc.t('상품을_직접_수거해주세요', '상품을 직접 수거해주세요'),
        subLabel: context.loc.t('택배사가_2_5일_이내_방문_예정', '택배사가 2~5일 이내 방문 예정'),
      ),

      // 직접수거 선택 시 수거 주소 표시
      if (_pickupMethod == 1) ...[
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBD0FF)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              context.loc.t('교환_요청이_확인되면_2_5일_이내_택배사가_방문할_예정이에요_54912a',
                  '교환 요청이 확인되면 2~5일 이내 택배사가 방문할 예정이에요.\n아래 주소가 맞는지 확인해주세요.'),
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 10),
            Text(user?.name ?? '',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              _pickupAddress(user),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(context.loc.t('주소변경', '주소변경 >'),
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ],

      // 옵션 2: 이미 발송
      _pickupOption(
        value: 2,
        label: context.loc.t('상품을_이미_판매자에게_택배_845c77', '상품을 이미 판매자에게 택배로 보냈어요'),
        subLabel: context.loc.t('운송장_번호를_고객센터에_전달해주세요', '운송장 번호를 아래에 입력해 주세요'),
      ),

      // 이미 발송 선택 시 반품 주소 + 운송장 입력
      if (_pickupMethod == 2) ...[
        const SizedBox(height: 8),
        // 반품 주소 안내 박스
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF90CAF9)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: AppColors.info),
              const SizedBox(width: 6),
              const Text('반품·교환 반송 주소',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info)),
            ]),
            const SizedBox(height: 8),
            const Text('전북 남원시 오들1길 97, 205-303',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(height: 4),
            Text('위 주소로 택배 발송 후 아래에 운송장 번호를 입력해 주세요.',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[600], height: 1.5)),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.loc.t('운송장_정보를_입력해주세요', '운송장 정보를 입력해주세요'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            // 택배사 선택
            DropdownButtonFormField<String>(
              value: _trackingCompany,
              hint: Text(context.loc.t('택배사_선택', '택배사 선택'),
                  style: TextStyle(fontSize: 13)),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
              ),
              items: _shippingCompanies
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _trackingCompany = v),
            ),
            const SizedBox(height: 10),
            // 운송장 번호
            TextField(
              controller: _trackingCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: context.loc.t('운송장_번호를_입력해주세요', '운송장 번호를 입력해주세요'),
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
              ),
            ),
          ]),
        ),
      ],
    ]);
  }

  String _pickupAddress(UserModel? user) {
    if (user?.address.isNotEmpty == true) return user!.address;
    if (widget.order.userAddress.isNotEmpty) return widget.order.userAddress;
    return context.loc.t('주소 정보 없음', '주소 정보 없음');
  }

  Widget _pickupOption(
      {required int value, required String label, required String subLabel}) {
    final sel = _pickupMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _pickupMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFE3F2FD) : Colors.white,
          border: Border.all(
              color: sel ? AppColors.primary : Colors.grey[300]!,
              width: sel ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          _radioCircle(sel),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: sel ? AppColors.primary : Colors.black87,
                    )),
                const SizedBox(height: 2),
                Text(subLabel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ])),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════
  // STEP 3: 결제 (직접부담) or 완료확인 (판매자부담)
  // ══════════════════════════════════════
  Widget _buildStep3(UserModel? user) {
    if (_shippingBySelf) {
      // ── 직접부담: 결제수단 선택 ──
      return _buildPaymentStep();
    } else {
      // ── 판매자부담: 수거 확인 + 교환 요청 ──
      return _buildConfirmStep(user);
    }
  }

  // 결제수단 선택 UI
  Widget _buildPaymentStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.loc.t('결제수단_선택', '결제수단 선택'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(context.loc.t('교환배송비', '교환배송비'),
          style: TextStyle(fontSize: 13, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(context.loc.t('6_000원', '6,000원'),
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(context.loc.t('교환비용을_결제하면_교환_요_0376b7', '교환비용을 결제하면 교환 요청이 완료돼요.'),
          style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      const SizedBox(height: 24),
      _payMethodTile(
        value: 'card',
        icon: Container(
          width: 36,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.credit_card, color: Colors.white, size: 16),
        ),
        label: context.loc.t('신용카드', '신용카드'),
      ),
      _divider(),
      _payMethodTile(
        value: 'kakao',
        icon: Container(
          width: 50,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE500),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text('pay',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3A1D1D))),
          ),
        ),
        label: context.loc.t('카카오페이', '카카오페이'),
      ),
      _divider(),
      _payMethodTile(
        value: 'payco',
        icon: Container(
          width: 50,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFEF2D2D),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text('PAYCO',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
        label: context.loc.t('페이코', '페이코'),
      ),
      _divider(),
      _payMethodTile(
        value: 'toss',
        icon: Container(
          width: 50,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0064FF),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text('toss',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
        label: context.loc.t('토스페이', '토스페이'),
      ),
    ]);
  }

  Widget _payMethodTile(
      {required String value, required Widget icon, required String label}) {
    final sel = _payMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _payMethod = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          _radioCircle(sel),
          const SizedBox(width: 16),
          icon,
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                color: sel ? AppColors.primary : Colors.black87,
              )),
        ]),
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: Colors.grey[100]);

  // 판매자부담 확인 UI
  Widget _buildConfirmStep(UserModel? user) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.loc.t('신청_내용_확인', '신청 내용 확인'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),

      // 사유 확인
      _confirmRow(context.loc.t('교환_사유', '교환 사유'), _selectedReason ?? ''),
      const SizedBox(height: 10),
      // 수거 방법 확인
      _confirmRow(
          '수거 방법',
          _pickupMethod == 1
              ? context.loc.t('직접 수거', '직접 수거')
              : context.loc.t('이미 발송', '이미 발송')),
      const SizedBox(height: 16),

      // 배송비 무료 배지
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FFF4),
          border: Border.all(color: const Color(0xFFBBF7D0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 8),
          Text(context.loc.t('판매자_귀책_사유___배송비_86912c', '판매자 귀책 사유 — 배송비 무료'),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A))),
        ]),
      ),
      const SizedBox(height: 12),

      // 검수 후 환불 안내
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          border: Border.all(color: const Color(0xFFFFCC80)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.inventory_2_outlined,
                size: 15, color: AppColors.warning.withValues(alpha: 0.82)),
            const SizedBox(width: 6),
            Text('환불 처리 안내',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning.withValues(alpha: 0.90))),
          ]),
          const SizedBox(height: 8),
          _refundStepTile('1', '상품 반송'),
          _refundStepTile('2', '입고 후 상품 검수 진행'),
          _refundStepTile('3', '검수 완료 후 환불 처리 (영업일 1~3일)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber_rounded,
                  size: 13, color: AppColors.warning.withValues(alpha: 0.82)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('상품 검수 결과 반품 불가 조건에 해당하는 경우\n환불 없이 상품이 반송될 수 있습니다.',
                    style: TextStyle(
                        fontSize: 11,
                        height: 1.6,
                        color: AppColors.warning.withValues(alpha: 0.90))),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _refundStepTile(String step, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFFFF8F00),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(step,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
        ]),
      );

  Widget _confirmRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      );

  // ── 공용 라디오 원 ──
  Widget _radioCircle(bool selected) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: selected
            ? Container(
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.primary),
              )
            : null,
      );

  // ══════════════════════════════════════
  // 하단 버튼 바
  // ══════════════════════════════════════
  Widget _buildBottomBar(BuildContext context, UserModel? user) {
    String nextLabel;
    if (_step == 3 && _shippingBySelf) {
      nextLabel = context.loc.t('교환비용_결제', '교환비용 결제');
    } else if (_step == 3) {
      nextLabel = widget.isReturn
          ? context.loc.t('반품요청', '반품요청')
          : context.loc.t('교환요청', '교환요청');
    } else {
      nextLabel = context.loc.t('다음', '다음');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_step == 1) {
                Navigator.pop(context);
              } else {
                setState(() => _step--);
              }
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _step == 1 ? context.loc.t('닫기', '닫기') : '이전',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _isUploading ? null : () => _onNext(context),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: (_canProceed && !_isUploading)
                    ? AppColors.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _isUploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        nextLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _canProceed ? Colors.white : Colors.grey[500],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  bool get _canProceed {
    if (_step == 1) return _selectedReason != null;
    if (_step == 2) return _pickupMethod != 0;
    if (_step == 3 && _shippingBySelf) return _payMethod != null;
    return true;
  }

  void _onNext(BuildContext context) {
    if (!_canProceed) {
      final msgs = [
        context.loc.t('사유를_선택해주세요', '사유를 선택해주세요.'),
        context.loc.t('수거_방법을_선택해주세요', '수거 방법을 선택해주세요.'),
        context.loc.t('결제수단을_선택해주세요', '결제수단을 선택해주세요.')
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msgs[_step - 1]),
            duration: const Duration(seconds: 2)),
      );
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    _submit(context);
  }

  Future<void> _submit(BuildContext context) async {
    // 이미지 업로드 중 표시
    setState(() => _isUploading = true);
    try {
      // 임시 doc ID 생성 후 이미지 업로드
      final docRef =
          FirebaseFirestore.instance.collection('exchange_requests').doc();
      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        imageUrls = await _uploadImages(docRef.id);
      }
      await docRef.set({
        'orderId': widget.order.id,
        'type': widget.isReturn ? 'return' : 'exchange',
        'reason': _selectedReason ?? '',
        'detail': _reasonCtrl.text.trim(),
        'imageUrls': imageUrls,
        'pickupMethod': _pickupMethod == 1 ? 'pickup' : 'already_sent',
        'returnTrackingNumber': _trackingCtrl.text.trim(),
        'returnTrackingCompany': _trackingCompany ?? '',
        'shippingBySelf': _shippingBySelf,
        'payMethod': _payMethod ?? '',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'userId': widget.order.userId,
        'userName': widget.order.userName,
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(context.loc.t('요청 중 오류가 발생했어요 _', '요청 중 오류가 발생했어요: $e')),
              duration: Duration(seconds: 3)),
        );
      }
      return;
    }
    setState(() => _isUploading = false);

    if (!context.mounted) return;
    Navigator.pop(context);

    final label =
        widget.isReturn ? context.loc.t('반품', '반품') : context.loc.t('교환', '교환');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $label 요청이 접수됐어요. 담당자가 확인 후 처리해드립니다.'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 배송 실시간 추적 다이얼로그
// ════════════════════════════════════════════════════════════════

/// 고객 배송조회 버튼에서 택배사별 통합 추적 페이지를 바로 엽니다.
Future<void> _openTrackingPage({
  required BuildContext context,
  required String companyName,
  required String trackingNumber,
}) async {
  final carrierId = _carrierIdFromName(companyName);
  final uri = Uri.parse(
      'https://tracker.delivery/#/$carrierId/${Uri.encodeComponent(trackingNumber)}');
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.loc.t(
            '배송조회_페이지를_열_수_없습니다', '배송조회 페이지를 열 수 없습니다.')),
      ),
    );
  }
}

/// 택배사 이름 → tracker.delivery carrierId 매핑
String _carrierIdFromName(String name) {
  final n = name.trim().toLowerCase();
  if (n.contains('cj') || n.contains('대한통운')) return 'kr.cjlogistics';
  if (n.contains('한진')) return 'kr.hanjin';
  if (n.contains('롯데') || n.contains('lotte')) return 'kr.lotte';
  if (n.contains('우체국') || n.contains('epost')) return 'kr.epost';
  if (n.contains('gs') || n.contains('편의점')) return 'kr.gspostbox';
  if (n.contains('td') || n.contains('logi') || n.contains('로지'))
    return 'kr.tdlogi';
  if (n.contains('대신')) return 'kr.daesin';
  if (n.contains('경동')) return 'kr.kdexp';
  if (n.contains('일양')) return 'kr.ilyanglogis';
  if (n.contains('coupang') || n.contains('쿠팡')) return 'kr.coupang';
  if (n.contains('ssg') || n.contains('신세계')) return 'kr.ssglogistics';
  if (n.contains('로젠') || n.contains('logen')) return 'kr.logen';
  return 'kr.cjlogistics'; // 기본값
}

/// 배송 상태 코드 → 한국어 + 아이콘
({String label, IconData icon, Color color}) _statusInfo(
    BuildContext ctx, String code) {
  switch (code.toUpperCase()) {
    case 'AT_PICKUP':
      return (
        label: ctx.loc.t('집하_완료', '집하 완료'),
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF7B1FA2)
      );
    case 'IN_TRANSIT':
      return (
        label: ctx.loc.t('이동_중', '이동 중'),
        icon: Icons.local_shipping_outlined,
        color: AppColors.primary
      );
    case 'OUT_FOR_DELIVERY':
      return (
        label: ctx.loc.t('배달_중', '배달 중'),
        icon: Icons.delivery_dining_outlined,
        color: AppColors.accent
      );
    case 'DELIVERED':
      return (
        label: ctx.loc.t('배달_완료', '배달 완료'),
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success
      );
    case 'FAILED_ATTEMPT':
      return (
        label: ctx.loc.t('배달_실패', '배달 실패'),
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFC62828)
      );
    case 'AVAILABLE_FOR_PICKUP':
      return (
        label: ctx.loc.t('픽업_대기', '픽업 대기'),
        icon: Icons.store_outlined,
        color: const Color(0xFF00838F)
      );
    case 'INFORMATION_RECEIVED':
      return (
        label: ctx.loc.t('운송장_등록', '운송장 등록'),
        icon: Icons.receipt_long_outlined,
        color: Colors.grey
      );
    default:
      return (
        label: code,
        icon: Icons.radio_button_unchecked,
        color: Colors.grey
      );
  }
}

class _TrackingDialog extends StatefulWidget {
  final String trackingNumber;
  final String companyName;
  const _TrackingDialog(
      {required this.trackingNumber, required this.companyName});

  @override
  State<_TrackingDialog> createState() => _TrackingDialogState();
}

class _TrackingDialogState extends State<_TrackingDialog> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = [];
  Map<String, dynamic>? _lastEvent;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final carrierId = _carrierIdFromName(widget.companyName);
      const endpoint = 'https://apis.tracker.delivery/graphql';
      const query = r'''
query Track($carrierId: ID!, $trackingNumber: String!) {
  track(carrierId: $carrierId, trackingNumber: $trackingNumber) {
    lastEvent {
      time
      status { code text }
      description
    }
    events(last: 30) {
      edges {
        node {
          time
          status { code text }
          description
        }
      }
    }
  }
}
''';
      final resp = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query,
              'variables': {
                'carrierId': carrierId,
                'trackingNumber': widget.trackingNumber
              },
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data.containsKey('errors')) {
          setState(() {
            _error = context.loc.t('배송_정보를_찾을_수_없습니다', '배송 정보를 찾을 수 없습니다.');
            _loading = false;
          });
          return;
        }
        final track = data['data']?['track'];
        if (track == null) {
          setState(() {
            _error = context.loc.t('배송_정보를_찾을_수_없습니다', '배송 정보를 찾을 수 없습니다.');
            _loading = false;
          });
          return;
        }
        final edges = (track['events']?['edges'] as List? ?? []);
        final events = edges
            .map((e) => e['node'] as Map<String, dynamic>)
            .toList()
            .reversed
            .toList();
        setState(() {
          _events = List<Map<String, dynamic>>.from(events);
          _lastEvent = track['lastEvent'] as Map<String, dynamic>?;
          _loading = false;
        });
      } else {
        setState(() {
          _error = '서버 오류 (${resp.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '네트워크 오류: $e';
        _loading = false;
      });
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 헤더 ──
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF00838F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(context.loc.t('배송조회', '배송조회'),
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── 택배사 + 운송장 정보 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.companyName.isNotEmpty) ...[
                            Text(context.loc.t('택배사', '택배사'),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600])),
                            Text(widget.companyName,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                          ],
                          Text(context.loc.t('운송장번호', '운송장번호'),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                          Text(widget.trackingNumber,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00838F))),
                        ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded,
                        size: 18, color: Color(0xFF00838F)),
                    tooltip: context.loc.t('운송장_복사', '운송장 복사'),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: widget.trackingNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                context.loc.t('운송장번호가 복사됐어요', '운송장번호가 복사됐어요.')),
                            duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        size: 18, color: Color(0xFF00838F)),
                    tooltip: context.loc.t('새로고침', '새로고침'),
                    onPressed: _fetch,
                  ),
                ],
              ),
            ),

            const Divider(height: 20, indent: 16, endIndent: 16),

            // ── 본문 ──
            Flexible(
              child: _loading
                  ? Center(
                      child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(color: Color(0xFF00838F)),
                        SizedBox(height: 16),
                        Text(context.loc.t('배송_정보를_불러오는_중', '배송 정보를 불러오는 중...'),
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ]),
                    ))
                  : _error != null
                      ? _ErrorFallback(
                          message: _error!,
                          trackingNumber: widget.trackingNumber,
                          onRetry: _fetch,
                        )
                      : _events.isEmpty
                          ? Center(
                              child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.inbox_outlined,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text(
                                        context.loc.t('아직_배송_정보가_없습니다__0afdab',
                                            '아직 배송 정보가 없습니다.\n운송장 등록 직후에는 잠시 후 다시 확인해주세요.'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                  ]),
                            ))
                          : _TrackingTimeline(
                              events: _events, formatTime: _formatTime),
            ),

            // ── 하단 버튼 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00838F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.loc.t('닫기', '닫기')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final String Function(String?) formatTime;
  const _TrackingTimeline({required this.events, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: events.length,
      itemBuilder: (ctx, i) {
        final ev = events[i];
        final isFirst = i == 0; // 최신 이벤트
        final statusCode =
            (ev['status']?['code'] as String? ?? '').toUpperCase();
        final statusText = ev['status']?['text'] as String? ?? statusCode;
        final desc = ev['description'] as String? ?? '';
        final time = formatTime(ev['time'] as String?);
        final info = _statusInfo(context, statusCode);

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 타임라인 라인 + 아이콘 ──
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? info.color
                              : info.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: info.color, width: isFirst ? 2.5 : 1.5),
                        ),
                        child: Icon(info.icon,
                            size: 14,
                            color: isFirst ? Colors.white : info.color),
                      ),
                      if (i < events.length - 1)
                        Expanded(
                            child: Container(
                          width: 2,
                          color: Colors.grey[200],
                          margin: const EdgeInsets.symmetric(vertical: 2),
                        )),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // ── 이벤트 내용 ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: isFirst ? 14 : 13,
                                  fontWeight: isFirst
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isFirst ? info.color : Colors.black87,
                                ),
                              ),
                            ),
                            if (time.isNotEmpty)
                              Text(time,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(desc,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
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
}

class _ErrorFallback extends StatelessWidget {
  final String message;
  final String trackingNumber;
  final VoidCallback onRetry;
  const _ErrorFallback(
      {required this.message,
      required this.trackingNumber,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          Text('운송장번호: $trackingNumber',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00838F))),
          const SizedBox(height: 4),
          Text(
              context.loc
                  .t('택배사_앱_또는_사이트에서__8c75c7', '택배사 앱 또는 사이트에서 직접 조회하실 수 있어요.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(context.loc.t('다시 시도', '다시 시도')),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PC 쿠폰함 탭
// ══════════════════════════════════════════════════════════════
class _PcCouponTab extends StatefulWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  const _PcCouponTab({required this.userProvider, required this.loc});

  @override
  State<_PcCouponTab> createState() => _PcCouponTabState();
}

class _PcCouponTabState extends State<_PcCouponTab> {
  String _filter = 'all'; // all / valid / expired

  @override
  Widget build(BuildContext context) {
    return Consumer<CouponProvider>(
      builder: (ctx, cp, _) {
        final all = cp.coupons;
        final shown = _filter == 'valid'
            ? all.where((c) => c.isValid).toList()
            : _filter == 'expired'
                ? all.where((c) => !c.isValid).toList()
                : all;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PcTabHeader(
              icon: Icons.local_activity_rounded,
              title: context.loc.t('내_쿠폰함', '내 쿠폰함'),
              color: AppColors.accent,
              badge: '${all.where((c) => c.isValid).length}',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Wrap(
                spacing: 8,
                children: [
                  _filterChip('all', context.loc.t('전체', '전체')),
                  _filterChip('valid', context.loc.t('사용_가능', '사용 가능')),
                  _filterChip('expired', context.loc.t('만료_사용됨', '만료/사용됨')),
                ],
              ),
            ),
            if (cp.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (shown.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_activity_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        context.loc.t('보유_쿠폰_없음', '보유한 쿠폰이 없습니다.'),
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CouponCard(coupon: shown[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String val, String label) {
    final sel = _filter == val;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _filter = val),
      selectedColor: AppColors.accent.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: sel ? AppColors.accent : Colors.grey[700],
        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
        fontSize: 13,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 모바일 쿠폰함 탭
// ══════════════════════════════════════════════════════════════
class _MobileCouponTab extends StatefulWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  const _MobileCouponTab({required this.userProvider, required this.loc});

  @override
  State<_MobileCouponTab> createState() => _MobileCouponTabState();
}

class _MobileCouponTabState extends State<_MobileCouponTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<CouponProvider>(
      builder: (ctx, cp, _) {
        final all = cp.coupons;
        final shown = _filter == 'valid'
            ? all.where((c) => c.isValid).toList()
            : _filter == 'expired'
                ? all.where((c) => !c.isValid).toList()
                : all;

        return Column(
          children: [
            // 필터 바
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _chip('all', context.loc.t('전체', '전체')),
                  const SizedBox(width: 8),
                  _chip('valid', context.loc.t('사용_가능', '사용 가능')),
                  const SizedBox(width: 8),
                  _chip('expired', context.loc.t('만료_사용됨', '만료/사용됨')),
                ],
              ),
            ),
            const Divider(height: 1),
            if (cp.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (shown.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_activity_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        context.loc.t('보유_쿠폰_없음', '보유한 쿠폰이 없습니다.'),
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: shown.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CouponCard(coupon: shown[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _chip(String val, String label) {
    final sel = _filter == val;
    return GestureDetector(
      onTap: () => setState(() => _filter = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? AppColors.accent : AppColors.surfaceGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 쿠폰 카드 위젯 (공통)
// ══════════════════════════════════════════════════════════════
class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final valid = coupon.isValid;
    return Opacity(
      opacity: valid ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: valid
                ? AppColors.accent.withValues(alpha: 0.4)
                : Colors.grey.shade300,
          ),
          boxShadow: valid
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // 타입 뱃지
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: valid
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_activity_rounded,
                    size: 22,
                    color: valid ? AppColors.accent : Colors.grey,
                  ),
                  Text(
                    coupon.type == CouponType.percent ? '%' : '₩',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: valid ? AppColors.accent : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // 쿠폰 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coupon.typeLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valid ? AppColors.accent : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(
                        '~${coupon.expiresAt.year}.${coupon.expiresAt.month.toString().padLeft(2, '0')}.${coupon.expiresAt.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 상태 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: valid ? AppColors.accent : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                valid
                    ? context.loc.t('사용_가능', '사용 가능')
                    : coupon.isUsed
                        ? context.loc.t('사용됨', '사용됨')
                        : context.loc.t('만료됨', '만료됨'),
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 포인트 탭 — 잔액 요약과 적립·사용 내역 필터
// ══════════════════════════════════════════════════════════════
class _PcPointTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  const _PcPointTab({required this.userProvider, required this.loc});

  @override
  Widget build(BuildContext context) =>
      const _PointHistoryPanel(isMobile: false);
}

class _MobilePointTab extends StatelessWidget {
  final UserProvider userProvider;
  final AppLocalizations loc;
  const _MobilePointTab({required this.userProvider, required this.loc});

  @override
  Widget build(BuildContext context) =>
      const _PointHistoryPanel(isMobile: true);
}

class _PointHistoryPanel extends StatefulWidget {
  final bool isMobile;
  const _PointHistoryPanel({required this.isMobile});

  @override
  State<_PointHistoryPanel> createState() => _PointHistoryPanelState();
}

class _PointHistoryPanelState extends State<_PointHistoryPanel> {
  int _filter = 0; // 0: 전체, 1: 적립, 2: 사용

  List<PointHistory> _filtered(List<PointHistory> history) {
    if (_filter == 0) return history;
    return history.where((item) {
      final earned = item.amount > 0;
      return _filter == 1 ? earned : !earned;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Consumer<PointProvider>(
        builder: (ctx, pp, _) {
          final history = _filtered(pp.history);
          final earned = pp.history
              .where((item) => item.amount > 0)
              .fold<int>(0, (sum, item) => sum + item.amount);
          final used = pp.history
              .where((item) => item.amount < 0)
              .fold<int>(0, (sum, item) => sum + item.amount.abs());
          final number = (int value) => value.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
          final horizontal = widget.isMobile ? 16.0 : 24.0;
          final minPoints = PointService.minUsePoints;
          final canUse = pp.balance >= minPoints;
          final now = DateTime.now();
          final expiringSoon = pp.history.where((item) {
            final expires = item.expiresAt;
            if (item.amount <= 0 || expires == null) return false;
            final days = expires.difference(now).inDays;
            return days >= 0 && days <= 30;
          }).fold<int>(0, (sum, item) => sum + item.amount);
          final nearestExpiry = pp.history
              .where((item) =>
                  item.amount > 0 &&
                  item.expiresAt != null &&
                  !item.expiresAt!.isBefore(now))
              .map((item) => item.expiresAt!)
              .fold<DateTime?>(
                  null,
                  (nearest, date) => nearest == null || date.isBefore(nearest)
                      ? date
                      : nearest);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isMobile)
                _PcTabHeader(
                  icon: Icons.stars_rounded,
                  title: context.loc.t('포인트', '포인트'),
                  color: AppColors.accent,
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    horizontal, widget.isMobile ? 16 : 0, horizontal, 16),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(widget.isMobile ? 18 : 22),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(context.loc.t('보유_포인트', '보유 포인트'),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const Spacer(),
                          Text(canUse ? '사용 가능' : '${number(minPoints)}P부터 사용',
                              style: TextStyle(
                                  color: canUse
                                      ? AppColors.accent
                                      : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${number(pp.balance)} P',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PointSummary(
                                label: '누적 적립', value: '+${number(earned)}P'),
                          ),
                          Expanded(
                            child: _PointSummary(
                                label: '누적 사용', value: '-${number(used)}P'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (expiringSoon > 0)
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD98A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 18, color: Color(0xFFB7791F)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nearestExpiry == null
                                ? '30일 이내 소멸 예정 포인트 ${number(expiringSoon)}P'
                                : '30일 이내 ${number(expiringSoon)}P가 소멸 예정입니다.\n'
                                    '소멸 예정일: ${nearestExpiry.year}.${nearestExpiry.month}.${nearestExpiry.day}',
                            style: const TextStyle(
                              color: Color(0xFF8A5A00),
                              fontSize: 12,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 8),
                child: Row(
                  children: [
                    Text(context.loc.t('포인트_내역', '포인트 내역'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${history.length}건',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PointFilterChip(
                          label: '전체',
                          selected: _filter == 0,
                          onTap: () => setState(() => _filter = 0)),
                      _PointFilterChip(
                          label: '적립',
                          selected: _filter == 1,
                          onTap: () => setState(() => _filter = 1)),
                      _PointFilterChip(
                          label: '사용',
                          selected: _filter == 2,
                          onTap: () => setState(() => _filter = 2)),
                    ],
                  ),
                ),
              ),
              if (pp.isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (history.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _filter == 0
                          ? context.loc.t('포인트_내역_없음', '포인트 내역이 없습니다.')
                          : '해당 내역이 없습니다.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 24),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _PointHistoryTile(item: history[i]),
                  ),
                ),
            ],
          );
        },
      );
    } catch (error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '포인트 내역을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
  }
}

class _PointSummary extends StatelessWidget {
  final String label;
  final String value;
  const _PointSummary({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      );
}

class _PointFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PointFilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.primary,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700),
          side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
// 포인트 내역 타일 (공통)
// ══════════════════════════════════════════════════════════════
class _PointHistoryTile extends StatelessWidget {
  final PointHistory item;
  const _PointHistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isEarn = item.action == PointActionType.earn ||
        item.action == PointActionType.admin && item.amount > 0;
    final amtStr = isEarn
        ? '+${item.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} P'
        : '${item.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} P';
    final amtColor = isEarn ? AppColors.accent : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEarn
                  ? const Color(0xFFFF6F00).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarn ? Icons.add_rounded : Icons.remove_rounded,
              size: 20,
              color: isEarn ? const Color(0xFFFF6F00) : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.desc,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.createdAt.year}.${item.createdAt.month.toString().padLeft(2, '0')}.${item.createdAt.day.toString().padLeft(2, '0')}  ${item.action.label}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            amtStr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: amtColor,
            ),
          ),
        ],
      ),
    );
  }
}
