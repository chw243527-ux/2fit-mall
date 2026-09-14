import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/order_service.dart';
import '../../utils/theme.dart';

/// 관리자 전용 단체주문 접수 관리 화면.
/// 일반 주문 탭과 분리해 단체 주문만 조회하고 상태를 변경합니다.
class AdminGroupOrderTab extends StatefulWidget {
  const AdminGroupOrderTab({super.key});

  @override
  State<AdminGroupOrderTab> createState() => _AdminGroupOrderTabState();
}

class _AdminGroupOrderTabState extends State<AdminGroupOrderTab> {
  String _statusFilter = 'all';
  String _query = '';

  static const _statusOptions = <String, String>{
    'all': '전체 상태',
    'pending': '접수·입금 대기',
    'confirmed': '주문 확인',
    'processing': '제작·준비 중',
    'shipped': '배송 중',
    'delivered': '배송 완료',
    'cancelled': '취소',
    'refunded': '환불',
  };

  List<OrderModel> _filtered(List<OrderModel> orders) {
    final query = _query.trim().toLowerCase();
    return orders.where((order) {
      if (order.orderType != 'group') return false;
      if (_statusFilter != 'all' && order.status.name != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final options = order.customOptions ?? const <String, dynamic>{};
      final haystack = [
        order.id,
        order.userName,
        order.userPhone,
        order.userEmail,
        order.groupName ?? '',
        options['teamName'] ?? '',
        options['manager'] ?? '',
        options['phone'] ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  String _statusLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => '접수·입금 대기',
      OrderStatus.confirmed => '주문 확인',
      OrderStatus.processing => '제작·준비 중',
      OrderStatus.shipped => '배송 중',
      OrderStatus.delivered => '배송 완료',
      OrderStatus.purchaseConfirmed => '구매 확정',
      OrderStatus.cancelled => '취소',
      OrderStatus.refunded => '환불',
    };
  }

  Color _statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => AppColors.warning,
      OrderStatus.confirmed => AppColors.info,
      OrderStatus.processing => AppColors.primary,
      OrderStatus.shipped => const Color(0xFF6A5ACD),
      OrderStatus.delivered || OrderStatus.purchaseConfirmed => AppColors.success,
      OrderStatus.cancelled || OrderStatus.refunded => AppColors.error,
    };
  }

  String _money(double value) =>
      value.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  String _date(DateTime value) =>
      '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.watchAllOrders(),
      builder: (context, snapshot) {
        final orders = _filtered(snapshot.data ?? const <OrderModel>[]);
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              _buildToolbar(orders.length),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : orders.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                            itemCount: orders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, index) => _buildOrderCard(orders[index]),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('단체주문 접수 관리',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              Text('$count건', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: '팀명·주문번호·담당자 검색',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surfaceGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _statusFilter,
                  items: _statusOptions.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text('조건에 맞는 단체주문이 없습니다',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final options = order.customOptions ?? const <String, dynamic>{};
    final teamName = (order.groupName ?? options['teamName'] ?? '팀명 미입력').toString();
    final manager = (options['manager'] ?? order.userName).toString();
    final phone = (options['phone'] ?? order.userPhone).toString();
    final count = order.groupCount ?? int.tryParse('${options['persons'] ?? ''}') ?? 0;
    final color = _statusColor(order.status);

    return InkWell(
      onTap: () => _showDetail(order),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel(order.status),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.id} · ${_date(order.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _meta(Icons.person_outline_rounded, manager),
                _meta(Icons.phone_outlined, phone),
                _meta(Icons.groups_outlined, count > 0 ? '$count명' : '인원 미입력'),
                _meta(Icons.payments_outlined, '₩${_money(order.totalAmount)}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('상세 보기', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Future<void> _showDetail(OrderModel order) async {
    var selected = order.status;
    final options = order.customOptions ?? const <String, dynamic>{};
    final result = await showDialog<OrderStatus>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(order.groupName ?? options['teamName']?.toString() ?? '단체주문 상세'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailLine('주문번호', order.id),
                    _detailLine('접수일시', _date(order.createdAt)),
                    _detailLine('담당자', '${options['manager'] ?? order.userName}'),
                    _detailLine('연락처', '${options['phone'] ?? order.userPhone}'),
                    _detailLine('이메일', '${options['email'] ?? order.userEmail}'),
                    _detailLine('인원', '${options['persons'] ?? order.groupCount ?? '-'}명'),
                    _detailLine('배송지', order.userAddress),
                    _detailLine('주문금액', '₩${_money(order.totalAmount)}'),
                    if (options['memo'] != null) _detailLine('메모', '${options['memo']}'),
                    const Divider(height: 28),
                    const Text('주문 상품', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('${item.productName} · ${item.color} · ${item.size} · ${item.quantity}개'),
                        )),
                    const SizedBox(height: 16),
                    const Text('상태 변경', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<OrderStatus>(
                      value: selected,
                      items: OrderStatus.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(_statusLabel(status)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => selected = value);
                      },
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('닫기')),
              FilledButton(
                onPressed: selected == order.status
                    ? null
                    : () => Navigator.pop(dialogContext, selected),
                child: const Text('상태 저장'),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted || result == null || result == order.status) return;
    try {
      await OrderService.updateOrderStatusStrict(order.id, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_statusLabel(result)} 상태로 변경했습니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태 변경에 실패했습니다: $error')),
      );
    }
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 78, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

extension on OrderModel {
  int? get groupCountOrNull => groupCount;
}
