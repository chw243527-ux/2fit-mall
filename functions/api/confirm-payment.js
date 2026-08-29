// Cloudflare Pages Function — 토스페이먼츠 결제 승인
// URL: https://2fit-mall.co.kr/api/confirm-payment
// 환경변수: TOSS_SECRET_KEY (Cloudflare Pages 설정에서 추가)

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

    const secretKey = env.TOSS_SECRET_KEY;
    if (!secretKey) {
      return Response.json(
        { success: false, message: '서버 설정 오류' },
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
