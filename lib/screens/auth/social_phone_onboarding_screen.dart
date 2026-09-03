import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../main_screen.dart';

/// 소셜 Auth는 완료됐지만 Firestore 회원 문서는 아직 없는 신규 사용자의 필수 온보딩입니다.
/// OTP 검증은 현재 Firebase UID에 Phone provider를 link한 뒤, 같은 UID에만 문서를 생성합니다.
class SocialPhoneOnboardingScreen extends StatefulWidget {
  final String name;
  final String email;
  final String photoUrl;
  final String provider;

  const SocialPhoneOnboardingScreen({
    super.key,
    required this.name,
    required this.email,
    this.photoUrl = '',
    required this.provider,
  });

  @override
  State<SocialPhoneOnboardingScreen> createState() =>
      _SocialPhoneOnboardingScreenState();
}

class _SocialPhoneOnboardingScreenState
    extends State<SocialPhoneOnboardingScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  Timer? _timer;
  String? _verificationId;
  int _remaining = 0;
  bool _sending = false;
  bool _verifying = false;
  bool _verified = false;
  String? _verifiedPhone;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String _toE164(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) return '+82${digits.substring(1)}';
    if (digits.startsWith('82')) return '+$digits';
    return '+82$digits';
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: success ? AppColors.primary : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _sendCode() async {
    final phone = _toE164(_phoneController.text.trim());
    if (!RegExp(r'^\+82\d{9,10}$').hasMatch(phone)) {
      _showMessage('올바른 휴대폰 번호를 입력해주세요.');
      return;
    }
    setState(() {
      _sending = true;
      _verified = false;
      _verificationId = null;
      _verifiedPhone = null;
    });
    final result = await AuthService.sendPhoneVerification(phoneNumber: phone);
    if (!mounted) return;
    setState(() => _sending = false);
    final status = result['status'];
    if (status == 'code_sent' || status == 'timeout') {
      _verificationId = result['verificationId'] as String?;
      _remaining = 60;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _verificationId != null) {
          _otpFocusNode.requestFocus();
        }
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return timer.cancel();
        setState(() => _remaining--);
        if (_remaining <= 0) {
          timer.cancel();
          setState(() => _verificationId = null);
        }
      });
      _showMessage('인증번호가 발송되었습니다.', success: true);
    } else if (status == 'auto_verified') {
      setState(() {
        _verified = true;
        _verifiedPhone = phone;
      });
      _showMessage('전화번호가 자동으로 인증되었습니다.', success: true);
    } else {
      _showMessage(result['message'] as String? ?? 'SMS 발송에 실패했습니다.');
    }
  }

  Future<void> _verifyCode() async {
    final verificationId = _verificationId;
    final code = _otpController.text.trim();
    if (verificationId == null || code.length != 6) {
      _showMessage('인증번호 6자리를 입력해주세요.');
      return;
    }
    setState(() => _verifying = true);
    final result = await AuthService.verifyPhoneOtp(
      verificationId: verificationId,
      smsCode: code,
    );
    if (!mounted) return;
    setState(() => _verifying = false);
    if (result['status'] == 'verified') {
      _timer?.cancel();
      setState(() {
        _verified = true;
        _verificationId = null;
        _verifiedPhone = result['phoneNumber'] as String?;
      });
      _showMessage('전화번호 인증이 완료되었습니다.', success: true);
    } else {
      _showMessage(result['message'] as String? ?? '인증에 실패했습니다.');
    }
  }

  Future<void> _complete() async {
    final phone = _verifiedPhone;
    if (!_verified || phone == null || phone.isEmpty) {
      _showMessage('전화번호 본인확인을 완료해주세요.');
      return;
    }
    setState(() => _verifying = true);
    final result = await AuthService.completeSocialPhoneOnboarding(
      name: widget.name,
      email: widget.email,
      phone: phone,
      photoUrl: widget.photoUrl,
      provider: widget.provider,
    );
    if (!mounted) return;
    setState(() => _verifying = false);
    if (result.success && result.user != null) {
      context.read<UserProvider>().login(result.user!);
      context.read<CouponProvider>().loadValidCoupons(result.user!.id);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } else {
      _showMessage(result.error ?? '회원가입을 완료하지 못했습니다.');
    }
  }

  Future<void> _cancel() async {
    await AuthService.logout();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전화번호 본인확인'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.verified_user_outlined,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('가입을 계속하려면 전화번호 인증이 필요합니다.',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${widget.name}님, 소셜 로그인은 완료되었습니다.\n전화번호를 인증하면 동일 계정으로 회원가입이 완료됩니다.',
                style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 28),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_verified && !_sending,
              decoration: const InputDecoration(
                labelText: '휴대폰 번호',
                hintText: '010-1234-5678',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _verified || _sending ? null : _sendCode,
                child: Text(_sending ? '발송 중...' : '인증번호 받기'),
              ),
            ),
            if (_verificationId != null) ...[
              const SizedBox(height: 18),
              TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                autofocus: true,
                enabled: true,
                readOnly: false,
                enableInteractiveSelection: true,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onTap: () => _otpFocusNode.requestFocus(),
                decoration: InputDecoration(
                  labelText: '인증번호',
                  suffixText: '${_remaining}s',
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verifyCode,
                  child: Text(_verifying ? '확인 중...' : '인증번호 확인'),
                ),
              ),
            ],
            if (_verified) ...[
              const SizedBox(height: 18),
              const Text('전화번호 인증 완료',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _complete,
                  child: Text(_verifying ? '가입 처리 중...' : '회원가입 완료'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
