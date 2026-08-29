import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class SecureCheckoutService {
  static const _baseUrl = 'https://us-central1-fit-mall.cloudfunctions.net';

  static Future<SecureOrderResult> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String paymentMethod,
    String? memo,
    String? couponId,
    int usedPoints = 0,
  }) async {
    return _post(
      path: 'createSecureOrder',
      body: {
        'items': items,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'memo': memo ?? '',
        'couponId': couponId ?? '',
        'usedPoints': usedPoints,
      },
      parser: (data) => SecureOrderResult(
        success: data['success'] == true,
        orderId: data['orderId'] as String?,
        orderName: data['orderName'] as String?,
        amount: (data['amount'] as num?)?.toInt(),
        bankTransfer: data['bankTransfer'] == true,
        error: data['error'] as String?,
      ),
      onFailure: (message) => SecureOrderResult(success: false, error: message),
    );
  }

  static Future<SecurePaymentResult> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    return _post(
      path: 'confirmSecurePayment',
      body: {'paymentKey': paymentKey, 'orderId': orderId, 'amount': amount},
      parser: (data) => SecurePaymentResult(
        success: data['success'] == true,
        orderId: data['orderId'] as String?,
        paymentKey: data['paymentKey'] as String?,
        method: data['method'] as String?,
        error: data['error'] as String?,
      ),
      onFailure: (message) =>
          SecurePaymentResult(success: false, error: message),
    );
  }

  static Future<String> downloadCoupon(String couponId) async {
    return _post(
      path: 'downloadSecureCoupon',
      body: {'couponId': couponId},
      parser: (data) => data['result'] as String? ?? '',
      onFailure: (message) => message,
    );
  }

  static Future<void> cancelPaymentIntent(String orderId) async {
    await _post<Object?>(
      path: 'cancelSecurePayment',
      body: {'orderId': orderId},
      parser: (_) => null,
      onFailure: (_) => null,
    );
  }

  static Future<T> _post<T>({
    required String path,
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic>) parser,
    required T Function(String) onFailure,
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        return onFailure('로그인이 필요합니다.');
      }
      final response = await http
          .post(
            Uri.parse('$_baseUrl/$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      final dynamic decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      final data =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return parser(data);
      }
      return onFailure(data['error'] as String? ?? '안전한 결제 요청 처리에 실패했습니다.');
    } catch (_) {
      return onFailure('서버 연결에 실패했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }
}

class SecureOrderResult {
  final bool success;
  final String? orderId;
  final String? orderName;
  final int? amount;
  final bool bankTransfer;
  final String? error;

  const SecureOrderResult({
    required this.success,
    this.orderId,
    this.orderName,
    this.amount,
    this.bankTransfer = false,
    this.error,
  });
}

class SecurePaymentResult {
  final bool success;
  final String? orderId;
  final String? paymentKey;
  final String? method;
  final String? error;

  const SecurePaymentResult({
    required this.success,
    this.orderId,
    this.paymentKey,
    this.method,
    this.error,
  });
}
