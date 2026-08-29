// Cloudflare Pages Function — 토스페이먼츠 현금영수증 발급
// URL: https://2fit-mall.co.kr/api/issue-cash-receipt
// 환경변수: TOSS_SECRET_KEY (Cloudflare Pages 설정에서 추가)
//
// [type]
//   '소득공제' — 개인 소비자, 전화번호(010-XXXX-XXXX) or 주민등록번호 뒤 7자리
//   '지출증빙' — 사업자, 사업자번호 10자리
//
// 가상계좌·계좌이체는 토스페이먼츠가 자동 발급하므로 이 API 불필요.
// 카드·카카오페이·네이버페이·토스페이 결제 시 호출하세요.

const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://2fit-mall.co.kr',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json',
};

export async function onRequestPost({ request, env }) {
  try {
    const { paymentKey, customerIdentityNumber, type, taxFreeAmount } =
      await request.json();

    // 필수 파라미터 검증
    if (!paymentKey || !customerIdentityNumber || !type) {
      return Response.json(
        { success: false, message: '필수 파라미터 누락 (paymentKey, customerIdentityNumber, type)' },
        { status: 400, headers: corsHeaders }
      );
    }

    // type 유효성 검사
    if (type !== '소득공제' && type !== '지출증빙') {
      return Response.json(
        { success: false, message: "type은 '소득공제' 또는 '지출증빙'이어야 합니다." },
        { status: 400, headers: corsHeaders }
      );
    }

    const secretKey = env.TOSS_SECRET_KEY;
    if (!secretKey) {
      return Response.json(
        { success: false, message: '서버 설정 오류 (TOSS_SECRET_KEY 미등록)' },
        { status: 500, headers: corsHeaders }
      );
    }

    const credentials = btoa(`${secretKey}:`);

    // 요청 바디 구성
    const body = {
      customerIdentityNumber,
      type,
    };
    if (taxFreeAmount && taxFreeAmount > 0) {
      body.taxFreeAmount = taxFreeAmount;
    }

    // 토스페이먼츠 현금영수증 발급 API 호출
    const tossRes = await fetch(
      `https://api.tosspayments.com/v1/payments/${paymentKey}/cash-receipts`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${credentials}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      }
    );

    const data = await tossRes.json();

    if (tossRes.ok) {
      return Response.json(
        {
          success: true,
          receiptKey: data.receiptKey ?? null,
          orderId: data.orderId ?? null,
          type: data.type ?? type,
          issueNumber: data.issueNumber ?? null,
        },
        { headers: corsHeaders }
      );
    } else {
      // 이미 발급된 경우(중복 발급) 성공으로 처리
      if (data.code === 'ALREADY_REGISTERED_CASH_RECEIPT') {
        return Response.json(
          { success: true, alreadyIssued: true, message: '이미 발급된 현금영수증입니다.' },
          { headers: corsHeaders }
        );
      }
      return Response.json(
        { success: false, message: data.message ?? '현금영수증 발급 실패', code: data.code },
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
