import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/providers.dart';
import '../../services/payment_service.dart';
import '../../services/secure_checkout_service.dart';
import '../mypage/mypage_screen.dart';
import '../../utils/theme.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  WebViewController? _controller;
  PaymentCheckoutArgs? _args;
  bool _loading = true;
  bool _handlingResult = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args != null) return;
    final args = ModalRoute.of(context)?.settings.arguments as PaymentCheckoutArgs?;
    if (args == null) {
      setState(() {
        _loading = false;
        _error = '결제 정보가 없습니다.';
      });
      return;
    }
    _args = args;
    _openPaymentWidget(args);
  }

  void _openPaymentWidget(PaymentCheckoutArgs args) {
    final user = context.read<UserProvider>().user;
    final customerKey = user?.id.isNotEmpty == true ? user!.id : '@@ANONYMOUS';
    final widgetUri = Uri(
      scheme: 'https',
      host: '2fit-mall.co.kr',
      path: '/payment-widget.html',
      queryParameters: {
        'clientKey': TossConfig.clientKey,
        'customerKey': customerKey,
        'orderId': args.orderId,
        'orderName': args.orderName,
        'amount': args.amount.toString(),
        'customerName': args.customerName,
        'customerEmail': args.customerEmail,
        'customerMobilePhone': args.customerPhone,
        'successUrl': PaymentService.buildSuccessUrl(args.orderId, args.amount),
        'failUrl': PaymentService.buildFailUrl(args.orderId),
      },
    );

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri != null &&
              (uri.path == '/payment/success' ||
                  uri.path == '/payment/fail')) {
            if (!_handlingResult) {
              _handlingResult = true;
              _handlePaymentResult(uri);
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(widgetUri);
    _controller = controller;
  }

  Future<void> _handlePaymentResult(Uri uri) async {
    if (!mounted) return;
    final args = _args;
    if (args == null) return;
    final paymentKey = uri.queryParameters['paymentKey'] ?? '';
    final orderId = uri.queryParameters['orderId'] ?? args.orderId;
    final amount = int.tryParse(uri.queryParameters['amount'] ?? '') ?? args.amount;

    if (uri.path == '/payment/fail' || paymentKey.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = uri.queryParameters['message'] ?? '결제가 취소되었거나 승인되지 않았습니다.';
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await PaymentService.confirmPayment(
      paymentKey: paymentKey,
      orderId: orderId,
      amount: amount,
    );
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.error ?? '결제 승인에 실패했습니다.';
      });
      return;
    }

    context.read<CartProvider>().clearCart();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      await context.read<OrderProvider>().loadUserOrders(user.id);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MyPageScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 56),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('돌아가기'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                if (_controller != null) WebViewWidget(controller: _controller!),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ],
            ),
    );
  }
}
