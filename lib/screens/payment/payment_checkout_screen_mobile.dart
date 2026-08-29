import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../services/native_toss_payment_service.dart';
import '../../services/payment_service.dart';
import '../../services/secure_checkout_service.dart';
import '../../utils/theme.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  bool _isProcessing = false;

  Future<void> _startNativePayment(PaymentCheckoutArgs args) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final nativeResult = await NativeTossPaymentService.requestPayment(args);
    if (!mounted) return;
    if (!nativeResult.success ||
        nativeResult.paymentKey == null ||
        nativeResult.orderId != args.orderId ||
        nativeResult.amount != args.amount) {
      await SecureCheckoutService.cancelPaymentIntent(args.orderId);
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              nativeResult.errorMessage ?? '결제가 취소되었거나 결제 정보를 확인할 수 없습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await SecureCheckoutService.confirmPayment(
      paymentKey: nativeResult.paymentKey!,
      orderId: args.orderId,
      amount: args.amount,
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (!confirmed.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmed.error ?? '결제 승인에 실패했습니다. 고객센터에 문의해 주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<CartProvider>().clearCart();
    Navigator.of(context).pushNamedAndRemoveUntil('/mypage', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as PaymentCheckoutArgs?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('토스페이먼츠 결제'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: args == null
          ? const Center(child: Text('결제 정보를 찾을 수 없습니다.'))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payment_rounded,
                        size: 56, color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      '토스페이먼츠의 안전한 앱 결제 화면을 엽니다.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${args.amount.toString().replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+$)'), (match) => '${match[1]},')}원',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _startNativePayment(args),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('토스페이먼츠로 결제하기'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '결제 금액과 주문 정보는 서버에서 다시 확인됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
