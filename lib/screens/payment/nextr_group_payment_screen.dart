// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/nextr_payment_link_service.dart';
import '../../services/payment_service.dart';
import '../../utils/theme.dart';

class NextrGroupPaymentScreen extends StatefulWidget {
  final String token;
  final bool isSuccess;
  final Map<String, String> query;
  const NextrGroupPaymentScreen(
      {super.key,
      required this.token,
      this.isSuccess = false,
      this.query = const {}});
  @override
  State<NextrGroupPaymentScreen> createState() =>
      _NextrGroupPaymentScreenState();
}

class _NextrGroupPaymentScreenState extends State<NextrGroupPaymentScreen> {
  late Future<Map<String, dynamic>> _future;
  bool _busy = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _future = NextrPaymentLinkService.get(widget.token);
    if (widget.isSuccess) _confirm();
  }

  String _money(dynamic value) => '${(value as num? ?? 0).toInt()}'
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  Future<void> _start() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final data = await NextrPaymentLinkService.prepare(widget.token);
      final base = Uri.base;
      final success = Uri(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
          path: '/payment/group/success',
          queryParameters: {'token': widget.token});
      final fail = Uri(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
          path: '/payment/group/fail',
          queryParameters: {'token': widget.token});
      final uri = Uri(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
          path: '/payment-widget.html',
          queryParameters: {
            'clientKey': TossConfig.clientKey,
            'easyPayClientKey': TossConfig.easyPayClientKey,
            'customerKey': 'nextr-${data['orderId']}',
            'orderId': data['orderId'],
            'orderName': data['orderName'],
            'amount': '${data['amount']}',
            'customerName': data['customerName'] ?? '',
            'customerEmail': '',
            'customerMobilePhone': '',
            'successUrl': success.toString(),
            'failUrl': fail.toString()
          });
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault))
        throw Exception('결제창을 열 수 없습니다.');
    } catch (e) {
      if (mounted)
        setState(() {
          _message = e.toString().replaceFirst('Exception: ', '');
        });
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirm() async {
    final q = widget.query;
    final paymentKey = q['paymentKey'];
    final orderId = q['orderId'];
    final amount = int.tryParse(q['amount'] ?? '');
    if (paymentKey == null || orderId == null || amount == null) {
      setState(() => _message = '결제 승인 정보가 없습니다.');
      return;
    }
    try {
      await NextrPaymentLinkService.confirm(
          token: widget.token,
          paymentKey: paymentKey,
          orderId: orderId,
          amount: amount);
      if (mounted) setState(() => _message = '결제가 완료되었습니다. 주문번호: $orderId');
    } catch (e) {
      if (mounted)
        setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('NEXTR 단체주문 결제')),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snap.hasError)
              return _state('결제 링크를 확인할 수 없습니다.\n${snap.error}');
            final d = snap.data!;
            final status = d['status'];
            if (widget.isSuccess || _message != null)
              return _state(_message ?? '결제를 확인하고 있습니다.');
            if (status != 'active')
              return _state(status == 'expired'
                  ? '결제 링크가 만료되었습니다.'
                  : '이미 사용되었거나 취소된 링크입니다.');
            return ListView(padding: const EdgeInsets.all(20), children: [
              const Text('NEXTR',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text('단체주문 카드 결제',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['productName'] ?? '',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text('수량 ${d['quantity']}장'),
                            Text('상품 금액 ${_money(d['subtotal'])}원'),
                            Text('배송비 ${_money(d['shippingFee'])}원'),
                            const Divider(height: 24),
                            Text('결제 금액 ${_money(d['amount'])}원',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                            const SizedBox(height: 10),
                            const Text(
                                '※ 42,000원·39,000원 단체 할인은 현금 계좌이체에만 적용되며, 카드 결제에는 적용되지 않습니다.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.redAccent)),
                          ]))),
              const SizedBox(height: 18),
              const Text(
                  '배송지와 주문 정보는 상담 시 확인된 내용으로 등록됩니다. 카드번호·유효기간·CVC는 NEXTR 상담 채널이나 전화로 받지 않습니다.',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                  height: 52,
                  child: ElevatedButton(
                      onPressed: _busy ? null : _start,
                      child: Text(_busy ? '결제창 준비 중...' : '카드 결제하기'))),
            ]);
          }));
  Widget _state(String text) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16))));
}
