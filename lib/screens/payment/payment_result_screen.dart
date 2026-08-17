// payment_result_screen.dart
// 토스페이먼츠 결제 완료/실패 후 리디렉션되는 화면
// successUrl: /payment/success?paymentKey=...&orderId=...&amount=...
// failUrl:    /payment/fail?code=...&message=...&orderId=...

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/payment_service.dart';
import '../../services/order_service.dart';
import '../../models/models.dart';

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
      final uri = Uri.parse(html.window.location.href);
      final paymentKey = uri.queryParameters['paymentKey'] ?? '';
      final orderId    = uri.queryParameters['orderId'] ?? '';
      final amountStr  = uri.queryParameters['amount'] ?? '0';
      final amount     = int.tryParse(amountStr) ?? 0;

      if (paymentKey.isEmpty || orderId.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMsg = '결제 파라미터가 올바르지 않습니다.';
        });
        return;
      }

      // Cloudflare Pages Function으로 결제 승인
      final result = await PaymentService.confirmPayment(
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );

      if (!mounted) return;

      if (result.success) {
        // 주문 상태 업데이트
        await OrderService.updateOrderStatus(orderId, OrderStatus.pending);

        // 현금영수증 자동 발급
        final userProv = context.read<UserProvider>();
        final cashNum = userProv.user?.cashReceiptNum;
        if (cashNum != null && cashNum.isNotEmpty && result.paymentKey != null) {
          final receiptType = cashNum.replaceAll('-', '').replaceAll(' ', '').length == 10
              ? '지출증빙'
              : '소득공제';
          await PaymentService.issueCashReceipt(
            paymentKey: result.paymentKey!,
            customerIdentityNumber: cashNum,
            type: receiptType,
          );
        }

        setState(() => _isProcessing = false);

        // 장바구니 비우기
        if (mounted) context.read<CartProvider>().clear();

        // 주문완료 화면으로 이동
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/mypage',
            (route) => false,
          );
        }
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
                      style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
                  SizedBox(height: 8),
                  Text('잠시만 기다려주세요',
                      style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                ],
              )
            : _errorMsg != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text('결제 처리 오류',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(_errorMsg!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 14)),
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
class PaymentFailScreen extends StatelessWidget {
  const PaymentFailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(html.window.location.href);
    final message = uri.queryParameters['message'] ?? '결제에 실패했습니다.';
    final code    = uri.queryParameters['code'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.red, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('결제 실패',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 10),
            Text(message,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF666666))),
            if (code.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('오류 코드: $code',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF999999))),
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
