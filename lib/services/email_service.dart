// email_service.dart - 이메일 자동 발송 (EmailJS API)
// EmailJS: https://www.emailjs.com (무료: 월 200건, 템플릿 2개)
// 사용 템플릿: template_order (주문확인), template_status (상태변경)
// 환영/비밀번호 이메일 → Firebase Authentication 자동 처리
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class EmailService {
  // ── EmailJS 설정 ─────────────────────────────────────
  static const _serviceId = 'service_2fitmall';
  static const _templateOrderId = 'template_order';   // 주문 확인
  static const _templateStatusId = 'template_status'; // 상태 변경
  static const _publicKey = 'S7NAATfTC4cwKqgK7';
  static const _origin = 'https://2fit-mall.co.kr';   // 실제 도메인

  static final _db = FirebaseFirestore.instance;

  // ── EmailJS API 호출 ──────────────────────────────────
  static Future<bool> _sendEmail({
    required String templateId,
    required Map<String, dynamic> templateParams,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': _origin,
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': templateId,
          'user_id': _publicKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) debugPrint('✅ 이메일 발송 성공: $templateId');
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ 이메일 발송 실패: ${response.statusCode} ${response.body}');
        }
        return _queueEmail(templateId: templateId, params: templateParams);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('EmailJS 오류: $e');
      return _queueEmail(templateId: templateId, params: templateParams);
    }
  }

  // ── Firestore 이메일 큐 (발송 실패 시 저장 → 재시도) ─
  static Future<bool> _queueEmail({
    required String templateId,
    required Map<String, dynamic> params,
  }) async {
    try {
      await _db.collection('email_queue').add({
        'templateId': templateId,
        'params': params,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) debugPrint('📧 이메일 큐 저장 완료');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('이메일 큐 저장 실패: $e');
      return false;
    }
  }

  // ── 주문 확인 이메일 ──────────────────────────────────
  static Future<bool> sendOrderConfirmEmail(OrderModel order) async {
    if (order.userEmail.isEmpty) return false;

    final itemList = order.items
        .map((i) => '${i.productName} (${i.size}/${i.color}) × ${i.quantity}개 - ${_fmtPrice(i.price * i.quantity)}원')
        .join(', ');

    return _sendEmail(
      templateId: _templateOrderId,
      templateParams: {
        'to_email': order.userEmail,
        'to_name': order.userName,
        'order_id': order.id,
        'order_date': '${order.createdAt.year}.${order.createdAt.month.toString().padLeft(2,'0')}.${order.createdAt.day.toString().padLeft(2,'0')}',
        'item_list': itemList,
        'total_amount': '${_fmtPrice(order.totalAmount)}원',
        'shipping_fee': order.shippingFee > 0 ? '${_fmtPrice(order.shippingFee)}원' : '무료',
        'shipping_address': order.userAddress,
        'payment_method': order.paymentMethod,
        'shop_name': '2FIT MALL',
        'shop_url': _origin,
      },
    );
  }

  // ── 주문 상태 변경 이메일 ─────────────────────────────
  static Future<bool> sendOrderStatusEmail({
    required OrderModel order,
    required OrderStatus newStatus,
    String? trackingNumber,
    String? courierName,
  }) async {
    if (order.userEmail.isEmpty) return false;

    String statusMsg = '';
    String actionMsg = '';

    switch (newStatus) {
      case OrderStatus.confirmed:
        statusMsg = '주문이 확인되었습니다';
        actionMsg = '주문 내역을 확인하시려면 아래 버튼을 클릭하세요.';
        break;
      case OrderStatus.processing:
        statusMsg = '상품 제작/준비 중입니다';
        actionMsg = '고객님의 상품을 정성껏 준비하고 있습니다.';
        break;
      case OrderStatus.shipped:
        statusMsg = '배송이 시작되었습니다';
        actionMsg = trackingNumber != null
            ? '운송장 번호: $trackingNumber (${courierName ?? '택배사'})'
            : '배송이 시작되었습니다.';
        break;
      case OrderStatus.delivered:
        statusMsg = '배송이 완료되었습니다';
        actionMsg = '상품을 수령하셨나요? 리뷰를 남겨주시면 감사하겠습니다.';
        break;
      case OrderStatus.cancelled:
        statusMsg = '주문이 취소되었습니다';
        actionMsg = '주문 취소가 완료되었습니다. 결제 금액은 3-5일 내 환불됩니다.';
        break;
      default:
        statusMsg = newStatus.label;
        actionMsg = '';
    }

    final sid = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    return _sendEmail(
      templateId: _templateStatusId,
      templateParams: {
        'to_email': order.userEmail,
        'to_name': order.userName,
        'order_id': order.id,
        'order_id_short': sid,
        'status': newStatus.label,
        'status_message': statusMsg,
        'action_message': actionMsg,
        'tracking_number': trackingNumber ?? '',
        'courier_name': courierName ?? '',
        'order_url': _origin,
        'shop_name': '2FIT MALL',
      },
    );
  }

  // ── 가격 포맷 ─────────────────────────────────────────
  static String _fmtPrice(double amount) {
    final n = amount.toInt();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
