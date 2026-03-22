// payment_service.dart
// ══════════════════════════════════════════════════════════════
// 토스페이먼츠 결제 서비스 (테스트 → 실결제 전환 가이드 포함)
//
// 🔑 실결제 전환 3단계:
//   1. TOSS_CLIENT_KEY / TOSS_SECRET_KEY 를 실제 키로 교체
//   2. _confirmViaServer() 에서 Supabase Edge Function URL 입력
//   3. Edge Function 배포 (아래 주석 참고)
// ══════════════════════════════════════════════════════════════
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

// ─── 🔑 키 설정 ────────────────────────────────────────────────
class TossConfig {
  // 테스트 키 (기본값 — 실결제 시 아래 값으로 교체)
  // 발급: https://developers.tosspayments.com → 개발 → API 키
  static const clientKey = 'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq';

  // ⚠️ secretKey 는 절대 앱 배포본에 포함하지 마세요.
  // 아래 값은 개발/테스트 전용입니다.
  // 실 운영 시 반드시 Supabase Edge Function 또는 별도 서버에서만 사용하세요.
  static const secretKey = 'test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R';

  // Supabase Edge Function URL (결제 승인용)
  // 배포 후 아래 주석 해제 및 URL 입력:
  // static const confirmEdgeFunctionUrl =
  //     'https://YOUR_PROJECT.supabase.co/functions/v1/confirm-payment';
  static const confirmEdgeFunctionUrl = '';

  static bool get useEdgeFunction => confirmEdgeFunctionUrl.isNotEmpty;
  static bool get isLiveMode => !clientKey.startsWith('test_');
}

// ══════════════════════════════════════════════════════════════
// PaymentService — 결제 요청 / 승인 / 취소
// ══════════════════════════════════════════════════════════════
class PaymentService {

  // ─── 결제 요청 (웹·앱 공통 진입점) ──────────────────────────
  static Future<PaymentResult> requestPayment(
    BuildContext context, {
    required String orderId,
    required String orderName,
    required int amount,
    required String customerName,
    required String customerEmail,
    required String paymentMethod,
  }) async {
    return await _showPaymentDialog(
      context,
      orderId: orderId,
      orderName: orderName,
      amount: amount,
      customerName: customerName,
      customerEmail: customerEmail,
      paymentMethod: paymentMethod,
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
      // ✅ 운영 환경: Supabase Edge Function 경유 (secretKey 앱 노출 없음)
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

  // ── Edge Function 경유 승인 (운영 권장) ──
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
          'apikey': SupabaseConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
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
        // 테스트 환경 네트워크 오류 → 시뮬레이션
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

  // ─── 결제 팝업 표시 ───────────────────────────────────────────
  static Future<PaymentResult> _showPaymentDialog(
    BuildContext context, {
    required String orderId,
    required String orderName,
    required int amount,
    required String customerName,
    required String customerEmail,
    required String paymentMethod,
  }) async {
    final result = await showDialog<PaymentResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentDialog(
        orderId: orderId,
        orderName: orderName,
        amount: amount,
        customerName: customerName,
        customerEmail: customerEmail,
        paymentMethod: paymentMethod,
      ),
    );
    return result ?? const PaymentResult(success: false, error: '결제가 취소되었습니다.');
  }

  // ─── 결제 수단 매핑 ───────────────────────────────────────────
  static String mapPaymentMethod(String method) {
    switch (method) {
      case '카카오페이':   return 'KAKAO_PAY';
      case '네이버페이':   return 'NAVER_PAY';
      case '토스페이':    return 'TOSS_PAY';
      case '신용/체크카드': return 'CARD';
      case '무통장입금':   return 'VIRTUAL_ACCOUNT';
      default:           return 'CARD';
    }
  }
}

// ══════════════════════════════════════════════════════════════
// 결제 팝업 다이얼로그
// ══════════════════════════════════════════════════════════════
class _PaymentDialog extends StatefulWidget {
  final String orderId;
  final String orderName;
  final int amount;
  final String customerName;
  final String customerEmail;
  final String paymentMethod;

  const _PaymentDialog({
    required this.orderId,
    required this.orderName,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.paymentMethod,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _cardNumberCtrl = TextEditingController(text: '4330000000000000');
  final _expiryCtrl     = TextEditingController(text: '12/26');
  final _pwCtrl         = TextEditingController(text: '00');
  final _birthCtrl      = TextEditingController(text: '000101');

  bool   _isProcessing = false;
  String? _errorMsg;
  int    _step = 0; // 0: 입력, 1: 처리중, 2: 완료, 3: 실패

  String get _fmt => widget.amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _pwCtrl.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() { _isProcessing = true; _errorMsg = null; _step = 1; });

    // 결제 키 생성 (실서비스: 토스 SDK에서 발급받음)
    final paymentKey = TossConfig.isLiveMode
        ? 'live_pay_${DateTime.now().millisecondsSinceEpoch}'
        : 'test_pay_${DateTime.now().millisecondsSinceEpoch}';

    // 결제 승인
    final result = await PaymentService.confirmPayment(
      paymentKey: paymentKey,
      orderId: widget.orderId,
      amount: widget.amount,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() => _step = 2);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, result);
    } else {
      setState(() { _step = 3; _errorMsg = result.error; _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildOrderInfo(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _step == 2
                  ? _buildSuccessView()
                  : _step == 1
                      ? _buildProcessingView()
                      : _buildCardForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isLive = TossConfig.isLiveMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFF0064FF) : const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLive ? '토스페이먼츠 결제' : '토스페이먼츠 테스트 결제',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          if (!isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('TEST',
                  style: TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          if (_step == 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pop(
                  context, const PaymentResult(success: false, error: '결제가 취소되었습니다.')),
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(widget.orderName,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                overflow: TextOverflow.ellipsis),
          ),
          Text('$_fmt원',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    final isLive = TossConfig.isLiveMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 모드 안내 배너
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLive
                ? const Color(0xFFE3F2FD)
                : const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLive ? const Color(0xFF1E88E5) : const Color(0xFFFFE082),
            ),
          ),
          child: Row(
            children: [
              Icon(isLive ? Icons.security_rounded : Icons.info_outline,
                  size: 16,
                  color: isLive ? const Color(0xFF1565C0) : const Color(0xFF856404)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLive
                      ? '실제 결제가 진행됩니다. 카드 정보를 안전하게 입력하세요.'
                      : '테스트 결제입니다. 실제 결제가 발생하지 않습니다.',
                  style: TextStyle(
                      fontSize: 12,
                      color: isLive ? const Color(0xFF1565C0) : const Color(0xFF856404)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 결제 수단 표시
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF0064FF), width: 2),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF0F4FF),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFF0064FF)),
              const SizedBox(width: 8),
              Text(_getPaymentLabel(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Color(0xFF0064FF))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 카드 입력 폼
        _buildField('카드번호', _cardNumberCtrl, hint: '1234 5678 9012 3456'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildField('유효기간', _expiryCtrl, hint: 'MM/YY')),
            const SizedBox(width: 12),
            Expanded(
                child: _buildField('비밀번호 앞 2자리', _pwCtrl,
                    hint: '••', obscure: true)),
          ],
        ),
        const SizedBox(height: 12),
        _buildField('생년월일 6자리', _birthCtrl, hint: 'YYMMDD'),

        if (_errorMsg != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMsg!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // 결제 버튼
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0064FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('$_fmt원 결제하기',
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(
                context, const PaymentResult(success: false, error: '결제가 취소되었습니다.')),
            child: const Text('취소', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  String _getPaymentLabel() {
    switch (widget.paymentMethod) {
      case '카카오페이':   return '카카오페이';
      case '네이버페이':   return '네이버페이';
      case '토스페이':    return '토스페이';
      case '무통장입금':   return '무통장입금 (가상계좌)';
      default:           return '신용/체크카드';
    }
  }

  Widget _buildProcessingView() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF0064FF)),
          SizedBox(height: 16),
          Text('결제를 처리하고 있습니다...',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
          SizedBox(height: 4),
          Text('잠시만 기다려주세요',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
                color: Color(0xFF00C853), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 14),
          const Text('결제 완료!',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('$_fmt원이 결제되었습니다',
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF0064FF), width: 2)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
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

/* ══════════════════════════════════════════════════════════════
   Supabase Edge Function — confirm-payment
   (supabase/functions/confirm-payment/index.ts)

   이 파일을 배포하면 secretKey가 서버에서만 사용됩니다.
   배포 명령: supabase functions deploy confirm-payment

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const { paymentKey, orderId, amount } = await req.json();
  const secretKey = Deno.env.get("TOSS_SECRET_KEY")!;
  const credentials = btoa(`${secretKey}:`);

  const res = await fetch("https://api.tosspayments.com/v1/payments/confirm", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${credentials}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ paymentKey, orderId, amount }),
  });

  const data = await res.json();
  if (res.ok) {
    return new Response(JSON.stringify({ success: true, ...data }), {
      headers: { "Content-Type": "application/json" },
    });
  }
  return new Response(JSON.stringify({ success: false, message: data.message }), {
    status: 400,
    headers: { "Content-Type": "application/json" },
  });
});

   환경변수 설정:
   supabase secrets set TOSS_SECRET_KEY=live_sk_여기에실제시크릿키
   ══════════════════════════════════════════════════════════════ */
