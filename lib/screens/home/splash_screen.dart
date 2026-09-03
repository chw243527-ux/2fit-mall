import 'dart:async';

import '../../utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../main_screen.dart';
import '../admin/admin_screen.dart';
import '../products/product_detail_by_id_screen.dart';
import '../products/category_by_name_screen.dart';
import '../policy/terms_of_service_screen.dart';
import '../policy/privacy_policy_screen.dart';
import '../policy/account_deletion_screen.dart';
import '../orders/group_order_landing_screen.dart';
import '../orders/group_order_form_screen.dart';
import '../orders/group_order_only_screen.dart';
import '../orders/order_guide_screen.dart';
import '../mypage/size_profile_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../not_found_screen.dart';
import '../chat/chat_screen.dart';
import '../payment/payment_result_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _progressAnim;
  bool _navigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700), // 1800→700 빠른 등장
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();

    // Firebase/Storage가 응답하지 않아도 스플래시가 무한히 남지 않도록
    // 안전한 최대 대기 시간을 둡니다.
    _fallbackTimer = Timer(const Duration(seconds: 15), _fallbackToRoute);

    // delay 완전 제거 → Firebase 응답 즉시 전환 (애니메이션은 독립 실행)
    _checkAutoLogin();
  }

  /// Firebase 자동로그인 확인 후 라우팅
  Future<void> _checkAutoLogin() async {
    if (!mounted || _navigated) return;
    _navigated = true;

    // ── 웹 URL 파싱 ──────────────────────────────────────────────────
    // 1) pathname 우선: 토스페이먼츠가 top.location.href로 리다이렉트하면
    //    https://2fit-mall.co.kr/payment/success?paymentKey=... 형태이므로
    //    pathname(/payment/success)을 먼저 확인
    // 2) fragment: Flutter hash-routing (#/path?query) 방식
    _DeepLink? deepLink;
    if (kIsWeb) {
      try {
        final pathname = Uri.base.path;
        final query = Uri.base.queryParameters;
        // 브라우저 주소창으로 직접 여는 공개 페이지와 결제 콜백은
        // hash(#) 없이도 현재 pathname을 딥링크로 인식해야 합니다.
        const publicPathRoutes = {
          '/privacy-policy',
          '/account-deletion',
          '/terms-of-service',
          '/refund-policy',
          '/signup',
          '/login',
          '/payment/success',
          '/payment/fail',
          '/admin',
        };
        if (publicPathRoutes.contains(pathname)) {
          deepLink = _DeepLink(pathname, query, requiresAuth: false);
        } else {
          // fragment 기반 hash-routing: https://2fit-mall.co.kr/#/path?query
          final fragment = Uri.base.fragment; // e.g. "/product?id=abc123"
          if (fragment.isNotEmpty) {
            deepLink = _parseDeepLink(fragment);
          }
        }
      } catch (_) {}
    }

    try {
      final firebaseReady = await AuthService.waitForFirebaseInitialization();
      if (!firebaseReady) {
        if (deepLink != null && deepLink.requiresAuth) {
          _goToLoginWithRedirect(deepLink);
        } else if (deepLink != null) {
          if (mounted)
            _navigateAfterLogin(deepLink, isLoggedIn: false, isAdmin: false);
        } else {
          _goToPublicHome();
        }
        return;
      }

      final result = await AuthService.restoreSession().timeout(
        const Duration(seconds: 5),
        onTimeout: () => const AuthResult(success: false),
      );

      if (result.success && result.user != null) {
        if (mounted) {
          context.read<UserProvider>().login(result.user!);
          context.read<CouponProvider>().loadValidCoupons(result.user!.id);
        }
        if (mounted)
          _navigateAfterLogin(deepLink,
              isLoggedIn: true, isAdmin: result.user!.isAdmin);
      } else {
        // 세션 없음
        if (deepLink != null && deepLink.requiresAuth) {
          // 로그인 필요 페이지 → 로그인 후 리다이렉트
          _goToLoginWithRedirect(deepLink);
        } else if (deepLink != null) {
          // 로그인 불필요 공개 페이지 → 바로 이동
          if (mounted)
            _navigateAfterLogin(deepLink, isLoggedIn: false, isAdmin: false);
        } else {
          _goToPublicHome();
        }
      }
    } catch (_) {
      _goToPublicHome();
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // URL fragment를 파싱해 _DeepLink 객체로 변환
  // ──────────────────────────────────────────────────────────────────
  _DeepLink? _parseDeepLink(String fragment) {
    // fragment = "/product?id=abc" 또는 "/products" 등
    final uri = Uri.parse(fragment);
    final path = uri.path; // "/product"
    final q = uri.queryParameters; // {"id": "abc"}

    switch (path) {
      // 홈
      case '/':
      case '/home':
        return _DeepLink(path, q, requiresAuth: false);
      // 상품 목록
      case '/products':
        return _DeepLink(path, q, requiresAuth: false);
      // 상품 상세 (/product?id=XXXX)
      case '/product':
        return _DeepLink(path, q, requiresAuth: false);
      // 카테고리 (/category?name=상의)
      case '/category':
        return _DeepLink(path, q, requiresAuth: false);
      // 장바구니
      case '/cart':
      case '/cart-tab':
        return _DeepLink('/cart', q, requiresAuth: false);
      // 마이페이지
      case '/mypage':
        return _DeepLink(path, q, requiresAuth: true);
      // 로그인
      case '/login':
        return _DeepLink(path, q, requiresAuth: false);
      // 회원가입
      case '/signup':
        return _DeepLink(path, q, requiresAuth: false);
      // 관리자
      case '/admin':
        return _DeepLink(path, q, requiresAuth: true, requiresAdmin: true);
      // 단체주문
      case '/group-order':
      case '/group-guide':
        return _DeepLink(path, q, requiresAuth: false);
      case '/group-form':
        return _DeepLink(path, q, requiresAuth: false);
      case '/group-only':
        return _DeepLink(path, q, requiresAuth: false);
      // 주문 가이드
      case '/order-guide':
        return _DeepLink(path, q, requiresAuth: false);
      // 채팅
      case '/chat':
        return _DeepLink(path, q, requiresAuth: false);
      // 이용약관
      case '/terms-of-service':
      case '/refund-policy':
        return _DeepLink(path, q, requiresAuth: false);
      // 개인정보처리방침
      case '/privacy-policy':
        return _DeepLink(path, q, requiresAuth: false);
      // 계정 삭제 요청
      case '/account-deletion':
        return _DeepLink(path, q, requiresAuth: false);
      // 사이즈 프로필
      case '/size-profile':
        return _DeepLink(path, q, requiresAuth: true);
      // 알림 센터
      case '/notifications':
        return _DeepLink(path, q, requiresAuth: true);
      // 결제 성공/실패 콜백 (fragment 방식으로 접근하는 경우 처리)
      case '/payment/success':
        return _DeepLink(path, q, requiresAuth: false);
      case '/payment/fail':
        return _DeepLink(path, q, requiresAuth: false);
      default:
        return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // 로그인 여부에 따라 목표 화면으로 이동
  // ──────────────────────────────────────────────────────────────────
  void _navigateAfterLogin(_DeepLink? link,
      {required bool isLoggedIn, required bool isAdmin}) {
    if (!mounted) return;

    Widget target;

    if (link == null) {
      // 홈은 공개 화면이므로 로그아웃 상태에서도 진입합니다.
      target = const MainScreen();
    } else {
      switch (link.path) {
        case '/':
        case '/home':
          target = const MainScreen(initialIndex: 0);
          break;
        case '/products':
          target = MainScreen(
            initialIndex: 1,
            initialCategory: link.query['category'],
            initialSearch: link.query['search'],
          );
          break;
        case '/product':
          final id = link.query['id'] ?? '';
          target = id.isNotEmpty
              ? ProductDetailByIdScreen(productId: id)
              : const NotFoundScreen();
          break;
        case '/category':
          final name = link.query['name'] ?? '';
          target = name.isNotEmpty
              ? CategoryByNameScreen(categoryName: name)
              : const NotFoundScreen();
          break;
        case '/cart':
          target = const MainScreen(initialIndex: 2);
          break;
        case '/mypage':
          target = isLoggedIn
              ? const MainScreen(initialIndex: 3)
              : const LoginScreen();
          break;
        case '/login':
          target = const LoginScreen();
          break;
        case '/signup':
          target = const SignUpScreen();
          break;
        case '/admin':
          if (isLoggedIn && !isAdmin) {
            // 고객용 세션이 관리자 주소에 남아 있으면 관리자 로그인 전에 정리합니다.
            AuthService.logout().whenComplete(() {
              if (mounted) _goToLoginWithRedirect(link);
            });
            return;
          }
          if (isLoggedIn && isAdmin) {
            final tab = link.query['tab'];
            int initialTab = 0;
            if (tab == 'orders')
              initialTab = 1;
            else if (tab == 'products')
              initialTab = 2;
            else if (tab == 'users') initialTab = 3;
            target = AdminScreen(
              initialTab: initialTab,
              adminOnly: true,
            );
          } else {
            // /admin에서 로그인하면 로그인 성공 후 관리자 대시보드로 이동하도록
            // redirectPath를 반드시 유지합니다. 일반 계정은 LoginScreen에서 차단합니다.
            target = const LoginScreen(
              redirectPath: '/admin',
              adminOnly: true,
            );
          }
          break;
        case '/group-order':
        case '/group-guide':
          target = const GroupOrderLandingScreen();
          break;
        case '/group-form':
          target = const GroupOrderFormScreen(initialCount: 5);
          break;
        case '/group-only':
          target = const GroupOrderOnlyScreen();
          break;
        case '/order-guide':
          target = const OrderGuideScreen();
          break;
        case '/chat':
          target = const ChatScreen();
          break;
        case '/terms-of-service':
        case '/refund-policy':
          target = const TermsOfServiceScreen();
          break;
        case '/privacy-policy':
          target = const PrivacyPolicyScreen();
          break;
        case '/account-deletion':
          target = const AccountDeletionScreen();
          break;
        case '/size-profile':
          target = isLoggedIn ? const SizeProfileScreen() : const LoginScreen();
          break;
        case '/notifications':
          target = isLoggedIn
              ? const NotificationCenterScreen()
              : const LoginScreen();
          break;
        // ── 토스페이먼츠 결제 콜백 ────────────────────────────
        // top.location.href로 리다이렉트되어 pathname 방식으로 진입
        case '/payment/success':
          target = const PaymentSuccessScreen();
          break;
        case '/payment/fail':
          target = const PaymentFailScreen();
          break;
        default:
          // 알 수 없는 공개 경로는 홈으로 복귀시킵니다.
          target = const MainScreen();
      }
    }

    Navigator.of(context, rootNavigator: true).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goToPublicHome() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goToLoginWithRedirect(_DeepLink link) {
    if (!mounted) return;
    // 로그인 후 딥링크로 이동할 수 있도록 arguments 전달
    Navigator.of(context, rootNavigator: true).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LoginScreen(
          redirectPath: link.path,
          adminOnly: link.path == '/admin',
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _fallbackToRoute() {
    if (!mounted || _navigated) return;
    _navigated = true;

    _DeepLink? link;
    if (kIsWeb) {
      try {
        final pathname = Uri.base.path;
        final query = Uri.base.queryParameters;
        if (pathname != '/' && pathname.isNotEmpty) {
          link = _DeepLink(pathname, query, requiresAuth: false);
        } else if (Uri.base.fragment.isNotEmpty) {
          link = _parseDeepLink(Uri.base.fragment);
        }
      } catch (_) {}
    }

    if (link != null) {
      _navigateAfterLogin(link, isLoggedIn: false, isAdmin: false);
    } else {
      _goToPublicHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _animController,
        builder: (ctx, _) => Stack(
          children: [
            // ── 중앙 로고 + 태그라인 ─────────────────────────
            Center(
              child: Opacity(
                opacity: _fadeAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 아이콘 – 화면 크기에 맞춰 최대한 크게
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final size = MediaQuery.of(ctx).size;
                          // 화면 짧은 쪽의 65% 사용 (최소 200, 최대 340)
                          final iconSize =
                              (size.shortestSide * 0.65).clamp(200.0, 340.0);
                          return ClipRRect(
                            borderRadius:
                                BorderRadius.circular(iconSize * 0.18),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: iconSize,
                              height: iconSize,
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // 태그라인
                      const Text(
                        'SPORTS & FITNESS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 하단 진행 바 ─────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Opacity(
                opacity: _fadeAnim.value,
                child: Column(
                  children: [
                    // 진행 바
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _progressAnim.value,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.textPrimary,
                          ),
                          minHeight: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '2FIT MALL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: AppColors.border,
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

  Widget _fallbackLogo() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '2FIT',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'KOREA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// URL 딥링크 정보를 담는 단순 데이터 클래스
// ─────────────────────────────────────────────────────────────────────────────
class _DeepLink {
  final String path;
  final Map<String, String> query;
  final bool requiresAuth;
  final bool requiresAdmin;

  const _DeepLink(
    this.path,
    this.query, {
    this.requiresAuth = false,
    this.requiresAdmin = false,
  });
}
