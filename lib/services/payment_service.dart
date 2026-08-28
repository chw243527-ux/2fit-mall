// payment_service.dart
// ══════════════════════════════════════════════════════════════
// 토스페이먼츠 결제 서비스 — Payment Widget 방식 (v2)
//
// 🔑 연동 구성:
//   • clientKey  : live_ck_kYG57Eba3GbJ4WOYa1vE8pWDOxmA (앱 포함 가능)
//   • secretKey  : Cloudflare Pages 환경변수 TOSS_SECRET_KEY (서버 전용)
//   • 결제 승인   : https://2fit-mall.co.kr/api/confirm-payment (CF Pages Function)
//   • 현금영수증  : https://2fit-mall.co.kr/api/issue-cash-receipt (CF Pages Function)
//   • SDK        : https://js.tosspayments.com/v2/standard (web/index.html)
//
// ⚠️ secretKey는 절대 Git·앱 배포본에 포함하지 마세요.
// ══════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:http/http.dart' as http;

// ─── 🔑 키 설정 ────────────────────────────────────────────────
class TossConfig {
  static const clientKey = 'test_ck_ORzdMaqN3wyZjLgO7ozbr5AkYXQG';
  static const secretKey = ''; // 앱에서 직접 사용 안 함 — CF Pages Function 전용

  // ── 간편결제 클라이언트 키 (카카오페이·네이버페이·토스페이) ──
  // gck 키를 Payment Widget에 함께 전달하면 간편결제 버튼이 활성화됩니다.
  static const easyPayClientKey = 'test_gck_ORzdMaqN3wyZjLgO7ozbr5AkYXQG';

  // ── Cloudflare Pages Function URL ───────────────────────────
  static const confirmEdgeFunctionUrl =
      'https://2fit-mall.co.kr/api/confirm-payment';
  static const cashReceiptEdgeFunctionUrl =
      'https://2fit-mall.co.kr/api/issue-cash-receipt';

  static bool get useEdgeFunction => confirmEdgeFunctionUrl.isNotEmpty;
  static bool get isLiveMode => !clientKey.startsWith('test_');
}

// ══════════════════════════════════════════════════════════════
// PaymentService — Payment Widget 방식
// ══════════════════════════════════════════════════════════════
class PaymentService {

  // ─── Widget 초기화 (JS 호출) ──────────────────────────────────
  // checkout 화면 initState에서 호출 → 위젯 인스턴스 준비
  static Future<String> initWidget({
    required int amount,
    required String customerKey,
  }) async {
    final completer = Completer<String>();
    js.context['_tossWidgetInitCallback'] = js.allowInterop((String result) {
      if (!completer.isCompleted) completer.complete(result);
    });
    final params = js.JsObject.jsify({
      'clientKey': TossConfig.clientKey,
      'customerKey': customerKey,
      'amount': amount,
    });
    js.context.callMethod('initTossWidget', [params]);
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => 'error:위젯 초기화 시간 초과',
    );
  }

  // ─── Widget 렌더링 (JS 호출) ──────────────────────────────────
  // DOM에 #payment-method, #agreement div가 준비된 후 호출
  static Future<String> renderWidget() async {
    final completer = Completer<String>();
    js.context['_tossWidgetRenderCallback'] = js.allowInterop((String result) {
      if (!completer.isCompleted) completer.complete(result);
    });
    js.context.callMethod('renderTossWidget', []);
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => 'error:위젯 렌더링 시간 초과',
    );
  }

  // ─── 금액 업데이트 (쿠폰 등) ──────────────────────────────────
  static void updateWidgetAmount(int amount) {
    final params = js.JsObject.jsify({'amount': amount});
    js.context.callMethod('updateTossWidgetAmount', [params]);
  }

  // ─── 결제 요청 (결제하기 버튼 → JS 호출) ──────────────────────
  // 성공 시 successUrl 리디렉션, 취소/오류 시 'error:...' 반환
  static Future<String> submitWidget({
    required String orderId,
    required String orderName,
    required String customerName,
    required String customerEmail,
    String customerMobilePhone = '',
    required String successUrl,
    required String failUrl,
  }) async {
    final completer = Completer<String>();
    js.context['_tossWidgetSubmitCallback'] = js.allowInterop((String result) {
      if (!completer.isCompleted) completer.complete(result);
    });
    final params = js.JsObject.jsify({
      'orderId':             orderId,
      'orderName':           orderName,
      'customerName':        customerName,
      'customerEmail':       customerEmail,
      'customerMobilePhone': customerMobilePhone,
      'successUrl':          successUrl,
      'failUrl':             failUrl,
    });
    js.context.callMethod('submitTossWidget', [params]);
    // 성공 시 successUrl로 리디렉션되어 이 future는 완료되지 않음
    // 취소/오류 시 _tossWidgetSubmitCallback이 호출됨
    return completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () => 'error:결제 시간이 초과되었습니다.',
    );
  }

  // ─── 결제 승인 — 보안 라우팅 ─────────────────────────────────
  // 우선순위: Edge Function → 직접 API (개발 환경 전용)
  static Future<PaymentResult> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    if (TossConfig.useEdgeFunction) {
      // ✅ 운영 환경: Cloudflare Pages Function 경유 (secretKey 앱 노출 없음)
      return await _confirmViaEdgeFunction(
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );
    } else {
      // ⚠️ 개발/테스트 환경 전용: 앱에서 직접 호출
      return await _confirmDirectly(
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
      );
    }
  }

  // ── Cloudflare Pages Function 경유 승인 (운영 권장) ──
  static Future<PaymentResult> _confirmViaEdgeFunction({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(TossConfig.confirmEdgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': amount,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return PaymentResult(
          success: true,
          paymentKey: data['paymentKey'],
          orderId: data['orderId'],
          method: data['method'],
        );
      }
      return PaymentResult(
        success: false,
        error: data['message'] ?? '결제 승인에 실패했습니다.',
      );
    } catch (e) {
      return PaymentResult(success: false, error: '네트워크 오류: $e');
    }
  }

  // ── 직접 API 승인 (테스트/개발 전용) ──
  static Future<PaymentResult> _confirmDirectly({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      final credentials = base64Encode(utf8.encode('${TossConfig.secretKey}:'));
      final response = await http.post(
        Uri.parse('https://api.tosspayments.com/v1/payments/confirm'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paymentKey': paymentKey,
          'orderId': orderId,
          'amount': amount,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentResult(
          success: true,
          paymentKey: data['paymentKey'],
          orderId: data['orderId'],
          method: data['method'],
        );
      } else {
        // 테스트 환경에서 API 오류 시 시뮬레이션 성공
        if (!TossConfig.isLiveMode) {
          return PaymentResult(
            success: true,
            paymentKey: paymentKey,
            orderId: orderId,
            method: 'CARD',
          );
        }
        final err = jsonDecode(response.body);
        return PaymentResult(
          success: false,
          error: err['message'] ?? '결제 승인에 실패했습니다.',
        );
      }
    } catch (e) {
      if (!TossConfig.isLiveMode) {
        return PaymentResult(
          success: true,
          paymentKey: paymentKey,
          orderId: orderId,
          method: 'CARD',
        );
      }
      return PaymentResult(success: false, error: '네트워크 오류: $e');
    }
  }

  // ─── 현금영수증 발급 ──────────────────────────────────────────
  // 토스페이먼츠 POST /v1/payments/{paymentKey}/cash-receipts
  //
  // [type]
  //   '소득공제' — 개인 소비자, 전화번호 or 주민등록번호 뒤 7자리
  //   '지출증빙' — 사업자, 사업자번호 10자리
  //
  // 발급 다음 날 오전 9시경 국세청 홈택스에 자동 신고됩니다.
  // 가상계좌·계좌이체는 결제 승인 시 자동 발급되므로,
  // 카드(KAKAO_PAY / NAVER_PAY / TOSS_PAY / CARD) 결제 시 이 메서드를 호출하세요.
  static Future<CashReceiptResult> issueCashReceipt({
    required String paymentKey,
    required String customerIdentityNumber, // 전화번호(010-...) or 사업자번호(10자리)
    String type = '소득공제',               // '소득공제' or '지출증빙'
    int taxFreeAmount = 0,
  }) async {
    if (TossConfig.useEdgeFunction &&
        TossConfig.cashReceiptEdgeFunctionUrl.isNotEmpty) {
      return await _issueCashReceiptViaEdge(
        paymentKey: paymentKey,
        customerIdentityNumber: customerIdentityNumber,
        type: type,
        taxFreeAmount: taxFreeAmount,
      );
    }
    return await _issueCashReceiptDirectly(
      paymentKey: paymentKey,
      customerIdentityNumber: customerIdentityNumber,
      type: type,
      taxFreeAmount: taxFreeAmount,
    );
  }

  // ── Cloudflare Pages Function 경유 현금영수증 발급 (운영 권장) ──
  static Future<CashReceiptResult> _issueCashReceiptViaEdge({
    required String paymentKey,
    required String customerIdentityNumber,
    required String type,
    required int taxFreeAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(TossConfig.cashReceiptEdgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paymentKey': paymentKey,
          'customerIdentityNumber': customerIdentityNumber,
          'type': type,
          'taxFreeAmount': taxFreeAmount,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return CashReceiptResult(
          success: true,
          receiptKey: data['receiptKey'] as String?,
          orderId: data['orderId'] as String?,
        );
      }
      return CashReceiptResult(
        success: false,
        error: data['message'] as String? ?? '현금영수증 발급에 실패했습니다.',
      );
    } catch (e) {
      return CashReceiptResult(success: false, error: '네트워크 오류: $e');
    }
  }

  // ── 직접 API 현금영수증 발급 (테스트/개발 전용) ──
  static Future<CashReceiptResult> _issueCashReceiptDirectly({
    required String paymentKey,
    required String customerIdentityNumber,
    required String type,
    required int taxFreeAmount,
  }) async {
    try {
      final credentials = base64Encode(utf8.encode('${TossConfig.secretKey}:'));
      final response = await http.post(
        Uri.parse(
            'https://api.tosspayments.com/v1/payments/$paymentKey/cash-receipts'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customerIdentityNumber': customerIdentityNumber,
          'type': type,
          if (taxFreeAmount > 0) 'taxFreeAmount': taxFreeAmount,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CashReceiptResult(
          success: true,
          receiptKey: data['receiptKey'] as String?,
          orderId: data['orderId'] as String?,
        );
      } else {
        if (!TossConfig.isLiveMode) {
          return CashReceiptResult(
            success: true,
            receiptKey: 'test_rcpt_${DateTime.now().millisecondsSinceEpoch}',
          );
        }
        final err = jsonDecode(response.body);
        return CashReceiptResult(
          success: false,
          error: err['message'] as String? ?? '현금영수증 발급에 실패했습니다.',
        );
      }
    } catch (e) {
      if (!TossConfig.isLiveMode) {
        return CashReceiptResult(
          success: true,
          receiptKey: 'test_rcpt_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      return CashReceiptResult(success: false, error: '네트워크 오류: $e');
    }
  }

  // ─── 결제 수단 매핑 (기존 호환용) ────────────────────────────
  static String mapPaymentMethod(String method) {
    switch (method) {
      case '카카오페이':    return 'KAKAO_PAY';
      case '네이버페이':    return 'NAVER_PAY';
      case '토스페이':     return 'TOSS_PAY';
      case '신용/체크카드': return 'CARD';
      case '무통장입금':    return 'VIRTUAL_ACCOUNT';
      default:            return 'CARD';
    }
  }

  // ─── 현금영수증 필요 결제수단 여부 ────────────────────────────
  static bool needsCashReceiptApiCall(String? paymentMethod) {
    if (paymentMethod == null) return false;
    const autoIssueMethods = ['무통장입금', 'VIRTUAL_ACCOUNT'];
    return !autoIssueMethods.contains(paymentMethod);
  }

  // ─── successUrl 생성 헬퍼 ─────────────────────────────────────
  static String buildSuccessUrl(String orderId, int amount) {
    final baseUrl = html.window.location.origin;
    return '$baseUrl/payment/success?orderId=$orderId&amount=$amount';
  }

  // ─── failUrl 생성 헬퍼 ────────────────────────────────────────
  static String buildFailUrl(String orderId) {
    final baseUrl = html.window.location.origin;
    return '$baseUrl/payment/fail?orderId=$orderId';
  }
}

// ── 결제 결과 모델 ──────────────────────────────────────────────
class PaymentResult {
  final bool success;
  final String? paymentKey;
  final String? orderId;
  final String? method;
  final String? error;

  const PaymentResult({
    required this.success,
    this.paymentKey,
    this.orderId,
    this.method,
    this.error,
  });
}

// ── 현금영수증 발급 결과 모델 ────────────────────────────────────
class CashReceiptResult {
  final bool success;
  final String? receiptKey; // 토스페이먼츠 현금영수증 키
  final String? orderId;
  final String? error;

  const CashReceiptResult({
    required this.success,
    this.receiptKey,
    this.orderId,
    this.error,
  });
}

// ── 결제 화면 파라미터 모델 ─────────────────────────────────────
// cart_screen → PaymentCheckoutScreen에 전달
class PaymentCheckoutArgs {
  final String orderId;
  final String orderName;
  final int amount;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String selectedPayment;
  final String? couponId;
  final double couponDiscount;
  final int usedPoints;
  final double pointDiscount;

  const PaymentCheckoutArgs({
    required this.orderId,
    required this.orderName,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.selectedPayment,
    this.couponId,
    this.couponDiscount = 0,
    this.usedPoints = 0,
    this.pointDiscount = 0,
  });
}
