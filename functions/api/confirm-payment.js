// Cloudflare Pages Function — 토스페이먼츠 결제 승인
// URL: https://2fit-mall.co.kr/api/confirm-payment
// 환경변수:
//   TOSS_SECRET_KEY      → 카드 결제 시크릿 키 (live_sk_...)
//   TOSS_EASY_SECRET_KEY → 간편결제 시크릿 키  (live_gsk_...)
//
// paymentKey 접두사로 자동 구분:
//   live_pay_ / test_pay_ → 카드  → TOSS_SECRET_KEY 사용
//   live_easyp_ 등        → 간편결제 → TOSS_EASY_SECRET_KEY 사용

export async function onRequestPost({ request, env }) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': 'https://2fit-mall.co.kr',
    'Access-Control-Allow-Methods': 'POST',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  try {
    const { paymentKey, orderId, amount } = await request.json();

    if (!paymentKey || !orderId || !amount) {
      return Response.json(
        { success: false, message: '필수 파라미터 누락' },
        { status: 400, headers: corsHeaders }
      );
    }

    // paymentKey 접두사로 카드 vs 간편결제 자동 구분
    // 카카오페이·네이버페이·토스페이 paymentKey는 'live_easyp_' 또는 'kakaopay_' 등으로 시작
    const isEasyPay = !paymentKey.startsWith('live_pay_') &&
                      !paymentKey.startsWith('test_pay_') &&
                      !paymentKey.startsWith('live_bil_') &&
                      !paymentKey.startsWith('test_bil_');

    const secretKey = isEasyPay
      ? (env.TOSS_EASY_SECRET_KEY || env.TOSS_SECRET_KEY) // gsk 키 우선, 없으면 sk 키 폴백
      : env.TOSS_SECRET_KEY;

    if (!secretKey) {
      return Response.json(
        { success: false, message: '서버 설정 오류 (시크릿 키 미등록)' },
        { status: 500, headers: corsHeaders }
      );
    }

    const credentials = btoa(`${secretKey}:`);

    const tossRes = await fetch('https://api.tosspayments.com/v1/payments/confirm', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ paymentKey, orderId, amount }),
    });

    const data = await tossRes.json();

    if (tossRes.ok) {
      return Response.json({ success: true, ...data }, { headers: corsHeaders });
    } else {
      return Response.json(
        { success: false, message: data.message ?? '결제 승인 실패' },
        { status: 400, headers: corsHeaders }
      );
    }
  } catch (e) {
    return Response.json(
      { success: false, message: `서버 오류: ${e.message}` },
      { status: 500, headers: corsHeaders }
    );
  }
}

export async function onRequestOptions() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': 'https://2fit-mall.co.kr',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
