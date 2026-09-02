// Firebase Cloud Functions - 2FIT Mall
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret, defineString } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');
const crypto = require('crypto');
// Custom Token 서명 계정을 명시해 Functions 기본 계정 선택 불일치를 방지합니다.
const FIREBASE_TOKEN_SIGNER = 'firebase-adminsdk-fbsvc@fit-mall.iam.gserviceaccount.com';
initializeApp({ serviceAccountId: FIREBASE_TOKEN_SIGNER });
const db = getFirestore();

const ADMIN_TOKENS_DOC = 'admin_config/fcm_tokens';
// Secret Manager values are available only to server-side Functions.
const SOLAPI_API_KEY = defineSecret('SOLAPI_API_KEY');
const SOLAPI_API_SECRET = defineSecret('SOLAPI_API_SECRET');
const SOLAPI_SENDER_PHONE = '01072276914';
// 단체주문 접수 알림톡 템플릿은 카카오 검수 승인 후 Secret/환경설정으로 등록합니다.
const KAKAO_GROUP_ORDER_TEMPLATE_ID = defineString('KAKAO_GROUP_ORDER_TEMPLATE_ID', { default: '' });
// 1년 독점 만료 7일 전 알림톡 템플릿은 카카오 검수 승인 후 등록합니다.
// 템플릿이 아직 없으면 앱 알림과 이메일을 먼저 발송합니다.
const KAKAO_EXCLUSIVE_RENEWAL_TEMPLATE_ID = defineString('KAKAO_EXCLUSIVE_RENEWAL_TEMPLATE_ID', { default: '__UNCONFIGURED__' });
// 이메일 발송은 Resend API를 사용하며 API 키는 Firebase Secret Manager에서만 읽습니다.
const RESEND_API_KEY = defineSecret('RESEND_API_KEY');
const RESEND_FROM_EMAIL = defineString('RESEND_FROM_EMAIL', {
  default: '2FIT MALL <no-reply@2fit-mall.co.kr>',
});
// 토스 결제 비밀키는 Firebase Secret Manager에만 저장합니다.
const TOSS_SECRET_KEY = defineSecret('TOSS_SECRET_KEY');
// 카카오 알림톡 식별자는 비밀키가 아니지만, 클라이언트에 노출하지 않고 서버에서만 관리합니다.
const KAKAO_CHANNEL_ID = 'KA01PF2606170642574857w8Hjn9Czz4';
const KAKAO_ORDER_CONFIRMED_TEMPLATE_ID = 'KA01TP260617070446140hAHwuGcxCxF';
const KAKAO_CHAT_ALERT_TEMPLATE_ID = 'KA01TP260620035956868dCYREOJSYWF';
const KAKAO_CUSTOMER_CHAT_REPLY_TEMPLATE_ID = 'KA01TP260828143138157dXaG933iQOm';
// 관리자 알림 수신번호. 현재 등록된 SOLAPI 발신번호를 관리자 번호로 사용합니다.
const SOLAPI_ADMIN_PHONE = SOLAPI_SENDER_PHONE;
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
  {
    document: 'orders/{orderId}',
    secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET, RESEND_API_KEY],
  },
  async (event) => {
  const data = event.data?.data();
  if (!data) return;
  try {
    // 관리자 FCM 토큰이 없어도 고객용 단체주문 알림은 독립적으로 처리합니다.
    await _sendGroupOrderReceiptNotifications({
      orderId: event.params.orderId,
      data,
    });
    const tokens = await _getAdminTokens();
    if (tokens.length > 0) {
      const amount = data.totalAmount ? `${_fmt(data.totalAmount)}원` : '';
      await _sendMulticast(tokens, {
        title: '🛒 새 주문 접수',
        body: `${data.userName || '고객'}님 주문${amount ? ' ' + amount : ''}`,
        data: { type: 'new_order', orderId: event.params.orderId },
      });
    }
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
exports.sendTestNotification = onRequest(
  { cors: ['https://2fit-mall.co.kr', 'https://fit-mall.web.app', 'http://localhost:5000'], minInstances: 1 },
  async (req, res) => {
  if (req.method !== 'POST') { res.status(405).send('Method Not Allowed'); return; }
  if (!(await requireAdmin(req, res))) return;
  try {
    const { token, title, body } = req.body;
    if (!token) { res.status(400).json({ error: 'token required' }); return; }
    const notificationTitle = title || '테스트 알림';
    const notificationBody = body || '알림이 정상 작동합니다!';
    const startedAt = Date.now();
    const sentAt = new Date().toISOString();
    await getMessaging().send({
      token,
      notification: { title: notificationTitle, body: notificationBody },
      // 웹 FCM이 모바일·PC Service Worker에 표시 정보를 명시적으로 전달하도록 합니다.
      data: {
        title: notificationTitle,
        body: notificationBody,
        type: 'test',
        sentAt,
      },
      webpush: {
        headers: { Urgency: 'high' },
        notification: {
          title: notificationTitle,
          body: notificationBody,
          icon: 'https://2fit-mall.co.kr/icons/Icon-192.png',
          badge: 'https://2fit-mall.co.kr/icons/Icon-192.png',
          tag: '2fit-test-notification',
        },
        fcmOptions: { link: 'https://2fit-mall.co.kr/' },
      },
    });
    res.json({ success: true, sentAt, serverDurationMs: Date.now() - startedAt });
    } catch (e) { res.status(500).json({ error: String(e) }); }
  }
);

// ══════════════════════════════════════════════════════
// 6) 🆕 새 채팅 문의 → 관리자 FCM 푸시 알림
// ══════════════════════════════════════════════════════
exports.onNewChatMessage = onDocumentCreated(
  { document: 'chats/{roomId}/messages/{messageId}', secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET] },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (data.isAdmin === true || data.isSystem === true) return; // 관리자·자동 답변 제외

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
// 7) 관리자 답변 → 해당 고객에게만 알림톡
// ══════════════════════════════════════════════════════
exports.onAdminChatReply = onDocumentCreated(
  { document: 'chats/{roomId}/messages/{messageId}', secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET] },
  async (event) => {
    const data = event.data?.data();
    if (!data || data.isAdmin !== true || data.isSystem === true) return;

    const message = String(data.message || data.text || '').trim();
    if (!message) return;

    try {
      const roomId = event.params.roomId;
      const roomSnap = await db.collection('chat_rooms').doc(roomId).get();
      const room = roomSnap.data() || {};
      const userId = String(room.userId || roomId || '').trim();
      if (!userId) {
        console.warn('관리자 답변 고객 식별 실패:', roomId);
        return;
      }

      const userSnap = await db.collection('users').doc(userId).get();
      const user = userSnap.data() || {};
      const phone = String(user.phone || user.phoneNumber || '').replace(/[^0-9+]/g, '');
      if (!/^\+?[0-9]{8,15}$/.test(phone)) {
        console.warn('고객 전화번호 없음 또는 형식 오류:', userId);
        return;
      }

      const result = await _sendSolapiAlimtalk({
        phone,
        templateId: KAKAO_CUSTOMER_CHAT_REPLY_TEMPLATE_ID,
        variables: { '#{답변내용}': message.slice(0, 500) },
      });
      console.log(`고객 답변 알림톡 처리 결과: ${result.ok ? 'accepted' : 'rejected'} (${result.statusCode})`);
    } catch (e) {
      console.error('onAdminChatReply Alimtalk error:', e);
    }
  }
);

// ══════════════════════════════════════════════════════
// 8) 🆕 관리자 FCM 토큰 자동 등록
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
// 관리자 계정의 Custom Claim을 복구할 수 있는 단일 소유자 이메일입니다.
// 실제 권한 부여는 서버에서 검증된 Firebase ID 토큰과 이메일 인증 상태를 함께 확인합니다.
const OWNER_ADMIN_EMAIL = 'chw243527@gmail.com';

// 직원 추가·해제는 Firestore isAdmin 필드만 바꾸면 Rules와 실제 토큰이
// 불일치하므로, 관리자 전용 서버 함수에서 Custom Claim도 함께 갱신합니다.
exports.setStaffAdminClaim = onRequest({
  cors: ['https://2fit-mall.co.kr', 'https://fit-mall.web.app', 'http://localhost:5000'],
}, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method Not Allowed' });
    return;
  }
  if (!(await requireAdmin(req, res))) return;
  if (!(await enforceRateLimit(req, res, `staff-claim:${req.adminUid}`, { limit: 20, windowMs: 60 * 60 * 1000 }))) return;
  try {
    const targetUid = String(req.body?.targetUid || '').trim();
    const grant = req.body?.grant === true;
    const currentUid = String(req.adminUid || '').trim();
    if (!targetUid || targetUid === currentUid) {
      res.status(400).json({ error: 'Invalid target user' });
      return;
    }
    const target = await getAuth().getUser(targetUid);
    const currentClaims = { ...(target.customClaims || {}) };
    if (grant) {
      currentClaims.admin = true;
    } else {
      delete currentClaims.admin;
      delete currentClaims.isAdmin;
    }
    await getAuth().setCustomUserClaims(targetUid, currentClaims);
    const profileRef = db.collection('users').doc(targetUid);
    await profileRef.update({
      isAdmin: grant,
      ...(grant && req.body?.staffRole
        ? { staffRole: String(req.body.staffRole).trim().slice(0, 50) }
        : { staffRole: FieldValue.delete() }),
      staffRoleUpdatedAt: FieldValue.serverTimestamp(),
    });
    await db.collection('access_logs').add({
      action: grant ? 'staff_admin_granted' : 'staff_admin_revoked',
      adminId: req.adminUid,
      targetUid,
      createdAt: FieldValue.serverTimestamp(),
    });
    res.json({ success: true, grant, targetUid });
  } catch (e) {
    console.error('setStaffAdminClaim error:', e);
    res.status(404).json({ error: 'Target user not found or claim update failed' });
  }
});

exports.ensureOwnerAdminClaim = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method Not Allowed' });
    return;
  }
  const header = req.get('authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: 'Missing Firebase ID token' });
    return;
  }
  try {
    const decoded = await getAuth().verifyIdToken(match[1]);
    if (decoded.email !== OWNER_ADMIN_EMAIL || decoded.email_verified !== true) {
      res.status(403).json({ error: 'Owner account required' });
      return;
    }
    const email = String(decoded.email || '').trim().toLowerCase();
    const account = await getAuth().getUser(decoded.uid);
    await getAuth().setCustomUserClaims(decoded.uid, {
      ...(account.customClaims || {}),
      admin: true,
    });
    res.json({ success: true });
  } catch (e) {
    console.error('ensureOwnerAdminClaim error:', e);
    res.status(401).json({ error: 'Unable to verify administrator account' });
  }
});

async function requireAdmin(req, res) {
  const header = req.get('authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: 'Missing Firebase ID token' });
    return false;
  }

  try {
    const decoded = await getAuth().verifyIdToken(match[1]);
    const isAdmin = decoded.admin === true;
    if (!isAdmin) {
      res.status(403).json({ error: 'Admin access required' });
      return false;
    }
    req.adminUid = decoded.uid;
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

// Kakao OAuth access token을 서버에서 검증하고 provider Custom Claim을 포함한
// Firebase Custom Token을 발급합니다. 클라이언트가 provider claim을 직접 만들 수 없게 합니다.
exports.exchangeKakaoToken = onRequest(
  {
    serviceAccount: '187081765755-compute@developer.gserviceaccount.com',
    cors: [
    'https://2fit-mall.co.kr',
    'https://fit-mall.web.app',
    'http://localhost:5000',
  ] },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }
    const accessToken = String(req.body?.accessToken || '');
    if (!accessToken || accessToken.length > 4096) {
      res.status(400).json({ error: 'Kakao access token is required' });
      return;
    }
    try {
      const profileResponse = await fetch('https://kapi.kakao.com/v2/user/me', {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      const profile = await profileResponse.json();
      const kakaoId = String(profile?.id || '');
      if (!profileResponse.ok || !kakaoId) {
        res.status(401).json({ error: 'Kakao authorization failed' });
        return;
      }
      const account = profile.kakao_account || {};
      const properties = profile.properties || {};
      const email = String(account.email || `${kakaoId}@kakao.com`).toLowerCase();
      const name = String(properties.nickname || '카카오 사용자').slice(0, 100);
      const photoUrl = String(properties.profile_image || '').slice(0, 2000);
      let user;
      try {
        user = await getAuth().getUserByEmail(email);
      } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
        user = await getAuth().createUser({ email, displayName: name, photoURL: photoUrl || undefined });
      }
      const customToken = await getAuth().createCustomToken(user.uid, {
        provider: 'kakao',
        kakaoId,
      });
      res.json({ customToken, email, name, photoUrl, kakaoId });
    } catch (error) {
      const errorCode = String(error?.code || error?.name || 'internal-error');
      console.error('exchangeKakaoToken error:', errorCode, error?.message || error);
      res.status(500).json({
        error: `Kakao login failed (${errorCode})`,
      });
    }
  }
);

// ══════════════════════════════════════════════════════
// 9) 서버 전용 SOLAPI 알림 발송
// ══════════════════════════════════════════════════════
const ALLOWED_ORDER_NOTIFICATION_KINDS = new Set([
  'order_confirmed', 'shipped', 'delivered', 'cancelled',
]);

async function requireSignedIn(req, res, { checkRevoked = false } = {}) {
  const header = req.get('authorization') || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: 'Missing Firebase ID token' });
    return null;
  }
  try {
    return await getAuth().verifyIdToken(match[1], checkRevoked);
  } catch (error) {
    console.error('HTTP authentication failed:', error.message);
    res.status(401).json({ error: 'Invalid or expired Firebase ID token' });
    return null;
  }
}

// Authenticated endpoints still need abuse controls. The raw IP is never stored;
// only a one-way hash is used as part of the rate-limit document ID.
async function enforceRateLimit(req, res, key, { limit, windowMs }) {
  const forwarded = String(req.get('x-forwarded-for') || '').split(',')[0].trim();
  const ip = forwarded || req.ip || 'unknown';
  const bucketKey = crypto.createHash('sha256')
    .update(`${key}:${ip}`)
    .digest('hex');
  const ref = db.collection('_rate_limits').doc(bucketKey);
  const now = Date.now();
  let allowed = false;
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() || {};
    const startedAt = Number(data.startedAt || 0);
    const count = Number(data.count || 0);
    if (!startedAt || now - startedAt >= windowMs) {
      tx.set(ref, { startedAt: now, count: 1, expiresAt: new Date(now + windowMs) });
      allowed = true;
    } else if (count < limit) {
      tx.update(ref, { count: count + 1 });
      allowed = true;
    }
  });
  if (!allowed) {
    res.status(429).json({ error: 'Too many requests. Please try again later.' });
  }
  return allowed;
}

// ══════════════════════════════════════════════════════
// 9) 본인 계정 삭제 (인증 사용자 전용)
// - 고객의 직접 확인 + Firebase ID 토큰 검증을 거칩니다.
// - 주문·결제 등 보존이 필요한 기록은 개인식별정보만 익명화합니다.
// - 나머지 계정 데이터, 채팅, 알림, 리뷰, 저장 파일은 제거합니다.
// ══════════════════════════════════════════════════════
exports.deleteMyAccount = onRequest(
  { cors: ['https://2fit-mall.co.kr', 'https://fit-mall.web.app', 'http://localhost:5000'] },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method Not Allowed' });
      return;
    }

    // 무단 호출을 막기 위해 취소·폐기된 토큰도 거부합니다.
    const decoded = await requireSignedIn(req, res, { checkRevoked: true });
    if (!decoded) return;
    if (req.body?.confirmAccountDeletion !== true) {
      res.status(400).json({ error: 'Explicit account deletion confirmation is required' });
      return;
    }
    const reason = String(req.body?.reason || '').trim();
    const detail = String(req.body?.detail || '').trim().slice(0, 300);
    if (!reason || reason.length > 80) {
      res.status(400).json({ error: 'A valid account deletion reason is required.', code: 'reason-required' });
      return;
    }

    // 오래된 로그인 토큰만으로 실행되는 실수·탈취 위험을 줄입니다.
    const authTimeMs = Number(decoded.auth_time || 0) * 1000;
    const maxAuthAgeMs = 15 * 60 * 1000;
    if (!authTimeMs || Date.now() - authTimeMs > maxAuthAgeMs) {
      res.status(401).json({
        error: 'Recent sign-in required',
        code: 'recent-login-required',
      });
      return;
    }

    const uid = decoded.uid;
    try {
      const userDoc = await db.collection('users').doc(uid).get();
      if (decoded.admin === true) {
        res.status(403).json({
          error: 'Administrator accounts must be deleted through an owner-approved process.',
          code: 'admin-account-protected',
        });
        return;
      }

      const summary = await _removeAccountData(uid, decoded.email || '');
      // 탈퇴 사유는 개인 식별자 없이 서비스 개선용 통계 자료로만 보관합니다.
      await db.collection('account_deletion_feedback').add({
        reason,
        detail,
        createdAt: FieldValue.serverTimestamp(),
      });
      // 데이터 처리에 성공한 뒤 인증 계정을 마지막에 삭제합니다.
      await getAuth().deleteUser(uid);
      console.log('Account deletion completed:', { summary });
      res.status(200).json({ success: true, summary });
    } catch (error) {
      // 이메일·전화번호·주문 내용 등 개인정보는 오류 로그에 남기지 않습니다.
      console.error('deleteMyAccount failed:', {
        code: error?.code || 'unknown',
      });
      res.status(500).json({
        error: 'Account deletion could not be completed. Please try again or contact support.',
      });
    }
  }
);

async function _removeAccountData(uid, email) {
  const summary = {
    deleted: {},
    anonymizedOrders: 0,
    anonymizedRequests: 0,
  };

  // 1) 보존 의무가 있을 수 있는 주문 기록은 거래 증빙만 남기고 개인식별정보를 제거합니다.
  const orderSnapshot = await db.collection('orders').where('userId', '==', uid).get();
  const orderIds = orderSnapshot.docs.map((doc) => doc.id);
  await _anonymizeDocuments(orderSnapshot.docs, {
    userId: '',
    userName: '탈퇴회원',
    userEmail: '',
    userPhone: '',
    userAddress: '',
    recipientName: '',
    recipientPhone: '',
    shippingAddress: '',
    deletedUser: true,
    anonymizedAt: FieldValue.serverTimestamp(),
  });
  summary.anonymizedOrders = orderSnapshot.size;

  // 주문을 표시하는 관리자 알림에서도 고객 이름을 지웁니다.
  for (const orderIdChunk of _chunk(orderIds, 30)) {
    const notifications = await db.collection('admin_notifications')
      .where('orderId', 'in', orderIdChunk).get();
    await _anonymizeDocuments(notifications.docs, {
      customerName: '탈퇴회원',
      body: '탈퇴회원의 주문 기록',
      anonymizedAt: FieldValue.serverTimestamp(),
    });
  }

  // 2) 공개 리뷰·리뷰 이미지·고객 상담은 삭제합니다.
  const reviewSnapshot = await db.collection('reviews').where('userId', '==', uid).get();
  const productIds = [...new Set(reviewSnapshot.docs
    .map((doc) => String(doc.data().productId || ''))
    .filter(Boolean))];
  for (const reviewDoc of reviewSnapshot.docs) {
    await _deleteStoragePrefix(`reviews/${reviewDoc.id}/`);
  }
  summary.deleted.reviews = await _deleteDocumentRefs(reviewSnapshot.docs);
  await _refreshProductReviewStats(productIds);

  await _recursiveDeleteDocument(db.collection('chats').doc(uid));
  await db.collection('chat_rooms').doc(uid).delete().catch(() => {});
  summary.deleted.chat = 1;

  // 3) 즉시 삭제할 개인 설정·알림·신청·동의 이력입니다.
  summary.deleted.notifications = await _deleteQuery(
    db.collection('notifications').where('userId', '==', uid)
  );
  summary.deleted.restockAlerts = await _deleteQuery(
    db.collection('restock_alerts').where('userId', '==', uid)
  );
  summary.deleted.privacyRequests = await _deleteQuery(
    db.collection('privacy_requests').where('userId', '==', uid)
  );
  summary.deleted.consentHistory = await _deleteQuery(
    db.collection('consent_history').where('userId', '==', uid)
  );

  // 교환·반품·디자인 요청은 주문 증빙을 위해 남길 수 있으므로 식별 정보만 익명화합니다.
  for (const collectionName of ['exchange_requests', 'design_requests']) {
    const snapshot = await db.collection(collectionName).where('userId', '==', uid).get();
    await _anonymizeDocuments(snapshot.docs, {
      userId: '',
      userName: '탈퇴회원',
      userEmail: '',
      userPhone: '',
      userAddress: '',
      customerName: '탈퇴회원',
      customerEmail: '',
      customerPhone: '',
      address: '',
      deletedUser: true,
      anonymizedAt: FieldValue.serverTimestamp(),
    });
    summary.anonymizedRequests += snapshot.size;
  }

  // 사용자 문서의 하위 컬렉션(포인트 이력 포함)과 별도 사용자 트리를 정리합니다.
  await _recursiveDeleteDocument(db.collection('user_coupons').doc(uid));
  await _recursiveDeleteDocument(db.collection('size_profiles').doc(uid));
  await db.collection('fcmTokens').doc(uid).delete().catch(() => {});
  await _recursiveDeleteDocument(db.collection('users').doc(uid));
  summary.deleted.userData = 1;

  // 발송되지 않은 이메일에 남은 주소도 제거합니다. 이메일이 없는 소셜 계정은 건너뜁니다.
  if (email) {
    summary.deleted.queuedEmails = await _deleteQuery(
      db.collection('email_queue').where('params.to_email', '==', email)
    );
  }

  return summary;
}

async function _deleteQuery(query) {
  const snapshot = await query.get();
  return _deleteDocumentRefs(snapshot.docs);
}

async function _deleteDocumentRefs(docs) {
  let deleted = 0;
  for (const docsChunk of _chunk(docs, 400)) {
    const batch = db.batch();
    for (const doc of docsChunk) batch.delete(doc.ref);
    await batch.commit();
    deleted += docsChunk.length;
  }
  return deleted;
}

async function _anonymizeDocuments(docs, values) {
  for (const docsChunk of _chunk(docs, 400)) {
    const batch = db.batch();
    for (const doc of docsChunk) batch.set(doc.ref, values, { merge: true });
    await batch.commit();
  }
}

async function _recursiveDeleteDocument(docRef) {
  const snapshot = await docRef.get();
  if (snapshot.exists) await db.recursiveDelete(docRef);
}

async function _deleteStoragePrefix(prefix) {
  try {
    await getStorage().bucket().deleteFiles({ prefix, force: true });
  } catch (error) {
    // 저장 파일이 없는 경우 등은 탈퇴 전체를 막지 않습니다.
    if (error?.code !== 404) console.warn('Storage cleanup skipped:', { prefix, code: error?.code });
  }
}

async function _refreshProductReviewStats(productIds) {
  for (const productId of productIds) {
    const snapshot = await db.collection('reviews').where('productId', '==', productId).get();
    const ratings = snapshot.docs
      .map((doc) => Number(doc.data().rating || 0))
      .filter((rating) => Number.isFinite(rating) && rating > 0);
    const rating = ratings.length
      ? Number((ratings.reduce((sum, value) => sum + value, 0) / ratings.length).toFixed(1))
      : 0;
    await db.collection('products').doc(productId).set({
      rating,
      reviewCount: ratings.length,
    }, { merge: true });
  }
}

function _chunk(items, size) {
  const chunks = [];
  for (let i = 0; i < items.length; i += size) chunks.push(items.slice(i, i + size));
  return chunks;
}

// ══════════════════════════════════════════════════════
// 10) 안전한 결제 의도 생성·승인·주문 확정
// - 금액·상품명·배송비·쿠폰·포인트는 클라이언트 값이 아닌 서버 데이터로 계산합니다.
// - 카드/간편결제는 토스 승인 성공 후에만 orders 문서를 생성합니다.
// ══════════════════════════════════════════════════════
const PAYMENT_CORS = ['https://2fit-mall.co.kr', 'https://fit-mall.web.app', 'http://localhost:5000'];
const PAYMENT_INTENT_TTL_MS = 30 * 60 * 1000;
const BANK_TRANSFER_TTL_MS = 24 * 60 * 60 * 1000;
const SHIPPING_FREE_THRESHOLD = 300000;
const DEFAULT_SHIPPING_FEE = 4000;

// 신규 회원 가입 혜택: 사용자 본인만 호출할 수 있고,
// 포인트 이력과 고정 쿠폰 문서를 멱등 키로 사용해 재호출에도 중복 지급하지 않습니다.
exports.claimWelcomeBonus = onRequest({ cors: PAYMENT_CORS }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method Not Allowed' });
    return;
  }
  const decoded = await requireSignedIn(req, res);
  if (!decoded) return;
  if (!(await enforceRateLimit(req, res, `welcome:${decoded.uid}`, { limit: 3, windowMs: 24 * 60 * 60 * 1000 }))) return;

  try {
    const userRef = db.collection('users').doc(decoded.uid);
    const bonusRef = userRef.collection('point_history').doc('welcome_bonus');
    const couponRef = db.collection('user_coupons').doc(decoded.uid)
      .collection('coupons').doc('welcome_3000');
    let pointsGranted = false;
    let couponGranted = false;

    await db.runTransaction(async (tx) => {
      const bonusSnap = await tx.get(bonusRef);
      const couponSnap = await tx.get(couponRef);
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw new Error('User profile not found');

      if (!bonusSnap.exists) {
        const currentPoints = Number(userSnap.data()?.points || 0);
        tx.update(userRef, { points: currentPoints + 1000 });
        tx.set(bonusRef, {
          action: 'admin',
          amount: 1000,
          desc: '회원가입 축하 포인트',
          createdAt: FieldValue.serverTimestamp(),
          expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        });
        pointsGranted = true;
      }

      if (!couponSnap.exists) {
        tx.set(couponRef, {
          couponId: 'welcome_3000',
          code: 'WELCOME3000',
          name: '신규회원 3,000원 할인 쿠폰',
          type: 'fixed',
          value: 3000,
          minOrderAmount: 60000,
          isUsed: false,
          isReserved: false,
          isStackable: true,
          isDownloadable: false,
          downloadCount: 0,
          expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          createdAt: FieldValue.serverTimestamp(),
        });
        couponGranted = true;
      }
    });

    res.json({ success: true, pointsGranted, couponGranted, amount: pointsGranted ? 1000 : 0 });
  } catch (error) {
    console.error('claimWelcomeBonus failed:', { code: error?.code || 'welcome-benefit-failed' });
    res.status(400).json({ error: 'Welcome benefits could not be processed' });
  }
});

exports.createSecureOrder = onRequest({ cors: PAYMENT_CORS }, async (req, res) => {
  if (req.method !== 'POST') { res.status(405).json({ error: 'Method Not Allowed' }); return; }
  // 결제 요청은 ID 토큰의 서명·발급자·대상 검증을 수행합니다.
  // checkRevoked=true는 Firebase Auth REST 호출을 추가로 요구해
  // 런타임 OAuth 토큰 오류로 결제창 진입 전 요청이 막힐 수 있습니다.
  const decoded = await requireSignedIn(req, res);
  if (!decoded) return;
  if (!(await enforceRateLimit(req, res, `create-order:${decoded.uid}`, { limit: 10, windowMs: 10 * 60 * 1000 }))) return;
  try {
    const payload = _readCheckoutPayload(req.body);
    const prepared = await _prepareOrderFromServerData(decoded.uid, payload);
    if (prepared.isBankTransfer) {
      await _finalizeBankTransferOrder(decoded.uid, prepared);
      res.status(200).json({ success: true, orderId: prepared.orderId, amount: prepared.order.totalAmount, bankTransfer: true });
      return;
    }
    await db.runTransaction(async (tx) => {
      const userRef = db.collection('users').doc(decoded.uid);
      const user = await tx.get(userRef);
      if (!user.exists) throw new Error('User profile unavailable');
      await _reserveBenefits(tx, decoded.uid, prepared, prepared.orderId, user.data() || {});
      tx.set(db.collection('payment_intents').doc(prepared.orderId), {
        userId: decoded.uid,
        status: 'pending',
        amount: prepared.order.totalAmount,
        order: prepared.order,
        couponId: prepared.couponId || null,
        couponIds: prepared.couponIds,
        usedPoints: prepared.usedPoints,
        expiresAt: new Date(Date.now() + PAYMENT_INTENT_TTL_MS),
        createdAt: FieldValue.serverTimestamp(),
      });
    });
    res.status(200).json({ success: true, orderId: prepared.orderId, amount: prepared.order.totalAmount, orderName: prepared.orderName });
  } catch (error) {
    console.error('createSecureOrder failed:', { code: error?.code || 'checkout-preparation-failed' });
    res.status(400).json({ error: _safeCheckoutError(error) });
  }
});

exports.confirmSecurePayment = onRequest({ secrets: [TOSS_SECRET_KEY], cors: PAYMENT_CORS }, async (req, res) => {
  if (req.method !== 'POST') { res.status(405).json({ error: 'Method Not Allowed' }); return; }
  // 결제 승인도 기본 ID 토큰 검증만 사용해 런타임 OAuth 의존성을 피합니다.
  const decoded = await requireSignedIn(req, res);
  if (!decoded) return;
  const orderId = String(req.body?.orderId || '').trim().slice(0, 120);
  if (!(await enforceRateLimit(req, res, `confirm-payment:${decoded.uid}:${orderId}`, { limit: 8, windowMs: 15 * 60 * 1000 }))) return;
  const paymentKey = String(req.body?.paymentKey || '').trim();
  const amount = Number(req.body?.amount);
  if (!paymentKey || !orderId || !Number.isSafeInteger(amount) || amount <= 0) {
    res.status(400).json({ error: 'Invalid payment confirmation request' }); return;
  }
  try {
    const intentRef = db.collection('payment_intents').doc(orderId);
    const intentSnap = await intentRef.get();
    const intent = intentSnap.data();
    if (!intentSnap.exists || intent.userId !== decoded.uid || intent.status !== 'pending') {
      res.status(403).json({ error: 'Payment request is unavailable' }); return;
    }
    if (intent.expiresAt?.toDate?.().getTime() < Date.now() || intent.amount !== amount) {
      res.status(400).json({ error: 'Payment amount does not match the secure order' }); return;
    }
    const secret = TOSS_SECRET_KEY.value();
    if (!secret) { res.status(503).json({ error: 'Payment service is not configured' }); return; }
    const tossResponse = await fetch('https://api.tosspayments.com/v1/payments/confirm', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${Buffer.from(`${secret}:`).toString('base64')}`,
        'Content-Type': 'application/json',
        'Idempotency-Key': `confirm-${orderId}`,
      },
      body: JSON.stringify({ paymentKey, orderId, amount: intent.amount }),
    });
    const toss = await tossResponse.json();
    if (!tossResponse.ok || toss.orderId !== orderId || Number(toss.totalAmount) !== intent.amount) {
      console.warn('Toss payment confirmation rejected:', { status: tossResponse.status, code: toss?.code || 'unknown' });
      res.status(400).json({ error: 'Payment approval failed' }); return;
    }
    await db.runTransaction(async (tx) => {
      const latest = await tx.get(intentRef);
      const latestData = latest.data();
      if (!latest.exists || latestData.userId !== decoded.uid) throw new Error('Payment request unavailable');
      if (latestData.status === 'confirmed') return;
      if (latestData.status !== 'pending') throw new Error('Payment request unavailable');
      const orderRef = db.collection('orders').doc(orderId);
      const existingOrder = await tx.get(orderRef);
      if (!existingOrder.exists) {
        tx.set(orderRef, {
          ...latestData.order,
          status: 'confirmed',
          paymentStatus: 'paid',
          paymentKey,
          paymentMethod: toss.method || latestData.order.paymentMethod,
          // 가상계좌 DEPOSIT_CALLBACK의 secret과 대조하기 위해 승인 시 저장합니다.
          tossPaymentSecret: typeof toss.secret === 'string' ? toss.secret : null,
          paidAt: FieldValue.serverTimestamp(),
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
      await _commitReservedBenefits(tx, decoded.uid, latestData, orderId);
      tx.update(intentRef, { status: 'confirmed', paymentKey, confirmedAt: FieldValue.serverTimestamp() });
    });
    res.status(200).json({ success: true, orderId, paymentKey, method: toss.method || '' });
  } catch (error) {
    console.error('confirmSecurePayment failed:', { code: error?.code || 'payment-confirmation-failed' });
    res.status(400).json({ error: 'Payment could not be finalized. Please contact support if payment was completed.' });
  }
});

// 인증된 현금영수증 발급
// 결제키로 주문을 조회해 현재 로그인 사용자의 결제인지 확인한 뒤 토스에 요청합니다.
exports.issueCashReceiptSecure = onRequest({ secrets: [TOSS_SECRET_KEY], cors: PAYMENT_CORS }, async (req, res) => {
  if (req.method !== 'POST') { res.status(405).json({ error: 'Method Not Allowed' }); return; }
  const decoded = await requireSignedIn(req, res);
  if (!decoded) return;
  if (!(await enforceRateLimit(req, res, `cash-receipt:${decoded.uid}`, { limit: 5, windowMs: 60 * 60 * 1000 }))) return;
  const paymentKey = String(req.body?.paymentKey || '').trim().slice(0, 200);
  const identity = String(req.body?.customerIdentityNumber || '').replace(/[^0-9]/g, '');
  const type = String(req.body?.type || '').trim();
  const taxFreeAmount = Number(req.body?.taxFreeAmount || 0);
  if (!paymentKey || !['소득공제', '지출증빙'].includes(type)
      || !/^([0-9]{10}|[0-9]{11}|[0-9]{13})$/.test(identity)
      || !Number.isSafeInteger(taxFreeAmount) || taxFreeAmount < 0) {
    res.status(400).json({ error: 'Invalid cash receipt request' }); return;
  }
  try {
    const orderSnap = await db.collection('orders').where('paymentKey', '==', paymentKey).limit(1).get();
    const orderDoc = orderSnap.docs[0];
    const order = orderDoc?.data();
    if (!orderDoc || !order || order.userId !== decoded.uid || order.paymentStatus !== 'paid') {
      res.status(403).json({ error: 'Payment does not belong to the signed-in user' }); return;
    }
    const secret = TOSS_SECRET_KEY.value();
    if (!secret) { res.status(503).json({ error: 'Payment service is not configured' }); return; }
    const tossResponse = await fetch(
      `https://api.tosspayments.com/v1/payments/${encodeURIComponent(paymentKey)}/cash-receipts`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${Buffer.from(`${secret}:`).toString('base64')}`,
          'Content-Type': 'application/json',
          'Idempotency-Key': `cash-receipt-${orderDoc.id}-${type}`,
        },
        body: JSON.stringify({
          customerIdentityNumber: identity,
          type,
          ...(taxFreeAmount > 0 ? { taxFreeAmount } : {}),
        }),
      },
    );
    const toss = await tossResponse.json().catch(() => ({}));
    if (tossResponse.ok || toss.code === 'ALREADY_REGISTERED_CASH_RECEIPT') {
      res.status(200).json({
        success: true,
        alreadyIssued: toss.code === 'ALREADY_REGISTERED_CASH_RECEIPT',
        receiptKey: toss.receiptKey || null,
        orderId: toss.orderId || orderDoc.id,
      });
      return;
    }
    console.warn('Cash receipt request rejected:', { status: tossResponse.status, code: toss.code || 'unknown' });
    res.status(400).json({ error: 'Cash receipt issuance failed' });
  } catch (error) {
    console.error('issueCashReceiptSecure failed:', { code: error?.code || 'cash-receipt-failed' });
    res.status(400).json({ error: 'Cash receipt issuance failed' });
  }
});

// 토스 가상계좌 입금 완료 웹훅
// 입금 이벤트를 받으면 주문번호·secret·결제금액·결제상태를 모두 확인한 뒤 확정합니다.
exports.tossVirtualAccountWebhook = onRequest(
  { secrets: [TOSS_SECRET_KEY] },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }
    const payload = req.body && typeof req.body === 'object' ? req.body : {};
    const eventType = String(payload.eventType || '').trim();
    const data = payload.data && typeof payload.data === 'object' ? payload.data : payload;
    const orderId = String(data.orderId || '').trim();
    const callbackSecret = String(data.secret || '').trim();
    const status = String(data.status || '').trim().toUpperCase();

    if (eventType && eventType !== 'DEPOSIT_CALLBACK') {
      res.status(400).send('Unsupported event');
      return;
    }
    if (!orderId || !callbackSecret || !status) {
      res.status(400).send('Invalid webhook payload');
      return;
    }

    try {
      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await orderRef.get();
      if (!orderSnap.exists) {
        // 토스 재전송 대상으로 남기기 위해 404를 반환합니다.
        res.status(404).send('Order not found');
        return;
      }
      const order = orderSnap.data() || {};
      const storedSecret = String(order.tossPaymentSecret || '').trim();
      const sameLength = storedSecret.length === callbackSecret.length;
      const secretMatches = sameLength && crypto.timingSafeEqual(
        Buffer.from(storedSecret), Buffer.from(callbackSecret),
      );
      if (!storedSecret || !secretMatches) {
        console.error('Toss webhook secret mismatch', { orderId, status });
        res.status(401).send('Invalid webhook secret');
        return;
      }

      if (status === 'CANCELED' || status === 'CANCELLED') {
        await db.runTransaction(async (tx) => {
          const latest = await tx.get(orderRef);
          const latestData = latest.data() || {};
          if (!latest.exists || latestData.paymentStatus === 'paid') return;
          tx.update(orderRef, {
            paymentStatus: 'cancelled',
            status: latestData.status === 'pending' ? 'cancelled' : latestData.status,
            updatedAt: FieldValue.serverTimestamp(),
          });
        });
        res.status(200).send('OK');
        return;
      }

      if (status !== 'DONE') {
        // WAITING_FOR_DEPOSIT 등은 아직 결제완료가 아니므로 확정하지 않습니다.
        res.status(200).send('OK');
        return;
      }

      const secretKey = TOSS_SECRET_KEY.value();
      const authHeader = `Basic ${Buffer.from(`${secretKey}:`).toString('base64')}`;
      const tossResponse = await fetch(
        `https://api.tosspayments.com/v1/payments/orders/${encodeURIComponent(orderId)}`,
        { headers: { Authorization: authHeader, 'Content-Type': 'application/json' } },
      );
      const tossPayment = await tossResponse.json().catch(() => ({}));
      if (!tossResponse.ok || tossPayment.status !== 'DONE'
          || Number(tossPayment.totalAmount) !== Number(order.totalAmount)) {
        console.error('Toss webhook payment verification failed', {
          orderId,
          httpStatus: tossResponse.status,
          tossStatus: tossPayment.status,
        });
        res.status(400).send('Payment verification failed');
        return;
      }

      await db.runTransaction(async (tx) => {
        const latest = await tx.get(orderRef);
        const latestData = latest.data() || {};
        if (!latest.exists || latestData.paymentStatus === 'paid') return;
        tx.update(orderRef, {
          status: 'confirmed',
          paymentStatus: 'paid',
          paymentKey: tossPayment.paymentKey || latestData.paymentKey || null,
          paymentMethod: tossPayment.method || latestData.paymentMethod || '무통장입금',
          paidAt: latestData.paidAt || FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
      res.status(200).send('OK');
    } catch (error) {
      console.error('tossVirtualAccountWebhook failed:', error);
      res.status(500).send('Webhook processing failed');
    }
  },
);

exports.cancelSecurePayment = onRequest({ cors: PAYMENT_CORS }, async (req, res) => {
  if (req.method !== 'POST') { res.status(405).json({ error: 'Method Not Allowed' }); return; }
  const decoded = await requireSignedIn(req, res);
  if (!decoded) return;
  if (!(await enforceRateLimit(req, res, `cancel-payment:${decoded.uid}`, { limit: 20, windowMs: 60 * 60 * 1000 }))) return;
  const orderId = String(req.body?.orderId || '');
  try { await _releasePaymentIntent(decoded.uid, orderId); res.status(200).json({ success: true }); }
  catch (_) { res.status(400).json({ error: 'Payment cancellation could not be processed' }); }
});

exports.cleanupExpiredPaymentIntents = onSchedule('every 15 minutes', async () => {
  const now = new Date();
  const snapshot = await db.collection('payment_intents').where('expiresAt', '<=', now).limit(100).get();
  for (const intent of snapshot.docs) {
    if (intent.data().status === 'pending') await _releasePaymentIntent(String(intent.data().userId || ''), intent.id).catch(() => {});
  }
});

function _asDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}
function _kstDateKey(date) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul', year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(date);
}
function _formatKstDate(date) {
  return new Intl.DateTimeFormat('ko-KR', {
    timeZone: 'Asia/Seoul', year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(date);
}
async function _claimExclusiveRenewalNotice(orderId, noticeKey) {
  const markerRef = db.collection('orders').doc(orderId)
    .collection('notification_deliveries').doc(`exclusive_renewal_${noticeKey}`);
  const now = Date.now();
  const claimed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(markerRef);
    const marker = snap.data() || {};
    const claimedAt = Number(marker.claimedAtMs || 0);
    if (marker.status === 'sent' ||
        (marker.status === 'processing' && claimedAt && now - claimedAt < 10 * 60 * 1000)) return false;
    tx.set(markerRef, {
      status: 'processing', noticeKey, attempts: Number(marker.attempts || 0) + 1,
      claimedAtMs: now, updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return true;
  });
  return claimed ? markerRef : null;
}
exports.sendExclusiveRenewalNoticesDaily = onSchedule({
  schedule: 'every day 09:00',
  timeZone: 'Asia/Seoul',
  secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET, RESEND_API_KEY],
}, async () => {
  const todayKey = _kstDateKey(new Date());
  const snapshot = await db.collection('orders').where('status', '==', 'delivered').get();
  let checked = 0;
  let sent = 0;
  for (const orderSnap of snapshot.docs) {
    const data = orderSnap.data() || {};
    const opts = data.customOptions || {};
    const isGroup = data.orderType === 'group' || data.orderType === 'additional' ||
      opts.orderType === 'group' || opts.orderType === 'additional';
    const isExclusive = data.exclusiveDesign === true || opts.exclusiveDesign === true;
    if (!isGroup || !isExclusive) continue;
    const deliveredAt = _asDate(data.deliveredAt);
    if (!deliveredAt) continue;
    checked++;
    const expiryDate = new Date(deliveredAt);
    expiryDate.setFullYear(expiryDate.getFullYear() + 1);
    const noticeDate = new Date(expiryDate.getTime() - 7 * 24 * 60 * 60 * 1000);
    // 당일 대상뿐 아니라 일시적 발송 실패로 지난 알림일도 만료 전까지 재시도합니다.
    if (_kstDateKey(noticeDate) > todayKey || expiryDate <= new Date()) continue;

    const markerRef = await _claimExclusiveRenewalNotice(orderSnap.id, todayKey);
    if (!markerRef) continue;
    const userId = String(data.userId || '').trim();
    const user = userId ? (await db.collection('users').doc(userId).get()).data() || {} : {};
    const name = String(data.userName || user.name || '고객').slice(0, 80);
    const phone = String(data.userPhone || user.phone || user.phoneNumber || '')
      .replace(/[^0-9+]/g, '');
    const email = String(data.userEmail || user.email || '').trim().toLowerCase();
    const orderNumber = String(orderSnap.id).slice(0, 80);
    const expiryText = _formatKstDate(expiryDate);
    const results = {};

    if (userId) {
      await db.collection('notifications').add({
        userId,
        title: '1년 독점 기간 만료 예정 안내',
        body: `${name}님의 단체주문 독점 기간이 ${expiryText}에 종료됩니다. 계속 이용을 원하시면 재신청해 주세요.`,
        type: 'exclusive_renewal', orderId: orderSnap.id, isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      }).catch((error) => console.error('exclusive in-app notification failed:', error));
      results.inApp = 'sent';
    } else {
      results.inApp = 'skipped_no_user';
    }

    const configuredTemplateId = KAKAO_EXCLUSIVE_RENEWAL_TEMPLATE_ID.value().trim();
    const templateId = configuredTemplateId === '__UNCONFIGURED__' ? '' : configuredTemplateId;
    if (templateId && /^\+?[0-9]{8,15}$/.test(phone)) {
      try {
        const result = await _sendSolapiAlimtalk({
          phone, templateId,
          variables: {
            '#{고객명}': name,
            '#{주문번호}': orderNumber,
            '#{만료일}': expiryText,
            '#{재신청URL}': 'https://2fit-mall.co.kr/#/group-order',
          },
        });
        results.alimtalk = result.ok ? 'sent' : `failed_${result.statusCode}`;
      } catch (error) {
        console.error('exclusive renewal alimtalk error:', error);
        results.alimtalk = 'failed';
      }
    } else {
      results.alimtalk = templateId ? 'skipped_invalid_phone' : 'skipped_template_not_configured';
    }

    if (email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      try {
        const result = await _sendResendEmail({
          to: email,
          subject: `[2FIT MALL] 1년 독점 기간 만료 예정 안내 (${orderNumber})`,
          text: `[2FIT MALL] ${name}님, 단체주문 독점 기간이 ${expiryText}에 종료됩니다. 계속 이용을 원하시면 재신청해 주세요. 주문번호: ${orderNumber}`,
          html: `<p>${name}님, 단체주문 독점 기간이 <strong>${expiryText}</strong>에 종료됩니다.</p><p>계속 이용을 원하시면 2FIT MALL에서 재신청해 주세요.</p><p>주문번호: ${orderNumber}</p>`,
        });
        results.email = result.ok ? 'sent' : `failed_${result.statusCode}`;
      } catch (error) {
        console.error('exclusive renewal email error:', error);
        results.email = 'failed';
      }
    } else {
      results.email = 'skipped_no_valid_email';
    }

    const delivered = Object.values(results).some((status) => status === 'sent');
    await markerRef.set({
      status: delivered ? 'sent' : 'failed', results,
      expiryDate: expiryDate.toISOString(), noticeDate: noticeDate.toISOString(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    if (delivered) sent++;
  }
  console.log(`exclusive renewal notices: checked=${checked}, sent=${sent}`);
});

exports.cleanupExpiredBankTransferOrders = onSchedule('every 15 minutes', async () => {
  const now = new Date();
  const snapshot = await db.collection('orders')
    .where('paymentStatus', '==', 'awaiting_deposit')
    .where('expiresAt', '<=', now)
    .limit(100)
    .get();
  for (const orderSnap of snapshot.docs) {
    await _expireBankTransferOrder(orderSnap.ref).catch((error) => {
      console.error('cleanupExpiredBankTransferOrders failed:', { code: error?.code || 'unknown' });
    });
  }
});

async function _expireBankTransferOrder(orderRef) {
  await db.runTransaction(async (tx) => {
    const latest = await tx.get(orderRef);
    const order = latest.data() || {};
    if (!latest.exists || order.paymentStatus !== 'awaiting_deposit') return;
    const uid = String(order.userId || '');
    if (!uid) return;
    const couponIds = Array.isArray(order.couponIds)
      ? order.couponIds
      : (order.couponId ? [order.couponId] : []);
    for (const couponId of couponIds) {
      tx.update(db.collection('user_coupons').doc(uid).collection('coupons').doc(couponId), {
        isReserved: false,
        reservedOrderId: FieldValue.delete(),
        reservedAt: FieldValue.delete(),
      });
    }
    const usedPoints = Math.max(0, Math.floor(Number(order.usedPoints || 0)));
    if (usedPoints > 0) {
      const userRef = db.collection('users').doc(uid);
      const user = await tx.get(userRef);
      const balance = Math.floor(Number(user.data()?.points || 0));
      tx.update(userRef, { points: balance + usedPoints });
      tx.set(userRef.collection('point_history').doc(`refund_${orderRef.id}`), {
        action: 'admin', amount: usedPoints,
        desc: `무통장입금 만료 주문 ${orderRef.id} 포인트 복구`,
        orderId: orderRef.id, createdAt: FieldValue.serverTimestamp(),
      });
    }
    tx.update(orderRef, {
      status: 'cancelled', paymentStatus: 'expired',
      cancelReason: '입금 기한 만료', updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

function _readCheckoutPayload(body) {
  const items = Array.isArray(body?.items) ? body.items : [];
  if (items.length < 1 || items.length > 30) throw new Error('Invalid order items');
  const deliveryAddress = String(body?.deliveryAddress || '').trim();
  if (!deliveryAddress || deliveryAddress.length > 500) throw new Error('Invalid delivery address');
  const paymentMethod = String(body?.paymentMethod || '').trim().slice(0, 60);
  if (!paymentMethod) throw new Error('Invalid payment method');
  const rawCouponIds = Array.isArray(body?.couponIds)
    ? body.couponIds
    : (body?.couponId ? [body.couponId] : []);
  const couponIds = [...new Set(rawCouponIds
    .map((id) => String(id || '').trim().slice(0, 120))
    .filter(Boolean))];
  if (couponIds.length > 10) throw new Error('Too many coupons');
  return {
    items,
    deliveryAddress,
    paymentMethod,
    memo: String(body?.memo || '').trim().slice(0, 500),
    couponIds,
    // 이전 클라이언트와의 호환을 위해 첫 번째 쿠폰 ID도 유지합니다.
    couponId: couponIds[0] || '',
    usedPoints: Math.max(0, Math.floor(Number(body?.usedPoints || 0))),
  };
}

const _CHECKOUT_COLOR_OPTIONS = [
  'K (블랙)', 'N (네이비)', 'W (화이트)', 'G (그레이)',
  'DG (다크그레이)', 'SB (스카이블루)', 'B (블루)', 'DB (다크블루)',
  'SP (스킨핑크)', 'LP (라이트핑크)', 'IO (아이보리)', 'LG (라이트그레이)',
  'R (레드)', 'PP (퍼플네이비)', 'ND (올리브그린)', 'BB (틸블루)',
  'FP (형광핑크)', 'FO (형광오렌지)', 'FG (형광그린)',
];

const _COLOR_ALIAS_GROUPS = [
  ['black', '블랙', '검정', '검은색'],
  ['white', '화이트', '흰색'],
  ['navy', '네이비'],
  ['gray', 'grey', '그레이', '회색'],
  ['red', '레드', '빨강', '빨간색'],
  ['blue', '블루', '파랑', '파란색'],
  ['pink', '핑크', '분홍', '분홍색'],
  ['purple', '퍼플', '보라', '보라색'],
  ['green', '그린', '초록', '초록색'],
  ['yellow', '옐로우', '노랑', '노란색'],
  ['orange', '오렌지', '주황', '주황색'],
  ['beige', '베이지'],
  ['brown', '브라운', '갈색'],
];

function _resolveProductOption(value, allowed) {
  const raw = String(value || '').trim();
  if (!Array.isArray(allowed) || allowed.length === 0 || allowed.includes(raw)) return raw;
  const candidates = new Set([raw]);
  const parenthesized = raw.match(/\(([^)]+)\)/)?.[1]?.trim();
  if (parenthesized) candidates.add(parenthesized);
  candidates.add(raw.replace(/\s*\([^)]*\)\s*/g, '').trim());
  const normalize = (text) => String(text).toLowerCase().replace(/[\s_\-./]+/g, '');
  const aliases = (text) => {
    const normalized = normalize(text);
    const group = _COLOR_ALIAS_GROUPS.find((items) => items.some((item) => normalize(item) === normalized));
    return new Set([normalized, ...(group || []).map(normalize)]);
  };
  for (const option of allowed) {
    const optionAliases = aliases(option);
    if ([...candidates].some((candidate) => {
      const candidateAliases = aliases(candidate);
      return [...candidateAliases].some((alias) => optionAliases.has(alias));
    })) return option;
  }
  return raw;
}
async function _prepareOrderFromServerData(uid, payload) {
  const userSnap = await db.collection('users').doc(uid).get();
  if (!userSnap.exists) throw new Error('User profile unavailable');
  const user = userSnap.data() || {};
  const items = [];
  let subtotal = 0;
  let isGroup = false;
  for (const requested of payload.items) {
    const productId = String(requested?.productId || '').slice(0, 120);
    const quantity = Math.floor(Number(requested?.quantity || 0));
    const size = String(requested?.size || '').slice(0, 80);
    const requestedColor = String(requested?.color || '').slice(0, 80);
    if (!productId || quantity < 1 || quantity > 50) throw new Error('Invalid product quantity');
    const productSnap = await db.collection('products').doc(productId).get();
    const product = productSnap.data();
    if (!productSnap.exists || product.isActive === false || !Number.isFinite(Number(product.price))) throw new Error('Product is unavailable');
    if (Array.isArray(product.sizes) && product.sizes.length && !product.sizes.includes(size)) throw new Error('Invalid product size');
    const color = _resolveProductOption(requestedColor, product.colors);
    // 색상 선택이 없는 상품은 클라이언트가 '-'를 전송하므로 검증에서 제외합니다.
    const hasColorSelection = !['', '-', '없음', '미지정'].includes(requestedColor.trim());
    const knownColor = _resolveProductOption(requestedColor, _CHECKOUT_COLOR_OPTIONS);
    const isKnownCheckoutColor = _CHECKOUT_COLOR_OPTIONS.includes(knownColor)
      || /^커스텀\s*\(#[0-9a-f]{6}\)$/i.test(requestedColor);
    if (hasColorSelection && Array.isArray(product.colors) && product.colors.length && !product.colors.includes(color) && !isKnownCheckoutColor) {
      console.error('Invalid product color', {
        productId,
        requestedColor,
        allowedColors: product.colors,
      });
      throw new Error('Invalid product color');
    }
    if ((Array.isArray(product.soldOutSizes) && product.soldOutSizes.includes(size)) || Number(product.stockCount || 0) < quantity) throw new Error('Product is out of stock');
    const unitPrice = Math.round(Number(product.price));
    subtotal += unitPrice * quantity;
    const requestedOptions = requested?.customOptions && typeof requested.customOptions === 'object' ? requested.customOptions : null;
    if (requestedOptions?.orderType === 'group' || requestedOptions?.orderType === 'additional') isGroup = true;
    items.push({ productId, productName: String(product.name || '').slice(0, 200), size, color, quantity, price: unitPrice, customOptions: requestedOptions || null, imageUrl: Array.isArray(product.images) ? String(product.images[0] || '') : '' });
  }
  const shippingFee = subtotal >= SHIPPING_FREE_THRESHOLD ? 0 : DEFAULT_SHIPPING_FEE;
  const coupons = await _calculateCoupons(uid, payload.couponIds, subtotal + shippingFee);
  if (payload.usedPoints && (payload.usedPoints < 10000 || payload.usedPoints > subtotal + shippingFee - coupons.discount)) throw new Error('Invalid points amount');
  const totalAmount = Math.max(0, subtotal + shippingFee - coupons.discount - payload.usedPoints);
  if (!Number.isSafeInteger(totalAmount) || totalAmount < 0) throw new Error('Invalid payment amount');
  const orderId = `${isGroup ? 'GRP' : 'ORD'}-${Date.now()}-${crypto.randomBytes(3).toString('hex')}`;
  const order = { id: orderId, userId: uid, userName: String(user.name || '고객').slice(0, 100), userEmail: String(user.email || '').slice(0, 254), userPhone: String(user.phone || '').slice(0, 40), userAddress: payload.deliveryAddress, items, subtotal, totalAmount, shippingFee, couponId: coupons.ids[0] || null, couponIds: coupons.ids, couponDiscount: coupons.discount, couponDiscounts: coupons.discounts, usedPoints: payload.usedPoints, pointDiscount: payload.usedPoints, paymentMethod: payload.paymentMethod, status: 'pending', orderType: isGroup ? 'group' : 'regular', memo: payload.memo || null };
  return { orderId, order, orderName: `${items[0].productName}${items.length > 1 ? ` 외 ${items.length - 1}건` : ''}`, couponId: coupons.ids[0] || '', couponIds: coupons.ids, usedPoints: payload.usedPoints, isBankTransfer: payload.paymentMethod.includes('무통장') };
}

async function _calculateCoupons(uid, couponIds, orderAmount) {
  const ids = Array.isArray(couponIds) ? couponIds : [];
  if (ids.length === 0) return { ids: [], discounts: [], discount: 0 };

  const coupons = [];
  for (const couponId of ids) {
    const snap = await db.collection('user_coupons').doc(uid).collection('coupons').doc(couponId).get();
    const coupon = snap.data();
    if (!snap.exists || coupon.isUsed === true || coupon.isReserved === true || coupon.expiresAt?.toDate?.() <= new Date()) {
      throw new Error('Coupon is unavailable');
    }
    // 관리자 수정사항은 이미 발급된 쿠폰에도 반영합니다.
    // 원본이 삭제된 경우에는 발급 당시의 사용자 쿠폰 설정을 유지합니다.
    const sourceSnap = await db.collection('admin_coupons').doc(couponId).get();
    const source = sourceSnap.data();
    const effectiveCoupon = sourceSnap.exists
      ? { ...coupon, isStackable: source?.isStackable === true }
      : coupon;
    coupons.push({ id: couponId, data: effectiveCoupon });
  }

  // 한 장만 쓸 때는 기존 쿠폰도 사용할 수 있지만, 여러 장이면
  // 선택된 모든 쿠폰이 관리자 설정상 중복 사용 허용이어야 합니다.
  if (coupons.length > 1 && coupons.some(({ data }) => data.isStackable !== true)) {
    throw new Error('Coupons cannot be combined');
  }

  const discounts = [];
  let remaining = orderAmount;
  for (const { data: coupon } of coupons) {
    const minimum = Number(coupon.minOrderAmount || 0);
    if (orderAmount < minimum) throw new Error('Coupon minimum order amount is not met');
    let discount = coupon.type === 'percent'
      ? Math.floor(remaining * Number(coupon.value || 0) / 100)
      : Math.floor(Number(coupon.value || 0));
    if (coupon.maxDiscountAmount != null) {
      discount = Math.min(discount, Math.floor(Number(coupon.maxDiscountAmount)));
    }
    discount = Math.max(0, Math.min(discount, remaining));
    discounts.push(discount);
    remaining -= discount;
  }
  return {
    ids: coupons.map(({ id }) => id),
    discounts,
    discount: discounts.reduce((sum, value) => sum + value, 0),
  };
}

async function _finalizeBankTransferOrder(uid, prepared) {
  await db.runTransaction(async (tx) => {
    const userRef = db.collection('users').doc(uid);
    const user = await tx.get(userRef);
    if (!user.exists) throw new Error('User profile unavailable');
    await _reserveBenefits(tx, uid, prepared, prepared.orderId, user.data() || {});
    tx.set(db.collection('orders').doc(prepared.orderId), {
      ...prepared.order,
      paymentStatus: 'awaiting_deposit',
      expiresAt: new Date(Date.now() + BANK_TRANSFER_TTL_MS),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

async function _reserveBenefits(tx, uid, prepared, orderId, user) {
  const couponIds = Array.isArray(prepared.couponIds)
    ? prepared.couponIds
    : (prepared.couponId ? [prepared.couponId] : []);
  const couponRefs = couponIds.map((couponId) =>
    db.collection('user_coupons').doc(uid).collection('coupons').doc(couponId));
  const couponSnaps = [];
  for (const couponRef of couponRefs) couponSnaps.push(await tx.get(couponRef));
  for (let i = 0; i < couponSnaps.length; i += 1) {
    const coupon = couponSnaps[i];
    if (!coupon.exists || coupon.data().isUsed === true || coupon.data().isReserved === true) {
      throw new Error('Coupon is unavailable');
    }
    tx.update(couponRefs[i], { isReserved: true, reservedOrderId: orderId, reservedAt: FieldValue.serverTimestamp() });
  }
  if (prepared.usedPoints > 0) {
    const balance = Math.floor(Number(user.points || 0));
    if (balance < prepared.usedPoints) throw new Error('Insufficient points');
    tx.update(db.collection('users').doc(uid), { points: balance - prepared.usedPoints });
    tx.set(db.collection('users').doc(uid).collection('point_history').doc(`reserve_${orderId}`), { action: 'use', amount: -prepared.usedPoints, desc: `주문 ${orderId} 포인트 사용`, orderId, createdAt: FieldValue.serverTimestamp() });
  }
}

async function _commitReservedBenefits(tx, uid, intent, orderId) {
  const couponIds = Array.isArray(intent.couponIds)
    ? intent.couponIds
    : (intent.couponId ? [intent.couponId] : []);
  for (const couponId of couponIds) {
    tx.update(db.collection('user_coupons').doc(uid).collection('coupons').doc(couponId), {
      isUsed: true,
      usedOrderId: orderId,
      usedAt: FieldValue.serverTimestamp(),
      isReserved: false,
      reservedOrderId: FieldValue.delete(),
      reservedAt: FieldValue.delete(),
    });
  }
}

async function _releasePaymentIntent(uid, orderId) {
  if (!uid || !orderId) throw new Error('Invalid payment request');
  await db.runTransaction(async (tx) => {
    const intentRef = db.collection('payment_intents').doc(orderId);
    const intentSnap = await tx.get(intentRef);
    const intent = intentSnap.data();
    if (!intentSnap.exists || intent.userId !== uid || intent.status !== 'pending') return;
    const couponIds = Array.isArray(intent.couponIds)
      ? intent.couponIds
      : (intent.couponId ? [intent.couponId] : []);
    for (const couponId of couponIds) {
      tx.update(db.collection('user_coupons').doc(uid).collection('coupons').doc(couponId), {
        isReserved: false,
        reservedOrderId: FieldValue.delete(),
        reservedAt: FieldValue.delete(),
      });
    }
    if (Number(intent.usedPoints || 0) > 0) {
      const userRef = db.collection('users').doc(uid);
      const user = await tx.get(userRef);
      const balance = Math.floor(Number(user.data()?.points || 0));
      tx.update(userRef, { points: balance + Number(intent.usedPoints) });
      tx.set(userRef.collection('point_history').doc(`refund_${orderId}`), { action: 'admin', amount: Number(intent.usedPoints), desc: `미완료 주문 ${orderId} 포인트 복구`, orderId, createdAt: FieldValue.serverTimestamp() });
    }
    tx.update(intentRef, { status: 'cancelled', cancelledAt: FieldValue.serverTimestamp() });
  });
}

function _safeCheckoutError(error) {
  const allowed = new Set(['Invalid order items', 'Invalid delivery address', 'Invalid payment method', 'Invalid product quantity', 'Product is unavailable', 'Invalid product size', 'Invalid product color', 'Product is out of stock', 'Coupon is unavailable', 'Coupon minimum order amount is not met', 'Coupons cannot be combined', 'Too many coupons', 'Invalid points amount', 'Insufficient points']);
  return allowed.has(error?.message) ? error.message : 'Unable to prepare a secure order';
}

// 쿠폰 할인 조건·다운로드 수·중복 발급을 서버에서 원자적으로 검증합니다.
exports.downloadSecureCoupon = onRequest({ cors: PAYMENT_CORS }, async (req, res) => {
  if (req.method !== 'POST') { res.status(405).json({ error: 'Method Not Allowed' }); return; }
  const decoded = await requireSignedIn(req, res, { checkRevoked: true });
  if (!decoded) return;
  if (!(await enforceRateLimit(req, res, `download-coupon:${decoded.uid}`, { limit: 20, windowMs: 60 * 60 * 1000 }))) return;
  const couponId = String(req.body?.couponId || '').slice(0, 120);
  if (!couponId) { res.status(400).json({ error: 'Coupon ID is required' }); return; }
  try {
    const result = await db.runTransaction(async (tx) => {
      const sourceRef = db.collection('admin_coupons').doc(couponId);
      const targetRef = db.collection('user_coupons').doc(decoded.uid).collection('coupons').doc(couponId);
      const source = await tx.get(sourceRef);
      const existing = await tx.get(targetRef);
      if (!source.exists || source.data()?.isDownloadable !== true) return 'not_downloadable';
      if (existing.exists) return 'already_downloaded';
      const coupon = source.data() || {};
      const expiresAt = coupon.expiresAt?.toDate?.();
      if (expiresAt && expiresAt <= new Date()) return 'expired';
      const limit = Number.isFinite(Number(coupon.downloadLimit)) ? Number(coupon.downloadLimit) : null;
      const count = Math.floor(Number(coupon.downloadCount || 0));
      if (limit !== null && count >= limit) return 'limit_exceeded';
      tx.set(targetRef, { couponId, code: String(coupon.code || ''), name: String(coupon.name || ''), type: coupon.type === 'percent' ? 'percent' : 'fixed', value: Math.max(0, Number(coupon.value || 0)), minOrderAmount: Math.max(0, Number(coupon.minOrderAmount || 0)), ...(coupon.maxDiscountAmount != null ? { maxDiscountAmount: Number(coupon.maxDiscountAmount) } : {}), ...(coupon.startsAt ? { startsAt: coupon.startsAt } : {}), ...(coupon.expiresAt ? { expiresAt: coupon.expiresAt } : {}), isUsed: false, isStackable: coupon.isStackable === true, downloadedAt: FieldValue.serverTimestamp() });
      tx.update(sourceRef, { downloadCount: FieldValue.increment(1) });
      return '';
    });
    res.status(200).json({ success: result === '', result });
  } catch (error) {
    console.error('downloadSecureCoupon failed:', { code: error?.code || 'coupon-download-failed' });
    res.status(400).json({ error: 'Coupon could not be downloaded' });
  }
});

exports.sendSolapiChatAlert = onRequest(
  { secrets: [SOLAPI_API_KEY, SOLAPI_API_SECRET], cors: [
    'https://2fit-mall.co.kr', 'https://fit-mall.web.app', 'http://localhost:5000',
  ] },
  async (req, res) => {
    if (req.method !== 'POST') { res.status(405).json({ error: 'Method Not Allowed' }); return; }
    const decoded = await requireSignedIn(req, res);
    if (!decoded) return;
    if (!(await enforceRateLimit(req, res, `chat-alert:${decoded.uid}`, { limit: 3, windowMs: 10 * 60 * 1000 }))) return;
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
    if (!(await enforceRateLimit(req, res, `order-notification:${decoded.uid}`, { limit: 5, windowMs: 60 * 60 * 1000 }))) return;
    const orderId = String(req.body?.orderId || '').trim().slice(0, 120);
    const kind = String(req.body?.kind || '');
    const params = req.body?.params && typeof req.body.params === 'object' ? req.body.params : {};
    if (!orderId || !ALLOWED_ORDER_NOTIFICATION_KINDS.has(kind)) {
      res.status(400).json({ error: 'Valid orderId and notification kind are required' }); return;
    }
    const orderSnap = await db.collection('orders').doc(orderId).get();
    if (!orderSnap.exists) { res.status(404).json({ error: 'Order not found' }); return; }
    const order = orderSnap.data();
    const isAdminUser = decoded.admin === true;
    if (!isAdminUser && order.userId !== decoded.uid) {
      res.status(403).json({ error: 'Order access denied' }); return;
    }
    // Customers may receive the one-time order-confirmed message only.
    // Delivery-state and cancellation notices are trusted back-office actions.
    if (!isAdminUser && kind !== 'order_confirmed') {
      res.status(403).json({ error: 'Only administrators may send order state notifications' }); return;
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
// 단체주문 고객 접수 알림: 알림톡 + 이메일
// ══════════════════════════════════════════════════════
async function _sendGroupOrderReceiptNotifications({ orderId, data }) {
  // 일반 상품 주문에는 발송하지 않고 단체주문만 대상으로 합니다.
  const orderType = String(data.orderType || data.customOptions?.orderType || '');
  if (orderType !== 'group' && orderType !== 'additional') return;

  const phone = String(data.userPhone || data.customOptions?.phone || '').replace(/[^0-9+]/g, '');
  const email = String(data.userEmail || data.customOptions?.email || '').trim().toLowerCase();
  const markerRef = db.collection('orders').doc(orderId)
    .collection('notification_deliveries').doc('group_order_receipt');
  const now = Date.now();

  // Firestore 트리거 재시도/중복 실행을 방지합니다. 10분이 지나면 실패한 발송을 재시도할 수 있습니다.
  const claim = await db.runTransaction(async (tx) => {
    const snap = await tx.get(markerRef);
    const marker = snap.data() || {};
    const claimedAt = Number(marker.claimedAtMs || 0);
    if (marker.status === 'sent' || (claimedAt && now - claimedAt < 10 * 60 * 1000)) {
      return null;
    }
    tx.set(markerRef, {
      status: 'processing',
      claimedAtMs: now,
      attempts: Number(marker.attempts || 0) + 1,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return marker;
  });
  if (claim === null) return;

  const name = String(data.userName || data.customOptions?.manager || '고객').slice(0, 80);
  const teamName = String(data.groupName || data.customOptions?.teamName || '-').slice(0, 100);
  const items = Array.isArray(data.items) ? data.items : [];
  const itemSummary = (items.length ? items.map((item) => item.productName || '상품').join(', ') : '단체주문 상품').slice(0, 160);
  const quantity = Number(data.groupCount || data.customOptions?.totalCount || items.reduce((sum, item) => sum + Number(item.quantity || 0), 0) || 0);
  const amount = Number(data.totalAmount || 0).toLocaleString('ko-KR');
  const orderNumber = String(orderId).slice(0, 80);
  const templateId = KAKAO_GROUP_ORDER_TEMPLATE_ID.value().trim();
  const results = {};

  if (templateId && /^\+?[0-9]{8,15}$/.test(phone)) {
    try {
      const result = await _sendSolapiAlimtalk({
        phone,
        templateId,
        variables: {
          '#{고객명}': name,
          '#{주문번호}': orderNumber,
          '#{팀명}': teamName,
          '#{상품명}': itemSummary,
          '#{수량}': String(quantity),
          '#{접수일시}': _formatKstTime(new Date()),
        },
      });
      results.alimtalk = result.ok ? 'sent' : `failed_${result.statusCode}`;
    } catch (error) {
      console.error('group order alimtalk error:', error);
      results.alimtalk = 'failed';
    }
  } else {
    results.alimtalk = templateId ? 'skipped_invalid_phone' : 'skipped_template_not_configured';
  }

  if (email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    try {
      const result = await _sendResendEmail({
        to: email,
        subject: `[2FIT MALL] 단체주문 접수 완료 (${orderNumber})`,
        text: `[2FIT MALL] ${name}님, 단체주문이 접수되었습니다.\\n주문번호: ${orderNumber}\\n팀명: ${teamName}\\n상품: ${itemSummary}\\n수량: ${quantity}\\n담당자가 확인 후 연락드리겠습니다.`,
        html: _groupOrderReceiptEmailHtml({ name, orderNumber, teamName, itemSummary, quantity, amount }),
      });
      results.email = result.ok ? 'sent' : `failed_${result.statusCode}`;
    } catch (error) {
      console.error('group order email error:', error);
      results.email = 'failed';
    }
  } else {
    results.email = email ? 'skipped_invalid_email' : 'skipped_no_email';
  }

  const sent = Object.values(results).some((status) => status === 'sent');
  await markerRef.set({
    status: sent ? 'sent' : 'failed',
    results,
    // 발송 로그에는 이메일·전화번호 원문을 저장하지 않습니다.
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

function _escapeHtml(value) {
  return String(value).replace(/[&<>'\"]/g, (char) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '\"': '&quot;',
  }[char]));
}

function _groupOrderReceiptEmailHtml({ name, orderNumber, teamName, itemSummary, quantity, amount }) {
  return `<!doctype html><html lang="ko"><body style="margin:0;background:#f6f5f2;font-family:Arial,'Apple SD Gothic Neo',sans-serif;color:#172033;">
  <div style="max-width:600px;margin:0 auto;padding:32px 18px;"><div style="background:#172033;color:#fff;border-radius:18px 18px 0 0;padding:24px 26px;"><div style="font-size:12px;letter-spacing:1.5px;opacity:.75;">2FIT MALL</div><h1 style="font-size:22px;margin:10px 0 0;">단체주문 접수 완료</h1></div>
  <div style="background:#fff;padding:28px 26px;border-radius:0 0 18px 18px;"><p style="font-size:16px;line-height:1.7;"><strong>${_escapeHtml(name)}님</strong>, 단체주문 신청이 정상적으로 접수되었습니다.</p>
  <div style="background:#f6f5f2;border-radius:12px;padding:18px;margin:22px 0;line-height:1.9;"><div><b>주문번호</b> ${_escapeHtml(orderNumber)}</div><div><b>팀명</b> ${_escapeHtml(teamName)}</div><div><b>상품</b> ${_escapeHtml(itemSummary)}</div><div><b>수량</b> ${_escapeHtml(quantity)}</div><div><b>예상 금액</b> ${_escapeHtml(amount)}원</div></div>
  <p style="font-size:14px;line-height:1.7;color:#5d6675;">담당자가 주문 내용을 확인한 뒤 디자인·견적 및 진행 일정을 안내드리겠습니다. 문의사항은 쇼핑몰 문의 채널을 이용해 주세요.</p>
  <p style="margin-top:28px;font-size:12px;color:#9299a5;">본 메일은 2FIT MALL 단체주문 접수 안내입니다.</p></div></div></body></html>`;
}

async function _sendResendEmail({ to, subject, text, html }) {
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${RESEND_API_KEY.value()}`,
    },
    body: JSON.stringify({ from: RESEND_FROM_EMAIL.value(), to: [to], subject, text, html }),
  });
  const responseText = await response.text();
  if (!response.ok) {
    console.error('Resend email request rejected:', response.status, responseText.slice(0, 500));
  }
  return { ok: response.ok, statusCode: response.status };
}

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
    phoneVerified: data.phoneVerified === true,
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
  const startedAt = Date.now();
  const sentAt = new Date().toISOString();
  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: { ...msgData, sentAt },
    android: { notification: { channelId: 'chat_alerts', priority: 'high', sound: 'default' } },
    apns:    { payload: { aps: { sound: 'default', badge: 1 } } },
    webpush: {
      notification: { icon: 'https://2fit-mall.co.kr/icons/Icon-192.png', requireInteraction: true },
      fcmOptions: { link: 'https://2fit-mall.co.kr/#/admin?tab=chat' },
    },
  });
  console.log(`FCM multicast timing: sentAt=${sentAt}, serverDurationMs=${Date.now() - startedAt}, success=${response.successCount}, failure=${response.failureCount}`);

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
