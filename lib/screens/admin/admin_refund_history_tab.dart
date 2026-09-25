import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class AdminRefundHistoryTab extends StatelessWidget {
  const AdminRefundHistoryTab({super.key});

  String _money(num value) => value
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (match) => ',');

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return value is String ? DateTime.tryParse(value) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('환불 내역'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('환불 내역을 불러오지 못했습니다.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data!.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where((row) => _isRefund(row))
              .toList()
            ..sort((a, b) => (_date(
                        b['cancelledAt'] ?? b['updatedAt'] ?? b['createdAt']) ??
                    DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(_date(
                        a['cancelledAt'] ?? a['updatedAt'] ?? a['createdAt']) ??
                    DateTime.fromMillisecondsSinceEpoch(0)));

          final company =
              rows.where((r) => r['cancelType'] == 'company_fault').toList();
          final customer =
              rows.where((r) => r['cancelType'] != 'company_fault').toList();
          final total = rows.fold<double>(
              0,
              (totalAmount, row) =>
                  totalAmount +
                  _number(row['refundAmount'] ?? row['totalAmount']));
          final shipping = rows.fold<double>(
              0,
              (totalAmount, row) =>
                  totalAmount + _number(row['refundShippingFee']));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summary(total, shipping, company.length, customer.length),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('취소·환불 내역이 없습니다.')),
                  ),
                )
              else
                ...rows.map((row) => _RefundCard(
                      row: row,
                      date: _date(row['cancelledAt'] ??
                          row['updatedAt'] ??
                          row['createdAt']),
                      money: _money,
                    )),
            ],
          );
        },
      ),
    );
  }

  bool _isRefund(Map<String, dynamic> row) {
    final status = row['paymentStatus']?.toString() ?? '';
    final orderStatus = row['status']?.toString() ?? '';
    return row['cancelType'] != null ||
        row['refundAmount'] != null ||
        status == 'refunded' ||
        status == 'partially_refunded' ||
        orderStatus == 'cancelled' ||
        orderStatus == 'refunded';
  }

  double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  Widget _summary(
      double total, double shipping, int companyCount, int customerCount) {
    Widget tile(String title, String value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ],
            ),
          ),
        );

    return Column(
      children: [
        Row(children: [
          tile('환불 합계', '${_money(total)}원', AppColors.primary),
          const SizedBox(width: 8),
          tile('환불 배송비', '${_money(shipping)}원', AppColors.success),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          tile('회사 측 귀책', '$companyCount건', AppColors.error),
          const SizedBox(width: 8),
          tile('단순 변심', '$customerCount건', AppColors.warning),
        ]),
      ],
    );
  }
}

class _RefundCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final DateTime? date;
  final String Function(num) money;

  const _RefundCard(
      {required this.row, required this.date, required this.money});

  @override
  Widget build(BuildContext context) {
    final company = row['cancelType'] == 'company_fault';
    final reason = company ? '회사 측 귀책' : '단순 변심';
    final refund = row['refundAmount'] ?? row['totalAmount'] ?? 0;
    final shipping = row['refundShippingFee'] ?? 0;
    final eventCoupon = row['eventCouponNotRestored'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(row['id']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (company ? AppColors.error : AppColors.warning)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(reason,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: company ? AppColors.error : AppColors.warning)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('${row['userName'] ?? '고객'} · ${row['userPhone'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 6),
          Text('환불 금액: ${money(refund)}원 · 배송비 환불: ${money(shipping)}원',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          if ((row['cancelReason'] ?? '').toString().isNotEmpty)
            Text('상세 사유: ${row['cancelReason']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (eventCoupon)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('이벤트성 쿠폰 미복구',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.w700)),
            ),
          if (date != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  '처리일: ${date!.year}.${date!.month.toString().padLeft(2, '0')}.${date!.day.toString().padLeft(2, '0')} ${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
        ]),
      ),
    );
  }
}
