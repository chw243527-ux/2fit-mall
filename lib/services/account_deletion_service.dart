import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AccountDeletionResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;

  const AccountDeletionResult._({
    required this.success,
    this.errorCode,
    this.errorMessage,
  });

  const AccountDeletionResult.success() : this._(success: true);

  const AccountDeletionResult.failure({
    String? errorCode,
    String? errorMessage,
  }) : this._(
          success: false,
          errorCode: errorCode,
          errorMessage: errorMessage,
        );
}

/// Firebase Authentication 계정과 계정에 연결된 개인정보를 서버에서 삭제합니다.
///
/// 삭제 범위와 주문 정보 익명화는 클라이언트가 아닌 Firebase Functions에서만 수행합니다.
class AccountDeletionService {
  static const _functionsBaseUrl =
      'https://us-central1-fit-mall.cloudfunctions.net';

  static Future<AccountDeletionResult> deleteCurrentAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AccountDeletionResult.failure(
        errorCode: 'not-signed-in',
        errorMessage: '로그인 정보를 확인할 수 없습니다. 다시 로그인해 주세요.',
      );
    }

    try {
      // 서버에서 최근 로그인 시간을 검증하므로 캐시가 아닌 새 ID 토큰을 사용합니다.
      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        return const AccountDeletionResult.failure(
          errorCode: 'token-unavailable',
          errorMessage: '보안 확인에 실패했습니다. 다시 로그인해 주세요.',
        );
      }

      final response = await http
          .post(
            Uri.parse('$_functionsBaseUrl/deleteMyAccount'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'confirmAccountDeletion': true}),
          )
          .timeout(const Duration(seconds: 45));

      Map<String, dynamic> payload = const {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) payload = decoded;
      } catch (_) {
        // 응답 본문이 JSON이 아니어도 상태 코드 기반의 안전한 오류를 반환합니다.
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const AccountDeletionResult.success();
      }

      final code = payload['code'] as String?;
      return AccountDeletionResult.failure(
        errorCode: code ?? 'server-error',
        errorMessage: _messageFor(code, payload['error'] as String?),
      );
    } catch (error) {
      if (kDebugMode) debugPrint('계정 삭제 서버 호출 실패: $error');
      return const AccountDeletionResult.failure(
        errorCode: 'network-error',
        errorMessage: '네트워크 문제로 회원 탈퇴를 완료하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  static String _messageFor(String? code, String? serverMessage) {
    switch (code) {
      case 'recent-login-required':
        return '보안을 위해 다시 로그인한 뒤 회원 탈퇴를 진행해 주세요.';
      case 'admin-account-protected':
        return '관리자 계정은 고객센터를 통해 탈퇴를 요청해 주세요.';
      default:
        return serverMessage ?? '회원 탈퇴를 완료하지 못했습니다. 고객센터에 문의해 주세요.';
    }
  }
}
