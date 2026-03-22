// signup_screen.dart — 보안 강화 v2
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/providers.dart';
import '../../utils/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart' show AuthResult;
import '../main_screen.dart';
import 'login_screen.dart' show LanguageSelectorWidget;

// ══════════════════════════════════════════
// 연속 가입 시도 방지 (클라이언트측 rate limit)
// ══════════════════════════════════════════
class _SignupRateLimit {
  static final List<DateTime> _attempts = [];
  static const int _maxAttempts = 3;       // 3회
  static const int _windowMinutes = 10;    // 10분 내

  static bool isBlocked() {
    final now = DateTime.now();
    _attempts.removeWhere(
      (t) => now.difference(t).inMinutes >= _windowMinutes,
    );
    return _attempts.length >= _maxAttempts;
  }

  static int remainingSeconds() {
    if (_attempts.isEmpty) return 0;
    final oldest = _attempts.first;
    final elapsed = DateTime.now().difference(oldest).inSeconds;
    final windowSecs = _windowMinutes * 60;
    return (windowSecs - elapsed).clamp(0, windowSecs);
  }

  static void record() {
    _attempts.add(DateTime.now());
  }

  static void clear() {
    _attempts.clear();
  }
}

// ══════════════════════════════════════════
// 국가 코드 데이터
// ══════════════════════════════════════════
class _Country {
  final String flag;
  final String name;
  final String code;
  const _Country(this.flag, this.name, this.code);
}

const List<_Country> _countries = [
  _Country('🇰🇷', '한국', '+82'),
  _Country('🇺🇸', 'USA', '+1'),
  _Country('🇯🇵', '日本', '+81'),
  _Country('🇨🇳', '中国', '+86'),
  _Country('🇬🇧', 'UK', '+44'),
  _Country('🇩🇪', 'Germany', '+49'),
  _Country('🇫🇷', 'France', '+33'),
  _Country('🇦🇺', 'Australia', '+61'),
  _Country('🇨🇦', 'Canada', '+1'),
  _Country('🇸🇬', 'Singapore', '+65'),
  _Country('🇹🇭', 'Thailand', '+66'),
  _Country('🇻🇳', 'Vietnam', '+84'),
  _Country('🇵🇭', 'Philippines', '+63'),
  _Country('🇮🇩', 'Indonesia', '+62'),
  _Country('🇲🇾', 'Malaysia', '+60'),
  _Country('🇮🇳', 'India', '+91'),
  _Country('🇧🇷', 'Brazil', '+55'),
  _Country('🇲🇽', 'Mexico', '+52'),
  _Country('🇿🇦', 'South Africa', '+27'),
  _Country('🇦🇪', 'UAE', '+971'),
];

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  // 비밀번호 강도
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.grey.shade300;
  List<bool> _passwordChecks = [false, false, false, false, false];

  // 이메일 중복확인
  bool _emailChecking = false;
  bool? _emailAvailable;

  // 국제 전화번호
  _Country _selectedCountry = _countries[0]; // 기본 한국

  // rate limit 타이머
  Timer? _blockTimer;
  int _blockRemaining = 0;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
    _emailCtrl.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _blockTimer?.cancel();
    super.dispose();
  }

  // ─── 비밀번호 강도 분석 ───
  void _onPasswordChanged() {
    final pw = _passwordCtrl.text;
    final hasLength = pw.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pw);
    final hasLower = RegExp(r'[a-z]').hasMatch(pw);
    final hasDigit = RegExp(r'[0-9]').hasMatch(pw);
    final hasSpecial = pw.split('').any((c) =>
        '!@#\$%^&*()_+-=[]{}|;:,.<>?/`~\\"\'\\\\'.contains(c));
    setState(() {
      _passwordChecks = [hasLength, hasUpper, hasLower, hasDigit, hasSpecial];
      final score = _passwordChecks.where((c) => c).length;
      _passwordStrength = pw.isEmpty ? 0.0 : score / 5.0;
      if (pw.isEmpty) {
        _passwordStrengthLabel = '';
        _passwordStrengthColor = Colors.grey.shade300;
      } else if (score <= 1) {
<<<<<<< HEAD
        _passwordStrengthLabel = '매우 취약';
        _passwordStrengthColor = Colors.red.shade400;
      } else if (score == 2) {
        _passwordStrengthLabel = '취약';
        _passwordStrengthColor = Colors.orange.shade400;
      } else if (score == 3) {
        _passwordStrengthLabel = '보통';
        _passwordStrengthColor = Colors.amber.shade500;
      } else if (score == 4) {
        _passwordStrengthLabel = '강함';
        _passwordStrengthColor = Colors.lightGreen.shade500;
      } else {
        _passwordStrengthLabel = '매우 강함';
=======
        _passwordStrengthLabel = context.read<LanguageProvider>().loc.signupPasswordStrengthVeryWeak;
        _passwordStrengthColor = Colors.red.shade400;
      } else if (score == 2) {
        _passwordStrengthLabel = context.read<LanguageProvider>().loc.signupPasswordStrengthWeak;
        _passwordStrengthColor = Colors.orange.shade400;
      } else if (score == 3) {
        _passwordStrengthLabel = context.read<LanguageProvider>().loc.signupPasswordStrengthFair;
        _passwordStrengthColor = Colors.amber.shade500;
      } else if (score == 4) {
        _passwordStrengthLabel = context.read<LanguageProvider>().loc.signupPasswordStrengthStrong;
        _passwordStrengthColor = Colors.lightGreen.shade500;
      } else {
        _passwordStrengthLabel = context.read<LanguageProvider>().loc.signupPasswordStrengthVeryStrong;
>>>>>>> origin/main
        _passwordStrengthColor = Colors.green.shade600;
      }
    });
  }

  // ─── 이메일 변경 시 중복확인 초기화 ───
  void _onEmailChanged() {
    if (_emailAvailable != null) setState(() => _emailAvailable = null);
  }

  // ─── 이메일 중복확인 ───
  Future<void> _checkEmailDuplicate() async {
    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email)) {
<<<<<<< HEAD
      _showSnack('올바른 이메일 형식을 입력해주세요.');
=======
      _showSnack(context.read<LanguageProvider>().loc.signupInvalidEmail);
>>>>>>> origin/main
      return;
    }
    setState(() => _emailChecking = true);
    final available = await AuthService.checkEmailAvailable(email);
    if (mounted) {
      setState(() { _emailChecking = false; _emailAvailable = available; });
<<<<<<< HEAD
      _showSnack(available ? '사용 가능한 이메일입니다.' : '이미 사용 중인 이메일입니다.',
=======
      _showSnack(available ? context.read<LanguageProvider>().loc.signupEmailAvailable : context.read<LanguageProvider>().loc.signupEmailAlreadyUsed,
>>>>>>> origin/main
          isSuccess: available);
    }
  }

  // ─── 국가 선택 다이얼로그 ───
  Future<void> _showCountryPicker() async {
    final result = await showModalBottomSheet<_Country>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
<<<<<<< HEAD
          const Text('국가 선택', style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
=======
          Builder(builder: (ctx) => Text(ctx.watch<LanguageProvider>().loc.signupCountrySelect, style: const TextStyle(fontSize: 16,
              fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
>>>>>>> origin/main
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _countries.length,
              itemBuilder: (_, i) {
                final c = _countries[i];
                return ListTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(c.name, style: const TextStyle(fontSize: 14)),
                  trailing: Text(c.code,
                      style: const TextStyle(fontSize: 13,
                          color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _selectedCountry = result);
  }

  // ─── 전화번호 한국 자동 하이픈 포맷 ───
  String _formatKoreanPhone(String digits) {
    // 한국 번호 자동 하이픈
    if (digits.startsWith('02')) {
      if (digits.length <= 2) return digits;
      if (digits.length <= 5) return '${digits.substring(0, 2)}-${digits.substring(2)}';
      if (digits.length <= 9) return '${digits.substring(0, 2)}-${digits.substring(2, 5)}-${digits.substring(5)}';
      return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6, 10)}';
    } else {
      if (digits.length <= 3) return digits;
      if (digits.length <= 6) return '${digits.substring(0, 3)}-${digits.substring(3)}';
      if (digits.length <= 10) return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, 11)}';
    }
  }

  void _onPhoneChanged(String value) {
    if (_selectedCountry.code != '+82') return;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = _formatKoreanPhone(digits);
    if (formatted != value) {
      _phoneCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // ─── 개인정보처리방침 팝업 ───
  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('개인정보처리방침',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: const [
                  _PolicySection(title: '제1조 (수집하는 개인정보 항목)',
                    content: '2FIT MALL은 회원가입 및 서비스 이용을 위해 아래와 같은 개인정보를 수집합니다.\n\n'
                        '• 필수항목: 이름, 이메일 주소, 비밀번호, 휴대폰 번호\n'
                        '• 선택항목: 마케팅 수신 동의\n'
                        '• 자동수집: 서비스 이용기록, 접속 로그, 쿠키, IP 주소'),
                  _PolicySection(title: '제2조 (개인정보의 수집 및 이용목적)',
                    content: '• 회원가입 및 본인 확인\n'
                        '• 서비스 제공 및 계약 이행\n'
                        '• 주문/배송/결제 처리\n'
                        '• 고객 문의 및 불만 처리\n'
                        '• 마케팅 및 광고 활용 (동의 시)'),
                  _PolicySection(title: '제3조 (개인정보 보유 및 이용기간)',
                    content: '회원 탈퇴 시 즉시 삭제합니다. 단, 관련 법령에 따라 아래 기간 동안 보관합니다.\n\n'
                        '• 계약/청약철회 기록: 5년 (전자상거래법)\n'
                        '• 소비자 불만/분쟁처리 기록: 3년\n'
                        '• 접속 로그: 3개월 (통신비밀보호법)'),
                  _PolicySection(title: '제4조 (개인정보 제3자 제공)',
                    content: '2FIT MALL은 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. '
                        '단, 배송 처리를 위해 택배사에 최소한의 정보(수령인, 주소, 연락처)를 제공합니다.'),
                  _PolicySection(title: '제5조 (개인정보처리 위탁)',
                    content: '• Firebase (Google): 회원 인증 및 데이터 저장\n'
                        '• EmailJS: 이메일 발송 서비스\n'
                        '• 택배사: 배송 처리'),
                  _PolicySection(title: '제6조 (이용자의 권리)',
                    content: '이용자는 언제든지 아래 권리를 행사할 수 있습니다.\n\n'
                        '• 개인정보 열람 요청\n'
                        '• 오류 정정 요청\n'
                        '• 삭제 요청 (회원 탈퇴)\n'
                        '• 처리 정지 요청\n\n'
                        '문의: cs@2fitkorea.com'),
                  _PolicySection(title: '제7조 (개인정보 보호책임자)',
                    content: '• 책임자: 2FIT MALL 운영팀\n'
                        '• 이메일: cs@2fitkorea.com\n\n'
                        '본 방침은 2025년 3월 21일부터 적용됩니다.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 이용약관 팝업 ───
  void _showTermsOfService() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
<<<<<<< HEAD
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('이용약관',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
=======
            Padding(
              padding: const EdgeInsets.all(16),
              child: Builder(builder: (bCtx) {
                final bLoc = bCtx.watch<LanguageProvider>().loc;
                return Text(bLoc.signupTermsTitleShort,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E)));
              }),
>>>>>>> origin/main
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: const [
                  _PolicySection(title: '제1조 (목적)',
                    content: '본 약관은 2FIT MALL(이하 "회사")이 제공하는 쇼핑몰 서비스의 이용조건 및 절차, '
                        '회사와 이용자 간의 권리·의무 관계를 규정함을 목적으로 합니다.'),
                  _PolicySection(title: '제2조 (회원가입)',
                    content: '• 만 14세 이상 이용 가능합니다.\n'
                        '• 타인의 정보 도용 가입은 금지됩니다.\n'
                        '• 허위 정보 제공 시 서비스 이용이 제한될 수 있습니다.'),
                  _PolicySection(title: '제3조 (서비스 이용)',
                    content: '• 서비스는 연중무휴 24시간 제공을 원칙으로 합니다.\n'
                        '• 시스템 정기점검, 천재지변 등 불가피한 경우 서비스가 중단될 수 있습니다.'),
                  _PolicySection(title: '제4조 (구매 및 결제)',
                    content: '• 주문 후 입금 확인 시 배송이 시작됩니다.\n'
                        '• 단순 변심에 의한 반품은 수령 후 7일 이내 가능합니다.\n'
                        '• 상품 하자의 경우 수령 후 3개월 이내 교환/환불이 가능합니다.'),
                  _PolicySection(title: '제5조 (금지행위)',
                    content: '• 타인의 계정 무단 사용\n'
                        '• 서비스 운영 방해\n'
                        '• 허위 리뷰 작성\n'
                        '• 불법 콘텐츠 유포'),
                  _PolicySection(title: '제6조 (면책조항)',
                    content: '천재지변, 전쟁 등 불가항력으로 인한 서비스 중단에 대해 회사는 책임을 지지 않습니다.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 가입 제출 ───
  Future<void> _submit() async {
    // rate limit 체크
    if (_SignupRateLimit.isBlocked()) {
      final secs = _SignupRateLimit.remainingSeconds();
<<<<<<< HEAD
      _showSnack('잠시 후 다시 시도해주세요. (${secs ~/ 60}분 ${secs % 60}초 후)');
=======
      _showSnack(context.read<LanguageProvider>().loc.signupRateLimitSecondsMsg(secs));
>>>>>>> origin/main
      _startBlockTimer();
      return;
    }

    final loc = context.read<LanguageProvider>().loc;
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms || !_agreePrivacy) {
      _showSnack(loc.signupRequiredTermsError);
      return;
    }
    final metCount = _passwordChecks.where((c) => c).length;
    if (metCount < 3) {
<<<<<<< HEAD
      _showSnack('비밀번호가 너무 취약합니다.');
      return;
    }
    if (_emailAvailable == null) {
      _showSnack('이메일 중복 확인을 먼저 진행해주세요.');
      return;
    }
    if (_emailAvailable == false) {
      _showSnack('이미 사용 중인 이메일입니다.');
=======
      _showSnack(loc.signupPasswordTooWeak);
      return;
    }
    if (_emailAvailable == null) {
      _showSnack(loc.signupEmailCheckFirst);
      return;
    }
    if (_emailAvailable == false) {
      _showSnack(loc.signupEmailAlreadyUsed);
>>>>>>> origin/main
      return;
    }

    // 가입 시도 기록
    _SignupRateLimit.record();
    setState(() => _isLoading = true);

    // 전화번호 국가코드 포함 (필수 - 빈값 불허)
    final phoneRaw = _phoneCtrl.text.trim();
    final phoneWithCode = '${_selectedCountry.code} $phoneRaw';

    AuthResult result;
    try {
      result = await AuthService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        phone: phoneWithCode,
      ).timeout(
        const Duration(seconds: 30),
<<<<<<< HEAD
        onTimeout: () => const AuthResult(
            success: false, error: '요청 시간이 초과되었습니다. 네트워크를 확인해주세요.'),
=======
        onTimeout: () => AuthResult(
            success: false, error: loc.signupTimeoutError),
>>>>>>> origin/main
      );
    } catch (e) {
      result = AuthResult(
          success: false, error: '회원가입 오류: ${e.toString().length > 100 ? e.toString().substring(0, 100) : e.toString()}');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      _SignupRateLimit.clear(); // 성공 시 초기화
      context.read<UserProvider>().login(result.user!);
      _showSnack(loc.signupSuccessMsg, isSuccess: true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
      }
    } else {
      _showSnack(result.error ?? loc.signupFailMsg);
    }
  }

  void _startBlockTimer() {
    _blockTimer?.cancel();
    setState(() => _blockRemaining = _SignupRateLimit.remainingSeconds());
    _blockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _blockRemaining = _SignupRateLimit.remainingSeconds());
      if (_blockRemaining <= 0) t.cancel();
    });
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFF1A1A2E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc.signupTitle,
            style: const TextStyle(color: Color(0xFF1A1A2E),
                fontSize: 18, fontWeight: FontWeight.w800)),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 8), child: LanguageSelectorWidget()),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 헤더 ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF2D2D5E)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    const Icon(Icons.security_rounded, color: Colors.white70, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.signupBenefitTitle,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
<<<<<<< HEAD
                        const Text('안전한 계정 보호를 위해 강력한 비밀번호를 사용해주세요.',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
=======
                        Text(loc.signupPasswordSafetyHint,
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
>>>>>>> origin/main
                      ],
                    )),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── rate limit 경고 배너 ──
                if (_blockRemaining > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.timer_outlined, color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
<<<<<<< HEAD
                        '연속 가입 시도가 감지되었습니다. '
                        '${_blockRemaining ~/ 60}분 ${_blockRemaining % 60}초 후 다시 시도해주세요.',
=======
                        '${loc.signupContinuousAttemptDetected} '
                        '${loc.signupContinuousAttemptWait(_blockRemaining ~/ 60, _blockRemaining % 60)}',
>>>>>>> origin/main
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                      )),
                    ]),
                  ),

                // ── 이름 ──
                _buildLabel('${loc.signupName} *'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _nameCtrl,
                  hint: loc.signupNameHint,
                  icon: Icons.person_outline_rounded,
                  // inputFormatters 제거: 웹 한글 IME 조합 입력 차단 문제 방지
                  // 대신 validator에서만 검증
                  validator: (v) {
<<<<<<< HEAD
                    if (v == null || v.trim().isEmpty) return '이름을 입력해주세요.';
                    if (v.trim().length < 2) return loc.signupNameError;
                    if (v.trim().length > 20) return '이름은 20자 이하로 입력해주세요.';
                    // 한글/영문/공백만 허용 (숫자·특수문자·이모지 차단)
                    if (!RegExp(r'^[가-힣a-zA-Z\s]+$').hasMatch(v.trim())) {
                      return '이름은 한글 또는 영문만 입력 가능합니다. (숫자·특수문자 불가)';
                    }
                    // 연속 공백 불허
                    if (v.trim().contains(RegExp(r'\s{2,}'))) {
                      return '공백은 연속으로 입력할 수 없습니다.';
=======
                    if (v == null || v.trim().isEmpty) return loc.signupNameEmptyError;
                    if (v.trim().length < 2) return loc.signupNameError;
                    if (v.trim().length > 20) return loc.signupNameTooLong;
                    // 한글/영문/공백만 허용 (숫자·특수문자·이모지 차단)
                    if (!RegExp(r'^[가-힣a-zA-Z\s]+$').hasMatch(v.trim())) {
                      return loc.signupNameFormatError;
                    }
                    // 연속 공백 불허
                    if (v.trim().contains(RegExp(r'\s{2,}'))) {
                      return loc.signupNameSpaceError;
>>>>>>> origin/main
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── 이메일 + 중복확인 ──
                _buildLabel('${loc.signupEmailLabel} *'),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        hintText: 'example@email.com',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.email_outlined, size: 18, color: Colors.grey.shade400),
                        suffixIcon: _emailAvailable == true
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                            : _emailAvailable == false
                                ? const Icon(Icons.cancel, color: Colors.red, size: 20)
                                : null,
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: _emailAvailable == true
                              ? const BorderSide(color: Colors.green, width: 1.5)
                              : _emailAvailable == false
                                  ? const BorderSide(color: Colors.red, width: 1.5)
                                  : BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) {
                        if (v == null || !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim())) {
                          return loc.signupEmailError;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _emailChecking ? null : _checkEmailDuplicate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: _emailChecking
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('중복확인',
                              style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── 휴대폰 (국제번호 + 필수) ──
                _buildLabel('휴대폰 번호 *'),
                const SizedBox(height: 4),
                Text(
                  _selectedCountry.code == '+82'
                      ? '한국: 010-0000-0000 형식으로 자동 입력됩니다.'
                      : '국가 코드 선택 후 번호를 입력해주세요.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // 국가 코드 선택
                  GestureDetector(
                    onTap: () async {
                      await _showCountryPicker();
                      // 국가 변경 시 전화번호 초기화
                      _phoneCtrl.clear();
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_selectedCountry.flag,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Text(_selectedCountry.code,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down, color: Colors.grey.shade500, size: 18),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      onChanged: _onPhoneChanged,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))],
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        hintText: _selectedCountry.code == '+82'
                            ? '010-0000-0000'
                            : _selectedCountry.code == '+1'
                                ? '555-123-4567'
                                : _selectedCountry.code == '+81'
                                    ? '90-0000-0000'
                                    : 'Phone number',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) {
                        // 필수 입력
                        if (v == null || v.trim().isEmpty) {
                          return '휴대폰 번호는 필수입니다.';
                        }
                        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                        // 한국: 9~11자리
                        if (_selectedCountry.code == '+82') {
                          if (digits.length < 9 || digits.length > 11) {
                            return '올바른 한국 휴대폰 번호를 입력해주세요. (예: 010-0000-0000)';
                          }
                          if (!digits.startsWith('0')) {
                            return '한국 번호는 0으로 시작해야 합니다.';
                          }
                        } else {
                          // 해외: 6~15자리 (E.164 기준)
                          if (digits.length < 6 || digits.length > 15) {
                            return '올바른 전화번호를 입력해주세요. (6~15자리)';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── 비밀번호 ──
                _buildLabel('${loc.signupPasswordLabel} *'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _passwordCtrl,
                  hint: '8자 이상, 대/소문자, 숫자, 특수문자',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePass,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey.shade400, size: 20),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '비밀번호를 입력해주세요.';
                    if (v.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                    if (_passwordChecks.where((c) => c).length < 3) {
                      return '비밀번호 강도가 부족합니다.';
                    }
                    return null;
                  },
                ),
                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildPasswordStrengthIndicator(),
                ],
                const SizedBox(height: 16),

                // ── 비밀번호 확인 ──
                _buildLabel('${loc.signupPasswordConfirmLabel} *'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _confirmCtrl,
                  hint: loc.signupPasswordConfirmHint2,
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey.shade400, size: 20),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return loc.signupConfirmPasswordError;
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── 약관 동의 ──
                _buildAgreementSection(),
                const SizedBox(height: 28),

                // ── 가입 버튼 ──
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _blockRemaining > 0) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : _blockRemaining > 0
<<<<<<< HEAD
                            ? Text('${_blockRemaining ~/ 60}:${(_blockRemaining % 60).toString().padLeft(2, '0')} 후 가입 가능',
=======
                            ? Text(loc.signupRateLimitCountdown(_blockRemaining ~/ 60, _blockRemaining % 60),
>>>>>>> origin/main
                                style: const TextStyle(fontSize: 14, color: Colors.white70))
                            : Text(loc.signupSubmitBtn,
                                style: const TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 로그인 이동 ──
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        children: [
                          TextSpan(text: loc.signupAlreadyHaveAccount),
                          TextSpan(text: loc.signupLoginLink,
                              style: const TextStyle(fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 비밀번호 강도 표시기 ──
  Widget _buildPasswordStrengthIndicator() {
<<<<<<< HEAD
    final checks = [
      {'label': '8자 이상', 'met': _passwordChecks[0]},
      {'label': '대문자', 'met': _passwordChecks[1]},
      {'label': '소문자', 'met': _passwordChecks[2]},
      {'label': '숫자', 'met': _passwordChecks[3]},
      {'label': '특수문자', 'met': _passwordChecks[4]},
=======
    final loc = context.read<LanguageProvider>().loc;
    final checks = [
      {'label': loc.signupPasswordStrength8Chars, 'met': _passwordChecks[0]},
      {'label': loc.signupPasswordStrengthUppercase, 'met': _passwordChecks[1]},
      {'label': loc.signupPasswordStrengthLowercase, 'met': _passwordChecks[2]},
      {'label': loc.signupPasswordStrengthNumber, 'met': _passwordChecks[3]},
      {'label': loc.signupPasswordStrengthSpecial, 'met': _passwordChecks[4]},
>>>>>>> origin/main
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
            minHeight: 6,
          ),
        )),
        const SizedBox(width: 10),
        Text(_passwordStrengthLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: _passwordStrengthColor)),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 6,
        children: checks.map((c) {
          final met = c['met'] as bool;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 14, color: met ? Colors.green.shade600 : Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(c['label'] as String,
                style: TextStyle(fontSize: 11,
                    color: met ? Colors.green.shade600 : Colors.grey.shade500,
                    fontWeight: met ? FontWeight.w600 : FontWeight.w400)),
          ]);
        }).toList(),
      ),
    ]);
  }

  Widget _buildLabel(String label) => Text(label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E)));

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
        suffixIcon: suffixIcon,
        filled: true, fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── 약관 동의 섹션 ──
  Widget _buildAgreementSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(loc.signupTermsTitle,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        _buildAgreementTile(
          label: loc.signupAgreeAll,
          value: _agreeTerms && _agreePrivacy && _agreeMarketing,
          isBold: true,
          onChanged: (v) => setState(() {
            _agreeTerms = v!; _agreePrivacy = v; _agreeMarketing = v;
          }),
        ),
        const Divider(height: 16, thickness: 0.5),
        // 이용약관 (전문 보기 버튼 포함)
        _buildAgreementTileWithLink(
          label: loc.signupTermsRequired,
          value: _agreeTerms,
          isRequired: true,
          onChanged: (v) => setState(() => _agreeTerms = v!),
          onViewTap: _showTermsOfService,
        ),
        const SizedBox(height: 4),
        // 개인정보처리방침 (전문 보기 버튼 포함)
        _buildAgreementTileWithLink(
          label: loc.signupPrivacyRequired,
          value: _agreePrivacy,
          isRequired: true,
          onChanged: (v) => setState(() => _agreePrivacy = v!),
          onViewTap: _showPrivacyPolicy,
        ),
        const SizedBox(height: 4),
        _buildAgreementTile(
          label: loc.signupMarketingOptional,
          value: _agreeMarketing,
          isOptional: true,
          onChanged: (v) => setState(() => _agreeMarketing = v!),
        ),
      ]),
    );
  }

  Widget _buildAgreementTileWithLink({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onViewTap,
    bool isRequired = false,
  }) {
    return Row(children: [
      SizedBox(width: 24, height: 24,
        child: Checkbox(
          value: value, onChanged: onChanged,
          activeColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      const SizedBox(width: 8),
      if (isRequired)
        Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(4)),
          child: const Text('필수',
              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      Expanded(
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
        ),
      ),
      GestureDetector(
        onTap: onViewTap,
        child: const Text('전문보기',
            style: TextStyle(fontSize: 12, color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
      ),
    ]);
  }

  Widget _buildAgreementTile({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isBold = false,
    bool isRequired = false,
    bool isOptional = false,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(children: [
        SizedBox(width: 24, height: 24,
          child: Checkbox(
            value: value, onChanged: onChanged,
            activeColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 8),
        if (isRequired)
          Container(margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(4)),
            child: const Text('필수',
                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        if (isOptional)
          Container(margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4)),
            child: const Text('선택',
                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                color: const Color(0xFF333333)))),
      ]),
    );
  }
}

// ── 약관 섹션 위젯 ──
class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text(content,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.6)),
      ]),
    );
  }
}
