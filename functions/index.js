// Firebase Cloud Functions - 2FIT Mall
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

const ADMIN_TOKENS_DOC = 'admin_config/fcm_tokens';

// ══════════════════════════════════════════════════════
// 1) 새 주문 접수 알림 (기존)
// ══════════════════════════════════════════════════════
exports.onNewOrder = onDocumentCreated('orders/{orderId}', async (event) => {
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
  } catch (e) { console.error('onNewOrder error:', e); }
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
  'chats/{roomId}/messages/{messageId}',
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
        console.log('관리자 토큰 없음 - 로그인 후 자동 등록됩니다');
        return;
      }
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
    } catch (e) { console.error('onNewChatMessage error:', e); }
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
// 헬퍼 함수들
// ══════════════════════════════════════════════════════
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

function _fmt(n) {
  return Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
