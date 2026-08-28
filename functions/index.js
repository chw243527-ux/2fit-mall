// Firebase Cloud Functions - 2FIT Mall
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const crypto = require('crypto');

initializeApp();
const db = getFirestore();

const ADMIN_TOKENS_DOC = 'admin_config/fcm_tokens';

// Secret Manager values are available only to server-side Functions.
const SOLAPI_API_KEY = defineSecret('SOLAPI_API_KEY');
const SOLAPI_API_SECRET = defineSecret('SOLAPI_API_SECRET');
const SOLAPI_SENDER_PHONE = '01072276914';
// 카카오 알림톡 식별자는 비밀키가 아니지만, 클라이언트에 노출하지 않고 서버에서만 관리합니다.
const KAKAO_CHANNEL_ID = 'KA01PF2606170642574857w8Hjn9Czz4';
const KAKAO_ORDER_CONFIRMED_TEMPLATE_ID = 'KA01TP260617070446140hAHwuGcxCxF';
const KAKAO_CHAT_ALERT_TEMPLATE_ID = 'KA01TP260620035956868dCYREOJSYWF';
const NAVER_CLIENT_ID = 'RTeQb5TSs920qoowhcra';
const NAVER_CLIENT_SECRET = defineSecret('NAVER_CLIENT_SECRET');
const NAVER_ALLOWED_REDIRECTS = new Set([
  'https://2fit-mall.co.kr/naver_callback.html',
  'https://fit-mall.web.app/naver_callback.html',
  'http://localhost:5000/naver_callback.html',
]);

// ══════════════════════════════════════════════════════
// 1) 새 주문 접수 알림 (기존)
// ══════════════════════════════════════════════════════
exports.onNewOrder = onDocumentCreated(
  { document: 'orders/{orderId}', secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET] },
  async (event) => {
  const data = event.data?.data();
  if (!data) return;
  try {
    const tokens = await _getAdminTokens();
    if (tokens.length === 0) return;
    const amount = data.totalAmount ? `${_fmt(data.totalAmount)}원` : '';
    await _sendMulticast(tokens, {
      title: '🛒 새 주문 접수',
      body: `${data.userName || '고객'}님 주문${amount ? ' ' + amount : ''}`,
      data: { type: 'new_order', orderId: event.params.orderId },
    });
  } catch (e) { console.error('onNewOrder error:', e);   }
});

// ══════════════════════════════════════════════════════
// 2) 주문 상태 변경 알림 (기존)
// ══════════════════════════════════════════════════════
exports.onOrderStatusChanged = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before?.data();
  const after  = event.data?.after?.data();
  if (!before || !after) return;
  if (before.status === after.status) return;
  try {
    const userId = after.userId || '';
    if (!userId) return;
    const notifRef = db.collection('notifications').doc();
    await notifRef.set({
      id: notifRef.id,
      userId,
      title: '📦 주문 상태 변경',
      body: `주문이 "${after.status}" 상태로 변경되었습니다`,
      type: 'order_status',
      orderId: event.params.orderId,
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (e) { console.error('onOrderStatusChanged error:', e); }
});

// ══════════════════════════════════════════════════════
// 3) FCM 큐 처리 (기존)
// ══════════════════════════════════════════════════════
exports.processFcmQueue = onDocumentCreated('fcm_queue/{docId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  try {
    const { token, title, body, type } = data;
    if (!token) return;
    await getMessaging().send({
      token,
      notification: { title: title || '알림', body: body || '' },
      data: { type: type || 'general' },
    });
    await event.data.ref.delete();
  } catch (e) { console.error('processFcmQueue error:', e); }
});

// ══════════════════════════════════════════════════════
// 4) 프로모션 알림 (기존)
// ══════════════════════════════════════════════════════
exports.sendPromoNotification = onRequest(async (req, res) => {
  if (req.method !== 'POST') { res.status(405).send('Method Not Allowed'); return; }
  if (!(await requireAdmin(req, res))) return;
  try {
    const { title, body, targetGrade } = req.body;
    if (!title) { res.status(400).json({ error: 'title required' }); return; }
    await db.collection('broadcast_notifications').add({
      title, body: body || '', targetGrade: targetGrade || 'all',
      createdAt: FieldValue.serverTimestamp(),
    });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: String(e) }); }
});

// ══════════════════════════════════════════════════════
// 5) 테스트 알림 (기존)
// ══════════════════════════════════════════════════════
exports.sendTestNotification = onRequest(async (req, res) => {
  if (req.method !== 'POST') { res.status(405).send('Method Not Allowed'); return; }
  if (!(await requireAdmin(req, res))) return;
  try {
    const { token, title, body } = req.body;
    if (!token) { res.status(400).json({ error: 'token required' }); return; }
    await getMessaging().send({
      token,
      notification: { title: title || '테스트 알림', body: body || '알림이 정상 작동합니다!' },
    });
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: String(e) }); }
});

// ══════════════════════════════════════════════════════
// 6) 🆕 새 채팅 문의 → 관리자 FCM 푸시 알림
// ══════════════════════════════════════════════════════
exports.onNewChatMessage = onDocumentCreated(
  { document: 'chats/{roomId}/messages/{messageId}', secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET] },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (data.isAdmin === true) return; // 관리자 메시지 제외

    const senderName = data.senderName || '고객';
    const message    = data.message || data.text || '';
    if (!message.trim()) return;

    console.log(`💬 새 채팅: ${senderName} → ${message.substring(0, 50)}`);

    try {
      const tokens = await _getAdminTokens();
      if (tokens.length === 0) {
        console.log('관리자 토큰 없음 - 알림톡은 계속 발송합니다');
      } else {
        const msgShort = message.length > 60 ? message.substring(0, 60) + '...' : message;
        await _sendMulticast(tokens, {
          title: `💬 ${senderName}님의 채팅 문의`,
          body: msgShort,
          data: {
            type: 'chat',
            roomId: event.params.roomId,
            click_action: 'https://2fit-mall.co.kr/#/admin?tab=chat',
          },
        });
      }
    } catch (e) { console.error('onNewChatMessage FCM error:', e); }

    // 채팅 문서가 저장된 뒤 서버에서 알림톡을 발송합니다.
    // 클라이언트의 FirebaseAuth 상태나 브라우저 캐시에 의존하지 않습니다.
    try {
      const result = await _sendSolapiAlimtalk({
        phone: SOLAPI_ADMIN_PHONE,
        templateId: KAKAO_CHAT_ALERT_TEMPLATE_ID,
        variables: {
          '#{고객명}': String(senderName).slice(0, 80),
          '#{시간}': _formatKstTime(new Date()),
          '#{주문번호}': '최근 주문 없음',
          '#{메시지}': message.trim().slice(0, 500),
        },
      });
      console.log(`채팅 알림톡 처리 결과: ${result.ok ? 'accepted' : 'rejected'} (${result.statusCode})`);
    } catch (e) { console.error('onNewChatMessage Alimtalk error:', e); }
  }
);

// ══════════════════════════════════════════════════════
// 7) 🆕 관리자 FCM 토큰 자동 등록
// ══════════════════════════════════════════════════════
exports.registerAdminToken = onDocumentCreated(
  'admin_fcm_tokens/{docId}',
  async (event) => {
    const data = event.data?.data();
    if (!data?.token) return;
    const newToken = data.token;
    try {
      const tokensDoc = await db.doc(ADMIN_TOKENS_DOC).get();
      let tokens = tokensDoc.data()?.tokens || [];
      tokens = tokens.filter(t => t !== newToken);
      tokens.push(newToken);
      if (tokens.length > 10) tokens = tokens.slice(-10);
      await db.doc(ADMIN_TOKENS_DOC).set({ tokens, updatedAt: new Date() });
      console.log(`✅ 관리자 토큰 저장 완료 (총 ${tokens.length}개)`);
      await event.data.ref.delete();
    } catch (e) { console.error('registerAdminToken error:', e); }
  }
);

// ══════════════════════════════════════════════════════
// 8) 포인트 1년 만료 처리 및 사전 안내
// 매일 새벽 실행: 만료 포인트를 소멸하고 30일 이내 만료 예정분을 알립니다.
// ══════════════════════════════════════════════════════
exports.expireUserPointsDaily = onSchedule('every day 03:10', async () => {
  const now = new Date();
  const noticeUntil = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  const usersSnap = await db.collection('users').get();
  let expiredCount = 0;
  let noticeCount = 0;

  for (const userDoc of usersSnap.docs) {
    const userRef = userDoc.ref;
    const historyRef = userRef.collection('point_history');
    // 기존 이력에는 expiresAt이 없을 수 있으므로 최근 이력을 읽어
    // 적립일 + 1년을 만료일로 보정한 뒤 서버에서 함께 처리합니다.
    const pendingSnap = await historyRef
      .orderBy('createdAt', 'desc')
      .limit(200)
      .get();

    for (const sourceDoc of pendingSnap.docs) {
      const source = sourceDoc.data();
      const amount = Number(source.amount || 0);
      const action = source.action || 'earn';
      const createdAt = source.createdAt?.toDate?.();
      const expiresAt = source.expiresAt?.toDate?.() ||
        (createdAt ? new Date(createdAt.getTime() + 365 * 24 * 60 * 60 * 1000) : null);
      if (amount <= 0 || !expiresAt || (action !== 'earn' && action !== 'admin')) continue;

      const daysLeft = Math.ceil((expiresAt.getTime() - now.getTime()) / 86400000);
      if (daysLeft >= 0 && daysLeft <= 30) {
        const noticeRef = historyRef.doc(`expiry_notice_${sourceDoc.id}`);
        const noticeSnap = await noticeRef.get();
        if (!noticeSnap.exists) {
          await db.collection('notifications').add({
            userId: userDoc.id,
            title: '포인트 소멸 예정 안내',
            body: `${amount.toLocaleString('ko-KR')}P가 ${expiresAt.getFullYear()}.${expiresAt.getMonth() + 1}.${expiresAt.getDate()}에 소멸 예정입니다.`,
            type: 'point_expiry',
            isRead: false,
            createdAt: FieldValue.serverTimestamp(),
          });
          await noticeRef.set({ action: 'expiry_notice', sourceId: sourceDoc.id, createdAt: FieldValue.serverTimestamp() });
          noticeCount++;
        }
      }

      if (expiresAt <= now) {
        const expireRef = historyRef.doc(`expire_${sourceDoc.id}`);
        await db.runTransaction(async (tx) => {
          if ((await tx.get(expireRef)).exists) return;
          const latestUser = await tx.get(userRef);
          const balance = Number(latestUser.data()?.points || 0);
          const expireAmount = Math.max(0, Math.min(balance, amount));
          if (expireAmount <= 0) return;
          tx.update(userRef, { points: balance - expireAmount });
          tx.set(expireRef, {
            action: 'expire',
            amount: -expireAmount,
            desc: `${expiresAt.getFullYear()}.${expiresAt.getMonth() + 1}.${expiresAt.getDate()} 적립 포인트 기간 만료 소멸`,
            orderId: source.orderId || null,
            createdAt: FieldValue.serverTimestamp(),
          });
          expiredCount++;
        });
      }
    }
  }
  console.log(`Point expiry completed: expired=${expiredCount}, notices=${noticeCount}`);
});

// ══════════════════════════════════════════════════════
// HTTP 관리자 인증
// ══════════════════════════════════════════════════════
async function requireAdmin(req, res) {
  const header = req.get('authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: 'Missing Firebase ID token' });
    return false;
  }

  try {
    const decoded = await getAuth().verifyIdToken(match[1]);
    const profile = await db.collection('users').doc(decoded.uid).get();
    const isAdmin = decoded.isAdmin === true || profile.data()?.isAdmin === true;
    if (!isAdmin) {
      res.status(403).json({ error: 'Admin access required' });
      return false;
    }
    return true;
  } catch (error) {
    console.error('HTTP admin authentication failed:', error);
    res.status(401).json({ error: 'Invalid or expired Firebase ID token' });
    return false;
  }
}

// ══════════════════════════════════════════════════════
// 8) 서버 전용 Naver OAuth
// ══════════════════════════════════════════════════════
exports.startNaverOAuth = onRequest(
  { secrets: [NAVER_CLIENT_SECRET], cors: [
    'https://2fit-mall.co.kr',
    'https://fit-mall.web.app',
    'http://localhost:5000',
  ] },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }
    const redirectUri = String(req.body?.redirectUri || '');
    if (!NAVER_ALLOWED_REDIRECTS.has(redirectUri)) {
      res.status(400).json({ error: 'Invalid redirect URI' });
      return;
    }
    const nonce = crypto.randomBytes(24).toString('base64url');
    const issuedAt = Date.now().toString();
    const payload = `${issuedAt}.${nonce}.${redirectUri}`;
    const signature = crypto
      .createHmac('sha256', NAVER_CLIENT_SECRET.value())
      .update(payload)
      .digest('base64url');
    const state = `${issuedAt}.${nonce}.${signature}`;
    const params = new URLSearchParams({
      response_type: 'code',
      client_id: NAVER_CLIENT_ID,
      redirect_uri: redirectUri,
      state,
    });
    res.json({
      authorizeUrl: `https://nid.naver.com/oauth2.0/authorize?${params}`,
      state,
    });
  }
);

exports.exchangeNaverCode = onRequest(
  { secrets: [NAVER_CLIENT_SECRET], cors: [
    'https://2fit-mall.co.kr',
    'https://fit-mall.web.app',
    'http://localhost:5000',
  ] },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }
    const code = String(req.body?.code || '');
    const state = String(req.body?.state || '');
    const redirectUri = String(req.body?.redirectUri || '');
    if (!code || !state || !NAVER_ALLOWED_REDIRECTS.has(redirectUri)) {
      res.status(400).json({ error: 'code, state, and redirectUri are required' });
      return;
    }
    try {
      const stateParts = state.split('.');
      if (stateParts.length !== 3) throw new Error('Invalid state');
      const [issuedAt, nonce, signature] = stateParts;
      const issuedMs = Number(issuedAt);
      if (!Number.isFinite(issuedMs) || Date.now() - issuedMs > 10 * 60 * 1000) {
        throw new Error('Expired state');
      }
      const payload = `${issuedAt}.${nonce}.${redirectUri}`;
      const expected = crypto
        .createHmac('sha256', NAVER_CLIENT_SECRET.value())
        .update(payload)
        .digest('base64url');
      if (signature.length !== expected.length ||
          !crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
        throw new Error('Invalid state signature');
      }

      const tokenParams = new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: NAVER_CLIENT_ID,
        client_secret: NAVER_CLIENT_SECRET.value(),
        code,
        state,
      });
      const tokenResponse = await fetch(
        `https://nid.naver.com/oauth2.0/token?${tokenParams}`,
        { headers: { Accept: 'application/json' } }
      );
      const token = await tokenResponse.json();
      if (!tokenResponse.ok || !token.access_token) {
        console.error('Naver token exchange failed:', token.error || tokenResponse.status);
        res.status(401).json({ error: 'Naver authorization failed' });
        return;
      }

      const profileResponse = await fetch('https://openapi.naver.com/v1/nid/me', {
        headers: { Authorization: `Bearer ${token.access_token}` },
      });
      const profile = await profileResponse.json();
      const naver = profile?.response;
      if (!profileResponse.ok || !naver?.id) {
        res.status(401).json({ error: 'Naver profile lookup failed' });
        return;
      }

      const email = String(naver.email || `${naver.id}@naver.com`).toLowerCase();
      const name = String(naver.name || '네이버 사용자').slice(0, 100);
      const photoUrl = String(naver.profile_image || '').slice(0, 2000);
      const user = await _getOrCreateNaverUser({
        naverId: String(naver.id), email, name, photoUrl,
      });
      const customToken = await getAuth().createCustomToken(user.uid, {
        provider: 'naver',
        naverId: String(naver.id),
      });
      res.json({ customToken });
    } catch (error) {
      console.error('exchangeNaverCode error:', error.message);
      res.status(500).json({ error: 'Naver login failed' });
    }
  }
);

// ══════════════════════════════════════════════════════
// 9) 서버 전용 SOLAPI 알림 발송
// ══════════════════════════════════════════════════════
const SOLAPI_ADMIN_PHONE = '01072276914';
const ALLOWED_ORDER_NOTIFICATION_KINDS = new Set([
  'order_confirmed', 'shipped', 'delivered', 'cancelled',
]);

async function requireSignedIn(req, res) {
  const header = req.get('authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: 'Missing Firebase ID token' });
    return null;
  }
  try {
    return await getAuth().verifyIdToken(match[1]);
  } catch (error) {
    console.error('HTTP authentication failed:', error.message);
    res.status(401).json({ error: 'Invalid or expired Firebase ID token' });
    return null;
  }
}

exports.sendSolapiChatAlert = onRequest(
  { secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET], cors: [
    'https://2fit-mall.co.kr', 'https://fit-mall.web.app', 'http://localhost:5000',
  ] },
  async (req, res) => {
    if (req.method !== 'POST') { res.status(405).json({ error: 'Method Not Allowed' }); return; }
    if (!(await requireSignedIn(req, res))) return;
    const userName = String(req.body?.userName || '고객').slice(0, 80);
    const message = String(req.body?.message || '').trim().slice(0, 500);
    const language = String(req.body?.language || 'KO').slice(0, 10);
    if (!message) { res.status(400).json({ error: 'message is required' }); return; }
    const result = await _sendSolapiAlimtalk({
      phone: SOLAPI_ADMIN_PHONE,
      templateId: KAKAO_CHAT_ALERT_TEMPLATE_ID,
      variables: {
        '#{고객명}': userName,
        '#{시간}': _formatKstTime(new Date()),
        '#{주문번호}': '최근 주문 없음',
        '#{메시지}': `[${language}] ${message}`.slice(0, 500),
      },
    });
        res.status(result.ok ? 200 : 502).json({ success: result.ok, statusCode: result.statusCode });
  },
);
// 채팅 알림 전용 이름으로도 노출해 구형 SMS 호출 경로와 명확히 분리합니다.
exports.sendSolapiChatAlimtalk = exports.sendSolapiChatAlert;
exports.sendSolapiOrderNotification = onRequest(
  { secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET], cors: [
    'https://2fit-mall.co.kr', 'https://fit-mall.web.app', 'http://localhost:5000',
  ] },
  async (req, res) => {
    if (req.method !== 'POST') { res.status(405).json({ error: 'Method Not Allowed' }); return; }
    const decoded = await requireSignedIn(req, res);
    if (!decoded) return;
    const orderId = String(req.body?.orderId || '');
    const kind = String(req.body?.kind || '');
    const params = req.body?.params && typeof req.body.params === 'object' ? req.body.params : {};
    if (!orderId || !ALLOWED_ORDER_NOTIFICATION_KINDS.has(kind)) {
      res.status(400).json({ error: 'Valid orderId and notification kind are required' }); return;
    }
    const orderSnap = await db.collection('orders').doc(orderId).get();
    if (!orderSnap.exists) { res.status(404).json({ error: 'Order not found' }); return; }
    const order = orderSnap.data();
    const profile = await db.collection('users').doc(decoded.uid).get();
    const isAdminUser = decoded.isAdmin === true || profile.data()?.isAdmin === true;
    if (!isAdminUser && order.userId !== decoded.uid) {
      res.status(403).json({ error: 'Order access denied' }); return;
    }
    const phone = String(order.userPhone || '').replace(/[^0-9+]/g, '');
    if (!/^\+?[0-9]{8,15}$/.test(phone)) {
      res.status(400).json({ error: 'Order phone is invalid' }); return;
    }
    const items = Array.isArray(order.items) ? order.items : [];
    const itemSummary = items.length ? `${items[0].productName || '상품'}${items.length > 1 ? ` 외 ${items.length - 1}건` : ''}` : '상품';
    const name = String(order.userName || '고객').slice(0, 80);
    const number = orderId.slice(0, 80);
    if (kind === 'order_confirmed') {
      const result = await _sendSolapiAlimtalk({
        phone,
        templateId: KAKAO_ORDER_CONFIRMED_TEMPLATE_ID,
        variables: {
          '#{고객명}': name,
          '#{주문번호}': number,
          '#{상품명}': itemSummary.slice(0, 100),
          '#{결제금액}': Number(order.totalAmount || 0).toLocaleString(),
          '#{결제수단}': String(order.paymentMethod || '-').slice(0, 40),
          '#{배송주소}': String(order.userAddress || order.deliveryAddress || '-').slice(0, 200),
        },
      });
      res.status(result.ok ? 200 : 502).json({ success: result.ok, statusCode: result.statusCode });
      return;
    }
    let text;
    if (kind === 'shipped') {
      text = `[2FIT MALL] ${name}님 상품이 발송되었습니다. 주문번호: ${number}, 택배사: ${String(params.courierName || '').slice(0, 60)}, 운송장번호: ${String(params.trackingNumber || '').slice(0, 80)}`;
    } else if (kind === 'delivered') {
      text = `[2FIT MALL] ${name}님 상품이 배송 완료되었습니다. 주문번호: ${number}, 상품: ${itemSummary}`;
    } else {
      text = `[2FIT MALL] ${name}님 주문이 취소되었습니다. 주문번호: ${number}, 사유: ${String(params.reason || '').slice(0, 200)}`;
    }
    const result = await _sendSolapiSms(phone, text);
    res.status(result.ok ? 200 : 502).json({ success: result.ok, statusCode: result.statusCode });
  },
);

// ══════════════════════════════════════════════════════
// 9) 서버 전용 SOLAPI SMS 발송 (관리자만)
// ══════════════════════════════════════════════════════
exports.sendSolapiSms = onRequest(
  { secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET] },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }
    if (!(await requireAdmin(req, res))) return;

    const phone = String(req.body?.phone || '').replace(/[^0-9+]/g, '');
    const text = String(req.body?.text || '').trim();
    if (!/^\+?[0-9]{8,15}$/.test(phone) || !text || text.length > 2000) {
      res.status(400).json({ error: 'Valid phone and text are required' });
      return;
    }

    try {
      const result = await _sendSolapiSms(phone, text);
      res.status(result.ok ? 200 : 502).json({
        success: result.ok,
        statusCode: result.statusCode,
      });
    } catch (error) {
      console.error('sendSolapiSms error:', error);
      res.status(500).json({ error: 'SMS delivery failed' });
    }
  }
);

// ══════════════════════════════════════════════════════
// 헬퍼 함수들
// ══════════════════════════════════════════════════════
async function _getOrCreateNaverUser({ naverId, email, name, photoUrl }) {
  let user;
  try {
    user = await getAuth().getUserByEmail(email);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    user = await getAuth().createUser({ email, displayName: name, photoURL: photoUrl || undefined });
  }
  const userRef = db.collection('users').doc(user.uid);
  const existing = await userRef.get();
  const data = existing.data() || {};
  const userData = {
    id: user.uid,
    name,
    email,
    phone: data.phone || '',
    profileImageUrl: photoUrl || data.profileImageUrl || '',
    grade: data.grade || 'bronze',
    memberTier: data.memberTier || data.grade || 'bronze',
    isAdmin: data.isAdmin === true,
    points: Number.isFinite(data.points) ? data.points : 0,
    coupons: Array.isArray(data.coupons) ? data.coupons : [],
    wishlist: Array.isArray(data.wishlist) ? data.wishlist : [],
    loginProvider: 'naver',
    naverId,
    ...(existing.exists ? { lastLoginAt: FieldValue.serverTimestamp() } :
      { createdAt: FieldValue.serverTimestamp() }),
  };
  await userRef.set(userData, { merge: true });
  return user;
}

async function _getAdminTokens() {
  const doc = await db.doc(ADMIN_TOKENS_DOC).get();
  return (doc.data()?.tokens || []).filter(t => t && t.length > 10);
}

async function _sendMulticast(tokens, { title, body, data: msgData = {} }) {
  if (tokens.length === 0) return;
  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: msgData,
    android: { notification: { channelId: 'chat_alerts', priority: 'high', sound: 'default' } },
    apns:    { payload: { aps: { sound: 'default', badge: 1 } } },
    webpush: {
      notification: { icon: 'https://2fit-mall.co.kr/icons/Icon-192.png', requireInteraction: true },
      fcmOptions: { link: 'https://2fit-mall.co.kr/#/admin?tab=chat' },
    },
  });
  console.log(`FCM: 성공 ${response.successCount}, 실패 ${response.failureCount}`);

  // 만료 토큰 제거
  const invalid = [];
  response.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error?.code;
      if (code === 'messaging/invalid-registration-token' ||
          code === 'messaging/registration-token-not-registered') {
        invalid.push(tokens[i]);
      }
    }
  });
  if (invalid.length > 0) {
    const valid = tokens.filter(t => !invalid.includes(t));
    await db.doc(ADMIN_TOKENS_DOC).set({ tokens: valid }, { merge: true });
    console.log(`만료 토큰 ${invalid.length}개 제거`);
  }
}

async function _sendSolapiAlimtalk({ phone, templateId, variables }) {
  const date = new Date().toISOString();
  const salt = crypto.randomBytes(16).toString('hex');
  const signature = crypto
    .createHmac('sha256', SOLAPI_API_SECRET.value())
    .update(`${date}${salt}`)
    .digest('hex');
  const response = await fetch('https://api.solapi.com/messages/v4/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      Authorization: `HMAC-SHA256 apiKey=${SOLAPI_API_KEY.value()}, date=${date}, salt=${salt}, signature=${signature}`,
    },
    body: JSON.stringify({
      messages: [{
        to: phone,
        // disableSms=true이므로 차단된 기존 번호는 대체 SMS 발신에 사용되지 않습니다.
        from: SOLAPI_SENDER_PHONE,
        kakaoOptions: {
          pfId: KAKAO_CHANNEL_ID,
          templateId,
          disableSms: true,
          variables,
        },
      }],
    }),
  });
  const responseText = await response.text();
  if (!response.ok) {
    console.error('SOLAPI Alimtalk request rejected:', response.status, responseText.slice(0, 500));
  } else {
    console.log('SOLAPI Alimtalk request accepted:', response.status);
  }
  return { ok: response.ok, statusCode: response.status };
}

async function _sendSolapiSms(phone, text) {
  const date = new Date().toISOString();
  const salt = crypto.randomBytes(16).toString('hex');
  const signature = crypto
    .createHmac('sha256', SOLAPI_API_SECRET.value())
    .update(`${date}${salt}`)
    .digest('hex');

  const response = await fetch('https://api.solapi.com/messages/v4/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      Authorization: `HMAC-SHA256 apiKey=${SOLAPI_API_KEY.value()}, date=${date}, salt=${salt}, signature=${signature}`,
    },
    body: JSON.stringify({
      message: {
        to: phone,
        from: SOLAPI_SENDER_PHONE,
        type: text.length > 90 ? 'LMS' : 'SMS',
        text,
      },
    }),
  });

  const responseText = await response.text();
  if (!response.ok) {
    // API 자격증명·메시지 본문은 로그에 남기지 않고 상태와 응답 코드만 기록합니다.
    console.error('SOLAPI request rejected:', response.status, responseText.slice(0, 500));
  } else {
    console.log('SOLAPI request accepted:', response.status);
  }
  return { ok: response.ok, statusCode: response.status };
}

function _formatKstTime(date) {
  return new Intl.DateTimeFormat('ko-KR', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(date).replace(/\. /g, '.').replace(/\.$/, '');
}

function _fmt(n) {
  return Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
