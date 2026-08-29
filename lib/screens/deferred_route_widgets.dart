import 'package:flutter/material.dart';

import 'payment/payment_checkout_screen.dart' deferred as payment_checkout;
import 'payment/payment_result_screen.dart' deferred as payment_result;

/// 결제 화면은 일반 쇼핑·로그인 화면에서 사용하지 않으므로 필요할 때만 로드합니다.
class DeferredPaymentCheckoutScreen extends StatefulWidget {
  const DeferredPaymentCheckoutScreen({super.key});

  @override
  State<DeferredPaymentCheckoutScreen> createState() =>
      _DeferredPaymentCheckoutScreenState();
}

class _DeferredPaymentCheckoutScreenState
    extends State<DeferredPaymentCheckoutScreen> {
  late final Future<void> _libraryFuture = payment_checkout.loadLibrary();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DeferredLoadingScreen();
        }
        if (snapshot.hasError) {
          return const _DeferredErrorScreen();
        }
        return const payment_checkout.PaymentCheckoutScreen();
      },
    );
  }
}

/// 토스 결제 콜백 화면도 결제 완료·실패 시에만 로드합니다.
class DeferredPaymentResultScreen extends StatefulWidget {
  final bool success;

  const DeferredPaymentResultScreen({
    required this.success,
    super.key,
  });

  @override
  State<DeferredPaymentResultScreen> createState() =>
      _DeferredPaymentResultScreenState();
}

class _DeferredPaymentResultScreenState
    extends State<DeferredPaymentResultScreen> {
  late final Future<void> _libraryFuture = payment_result.loadLibrary();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DeferredLoadingScreen();
        }
        if (snapshot.hasError) {
          return const _DeferredErrorScreen();
        }
        return widget.success
            ? const payment_result.PaymentSuccessScreen()
            : const payment_result.PaymentFailScreen();
      },
    );
  }
}

class _DeferredLoadingScreen extends StatelessWidget {
  const _DeferredLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DeferredErrorScreen extends StatelessWidget {
  const _DeferredErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('결제 화면을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.')),
    );
  }
}
