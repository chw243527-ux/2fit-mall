import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/pc_layout.dart';
import '../main_screen.dart';
import '../admin/admin_screen.dart';
import '../mypage/size_profile_screen.dart';
import '../notifications/notification_center_screen.dart';
import 'signup_screen.dart';
import 'social_phone_onboarding_screen.dart';
import '../../utils/navigation_helper.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectPath;

  const LoginScreen({super.key, this.redirectPath});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  Widget _targetAfterLogin({bool isAdmin = false}) {
    switch (widget.redirectPath) {
      case '/mypage':
        return const MainScreen(initialIndex: 3);
      case '/size-profile':
        return const SizeProfileScreen();
      case '/notifications':
        return const NotificationCenterScreen();
      case '/admin':
        return isAdmin ? const AdminScreen() : const MainScreen();
      default:
        // 관리자 권한이 확인된 계정은 로그인 직후 관리자 대시보드로 이동합니다.
        return isAdmin ? const AdminScreen() : const MainScreen();
    }
  }
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwFocusNode = FocusNode();
  bool _obscurePw = true;
  bool _rememberMe = false;
  List<String> _rememberedEmails = [];
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;
  bool _adminLoginRequested = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 언어 변경 시 번역 트리거
      context.read<LanguageProvider>().triggerTranslation();
    });
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    // 저장된 아이디 자동 입력
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final savedEmails = await AuthService.getRememberedEmails();
    if (savedEmails.isNotEmpty && mounted) {
      setState(() {
        _rememberedEmails = savedEmails;
        _emailCtrl.text = savedEmails.first;
        _rememberMe = true;
      });
    }
  }

  Future<void> _removeRememberedEmail(String email) async {
    await AuthService.clearRememberMe(email);
    if (!mounted) return;
    setState(() {
      _rememberedEmails.remove(email);
      if (_emailCtrl.text.trim().toLowerCase() == email) {
        _rememberMe = false;
      }
    });
  }

  void _selectRememberedEmail(String email) {
    setState(() {
      _emailCtrl.text = email;
      _emailCtrl.selection = TextSelection.collapsed(offset: email.length);
      _rememberMe = true;
    });
  }

  Widget _buildRememberedEmailChips() {
    if (_rememberedEmails.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.t('저장된_아이디', '저장된 아이디'),
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _rememberedEmails
                .map(
                  (email) => InputChip(
                    label: Text(email,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                    selected:
                        email == _emailCtrl.text.trim().toLowerCase(),
                    onSelected: (_) => _selectRememberedEmail(email),
                    onDeleted: () => _removeRememberedEmail(email),
                    deleteIconColor: AppColors.textSecondary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pwFocusNode.dispose();
    super.dispose();
  }

  // 로고 5번 연속 탭 → 저장된 이메일 자동 입력 + 비밀번호 입력란 이동
  Future<void> _handleLogoTap() async {
    final now = DateTime.now();
    if (_lastLogoTap != null &&
        now.difference(_lastLogoTap!) > const Duration(seconds: 3)) {
      _logoTapCount = 0;
    }
    _lastLogoTap = now;
    _logoTapCount++;

    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      // 관리자 계정의 비밀번호는 소스에 저장하지 않습니다.
      // 저장된 이메일만 자동 입력하고 비밀번호 입력란으로 이동합니다.
      _adminLoginRequested = true;
      if (_rememberedEmails.isEmpty) {
        final savedEmails = await AuthService.getRememberedEmails();
        if (!mounted) return;
        _rememberedEmails = savedEmails;
      }
      if (_rememberedEmails.isNotEmpty) {
        // 5번 클릭은 관리자 진입 동작이므로 기존 입력값이 있어도
        // 마지막으로 저장된 이메일을 우선 사용합니다.
        _emailCtrl.text = _rememberedEmails.first;
        _emailCtrl.selection =
            TextSelection.collapsed(offset: _emailCtrl.text.length);
        _rememberMe = true;
      }
      if (mounted) {
        _pwFocusNode.requestFocus();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(context.read<LanguageProvider>().loc.loginAdminEntered,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      // 사용자는 비밀번호를 직접 입력한 뒤 로그인 버튼을 누릅니다.
    }
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final userProv = context.read<UserProvider>();

    // AuthService로 실제 로그인
    userProv.setLoading(true);
    final result = await AuthService.login(
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text,
    );
    userProv.setLoading(false);

    if (!mounted) return;
    if (result.success && result.user != null) {
      userProv.login(result.user!);
      AnalyticsService.logLogin(method: 'email');
      // 관리자 이메일은 비밀번호가 아닌 식별자이므로, 다음 5번 클릭에서
      // 사용할 수 있도록 항상 저장합니다. 일반 계정은 기존 설정을 따릅니다.
      final email = _emailCtrl.text.trim();
      if (result.user?.isAdmin == true || _rememberMe) {
        await AuthService.saveRememberMe(email);
      } else {
        await AuthService.clearRememberMe(email);
      }
      if (!mounted) return;
      _rememberedEmails = await AuthService.getRememberedEmails();
      if (!mounted) return;
      final destination = _adminLoginRequested && result.user?.isAdmin == true
          ? const AdminScreen()
          : _targetAfterLogin(isAdmin: result.user?.isAdmin == true);
      _adminLoginRequested = false;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? loc.loginFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();

    // PC 레이아웃 복원
    if (isPcWeb(context)) return _buildPcLayout(context, userProv, loc);

    return wrapWithPopScope(
        context,
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.primary),
              onPressed: () => goBackOrHome(context),
            ),
          ),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 56),
                        // ── 로고 (5번 탭 → 관리자 자동 입력) ──
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _handleLogoTap,
                                child: Image.asset(
                                  'assets/images/2fit_logo.png',
                                  width: 200,
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // ── 언어 선택 버튼 ──
                              const LanguageSelectorWidget(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 44),

                        // ── 이메일 ──
                        _buildLabel(loc.email),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDeco(
                            hint: 'example@2fit.co.kr',
                            icon: Icons.email_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return loc.loginEmailRequired;
                            if (!v.contains('@')) return loc.loginEmailInvalid;
                            return null;
                          },
                        ),
                        _buildRememberedEmailChips(),
                        const SizedBox(height: 16),

                        // ── 비밀번호 ──
                        _buildLabel(loc.password),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _pwCtrl,
                          focusNode: _pwFocusNode,
                          obscureText: _obscurePw,
                          style: const TextStyle(fontSize: 15),
                          decoration: _inputDeco(
                            hint: loc.passwordHint,
                            icon: Icons.lock_outline_rounded,
                            suffix: GestureDetector(
                              onTap: () =>
                                  setState(() => _obscurePw = !_obscurePw),
                              child: Icon(
                                _obscurePw
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return loc.loginPasswordRequired;
                            if (v.length < 4) return loc.loginPasswordTooShort;
                            return null;
                          },
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 10),

                        // ── 로그인 유지 + 비번찾기 ──
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _rememberMe = !_rememberMe),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: _rememberMe
                                          ? AppColors.primary
                                          : Colors.white,
                                      border: Border.all(
                                        color: _rememberMe
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: _rememberMe
                                        ? const Icon(Icons.check,
                                            size: 12, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(context.loc.t('아이디_저장', '아이디 저장'),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showForgotPasswordDialog,
                              child: Text(loc.findPassword,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── 로그인 버튼 ──
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: userProv.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: userProv.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(loc.login,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    )),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── 구분선 ──
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: AppColors.border)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(loc.orDivider,
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13)),
                            ),
                            const Expanded(
                                child: Divider(color: AppColors.border)),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── 카카오 로그인 ──
                        _buildSocialBtn(
                          label: loc.kakaoLogin,
                          bgColor: const Color(0xFFFFE500),
                          textColor: const Color(0xFF3C1E1E),
                          icon: Icons.chat_bubble_rounded,
                          iconColor: const Color(0xFF3C1E1E),
                          onTap: () => _loginWithKakao(),
                        ),
                        const SizedBox(height: 10),

                        // ── 네이버 로그인 (Web + 앱) ──
                        _buildSocialBtn(
                          label: context.loc.t('네이버로_로그인', '네이버로 로그인'),
                          bgColor: const Color(0xFF03C75A),
                          textColor: Colors.white,
                          icon: Icons.account_circle_rounded,
                          iconColor: Colors.white,
                          onTap: () => _loginWithNaver(),
                        ),
                        const SizedBox(height: 10),

                        // ── 구글 로그인 ──
                        _buildSocialBtn(
                          label: loc.googleLogin,
                          bgColor: Colors.white,
                          textColor: AppColors.textSecondary,
                          icon: Icons.g_mobiledata_rounded,
                          iconColor: const Color(0xFF4285F4),
                          hasBorder: true,
                          onTap: () => _loginWithGoogle(),
                        ),
                        const SizedBox(height: 32),

                        // ── 회원가입 ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(loc.noAccount,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade500)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignUpScreen()),
                                );
                              },
                              child: Text(loc.signUp,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  )),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildPcLayout(
      BuildContext context, UserProvider userProv, dynamic loc) {
    return wrapWithPopScope(
        context,
        Scaffold(
          backgroundColor: AppColors.surfaceGray,
          body: Row(
            children: [
              // ── 왼쪽: 브랜드 패널 ──
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        Color(0xFF2D2D2D),
                        AppColors.textPrimary
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _handleLogoTap,
                        child: Image.asset(
                          'assets/images/logo_2fit_white.png',
                          width: 180,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('2FIT MALL',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4)),
                      const SizedBox(height: 8),
                      const Text('SPORTS & FITNESS WEAR',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                              letterSpacing: 3)),
                      const SizedBox(height: 48),
                      // 특징 박스들
                      _pcFeatureChip(
                          Icons.local_shipping_outlined, loc.loginFeature1),
                      const SizedBox(height: 12),
                      _pcFeatureChip(
                          Icons.verified_outlined, loc.loginFeature2),
                      const SizedBox(height: 12),
                      _pcFeatureChip(Icons.groups_outlined, loc.loginFeature3),
                    ],
                  ),
                ),
              ),
              // ── 오른쪽: 로그인 폼 ──
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── PC 언어 선택 ──
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [LanguageSelectorWidget()],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(loc.loginTitle,
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary)),
                                  const SizedBox(height: 8),
                                  Text(loc.loginWelcome,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 36),
                                  _buildLabel(loc.email),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(fontSize: 15),
                                    decoration: _inputDeco(
                                        hint: 'example@2fit.co.kr',
                                        icon: Icons.email_outlined),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return context.loc
                                            .t('이메일을 입력해주세요', '이메일을 입력해주세요');
                                      if (!v.contains('@'))
                                        return context.loc.t(
                                            '올바른 이메일 형식을 입력해주세요',
                                            '올바른 이메일 형식을 입력해주세요');
                                      return null;
                                    },
                                  ),
                                  _buildRememberedEmailChips(),
                                  const SizedBox(height: 16),
                                  _buildLabel(loc.password),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _pwCtrl,
                                    obscureText: _obscurePw,
                                    style: const TextStyle(fontSize: 15),
                                    decoration: _inputDeco(
                                      hint: loc.passwordHint,
                                      icon: Icons.lock_outline_rounded,
                                      suffix: GestureDetector(
                                        onTap: () => setState(
                                            () => _obscurePw = !_obscurePw),
                                        child: Icon(
                                            _obscurePw
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.grey,
                                            size: 20),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return context.loc
                                            .t('비밀번호를 입력해주세요', '비밀번호를 입력해주세요');
                                      if (v.length < 4)
                                        return context.loc.t(
                                            '비밀번호가 너무 짧습니다', '비밀번호가 너무 짧습니다');
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _login(),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _rememberMe = !_rememberMe),
                                        child: Row(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 150),
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: _rememberMe
                                                    ? AppColors.primary
                                                    : Colors.white,
                                                border: Border.all(
                                                    color: _rememberMe
                                                        ? AppColors.primary
                                                        : AppColors.border),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: _rememberMe
                                                  ? const Icon(Icons.check,
                                                      size: 12,
                                                      color: Colors.white)
                                                  : null,
                                            ),
                                            const SizedBox(width: 7),
                                            Text(context.loc.t('아이디_저장', '아이디 저장'),
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .textSecondary)),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: _showForgotPasswordDialog,
                                        child: Text(loc.findPassword,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed:
                                          userProv.isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                      child: userProv.isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white))
                                          : Text(loc.login,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      const Expanded(
                                          child:
                                              Divider(color: AppColors.border)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(loc.orDivider,
                                            style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 13)),
                                      ),
                                      const Expanded(
                                          child:
                                              Divider(color: AppColors.border)),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  // ── 카카오 로그인 ──
                                  _buildSocialBtn(
                                      label: loc.kakaoLogin,
                                      bgColor: const Color(0xFFFFE500),
                                      textColor: const Color(0xFF3C1E1E),
                                      icon: Icons.chat_bubble_rounded,
                                      iconColor: const Color(0xFF3C1E1E),
                                      onTap: () => _loginWithKakao()),
                                  const SizedBox(height: 10),
                                  // ── 네이버 로그인 (Web + 앱) ──
                                  _buildSocialBtn(
                                      label:
                                          context.loc.t('네이버로_로그인', '네이버로 로그인'),
                                      bgColor: const Color(0xFF03C75A),
                                      textColor: Colors.white,
                                      icon: Icons.account_circle_rounded,
                                      iconColor: Colors.white,
                                      onTap: () => _loginWithNaver()),
                                  const SizedBox(height: 10),
                                  _buildSocialBtn(
                                      label: loc.googleLogin,
                                      bgColor: Colors.white,
                                      textColor: AppColors.textSecondary,
                                      icon: Icons.g_mobiledata_rounded,
                                      iconColor: const Color(0xFF4285F4),
                                      hasBorder: true,
                                      onTap: () => _loginWithGoogle()),
                                  const SizedBox(height: 28),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(loc.noAccount,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade500)),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const SignUpScreen())),
                                        child: Text(loc.signUp,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _pcFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.border, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textHint),
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffix,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildSocialBtn({
    required String label,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool hasBorder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: hasBorder ? Border.all(color: AppColors.border) : null,
          boxShadow: hasBorder
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }

  Widget _hintRow(String email, String pw) => GestureDetector(
        onTap: () {
          // 탭하면 이메일/비밀번호 자동입력 + 바로 로그인
          _emailCtrl.text = email;
          _pwCtrl.text = pw;
          setState(() => _obscurePw = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('$email 입력 완료 — 로그인 버튼을 눌러주세요',
                    style: const TextStyle(fontSize: 12)),
              ]),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(email,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600)),
              ),
              Text('/ $pw',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace')),
            ],
          ),
        ),
      );

  /// 실제 Google 로그인
  Future<void> _loginWithGoogle() async {
    final userProv = context.read<UserProvider>();
    userProv.setLoading(true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (!mounted) return;
      userProv.setLoading(false);

      if (result.requiresPhoneVerification) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SocialPhoneOnboardingScreen(
              name: result.pendingName ?? 'Google 사용자',
              email: result.pendingEmail ?? '',
              photoUrl: result.pendingPhotoUrl ?? '',
              provider: result.pendingProvider ?? 'google',
            ),
          ),
        );
        return;
      }
      if (result.success && result.user != null) {
        userProv.login(result.user!);
        context.read<CouponProvider>().loadValidCoupons(result.user!.id);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => _targetAfterLogin(isAdmin: result.user?.isAdmin == true),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ??
                context.loc.t('google_로그인에_실패했습니다', 'Google 로그인에 실패했습니다')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        userProv.setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google 로그인 오류: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loginWithKakao() async {
    final userProv = context.read<UserProvider>();
    userProv.setLoading(true);
    try {
      final result = await AuthService.signInWithKakao();
      if (!mounted) return;
      userProv.setLoading(false);

      if (result.requiresPhoneVerification) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SocialPhoneOnboardingScreen(
              name: result.pendingName ?? '카카오 사용자',
              email: result.pendingEmail ?? '',
              photoUrl: result.pendingPhotoUrl ?? '',
              provider: result.pendingProvider ?? 'kakao',
            ),
          ),
        );
        return;
      }
      if (result.success && result.user != null) {
        userProv.login(result.user!);
        context.read<CouponProvider>().loadValidCoupons(result.user!.id);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => _targetAfterLogin(isAdmin: result.user?.isAdmin == true),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ??
                context.loc.t('카카오 로그인에 실패했습니다', '카카오 로그인에 실패했습니다')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        userProv.setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.t('카카오 로그인 오류 _', '카카오 로그인 오류: $e')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loginWithNaver() async {
    final userProv = context.read<UserProvider>();
    userProv.setLoading(true);
    try {
      final result = await AuthService.signInWithNaver();
      if (!mounted) return;
      userProv.setLoading(false);

      if (result.requiresPhoneVerification) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SocialPhoneOnboardingScreen(
              name: result.pendingName ?? '네이버 사용자',
              email: result.pendingEmail ?? '',
              photoUrl: result.pendingPhotoUrl ?? '',
              provider: result.pendingProvider ?? 'naver',
            ),
          ),
        );
        return;
      }
      if (result.success && result.user != null) {
        userProv.login(result.user!);
        context.read<CouponProvider>().loadValidCoupons(result.user!.id);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => _targetAfterLogin(isAdmin: result.user?.isAdmin == true),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ??
                context.loc.t('네이버 로그인에 실패했습니다', '네이버 로그인에 실패했습니다')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        userProv.setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.t('네이버 로그인 오류 _', '네이버 로그인 오류: $e')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 소셜 로그인 데모 다이얼로그
  // ignore: unused_element
  void _showSocialLoginDialog(String provider) {
    final isKakao = provider == '카카오';
    final nameCtrl = TextEditingController(
      text: isKakao ? context.loc.t('카카오 사용자', '카카오 사용자') : 'Google 사용자',
    );
    final emailCtrl = TextEditingController(
      text: isKakao ? 'user@kakao.com' : 'user@gmail.com',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isKakao ? const Color(0xFFFFE500) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: isKakao ? null : Border.all(color: AppColors.border),
              ),
              child: Center(
                child: isKakao
                    ? const Icon(Icons.chat_bubble_rounded,
                        size: 20, color: Color(0xFF3C1E1E))
                    : const Icon(Icons.g_mobiledata_rounded,
                        size: 24, color: Color(0xFF4285F4)),
              ),
            ),
            const SizedBox(width: 10),
            Text(loc.loginProviderLogin(provider),
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFFF8F00)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.loc
                          .t('데모 모드 아래 정보로 체험 로그인', '데모 모드: 아래 정보로 체험 로그인'),
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning.withValues(alpha: 0.90)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: loc.loginNameLabel,
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                filled: true,
                fillColor: AppColors.surfaceGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                labelText: loc.loginEmailLabel,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: AppColors.surfaceGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isKakao ? const Color(0xFFFFE500) : const Color(0xFF4285F4),
              foregroundColor: isKakao ? const Color(0xFF3C1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final userProv = context.read<UserProvider>();
              userProv.setLoading(true);
              final result = await AuthService.socialLogin(
                provider: isKakao ? 'kakao' : 'google',
                name: nameCtrl.text.trim().isEmpty
                    ? (isKakao
                        ? context.loc.t('카카오 사용자', '카카오 사용자')
                        : 'Google 사용자')
                    : nameCtrl.text.trim(),
                email: emailCtrl.text.trim().isEmpty
                    ? (isKakao ? 'user@kakao.com' : 'user@gmail.com')
                    : emailCtrl.text.trim(),
              );
              userProv.setLoading(false);
              if (!mounted) return;
              if (result.requiresPhoneVerification) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SocialPhoneOnboardingScreen(
                      name: result.pendingName ?? (isKakao ? '카카오 사용자' : 'Google 사용자'),
                      email: result.pendingEmail ?? '',
                      photoUrl: result.pendingPhotoUrl ?? '',
                      provider: result.pendingProvider ?? (isKakao ? 'kakao' : 'google'),
                    ),
                  ),
                );
                return;
              }
              if (result.success && result.user != null) {
                userProv.login(result.user!);
        context.read<CouponProvider>().loadValidCoupons(result.user!.id);
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => _targetAfterLogin(isAdmin: result.user?.isAdmin == true),
                    transitionsBuilder: (_, a, __, child) =>
                        FadeTransition(opacity: a, child: child),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              }
            },
            child: Text(loc.loginContinueWith(provider)),
          ),
        ],
      ),
    );
  }

  /// 비밀번호 찾기 다이얼로그
  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    bool sent = false;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(loc.loginForgotPassword,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          content: sent
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.loginEmailSent,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(emailCtrl.text,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(loc.loginCheckMailbox,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.loginForgotDesc,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: context.loc.t('이메일', '이메일'),
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceGray,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
          actions: sent
              ? [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(loc.confirm),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(loc.cancel,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: loading
                        ? null
                        : () async {
                            if (emailCtrl.text.trim().isEmpty) return;
                            setS(() => loading = true);
                            final result = await AuthService.resetPassword(
                              email: emailCtrl.text.trim(),
                            );
                            setS(() {
                              loading = false;
                              if (result.success) {
                                sent = true;
                              }
                            });
                            if (!result.success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      result.error ?? loc.loginErrorGeneral),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(loc.loginResetSend),
                  ),
                ],
        ),
      ),
    );
  }
}

// ── 언어 선택 버튼 (로그인/회원가입 공용) ───────────────────────
class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  void _showDialog(BuildContext context) {
    final lp = context.read<LanguageProvider>();
    final currentLang = lp.language;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lp.loc.selectLanguage,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...AppLanguage.values.map((lang) {
                  final isSel = lang == currentLang;
                  return GestureDetector(
                    onTap: () {
                      lp.setLanguage(lang);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(lang.flagEmoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(
                            lang.nativeName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          if (isSel)
                            const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    return GestureDetector(
      onTap: () => _showDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
          color: AppColors.background,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.flagEmoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              lang.code.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
