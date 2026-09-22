// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../services/order_excel_service.dart';
import '../../utils/web_utils.dart'
    if (dart.library.html) '../../utils/web_utils_html.dart';
import '../../services/order_service.dart';
import '../../services/group_order_policy_service.dart';
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
  bool _isGeneratingPdf = false;

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
      OrderStatus.delivered ||
      OrderStatus.purchaseConfirmed =>
        AppColors.success,
      OrderStatus.cancelled || OrderStatus.refunded => AppColors.error,
    };
  }

  String _money(double value) => value
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) =>
                                _buildOrderCard(orders[index]),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(int count) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        const title = Text(
          '단체주문 접수 관리',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        );
        final countText = Text('$count건',
            style: const TextStyle(color: AppColors.textSecondary));
        final policyButton = OutlinedButton.icon(
          onPressed: _openPolicyDialog,
          icon: const Icon(Icons.tune_rounded, size: 16),
          label: const Text('정책 설정'),
        );
        final header = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [countText, policyButton],
                  ),
                ],
              )
            : Row(
                children: [
                  const Expanded(child: title),
                  countText,
                  const SizedBox(width: 8),
                  policyButton,
                ],
              );
        final search = TextField(
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
        );
        final status = DropdownButtonFormField<String>(
          value: _statusFilter,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: '주문 상태',
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          items: _statusOptions.entries
              .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
        );
        final filters = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [search, const SizedBox(height: 8), status],
              )
            : Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 10),
                  SizedBox(width: 180, child: status),
                ],
              );
        return Container(
          padding: EdgeInsets.fromLTRB(20, compact ? 12 : 16, 20, 12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [header, const SizedBox(height: 12), filters],
          ),
        );
      },
    );
  }

  Future<void> _openPolicyDialog() async {
    final policy = await GroupOrderPolicyService.getPolicy();
    if (!mounted) return;
    final minCtrl = TextEditingController(text: '${policy.minimumQuantity}');
    final discountCtrl = TextEditingController(text: '${policy.discountRate}');
    final result = await showDialog<GroupOrderPolicy>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('단체주문 정책 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '최소 주문 수량',
                suffixText: '명',
                helperText: '단체주문 폼에서 이 수량 미만은 제출할 수 없습니다.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '단체주문 할인율',
                suffixText: '%',
                helperText: '상품 합계에 적용됩니다. 0~90% 범위.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소')),
          FilledButton(
            onPressed: () {
              final minimum = int.tryParse(minCtrl.text.trim());
              final discount = double.tryParse(discountCtrl.text.trim());
              if (minimum == null ||
                  minimum < 1 ||
                  discount == null ||
                  discount < 0 ||
                  discount > 90) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('수량과 할인율을 올바르게 입력해 주세요.')));
                return;
              }
              Navigator.pop(
                dialogContext,
                GroupOrderPolicy(
                    minimumQuantity: minimum, discountRate: discount),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    minCtrl.dispose();
    discountCtrl.dispose();
    if (!mounted || result == null) return;
    try {
      await GroupOrderPolicyService.savePolicy(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('단체주문 정책을 저장했습니다.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('정책 저장 실패: $error')));
    }
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
    final teamName =
        (order.groupName ?? options['teamName'] ?? '팀명 미입력').toString();
    final manager = (options['manager'] ?? order.userName).toString();
    final phone = (options['phone'] ?? order.userPhone).toString();
    final count =
        order.groupCount ?? int.tryParse('${options['persons'] ?? ''}') ?? 0;
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
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel(order.status),
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.id} · ${_date(order.createdAt)}',
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textHint)),
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('상세 보기',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded, size: 18),
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
        Text(text,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
          final dialogWidth = (MediaQuery.sizeOf(context).width - 32)
              .clamp(280.0, 560.0)
              .toDouble();
          return AlertDialog(
            title: Text(order.groupName ??
                options['teamName']?.toString() ??
                '단체주문 상세'),
            content: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailLine('주문번호', order.id),
                    _detailLine('접수일시', _date(order.createdAt)),
                    _detailLine(
                        '담당자', '${options['manager'] ?? order.userName}'),
                    _detailLine(
                        '연락처', '${options['phone'] ?? order.userPhone}'),
                    _detailLine(
                        '이메일', '${options['email'] ?? order.userEmail}'),
                    _detailLine('인원',
                        '${options['persons'] ?? order.groupCount ?? '-'}명'),
                    _detailLine('배송지', order.userAddress),
                    _detailLine('주문금액', '₩${_money(order.totalAmount)}'),
                    if (options['memo'] != null)
                      _detailLine('메모', '${options['memo']}'),
                    const Divider(height: 28),
                    const Text('주문 상품',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${item.productName} · ${item.color} · ${item.size} · ${item.quantity}개',
                            softWrap: true,
                          ),
                        )),
                    if (_isSingletOrder(order)) ...[
                      const SizedBox(height: 16),
                      const Text('싱글렛 단체주문 주문서',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isGeneratingPdf
                                ? null
                                : () => _downloadSingletPdf(order,
                                    productionOnly: false),
                            icon: const Icon(Icons.picture_as_pdf, size: 17),
                            label: const Text('고객용 PDF 다운로드'),
                          ),
                          FilledButton.icon(
                            onPressed: _isGeneratingPdf
                                ? null
                                : () => _downloadSingletPdf(order,
                                    productionOnly: true),
                            icon: const Icon(Icons.factory_outlined, size: 17),
                            label: const Text('발주용 PDF 다운로드'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('상태 변경',
                        style: TextStyle(fontWeight: FontWeight.w800)),
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
                        if (value != null)
                          setDialogState(() => selected = value);
                      },
                      decoration: const InputDecoration(
                          isDense: true, border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('닫기')),
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

  bool _isSingletOrder(OrderModel order) {
    final options = order.customOptions ?? const <String, dynamic>{};
    final values = <dynamic>[
      ...order.items.map((item) => item.productName),
      options['productName'],
      options['productNames'],
      options['category'],
      options['subCategory'],
      options['groupProductName'],
    ];
    final text = values.whereType<Object>().join(' ').toLowerCase();
    return text.contains('싱글렛') || text.contains('singlet');
  }

  Future<void> _downloadSingletPdf(OrderModel order,
      {required bool productionOnly}) async {
    if (!_isSingletOrder(order)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('싱글렛 단체주문 전용 주문서가 아닙니다.'),
        ));
      }
      return;
    }
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);
    try {
      // 목록에 캐시된 주문이 아니라 Firestore의 최신 주문 원문을 다시 읽습니다.
      // 따라서 주문서 저장 직후 수정된 옵션·명단·첨부 URL·금액도 PDF에 반영됩니다.
      final latestOrder = await OrderService.getOrderByIdStrict(order.id);
      if (!_isSingletOrder(latestOrder)) {
        throw StateError('싱글렛 단체주문 데이터를 찾을 수 없습니다.');
      }
      final bytes = await OrderExcelService.generateGroupOrderPdf(
        latestOrder,
        productionOnly: productionOnly,
      );
      final suffix = productionOnly ? '발주용' : '고객용';
      final fileName = '싱글렛단체주문_${latestOrder.id}_$suffix.pdf';
      if (kIsWeb) {
        downloadFileWeb(bytes, fileName, 'application/pdf');
      } else {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/$fileName';
        await File(path).writeAsBytes(bytes, flush: true);
        await SharePlus.instance.share(ShareParams(
          files: [XFile(path, mimeType: 'application/pdf', name: fileName)],
          subject: '싱글렛 단체주문 $suffix 주문서',
        ));
      }
      await _writePdfAuditLog(
        orderId: latestOrder.id,
        documentType: productionOnly ? 'production' : 'customer',
        outcome: 'success',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최신 주문 데이터로 $fileName 생성을 완료했습니다.')),
      );
    } catch (error) {
      await _writePdfAuditLog(
        orderId: order.id,
        documentType: productionOnly ? 'production' : 'customer',
        outcome: 'failure',
        error: error.toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최신 주문 데이터를 읽거나 PDF를 생성하지 못했습니다: $error')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _writePdfAuditLog({
    required String orderId,
    required String documentType,
    required String outcome,
    String? error,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('admin_audit_logs').add({
        'action': 'group_order_pdf_generation',
        'orderId': orderId,
        'documentType': documentType,
        'outcome': outcome,
        if (error != null)
          'error': error.substring(0, error.length > 500 ? 500 : error.length),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 감사 로그 실패가 주문서 PDF 다운로드 자체를 막지 않도록 무시합니다.
    }
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 78,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12))),
          Expanded(
              child: Text(value.isEmpty ? '-' : value,
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

extension on OrderModel {
// ignore: unused_element
  int? get groupCountOrNull => groupCount;
}
