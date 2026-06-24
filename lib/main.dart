import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
// 네이버 로그인: Web(dart.library.html)은 stub, 앱(dart.library.io)은 실제 패키지
import 'services/naver_login_stub.dart'
    if (dart.library.io) 'package:flutter_naver_login/flutter_naver_login.dart'
    as naver;
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'utils/theme.dart';
import 'utils/responsive.dart';
import 'providers/providers.dart';
import 'utils/app_localizations.dart';
import 'services/auth_service.dart';
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

  // 네이버 SDK 초기화 (앱 전용 — Web 빌드 시 stub 사용)
  try {
    await naver.FlutterNaverLogin.initSdk(
      clientId: 'RTeQb5TSs920qoowhcra',
      clientSecret: 'l5P3RChcnd',
      clientName: '2FIT mall',
      enableNaverAppAuthIOS: true,
    );
    if (kDebugMode) debugPrint('✅ NaverSdk 초기화 성공');
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ NaverSdk 초기화 오류: $e');
  }

  // Firebase 초기화 (오류 시에도 앱 실행 유지)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) debugPrint('✅ Firebase 초기화 성공');
    // FCM 초기화
    await FcmService.initialize();
    // 카테고리 서비스 사전 로드 (앱 시작 시 Firestore에서 카테고리 불러오기)
    await CategoryService.load();
    if (kDebugMode) debugPrint('✅ CategoryService 로드: ${CategoryService.mainCategories}');
  } catch (e) {
    if (kDebugMode) debugPrint('⚠️ Firebase 초기화 오류: $e');
    // Firebase 실패해도 앱은 계속 실행 (로컬 모드로 동작)
  }

  // Hive 초기화 (장바구니, 로컬 사용자 데이터용)
  try {
    await Hive.initFlutter();
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
        ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
        // LanguageProviderBridge로도 접근 가능하게 (context.loc 사용)
        ProxyProvider<LanguageProvider, LanguageProviderBridge>(
          update: (ctx, lp, _) => lp,
        ),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => PointProvider()),
        ChangeNotifierProvider(create: (_) => SizeProfileProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
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
                  product: groupOrderProduct is ProductModel ? groupOrderProduct : null,
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
            case '/admin':
              // 이메일 링크에서 진입 시 URL 파라미터로 탭 지정
              // 예: https://2fit-mall.co.kr/#/admin?tab=orders -> 주문관리(탭 1)
              final args = settings.arguments;
              int initialTab = 0;
              if (args is Map<String, dynamic>) {
                final tab = args['tab'];
                if (tab == 'orders') initialTab = 1;
                else if (tab is int) initialTab = tab;
              }
              return MaterialPageRoute(
                builder: (_) => AdminScreen(initialTab: initialTab),
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
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      // 3초 안에 안 되면 포기하고 로그인 화면에서 처리
      final result = await AuthService.restoreSession()
          .timeout(const Duration(seconds: 3),
              onTimeout: () => const AuthResult(success: false));
      if (!mounted) return;
      if (result.success && result.user != null) {
        final user = result.user!;
        context.read<UserProvider>().login(user);
        // 모두 백그라운드 비동기 (await 없음 - 스플래시 차단 방지)
        context.read<OrderProvider>().loadUserOrders(user.id);
        context.read<UserProvider>().syncWishlistFromFirestore();
        context.read<CouponProvider>().loadUserCoupons(user.id);
        context.read<PointProvider>().loadFromFirestore(user.id);
        context.read<NotificationProvider>().loadFromFirestore(user.id);
        context.read<SizeProfileProvider>().loadProfiles(user.id);
        FcmService.saveTokenToFirestore(user.id).catchError(
          (e) { if (kDebugMode) debugPrint('⚠️ FCM 토큰 저장 실패: $e'); },
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
