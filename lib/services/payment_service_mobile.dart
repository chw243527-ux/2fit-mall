import 'dart:convert';
import 'package:http/http.dart' as http;

class TossConfig {
  static const clientKey = 'test_ck_ORzdMaqN3wyZjLgO7ozbr5AkYXQG';
  static const secretKey = '';
  static const easyPayClientKey = 'test_gck_ORzdMaqN3wyZjLgO7ozbr5AkYXQG';
  static const confirmEdgeFunctionUrl =
      'https://2fit-mall.co.kr/api/confirm-payment';
  static const cashReceiptEdgeFunctionUrl =
      'https://2fit-mall.co.kr/api/issue-cash-receipt';
  static bool get useEdgeFunction => confirmEdgeFunctionUrl.isNotEmpty;
  static bool get isLiveMode => !clientKey.startsWith('test_');
}

class PaymentService {
  static Future<String> initWidget(
          {required int amount, required String customerKey}) async =>
      'error: Android 앱에서는 현재 웹 결제 위젯을 사용할 수 없습니다.';
  static Future<String> renderWidget() async =>
      'error: Android 앱에서는 현재 웹 결제 위젯을 사용할 수 없습니다.';
  static void updateWidgetAmount(int amount) {}
  static Future<String> submitWidget(
          {required String orderId,
          required String orderName,
          required String customerName,
          required String customerEmail,
          String customerMobilePhone = '',
          required String successUrl,
          required String failUrl}) async =>
      'error: Android 앱 결제 화면 준비 중입니다.';

  static Future<PaymentResult> confirmPayment(
      {required String paymentKey,
      required String orderId,
      required int amount}) async {
    try {
      final response = await http
          .post(Uri.parse(TossConfig.confirmEdgeFunctionUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'paymentKey': paymentKey,
                'orderId': orderId,
                'amount': amount
              }))
          .timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return PaymentResult(
            success: true,
            paymentKey: data['paymentKey'],
            orderId: data['orderId'],
            method: data['method']);
      }
      return PaymentResult(
          success: false, error: data['message'] ?? '결제 승인에 실패했습니다.');
    } catch (e) {
      return PaymentResult(success: false, error: '네트워크 오류: $e');
    }
  }

  static Future<CashReceiptResult> issueCashReceipt(
      {required String paymentKey,
      required String customerIdentityNumber,
      String type = '소득공제',
      int taxFreeAmount = 0}) async {
    try {
      final response = await http
          .post(Uri.parse(TossConfig.cashReceiptEdgeFunctionUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'paymentKey': paymentKey,
                'customerIdentityNumber': customerIdentityNumber,
                'type': type,
                'taxFreeAmount': taxFreeAmount
              }))
          .timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return CashReceiptResult(
            success: true,
            receiptKey: data['receiptKey'],
            orderId: data['orderId']);
      return CashReceiptResult(
          success: false, error: data['message'] ?? '현금영수증 발급에 실패했습니다.');
    } catch (e) {
      return CashReceiptResult(success: false, error: '네트워크 오류: $e');
    }
  }

  static String mapPaymentMethod(String method) {
    switch (method) {
      case '카카오페이':
        return 'KAKAO_PAY';
      case '네이버페이':
        return 'NAVER_PAY';
      case '토스페이':
        return 'TOSS_PAY';
      case '신용/체크카드':
        return 'CARD';
      case '무통장입금':
        return 'VIRTUAL_ACCOUNT';
      default:
        return 'CARD';
    }
  }

  static bool needsCashReceiptApiCall(String? paymentMethod) =>
      paymentMethod != null &&
      !['무통장입금', 'VIRTUAL_ACCOUNT'].contains(paymentMethod);
  static String buildSuccessUrl(String orderId, int amount) =>
      'https://2fit-mall.co.kr/payment/success?orderId=$orderId&amount=$amount';
  static String buildFailUrl(String orderId) =>
      'https://2fit-mall.co.kr/payment/fail?orderId=$orderId';
}

class PaymentResult {
  final bool success;
  final String? paymentKey;
  final String? orderId;
  final String? method;
  final String? error;
  const PaymentResult(
      {required this.success,
      this.paymentKey,
      this.orderId,
      this.method,
      this.error});
}

class CashReceiptResult {
  final bool success;
  final String? receiptKey;
  final String? orderId;
  final String? error;
  const CashReceiptResult(
      {required this.success, this.receiptKey, this.orderId, this.error});
}

class PaymentCheckoutArgs {
  final String orderId;
  final String orderName;
  final int amount;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerKey;
  final String selectedPayment;
  final String? couponId;
  final double couponDiscount;
  final int usedPoints;
  final double pointDiscount;
  const PaymentCheckoutArgs(
      {required this.orderId,
      required this.orderName,
      required this.amount,
      required this.customerName,
      required this.customerEmail,
      required this.customerPhone,
      required this.customerKey,
      required this.selectedPayment,
      this.couponId,
      this.couponDiscount = 0,
      this.usedPoints = 0,
      this.pointDiscount = 0});
}
