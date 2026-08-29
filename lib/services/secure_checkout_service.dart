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
        customerKey: data['customerKey'] as String?,
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
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return onFailure('로그인이 필요합니다.');
      }

      // 결제처럼 중요한 요청은 캐시된 토큰을 쓰지 않고 최신 ID 토큰을 발급합니다.
      // 예전 앱 세션에서 만료된 토큰이 남아 있는 경우에도 한 번 자동 복구합니다.
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return onFailure('로그인이 필요합니다. 다시 로그인해 주세요.');
      }
      var token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        return onFailure('로그인 인증을 갱신할 수 없습니다. 다시 로그인해 주세요.');
      }

      Future<http.Response> sendRequest(String idToken) {
        return http
            .post(
              Uri.parse('$_baseUrl/$path'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 30));
      }

      var response = await sendRequest(token);
      if (response.statusCode == 401) {
        // 서버가 취소·만료 토큰을 거부한 경우에만 새 토큰으로 한 번 더 시도합니다.
        await user.reload();
        user = FirebaseAuth.instance.currentUser;
        token = await user?.getIdToken(true);
        if (token != null && token.isNotEmpty) {
          response = await sendRequest(token);
        }
      }

      final dynamic decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      final data =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return parser(data);
      }
      if (response.statusCode == 401) {
        return onFailure('로그인 인증이 만료되었습니다. 로그아웃 후 다시 로그인해 주세요.');
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
  final String? customerKey;
  final bool bankTransfer;
  final String? error;

  const SecureOrderResult({
    required this.success,
    this.orderId,
    this.orderName,
    this.amount,
    this.customerKey,
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
