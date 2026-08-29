import 'package:flutter/services.dart';

import 'payment_service.dart';

class NativeTossPaymentService {
  static const _channel = MethodChannel('com.twofit.twofit/toss_payment');

  static Future<NativeTossPaymentResult> requestPayment(
    PaymentCheckoutArgs args,
  ) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'startPayment',
        {
          'clientKey': TossConfig.easyPayClientKey,
          'customerKey': args.customerKey,
          'orderId': args.orderId,
          'orderName': args.orderName,
          'amount': args.amount,
          'customerName': args.customerName,
          'customerEmail': args.customerEmail,
          'customerPhone': args.customerPhone,
        },
      );
      if (result?['success'] == true) {
        return NativeTossPaymentResult(
          success: true,
          paymentKey: result?['paymentKey'] as String?,
          orderId: result?['orderId'] as String?,
          amount: (result?['amount'] as num?)?.toInt(),
        );
      }
      return NativeTossPaymentResult(
        success: false,
        errorCode: result?['errorCode'] as String?,
        errorMessage:
            result?['errorMessage'] as String? ?? '결제가 취소되었거나 실패했습니다.',
      );
    } on PlatformException catch (error) {
      return NativeTossPaymentResult(
        success: false,
        errorCode: error.code,
        errorMessage: error.message ?? '결제 화면을 열 수 없습니다.',
      );
    } catch (_) {
      return const NativeTossPaymentResult(
        success: false,
        errorMessage: '결제 처리 중 오류가 발생했습니다.',
      );
    }
  }
}

class NativeTossPaymentResult {
  final bool success;
  final String? paymentKey;
  final String? orderId;
  final int? amount;
  final String? errorCode;
  final String? errorMessage;

  const NativeTossPaymentResult({
    required this.success,
    this.paymentKey,
    this.orderId,
    this.amount,
    this.errorCode,
    this.errorMessage,
  });
}
