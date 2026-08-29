import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/payment_service.dart';
import '../../utils/theme.dart';

class PaymentCheckoutScreen extends StatelessWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as PaymentCheckoutArgs?;
    return Scaffold(
      appBar: AppBar(title: const Text('결제'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.payment_rounded, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('안전한 결제를 위해 결제 페이지를 엽니다.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: args == null ? null : () async {
                final uri = Uri.parse(PaymentService.buildSuccessUrl(args.orderId, args.amount));
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('결제 페이지 열기'),
            ),
          ]),
        ),
      ),
    );
  }
}
