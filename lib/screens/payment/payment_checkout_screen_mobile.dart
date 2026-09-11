import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

          // Toss 결제위젯은 카드사 앱을 intent: 또는 카드사 전용 스킴으로
          // 호출한다. 이를 WebView 안에서 navigate 하게 두면
          // ERR_UNKNOWN_URL_SCHEME가 발생하므로 Android 외부 앱으로 전달한다.
          final scheme = uri?.scheme.toLowerCase();
          if (scheme != null &&
              scheme.isNotEmpty &&
              scheme != 'http' &&
              scheme != 'https' &&
              scheme != 'about' &&
              scheme != 'data') {
            _openExternalPaymentApp(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(widgetUri);
    _controller = controller;
  }

  Future<void> _openExternalPaymentApp(String rawUrl) async {
    final externalUri = _parseExternalPaymentUri(rawUrl);
    if (externalUri == null) {
      _showPaymentAppError('카드사 앱을 열 수 없는 결제 링크입니다.');
      return;
    }

    try {
      final launched = await launchUrl(
        externalUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showPaymentAppError('카드사 앱이 설치되어 있지 않거나 실행할 수 없습니다.');
      }
    } catch (_) {
      _showPaymentAppError('카드사 앱을 실행하지 못했습니다. 카드 결제를 다시 시도해 주세요.');
    }
  }

  Uri? _parseExternalPaymentUri(String rawUrl) {
    if (!rawUrl.startsWith('intent:')) {
      return Uri.tryParse(rawUrl);
    }

    // intent:foo://bar?...#Intent;scheme=foo;package=...;end 형식을
    // url_launcher가 실행할 수 있는 foo://bar... 형식으로 변환한다.
    final intentBody = rawUrl.substring('intent:'.length);
    final marker = intentBody.indexOf('#Intent;');
    final target = marker >= 0 ? intentBody.substring(0, marker) : intentBody;
    final parameters = marker >= 0
        ? intentBody.substring(marker + '#Intent;'.length).split(';')
        : const <String>[];
    final scheme = parameters
        .map((item) => item.split('='))
        .where((parts) => parts.length >= 2 && parts.first == 'scheme')
        .map((parts) => parts.sublist(1).join('='))
        .firstOrNull;

    if (scheme != null && target.startsWith('//')) {
      return Uri.tryParse('$scheme:$target');
    }
    return Uri.tryParse(target);
  }

  void _showPaymentAppError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
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
