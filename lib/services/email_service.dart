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
          'referer': '$_origin/',
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
        'shop_url': '$_origin/#/admin?tab=orders',
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
        'order_url': '$_origin/#/admin?tab=orders',
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

  // ── 채팅 문의 관리자 알림 이메일 ─────────────────────
  // 고객이 채팅 메시지를 보낼 때마다 관리자 이메일로 즉시 알림
  static Future<bool> sendChatAlert({
    required String userName,
    required String message,
    required String userId,
  }) async {
    const adminEmail = 'chw243527@gmail.com'; // 관리자 이메일
    const templateId = 'template_chat_alert';  // EmailJS 템플릿 ID

    final now = DateTime.now();
    final timeStr =
        '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} '
        '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

    return _sendEmail(
      templateId: templateId,
      templateParams: {
        'to_email': adminEmail,
        'to_name': '2FIT MALL 관리자',
        'from_name': userName,
        'message': message,
        'chat_time': timeStr,
        'user_id': userId,
        'admin_url': 'https://2fit-mall.co.kr/#/admin?tab=chat',
        'shop_name': '2FIT MALL',
      },
    );
  }

  // ── 무통장입금 주문 관리자 알림 이메일 ────────────────
  // 무통장입금 주문 발생 시 관리자에게 입금 확인 요청 발송
  /// 범용 관리자 알림 이메일 (디자인 수정 요청 등)
  static Future<bool> sendAdminAlert({
    required String subject,
    required String body,
  }) async {
    const adminEmail = 'chw243527@gmail.com';
    return _sendEmail(
      templateId: _templateStatusId,
      templateParams: {
        'to_email': adminEmail,
        'to_name': '2FIT MALL 관리자',
        'order_id': subject,
        'order_id_short': subject.length > 20 ? subject.substring(0, 20) : subject,
        'status': '관리자 알림',
        'status_message': subject,
        'action_message': body,
        'tracking_number': '',
        'courier_name': '',
        'order_url': 'https://2fit-mall.co.kr/#/admin?tab=orders',
        'shop_name': '2FIT MALL',
      },
    );
  }

  static Future<bool> sendBankTransferAdminAlert(OrderModel order) async {
    // 관리자 수신 이메일 (constants.dart의 CS 이메일로 발송)
    const adminEmail = 'chw243527@gmail.com'; // ✏️ 실제 관리자 이메일로 교체

    final itemList = order.items
        .map((i) => '${i.productName} (${i.size}/${i.color}) × ${i.quantity}개')
        .join('\n');

    return _sendEmail(
      templateId: _templateStatusId, // 기존 template_status 재활용
      templateParams: {
        'to_email': adminEmail,
        'to_name': '2FIT MALL 관리자',
        'order_id': order.id,
        'order_id_short': order.id.length > 8 ? order.id.substring(0, 8) : order.id,
        'status': '무통장입금 대기',
        'status_message': '⚠️ 무통장입금 주문이 접수되었습니다. 입금 확인 후 처리해 주세요.',
        'action_message':
            '주문자: ${order.userName} | 연락처: ${order.userPhone}\n'
            '주문금액: ${_fmtPrice(order.totalAmount)}원\n'
            '주문상품:\n$itemList\n'
            '배송지: ${order.userAddress}',
        'tracking_number': '',
        'courier_name': '',
        'order_url': 'https://2fit-mall.co.kr/#/admin?tab=orders',
        'shop_name': '2FIT MALL',
      },
    );
  }
}
