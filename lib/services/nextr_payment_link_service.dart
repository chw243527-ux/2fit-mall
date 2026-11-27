// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class NextrPaymentLinkService {
  static const baseUrl = 'https://us-central1-fit-mall.cloudfunctions.net';

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body,
      {bool admin = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (admin) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('관리자 로그인이 필요합니다.');
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) throw Exception('관리자 인증이 만료되었습니다.');
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http
        .post(Uri.parse('$baseUrl/$path'),
            headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final data =
        decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw Exception(data['error'] as String? ?? '요청 처리에 실패했습니다.');
    return data;
  }

  static Future<Map<String, dynamic>> create(
          {required String productId,
          required int quantity,
          required String customerName,
          required String customerPhone,
          required String deliveryAddress,
          String memo = '',
          int expiryHours = 72}) =>
      _post(
          'createNextrGroupPaymentLink',
          {
            'productId': productId,
            'quantity': quantity,
            'customerName': customerName,
            'customerPhone': customerPhone,
            'deliveryAddress': deliveryAddress,
            'memo': memo,
            'expiryHours': expiryHours
          },
          admin: true);
  static Future<List<Map<String, dynamic>>> list() async =>
      ((await _post('listNextrGroupPaymentLinks', {}, admin: true))['links']
                  as List? ??
              [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
  static Future<void> cancel(String linkId) async {
    await _post('cancelNextrGroupPaymentLink', {'linkId': linkId}, admin: true);
  }

  static Future<void> confirmBankTransfer(String orderId) async {
    await _post(
      'confirmBankTransferOrder',
      {'orderId': orderId},
      admin: true,
    );
  }

  static Future<List<Map<String, dynamic>>> searchMembers(String query) async =>
      ((await _post('searchNextrOrderMembers', {'query': query},
                  admin: true))['members'] as List? ??
              [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
  static Future<void> linkOrderToMember({
    required String orderId,
    required String userId,
  }) async {
    await _post(
        'linkNextrOrderToMember',
        {
          'orderId': orderId,
          'userId': userId,
        },
        admin: true);
  }

  static Future<void> claimGuestOrder(String orderId) async {
    await _post('claimNextrGuestOrder', {'orderId': orderId});
  }

  static Future<Map<String, dynamic>> get(String token) =>
      _post('getNextrGroupPaymentLink', {'token': token});
  static Future<Map<String, dynamic>> prepare(String token) =>
      _post('prepareNextrGroupPayment', {'token': token});
  static Future<Map<String, dynamic>> confirm(
          {required String token,
          required String paymentKey,
          required String orderId,
          required int amount}) =>
      _post('confirmNextrGroupPayment', {
        'token': token,
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount
      });
}
