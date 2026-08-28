import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'utils/theme.dart';
import 'utils/responsive.dart';
import 'providers/providers.dart';
import 'utils/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/order_service.dart';
import 'screens/home/splash_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/orders/checkout_screen.dart';
import 'screens/orders/group_order_form_screen.dart';
import 'screens/orders/group_order_only_screen.dart';
import 'screens/orders/group_order_landing_screen.dart';

import 'screens/orders/order_guide_screen.dart';
import 'screens/orders/group_custom_order_screen.dart';
import 'models/models.dart';
import 'screens/auth/login_screen.dart';
import 'services/category_service.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/policy/privacy_policy_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/policy/terms_of_service_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/products/product_detail_by_id_screen.dart';
import 'screens/products/category_by_name_screen.dart';
import 'screens/mypage/size_profile_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/notifications/notification_center_screen.dart';
import 'screens/main_screen.dart';
import 'screens/payment/payment_result_screen.dart';
import 'screens/payment/payment_checkout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 초기화
  try {
    kakao.KakaoSdk.init(
      nativeAppKey: '590de0b0412c1c14f49369bf99268914',
      javaScriptAppKey: 'cc9800839ee51bb010cd0d7046f4b565',
    );
    if (kDebugMode) debugPrint('✅ KakaoSdk 초기화 성공');
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ KakaoSdk 초기화 오류: $e');
  }

  // Firebase Core만 첫 화면 전에 초기화합니다.
  // FCM 권한 요청과 Firestore 사전 로드는 브라우저 권한창·네트워크 지연으로
  // 앱 첫 프레임을 막을 수 있으므로 runApp 이후 백그라운드에서 실행합니다.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    firebaseReady = true;
    if (kDebugMode) debugPrint('✅ Firebase 초기화 성공');
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ Firebase 초기화 오류: $e');
    // Firebase 실패해도 앱은 계속 실행 (로컬 모드로 동작)
  }

  // Hive 초기화 (장바구니, 로컬 사용자 데이터용)
  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 5));
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ Hive 초기화 오류: $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TwoFitMallApp());

  // 선택적 네트워크 초기화는 첫 프레임 이후 실행합니다.
  // 특히 Web FCM requestPermission()은 사용자의 브라우저 응답을 기다릴 수
  // 있으므로 main()에서 await하지 않습니다.
  if (firebaseReady) {
    Future<void>(() async {
      try {
        await FcmService.initialize().timeout(const Duration(seconds: 8));
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ FCM 백그라운드 초기화 건너뜀: $e');
      }
      try {
        await CategoryService.load().timeout(const Duration(seconds: 8));
        if (kDebugMode) {
          debugPrint('✅ CategoryService 로드: ${CategoryService.mainCategories}');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ CategoryService 백그라운드 로드 건너뜀: $e');
      }
    });
  }
}

// 전역 navigatorKey - 브라우저 뒤로가기와 Flutter Navigator 연동
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TwoFitMallApp extends StatefulWidget {
  const TwoFitMallApp({super.key});

  @override
  State<TwoFitMallApp> createState() => _TwoFitMallAppState();
}

class _TwoFitMallAppState extends State<TwoFitMallApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider<LanguageProvider>(
            create: (_) => LanguageProvider()),
        // LanguageProviderBridge로도 접근 가능하게 (context.loc 사용)
        ProxyProvider<LanguageProvider, LanguageProviderBridge>(
          update: (ctx, lp, _) => lp,
        ),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SizeProfileProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
        ChangeNotifierProvider(create: (_) => PointProvider()),
      ],
      child: MaterialApp(
        title: '2FIT MALL',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        // 웹에서 마우스/터치 드래그 스크롤 모두 활성화
        scrollBehavior: const _AppScrollBehavior(),
        // ── 전역 반응형 처리 ──────────────────────────────────
        // 1) 시스템 textScaler를 0.9~1.2 범위로 클램프
        //    → 접근성 설정에 의해 레이아웃 깨지는 현상 방지
        // 2) 화면 너비 기반 AppTheme(반응형 TextTheme) 적용
        builder: (context, child) {
          final sw = MediaQuery.of(context).size.width;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: clampedTextScaler(context),
            ),
            child: Theme(
              data: AppTheme.lightTheme(screenWidth: sw),
              child: child!,
            ),
          );
        },
        home: const _AppInit(),
        // 기본 테마 (builder에서 반응형으로 덮어씀)
        theme: AppTheme.lightTheme().copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
        ),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
                settings: settings,
              );
            case '/cart':
              return MaterialPageRoute(
                builder: (_) => const CartScreen(),
                settings: settings,
              );
            case '/checkout':
              return MaterialPageRoute(
                builder: (ctx) => CheckoutScreen(
                  cart: ctx.read<CartProvider>(),
                ),
                settings: settings,
              );
            case '/group-order':
              // product 인자가 있으면 GroupOrderLandingScreen(안내→주문서), 없으면 LandingScreen
              final groupOrderProduct = settings.arguments;
              return MaterialPageRoute(
                builder: (_) => GroupOrderLandingScreen(
                  product: groupOrderProduct is ProductModel
                      ? groupOrderProduct
                      : null,
                ),
              );
            case '/group-guide':
              // /group-guide → LandingScreen으로 리다이렉트
              return MaterialPageRoute(
                builder: (_) => const GroupOrderLandingScreen(),
                settings: settings,
              );
            case '/group-form':
              return MaterialPageRoute(
                builder: (_) => const GroupOrderFormScreen(initialCount: 5),
                settings: settings,
              );
            case '/group-only':
              return MaterialPageRoute(
                builder: (_) => const GroupOrderOnlyScreen(),
                settings: settings,
              );
            case '/order-guide':
              return MaterialPageRoute(
                builder: (_) => const OrderGuideScreen(),
                settings: settings,
              );
            case '/group-custom-order':
              // 상품 상세에서만 product 파라미터와 함께 push (직접 접근 시 홈으로)
              final product = settings.arguments;
              if (product is ProductModel) {
                return MaterialPageRoute(
                  builder: (_) => GroupCustomOrderScreen(product: product),
                  settings: settings,
                );
              }
              return MaterialPageRoute(
                builder: (_) => const _HomeRedirect(),
                settings: settings,
              );
            case '/chat':
              return MaterialPageRoute(
                builder: (_) => const ChatScreen(),
                settings: settings,
              );
            case '/privacy-policy':
              return MaterialPageRoute(
                builder: (_) => const PrivacyPolicyScreen(),
                settings: settings,
              );
            case '/terms-of-service':
              return MaterialPageRoute(
                builder: (_) => const TermsOfServiceScreen(),
                settings: settings,
              );
            // ── 신규 URL 직접 접근 라우트 ──────────────────────
            // 홈
            case '/':
            case '/home':
              return MaterialPageRoute(
                builder: (_) => const MainScreen(initialIndex: 0),
                settings: settings,
              );
            // 상품 목록
            case '/products':
              final args = settings.arguments;
              final category = args is Map ? args['category'] as String? : null;
              final search = args is Map ? args['search'] as String? : null;
              return MaterialPageRoute(
                builder: (_) => MainScreen(
                  initialIndex: 1,
                  initialCategory: category,
                  initialSearch: search,
                ),
                settings: settings,
              );
            // 상품 상세 (/products/:id)
            case '/product':
              final pArgs = settings.arguments;
              final pid =
                  pArgs is Map ? pArgs['id'] as String? : pArgs as String?;
              if (pid != null && pid.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (_) => ProductDetailByIdScreen(productId: pid),
                  settings: settings,
                );
              }
              return MaterialPageRoute(
                  builder: (_) => const NotFoundScreen(), settings: settings);
            // 카테고리 (/category/:name)
            case '/category':
              final cArgs = settings.arguments;
              final cname =
                  cArgs is Map ? cArgs['name'] as String? : cArgs as String?;
              if (cname != null && cname.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (_) => CategoryByNameScreen(categoryName: cname),
                  settings: settings,
                );
              }
              return MaterialPageRoute(
                  builder: (_) => const NotFoundScreen(), settings: settings);
            // 장바구니
            case '/cart-tab':
              return MaterialPageRoute(
                builder: (_) => const MainScreen(initialIndex: 2),
                settings: settings,
              );
            // 마이페이지
            case '/mypage':
              return MaterialPageRoute(
                builder: (_) => const MainScreen(initialIndex: 3),
                settings: settings,
              );
            // 회원가입
            case '/signup':
              return MaterialPageRoute(
                builder: (_) => const SignUpScreen(),
                settings: settings,
              );
            // 사이즈 프로필
            case '/size-profile':
              return MaterialPageRoute(
                builder: (_) => const SizeProfileScreen(),
                settings: settings,
              );
            // 알림 센터
            case '/notifications':
              return MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(),
                settings: settings,
              );
            // 환불 정책 (이용약관의 교환/환불 조항 직접 연결)
            case '/refund-policy':
              return MaterialPageRoute(
                builder: (_) => const TermsOfServiceScreen(),
                settings: settings,
              );
            case '/admin':
              // 이메일 링크에서 진입 시 URL 파라미터로 탭 지정
              // 예: https://2fit-mall.co.kr/#/admin?tab=orders -> 주문관리(탭 1)
              final args = settings.arguments;
              int initialTab = 0;
              if (args is Map<String, dynamic>) {
                final tab = args['tab'];
                if (tab == 'orders')
                  initialTab = 1;
                else if (tab is int) initialTab = tab;
              }
              return MaterialPageRoute(
                builder: (_) => AdminScreen(initialTab: initialTab),
                settings: settings,
              );
            // 토스페이먼츠 결제 성공 콜백
            case '/payment/success':
              return MaterialPageRoute(
                builder: (_) => const PaymentSuccessScreen(),
                settings: settings,
              );
            // 토스페이먼츠 결제 실패 콜백
            case '/payment/fail':
              return MaterialPageRoute(
                builder: (_) => const PaymentFailScreen(),
                settings: settings,
              );
            // 토스페이먼츠 Payment Widget 결제 화면
            case '/payment/checkout':
              return MaterialPageRoute(
                builder: (_) => const PaymentCheckoutScreen(),
                settings: settings,
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const NotFoundScreen(),
                settings: settings,
              );
          }
        },
      ),
    );
  }
}

/// 웹/데스크톱에서 마우스 드래그 스크롤 활성화 + 물리적 스크롤 부드럽게
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

/// 앱 초기화 (자동 로그인 세션 복구)
class _AppInit extends StatefulWidget {
  const _AppInit();
  @override
  State<_AppInit> createState() => _AppInitState();
}

class _AppInitState extends State<_AppInit> {
  Timer? _deliveryCheckTimer;
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _deepLinkSub =
        AppLinks().uriLinkStream.listen(AuthService.handleNaverDeepLink);
    // 앱 시작 후 1분 뒤 첫 번째 배송완료 자동 체크, 이후 30분마다 반복
    Future.delayed(const Duration(minutes: 1), () {
      if (!mounted) return;
      OrderService.autoCheckDelivered().then((n) {
        if (kDebugMode && n > 0) debugPrint('🚚 자동 배송완료 처리: $n건');
      });
    });
    _deliveryCheckTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      OrderService.autoCheckDelivered().then((n) {
        if (kDebugMode && n > 0) debugPrint('🚚 자동 배송완료 처리: $n건');
      });
    });
  }

  @override
  void dispose() {
    _deliveryCheckTimer?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    try {
      // 3초 안에 안 되면 포기하고 로그인 화면에서 처리
      final result = await AuthService.restoreSession().timeout(
          const Duration(seconds: 3),
          onTimeout: () => const AuthResult(success: false));
      if (!mounted) return;
      if (result.success && result.user != null) {
        final user = result.user!;
        context.read<UserProvider>().login(user);
        // 모두 백그라운드 비동기 (await 없음 - 스플래시 차단 방지)
        context.read<OrderProvider>().loadUserOrders(user.id);
        context.read<UserProvider>().syncWishlistFromFirestore();
        context.read<NotificationProvider>().loadFromFirestore(user.id);
        context.read<SizeProfileProvider>().loadProfiles(user.id);
        context.read<CouponProvider>().loadValidCoupons(user.id);
        context.read<PointProvider>().loadPoints(user.id);
        FcmService.saveTokenToFirestore(user.id).catchError(
          (e) {
            if (kDebugMode) debugPrint('⚠️ FCM 토큰 저장 실패: $e');
          },
        );
      }
      // 관리자용 전체 주문 백그라운드 로드
      context.read<OrderProvider>().loadAllOrders();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

// ── 웹 브라우저 뒤로가기 → Flutter Navigator.pop() 연동 ──
class _WebBackButtonHandler extends StatefulWidget {
  final Widget child;
  const _WebBackButtonHandler({required this.child});
  @override
  State<_WebBackButtonHandler> createState() => _WebBackButtonHandlerState();
}

class _WebBackButtonHandlerState extends State<_WebBackButtonHandler> {
  @override
  Widget build(BuildContext context) {
    // Router가 없을 때도 동작하는 PopScope 대신
    // NavigatorState를 직접 활용
    return widget.child;
  }
}

// 직접 접근 시 홈으로 리다이렉트 (상품 없이 group-custom-order 진입 방지)
class _HomeRedirect extends StatelessWidget {
  const _HomeRedirect();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
