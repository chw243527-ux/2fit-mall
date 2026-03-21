import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'utils/theme.dart';
import 'providers/providers.dart';
import 'services/auth_service.dart';
import 'screens/home/splash_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/orders/checkout_screen.dart';
import 'screens/orders/group_order_guide_screen.dart';
import 'screens/orders/group_order_form_screen.dart';
import 'screens/orders/group_order_only_screen.dart';

import 'screens/orders/order_guide_screen.dart';
import 'screens/orders/group_custom_order_screen.dart';
import 'models/models.dart';
import 'screens/chat/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (오류 시에도 앱 실행 유지)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) debugPrint('✅ Firebase 초기화 성공');
    // FCM 초기화
    await FcmService.initialize();
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
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title: '2FIT MALL',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        builder: (context, child) {
          return child!;
        },
        home: const _AppInit(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
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
            case '/group-guide':
              return MaterialPageRoute(
                builder: (_) => const GroupOrderGuideScreen(),
                settings: settings,
              );
            case '/group-form':
              return MaterialPageRoute(
                builder: (_) => const GroupOrderFormScreen(),
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
            default:
              return null;
          }
        },
      ),
    );
  }
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
    return Theme(
      data: AppTheme.lightTheme,
      child: const SplashScreen(),
    );
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
