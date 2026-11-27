const crypto = require('crypto');

const ELIGIBLE_STATUSES = new Set([
  'confirmed',
  'processing',
  'shipped',
  'delivered',
  'purchaseConfirmed',
]);

function normalizePhone(value) {
  const digits = String(value || '').replace(/[^0-9]/g, '');
  const normalized = digits.startsWith('82') ? `0${digits.slice(2)}` : digits;
  return /^01[016789]\d{7,8}$/.test(normalized) ? normalized : '';
}

function phonesMatch(left, right) {
  const a = normalizePhone(left);
  const b = normalizePhone(right);
  return Boolean(a && b && a === b);
}

function maskedEmail(value) {
  const email = String(value || '').trim();
  const at = email.indexOf('@');
  if (at <= 0) return email ? '***' : '';
  const local = email.slice(0, at);
  return `${local.slice(0, Math.min(2, local.length))}***${email.slice(at)}`;
}

function maskedPhone(value) {
  const phone = normalizePhone(value);
  return phone.length >= 4 ? `***-****-${phone.slice(-4)}` : '';
}

function createOrderId() {
  return `NEXTR-${crypto.randomBytes(16).toString('hex')}`;
}

function isEligibleOrder(order) {
  return order?.orderType === 'group'
    && order?.paymentStatus === 'paid'
    && ELIGIBLE_STATUSES.has(order?.status)
    && typeof order?.paymentLinkId === 'string'
    && order.paymentLinkId.trim().length > 0;
}

function isMatchingPaymentLink(link, orderId) {
  return Boolean(link && link.orderId === orderId);
}

function rateLimitDecision({ now, startedAt, count, limit, windowMs }) {
  if (!startedAt || now - startedAt >= windowMs) {
    return { allowed: true, reset: true, startedAt: now, count: 1 };
  }
  if (count < limit) {
    return { allowed: true, reset: false, startedAt, count: count + 1 };
  }
  return { allowed: false, reset: false, startedAt, count };
}

function buildAuditLog({ action, orderId, actorUid, actorEmail, targetUserId, source }) {
  return {
    action: String(action || '').slice(0, 80),
    orderId: String(orderId || '').slice(0, 120),
    actorUid: String(actorUid || '').slice(0, 160),
    actorEmail: String(actorEmail || '').slice(0, 254),
    targetUserId: String(targetUserId || '').slice(0, 160),
    source: String(source || '').slice(0, 40),
  };
}

module.exports = {
  ELIGIBLE_STATUSES,
  normalizePhone,
  phonesMatch,
  maskedEmail,
  maskedPhone,
  createOrderId,
  isEligibleOrder,
  isMatchingPaymentLink,
  rateLimitDecision,
  buildAuditLog,
};
