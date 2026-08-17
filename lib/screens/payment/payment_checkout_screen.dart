// payment_checkout_screen.dart
// 토스페이먼츠 Payment Widget 전용 결제 화면
//
// 흐름:
//   1. initState → PaymentService.initWidget() → JS 위젯 초기화
//   2. WidgetsBinding.addPostFrameCallback → PaymentService.renderWidget()
//      → index.html의 #payment-method, #agreement div에 렌더링
//   3. 결제하기 버튼 → PaymentService.submitWidget()
//      → 성공 시 /payment/success 리디렉션
//      → 실패/취소 시 에러 메시지 표시

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/payment_service.dart';
import '../../services/order_service.dart';
import '../../models/models.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() =>
      _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  bool _isInitializing = true;
  bool _isSubmitting = false;
  String? _initError;
  String? _submitError;

  // 파라미터 (route arguments로 수신)
  PaymentCheckoutArgs? _args;

  @override
  void initState() {
    super.initState();
    // div 컨테이너 등록
    _registerDivViews();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 최초 1회만 초기화
    if (_args == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as PaymentCheckoutArgs?;
      if (args != null) {
        _args = args;
        _initializeWidget();
      }
    }
  }

  // ── div 컨테이너 등록 ─────────────────────────────────────────
  void _registerDivViews() {
    // #payment-method div
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'toss-payment-method',
      (int viewId) {
        final div = html.DivElement()
          ..id = 'payment-method'
          ..style.width = '100%'
          ..style.minHeight = '300px';
        return div;
      },
    );
    // #agreement div
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'toss-agreement',
      (int viewId) {
        final div = html.DivElement()
          ..id = 'agreement'
          ..style.width = '100%';
        return div;
      },
    );
  }

  // ── 위젯 초기화 + 렌더링 ──────────────────────────────────────
  Future<void> _initializeWidget() async {
    if (_args == null) return;

    // Widget 방식: 로그인 사용자는 uid, 비로그인은 'ANONYMOUS' 고정
    final uid = context.read<UserProvider>().user?.id;
    final customerKey = (uid != null && uid.isNotEmpty) ? uid : 'ANONYMOUS';
    final initResult = await PaymentService.initWidget(
      amount: _args!.amount,
      customerKey: customerKey,
    );

    if (!mounted) return;

    if (initResult != 'ok') {
      setState(() {
        _isInitializing = false;
        _initError = initResult.replaceFirst('error:', '');
      });
      return;
    }

    // DOM이 생성된 이후에 renderWidget 호출
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 렌더링까지 약간의 딜레이 필요 (HtmlElementView DOM 생성 대기)
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final renderResult = await PaymentService.renderWidget();
      if (!mounted) return;

      if (renderResult.startsWith('error:')) {
        setState(() {
          _isInitializing = false;
          _initError = renderResult.replaceFirst('error:', '');
        });
      } else {
        setState(() => _isInitializing = false);
      }
    });
  }

  // ── 결제하기 버튼 ─────────────────────────────────────────────
  Future<void> _onPayPressed() async {
    if (_args == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final successUrl = PaymentService.buildSuccessUrl(
        _args!.orderId, _args!.amount);
    final failUrl = PaymentService.buildFailUrl(_args!.orderId);

    final result = await PaymentService.submitWidget(
      orderId:             _args!.orderId,
      orderName:           _args!.orderName,
      customerName:        _args!.customerName,
      customerEmail:       _args!.customerEmail,
      customerMobilePhone: _args!.customerPhone,
      successUrl:          successUrl,
      failUrl:             failUrl,
    );

    if (!mounted) return;

    // 성공 시 여기 도달하지 않음 (리디렉션됨)
    // 취소/오류 시
    setState(() {
      _isSubmitting = false;
      _submitError = result.replaceFirst('error:', '');
    });
  }

  // ── 무통장입금 처리 ───────────────────────────────────────────
  Future<void> _onVirtualAccountPressed() async {
    if (_args == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final userProv  = context.read<UserProvider>();
      final orderProv = context.read<OrderProvider>();
      final user      = userProv.user;
      final cart      = context.read<CartProvider>();

      // 주문 저장 (미결제 상태)
      final orderItems = cart.items.map((c) => OrderItem(
        productId:   c.product.id,
        productName: c.product.name,
        size:        c.selectedSize,
        color:       c.selectedColor,
        quantity:    c.quantity,
        price:       c.product.price,
      )).toList();

      final order = OrderModel(
        id:            _args!.orderId,
        userId:        user?.id ?? 'guest',
        userName:      _args!.customerName,
        userPhone:     _args!.customerPhone,
        userAddress:   '',
        status:        OrderStatus.pending,
        totalAmount:   _args!.amount.toDouble(),
        shippingFee:   cart.shippingFee,
        paymentMethod: _args!.selectedPayment,
        orderType:     'regular',
        createdAt:     DateTime.now(),
        items:         orderItems,
        cashReceiptNum: user?.cashReceiptNum?.isNotEmpty == true
            ? user!.cashReceiptNum
            : null,
      );

      await OrderService.saveOrder(order);
      orderProv.addOrder(order);
      cart.clearCart();

      if (!mounted) return;

      // 완료 화면으로 이동
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/mypage',
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitError = '주문 처리 오류: $e';
        });
      }
    }
  }

  String get _formattedAmount {
    final amt = _args?.amount ?? 0;
    return amt.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0064FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '결제',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18),
        ),
      ),
      body: args == null
          ? const Center(child: Text('결제 정보가 없습니다.'))
          : _buildBody(args),
    );
  }

  Widget _buildBody(PaymentCheckoutArgs args) {
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('결제 위젯 로드 실패',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('뒤로 가기'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── 주문 정보 ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    args.orderName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$_formattedAmount원',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0064FF)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── 무통장입금 선택 시 별도 버튼 ──────────────────────
          if (args.selectedPayment == '무통장입금') ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('무통장입금',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    '주문 완료 후 입금 계좌 안내 문자를 발송합니다.\n입금 확인 후 주문이 처리됩니다.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _onVirtualAccountPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0064FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          '$_formattedAmount원 주문하기',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ] else ...[
            // ── 토스 Payment Widget 렌더링 영역 ───────────────
            _isInitializing
                ? Container(
                    color: Colors.white,
                    height: 380,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: Color(0xFF0064FF)),
                          SizedBox(height: 16),
                          Text('결제 수단을 불러오는 중...',
                              style: TextStyle(
                                  color: Color(0xFF666666))),
                        ],
                      ),
                    ),
                  )
                : Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        // 결제수단 위젯
                        SizedBox(
                          height: 380,
                          child: HtmlElementView(
                            viewType: 'toss-payment-method',
                          ),
                        ),
                        // 이용약관 위젯
                        SizedBox(
                          height: 100,
                          child: HtmlElementView(
                            viewType: 'toss-agreement',
                          ),
                        ),
                      ],
                    ),
                  ),

            const SizedBox(height: 8),

            // ── 오류 메시지 ──────────────────────────────────
            if (_submitError != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_submitError!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            if (_submitError != null) const SizedBox(height: 8),

            // ── 결제하기 버튼 ─────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isInitializing || _isSubmitting)
                      ? null
                      : _onPayPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0064FF),
                    disabledBackgroundColor:
                        const Color(0xFF0064FF).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          '$_formattedAmount원 결제하기',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
