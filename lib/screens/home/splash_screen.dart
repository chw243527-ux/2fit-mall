import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../auth/login_screen.dart';

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
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
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
        ),
      ),
    );
  }
}
