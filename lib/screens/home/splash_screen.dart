import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
<<<<<<< HEAD
import '../auth/login_screen.dart';
=======
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../main_screen.dart';
>>>>>>> origin/main

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
<<<<<<< HEAD
=======
  late Animation<double> _progressAnim;
>>>>>>> origin/main
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
<<<<<<< HEAD
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0, 0.5)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    // 첫 프레임 완료 후 타이머 시작 (Navigator context 보장)
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2000), _goToLogin);
    });
  }

  void _goToLogin() {
    if (!mounted || _navigated) return;
    _navigated = true;
=======
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.95, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2200), _checkAutoLogin);
    });
  }

  /// Firebase 자동로그인 확인 후 라우팅
  Future<void> _checkAutoLogin() async {
    if (!mounted || _navigated) return;
    _navigated = true;

    try {
      // AuthService.restoreSession()으로 Firebase 세션 복구
      final result = await AuthService.restoreSession();

      if (result.success && result.user != null) {
        // 세션 복구 성공 → UserProvider에 유저 정보 설정
        if (mounted) {
          context.read<UserProvider>().login(result.user!);
        }

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MainScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } else {
        // 세션 없음 → 로그인 화면
        _goToLogin();
      }
    } catch (e) {
      // 오류 발생 시 로그인 화면으로 이동
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
>>>>>>> origin/main
    Navigator.of(context, rootNavigator: true).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
<<<<<<< HEAD
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (ctx, child) => Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_2fit_korea.png',
                    height: 120,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/logo_2fit.png',
                      height: 100,
                      errorBuilder: (_, __, ___2) => const Column(
                        children: [
                          Text(
                            '2FIT',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            'KOREA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 6,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
=======
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
                      // 아이콘
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/logo_2fit_korea.png',
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___2) => _fallbackLogo(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 태그라인
                      const Text(
                        'SPORTS & FITNESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 하단 진행 바 ─────────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 48,
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
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF111111),
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
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
>>>>>>> origin/main
        ),
      ),
    );
  }
<<<<<<< HEAD
=======

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
            color: Color(0xFF111111),
          ),
        ),
        Text(
          'KOREA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
>>>>>>> origin/main
}
