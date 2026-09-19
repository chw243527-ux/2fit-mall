import '../../utils/theme.dart';
// payment_checkout_screen.dart
// 토스페이먼츠 Payment Widget — fullscreen iframe 방식
//
// HtmlElementView + div 방식은 Flutter 캔버스가 포인터 이벤트를 가로채
// 토스 Widget 내부 드롭다운/클릭이 동작하지 않는 문제가 있음.
// → web/payment-widget.html 을 fullscreen iframe으로 띄워 해결.
//
// 흐름:
//   1. PaymentCheckoutArgs로 URL 파라미터 구성
//   2. /payment-widget.html?clientKey=...&orderId=...&successUrl=... 를 iframe으로 로드
//   3. 토스 Widget이 successUrl(/payment/success)로 리디렉션 → Flutter가 해당 라우트 처리

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/payment_service.dart';
import '../../services/secure_checkout_service.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  static int _viewSequence = 0;
  PaymentCheckoutArgs? _args;
  bool _registered = false;
  late final String _viewType = 'toss-payment-iframe-${_viewSequence++}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as PaymentCheckoutArgs?;
      if (args != null) {
        _args = args;
        _registerIframe(args);
      }
    }
  }

  void _registerIframe(PaymentCheckoutArgs args) {
    if (_registered) return;
    _registered = true;

    final uid = context.read<UserProvider>().user?.id;
    final customerKey = (uid != null && uid.isNotEmpty) ? uid : '@@ANONYMOUS';

    final successUrl =
        PaymentService.buildSuccessUrl(args.orderId, args.amount);
    final failUrl = PaymentService.buildFailUrl(args.orderId);

    // URL 파라미터 구성
    final uri = Uri(
      path: '/payment-widget.html',
      queryParameters: {
        'clientKey': TossConfig.clientKey,
        'easyPayClientKey': TossConfig.easyPayClientKey, // 카카오페이·네이버페이·토스페이
        'customerKey': customerKey,
        'orderId': args.orderId,
        'orderName': args.orderName,
        'amount': args.amount.toString(),
        'customerName': args.customerName,
        'customerEmail': args.customerEmail,
        'customerMobilePhone': args.customerPhone,
        'successUrl': successUrl,
        'failUrl': failUrl,
      },
    );

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = uri.toString()
          ..referrerPolicy = 'strict-origin-when-cross-origin'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'payment';
        iframe.setAttribute('loading', 'eager');
        return iframe;
      },
    );
  }

  // ── 무통장입금: 서버가 상품·할인·포인트를 검증해 주문을 생성합니다. ──
  Future<void> _onVirtualAccountPressed() async {
    final args = _args;
    if (args == null) return;
    final cart = context.read<CartProvider>();
    final result = await SecureCheckoutService.createOrder(
      items: cart.items
          .map((item) => {
                'productId': item.product.id,
                'size': item.selectedSize,
                'color': item.selectedColor,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'extraPrice': item.extraPrice,
                'customOptions': item.customOptions,
              })
          .toList(),
      deliveryAddress: '',
      paymentMethod: args.selectedPayment,
      couponIds: args.couponIds,
      couponId: args.couponId,
      usedPoints: args.usedPoints,
    );
    if (!mounted) return;
    if (!result.success || !result.bankTransfer) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.error ?? '주문 처리에 실패했습니다.'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    cart.clearCart();
    Navigator.of(context).pushNamedAndRemoveUntil('/mypage', (route) => false);
  }

  String get _formattedAmount {
    final amt = _args?.amount ?? 0;
    return amt
        .toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.8),
          child: Divider(height: 0.8, thickness: 0.8, color: AppColors.border),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '결제',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 18),
        ),
      ),
      body: args == null
          ? const Center(child: Text('결제 정보가 없습니다.'))
          : _buildBody(args),
    );
  }

  Widget _buildBody(PaymentCheckoutArgs args) {
    // 무통장입금은 iframe 없이 처리
    if (args.selectedPayment == '무통장입금') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_outlined,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('무통장입금',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const Text(
                '주문 완료 후 입금 계좌 안내 문자를 발송합니다.\n입금 확인 후 주문이 처리됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text('결제 금액: $_formattedAmount원',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onVirtualAccountPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    '$_formattedAmount원 주문하기',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 카드/간편결제 등 → iframe fullscreen
    if (!_registered) {
      return const Center(child: CircularProgressIndicator());
    }

    return HtmlElementView(viewType: _viewType);
  }
}
