import '../../utils/theme.dart';
// payment_result_screen.dart
// 토스페이먼츠 결제 완료/실패 후 리디렉션되는 화면
// successUrl: /payment/success?paymentKey=...&orderId=...&amount=...
// failUrl:    /payment/fail?code=...&message=...&orderId=...

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/secure_checkout_service.dart';

// ══════════════════════════════════════════════════════════════
// 결제 성공 화면
// ══════════════════════════════════════════════════════════════
class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isProcessing = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _processSuccess();
  }

  Future<void> _processSuccess() async {
    try {
      // URL 파라미터 파싱
      final uri = Uri.parse(Uri.base.toString());
      final paymentKey = uri.queryParameters['paymentKey'] ?? '';
      final orderId = uri.queryParameters['orderId'] ?? '';
      final amountStr = uri.queryParameters['amount'] ?? '0';
      final amount = int.tryParse(amountStr) ?? 0;

      if (paymentKey.isEmpty || orderId.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMsg = '결제 파라미터가 올바르지 않습니다.';
        });
        return;
      }

      // Firebase 서버가 결제 의도·주문 소유자·금액을 검증한 뒤 토스 승인을 수행합니다.
      final result = await SecureCheckoutService.confirmPayment(
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );

      if (!mounted) return;

      if (result.success) {
        // 주문 확정·쿠폰 사용 처리는 서버 트랜잭션에서 이미 완료되었습니다.
        // 장바구니 비우기
        context.read<CartProvider>().clearCart();

        setState(() => _isProcessing = false);

        // 주문완료 → 마이페이지로 이동
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/mypage',
          (route) => false,
        );
      } else {
        setState(() {
          _isProcessing = false;
          _errorMsg = result.error ?? '결제 승인에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMsg = '오류가 발생했습니다: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0064FF)),
                  SizedBox(height: 20),
                  Text('결제를 처리하고 있습니다...',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                  SizedBox(height: 8),
                  Text('잠시만 기다려주세요',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              )
            : _errorMsg != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 64),
                      const SizedBox(height: 16),
                      Text('결제 처리 오류',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(_errorMsg!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 14)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context, '/', (r) => false),
                        child: const Text('홈으로 돌아가기'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 결제 실패 화면
// ══════════════════════════════════════════════════════════════
class PaymentFailScreen extends StatefulWidget {
  const PaymentFailScreen({super.key});

  @override
  State<PaymentFailScreen> createState() => _PaymentFailScreenState();
}

class _PaymentFailScreenState extends State<PaymentFailScreen> {
  @override
  void initState() {
    super.initState();
    _refundReservedPoints();
  }

  Future<void> _refundReservedPoints() async {
    final uri = Uri.parse(Uri.base.toString());
    final orderId = uri.queryParameters['orderId'] ?? '';
    if (orderId.isEmpty) return;
    // 결제 실패 시 서버 트랜잭션이 예약된 쿠폰·포인트를 한 번만 해제합니다.
    await SecureCheckoutService.cancelPaymentIntent(orderId);
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(Uri.base.toString());
    final message = uri.queryParameters['message'] ?? '결제에 실패했습니다.';
    final code = uri.queryParameters['code'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.error, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('결제 실패',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary)),
            const SizedBox(height: 10),
            Text(message,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
            if (code.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('오류 코드: $code',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (r) => false),
                  child: const Text('홈으로'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0064FF)),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/cart', (r) => false),
                  child: const Text('다시 결제하기',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
