const assert = require('node:assert/strict');
const test = require('node:test');
const fs = require('node:fs');
const path = require('node:path');

const {
  normalizePhone,
  phonesMatch,
  maskedEmail,
  maskedPhone,
  createOrderId,
  isEligibleOrder,
  isMatchingPaymentLink,
  rateLimitDecision,
  buildAuditLog,
} = require('../nextr_order_link_security');

test('normalizes Korean mobile numbers and accepts +82 format only when valid', () => {
  assert.equal(normalizePhone('010-1234-5678'), '01012345678');
  assert.equal(normalizePhone('+82 10 1234 5678'), '01012345678');
  assert.equal(normalizePhone('0111234567'), '0111234567');
  assert.equal(normalizePhone('0101234'), '');
  assert.equal(normalizePhone('0201234567'), '');
  assert.equal(phonesMatch('010-1234-5678', '+821012345678'), true);
  assert.equal(phonesMatch('010-1234-5678', '010-9999-5678'), false);
});

test('masks member contact details returned by admin search', () => {
  assert.equal(maskedEmail('honggildong@example.com'), 'ho***@example.com');
  assert.equal(maskedPhone('010-1234-5678'), '***-****-5678');
  assert.equal(maskedEmail(''), '');
  assert.equal(maskedPhone('not-a-phone'), '');
});

test('creates unpredictable NEXTR order IDs without a timestamp', () => {
  const ids = new Set(Array.from({ length: 20 }, () => createOrderId()));
  assert.equal(ids.size, 20);
  for (const id of ids) {
    assert.match(id, /^NEXTR-[0-9a-f]{32}$/);
    assert.doesNotMatch(id, /\d{13}/);
  }
});

test('allows only paid group orders linked to a payment link', () => {
  const base = {
    orderType: 'group',
    paymentStatus: 'paid',
    status: 'confirmed',
    paymentLinkId: 'nextr-link-1',
  };
  assert.equal(isEligibleOrder(base), true);
  for (const status of ['pending', 'awaiting_deposit', 'cancelled', 'refunded']) {
    assert.equal(isEligibleOrder({ ...base, status }), false, status);
  }
  assert.equal(isEligibleOrder({ ...base, orderType: 'regular' }), false);
  assert.equal(isEligibleOrder({ ...base, paymentStatus: 'awaiting_deposit' }), false);
  assert.equal(isEligibleOrder({ ...base, paymentLinkId: '' }), false);
  assert.equal(isMatchingPaymentLink({ orderId: 'NEXTR-1' }, 'NEXTR-1'), true);
  assert.equal(isMatchingPaymentLink({ orderId: 'NEXTR-2' }, 'NEXTR-1'), false);
});

test('enforces fixed-window rate limit decisions', () => {
  const first = rateLimitDecision({ now: 1000, startedAt: 0, count: 0, limit: 2, windowMs: 60000 });
  assert.deepEqual(first, { allowed: true, reset: true, startedAt: 1000, count: 1 });
  const second = rateLimitDecision({ now: 2000, startedAt: 1000, count: 1, limit: 2, windowMs: 60000 });
  assert.deepEqual(second, { allowed: true, reset: false, startedAt: 1000, count: 2 });
  const blocked = rateLimitDecision({ now: 3000, startedAt: 1000, count: 2, limit: 2, windowMs: 60000 });
  assert.equal(blocked.allowed, false);
  const renewed = rateLimitDecision({ now: 61000, startedAt: 1000, count: 2, limit: 2, windowMs: 60000 });
  assert.deepEqual(renewed, { allowed: true, reset: true, startedAt: 61000, count: 1 });
});

test('builds bounded audit records without storing raw request metadata', () => {
  const record = buildAuditLog({
    action: 'nextr_order_member_link',
    orderId: 'O'.repeat(200),
    actorUid: 'U'.repeat(200),
    actorEmail: 'admin@example.com',
    targetUserId: 'T'.repeat(200),
    source: 'customer_claim',
    ip: '203.0.113.10',
  });
  assert.equal(record.orderId.length, 120);
  assert.equal(record.actorUid.length, 160);
  assert.equal(record.targetUserId.length, 160);
  assert.equal(record.source, 'customer_claim');
  assert.equal('ip' in record, false);
});

test('keeps the client Firebase token and audit-log security contracts wired', () => {
  const service = fs.readFileSync(
    path.join(__dirname, '../../lib/services/nextr_payment_link_service.dart'),
    'utf8',
  );
  const functions = fs.readFileSync(path.join(__dirname, '../index.js'), 'utf8');
  assert.match(service, /signedIn:\s*true/);
  assert.match(service, /headers\['Authorization'\]\s*=\s*'Bearer \$token'/);
  assert.match(functions, /admin_audit_logs/);
  assert.equal((functions.match(/writeNextrOrderLinkAudit\(/g) || []).length >= 3, true);
  assert.match(functions, /nextr-guest-claim:\$\{decoded\.uid\}/);
});
