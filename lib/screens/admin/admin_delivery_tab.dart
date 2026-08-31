import '../../utils/theme.dart';
// admin_delivery_tab.dart — 배송관리 탭
// 기능: 배송 현황 요약 / 배송중 주문 목록 / 운송장 일괄 입력 / 배송 상태 변경 / 배송 추적 링크

import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/order_service.dart';
import '../../widgets/design_revision_countdown.dart';

// ─────────────────────────────────────────────
// 색상 상수
// ─────────────────────────────────────────────
const _kPrimary = AppColors.primary;
const _kAccent = Color(0xFFE94560);
const _kShipping = AppColors.info; // 배송중
const _kDelivered = AppColors.success; // 배송완료
const _kReady = AppColors.accent; // 출고준비 (processing)
// ignore: unused_element
const _kPending = AppColors.primary; // 대기
const _kGrey = Color(0xFF9E9E9E);

// ─────────────────────────────────────────────
// 메인 탭 위젯
// ─────────────────────────────────────────────
class AdminDeliveryTab extends StatefulWidget {
  const AdminDeliveryTab({super.key});

  @override
  State<AdminDeliveryTab> createState() => _AdminDeliveryTabState();
}

class _AdminDeliveryTabState extends State<AdminDeliveryTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTab;

  // 필터
  String _searchQuery = '';
  OrderStatus? _statusFilter; // null = 전체
  final _searchCtrl = TextEditingController();

  // 선택 모드
  final Set<String> _selected = {};
  bool _selectMode = false;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _innerTab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── 상태 필터 → inner tab index 동기화
  void _onTabChanged(int i) {
    setState(() {
      _statusFilter = switch (i) {
        1 => OrderStatus.processing,
        2 => OrderStatus.shipped,
        3 => OrderStatus.delivered,
        _ => null,
      };
      _selected.clear();
      _selectMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.watchAllOrders(),
      builder: (ctx, snap) {
        final allOrders = snap.data ?? [];

        // 배송 관련 주문만 (취소/환불 제외)
        final deliveryOrders = allOrders
            .where(
              (o) =>
                  o.status != OrderStatus.pending &&
                  o.status != OrderStatus.confirmed &&
                  o.status != OrderStatus.cancelled &&
                  o.status != OrderStatus.refunded,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // 검색 필터
        final filtered = deliveryOrders.where((o) {
          final q = _searchQuery.toLowerCase();
          final matchSearch = q.isEmpty ||
              o.id.toLowerCase().contains(q) ||
              o.userName.toLowerCase().contains(q) ||
              o.userPhone.contains(q) ||
              (o.customOptions?['trackingNumber'] as String? ?? '').contains(q);
          final matchStatus =
              _statusFilter == null || o.status == _statusFilter;
          return matchSearch && matchStatus;
        }).toList();

        // 탭별 카운트
        final cntAll = deliveryOrders.length;
        final cntReady = deliveryOrders
            .where((o) => o.status == OrderStatus.processing)
            .length;
        final cntShipping =
            deliveryOrders.where((o) => o.status == OrderStatus.shipped).length;
        final cntDone = deliveryOrders
            .where((o) => o.status == OrderStatus.delivered)
            .length;

        return Column(
          children: [
            // ── 상단 요약 카드
            _SummaryBar(
              cntAll: cntAll,
              cntReady: cntReady,
              cntShipping: cntShipping,
              cntDone: cntDone,
            ),

            // ── 내부 탭 바
            Container(
              color: _kPrimary,
              child: TabBar(
                controller: _innerTab,
                onTap: _onTabChanged,
                indicatorColor: _kAccent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: '전체 ($cntAll)'),
                  Tab(text: '출고준비 ($cntReady)'),
                  Tab(text: '배송중 ($cntShipping)'),
                  Tab(text: '배송완료 ($cntDone)'),
                ],
              ),
            ),

            // ── 검색 + 액션 바
            _SearchActionBar(
              ctrl: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              selectMode: _selectMode,
              selectedCount: _selected.length,
              onToggleSelect: () => setState(() {
                _selectMode = !_selectMode;
                _selected.clear();
              }),
              onBulkShip: _selected.isNotEmpty
                  ? () => _bulkUpdateStatus(filtered, OrderStatus.shipped)
                  : null,
              onBulkDeliver: _selected.isNotEmpty
                  ? () => _bulkUpdateStatus(filtered, OrderStatus.delivered)
                  : null,
              onSelectAll: () => setState(() {
                if (_selected.length == filtered.length) {
                  _selected.clear();
                } else {
                  _selected.addAll(filtered.map((o) => o.id));
                }
              }),
              totalFiltered: filtered.length,
            ),

            // ── 주문 목록
            Expanded(
              child: snap.connectionState == ConnectionState.waiting &&
                      snap.data == null
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary))
                  : filtered.isEmpty
                      ? _EmptyState(statusFilter: _statusFilter)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _DeliveryCard(
                            order: filtered[i],
                            selectMode: _selectMode,
                            selected: _selected.contains(filtered[i].id),
                            onSelectChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(filtered[i].id);
                              } else {
                                _selected.remove(filtered[i].id);
                              }
                            }),
                            onStatusChanged: (order, status) =>
                                _changeStatus(order, status),
                            onTrackingInput: (order) =>
                                _showTrackingDialog(order),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  // ── 상태 변경
  Future<void> _changeStatus(OrderModel order, OrderStatus newStatus) async {
    if (newStatus == OrderStatus.shipped) {
      await _showTrackingDialog(order, presetStatus: newStatus);
      return;
    }
    await OrderService.updateOrderStatusWithTracking(
      orderId: order.id,
      status: newStatus,
    );
    if (!mounted) return;
    context.read<OrderProvider>().updateOrderStatus(order.id, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${order.userName} 주문 → ${newStatus.label}'),
      backgroundColor: _kPrimary,
    ));
  }

  // ── 운송장 입력 다이얼로그
  Future<void> _showTrackingDialog(OrderModel order,
      {OrderStatus? presetStatus}) async {
    // Firestore에서 기존 운송장 정보 가져오기
    String initCompany = '한진택배';
    String initTracking = '';
    String initMemo = '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .get();
      if (doc.exists) {
        initCompany = doc.data()?['shippingCompany'] as String? ??
            context.loc.t('한진택배', '한진택배');
        initTracking = doc.data()?['trackingNumber'] as String? ?? '';
        initMemo = doc.data()?['adminMemo'] as String? ?? '';
      }
    } catch (_) {}

    final companyCtrl = TextEditingController(text: initCompany);
    final trackingCtrl = TextEditingController(text: initTracking);
    final memoCtrl = TextEditingController(text: initMemo);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _TrackingDialog(
        order: order,
        companyCtrl: companyCtrl,
        trackingCtrl: trackingCtrl,
        memoCtrl: memoCtrl,
        presetStatus: presetStatus,
        onSave: (status) async {
          final trackingNum = trackingCtrl.text.trim();
          final company = companyCtrl.text.trim();
          final memo = memoCtrl.text.trim();
          await OrderService.updateOrderStatusWithTracking(
            orderId: order.id,
            status: status,
            trackingNumber: trackingNum.isEmpty ? null : trackingNum,
            shippingCompany: company.isEmpty ? null : company,
            adminMemo: memo.isEmpty ? null : memo,
          );
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          context.read<OrderProvider>().updateOrderStatus(order.id, status);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.loc.t('배송 정보 저장  운송장 _  미입력  trackingNum',
                '배송 정보 저장 ✅ 운송장: ${trackingNum.isEmpty ? "미입력" : trackingNum}')),
            backgroundColor: _kPrimary,
          ));
        },
      ),
    );
  }

  // ── 일괄 상태 변경
  Future<void> _bulkUpdateStatus(
      List<OrderModel> filtered, OrderStatus newStatus) async {
    final targets = filtered.where((o) => _selected.contains(o.id)).toList();
    if (targets.isEmpty) return;

    // 배송중으로 일괄 변경 시 운송장 일괄 입력
    if (newStatus == OrderStatus.shipped) {
      await _showBulkTrackingDialog(targets);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${newStatus.label} 일괄 변경'),
        content: Text(context.loc.t('선택한 _건을 _으로 변경하시겠습니까',
            '선택한 ${targets.length}건을 "${newStatus.label}"으로 변경하시겠습니까?')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.loc.t('취소', '취소'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.loc.t('변경', '변경'),
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    for (final o in targets) {
      await OrderService.updateOrderStatusWithTracking(
          orderId: o.id, status: newStatus);
      if (mounted)
        context.read<OrderProvider>().updateOrderStatus(o.id, newStatus);
    }
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${targets.length}건 → ${newStatus.label} 일괄 변경 완료'),
        backgroundColor: _kPrimary,
      ));
    }
  }

  // ── 일괄 운송장 입력 다이얼로그
  Future<void> _showBulkTrackingDialog(List<OrderModel> targets) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _BulkTrackingDialog(
        orders: targets,
        onSave: (entries) async {
          int count = 0;
          for (final entry in entries) {
            if (entry.trackingNumber.isNotEmpty) {
              await OrderService.updateOrderStatusWithTracking(
                orderId: entry.orderId,
                status: OrderStatus.shipped,
                trackingNumber: entry.trackingNumber,
                shippingCompany: entry.company,
              );
              if (mounted) {
                // ignore: use_build_context_synchronously
                context
                    .read<OrderProvider>()
                    .updateOrderStatus(entry.orderId, OrderStatus.shipped);
              }
              count++;
            }
          }
          if (!mounted) return;
          setState(() {
            _selected.clear();
            _selectMode = false;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$count건 운송장 등록 및 배송중 처리 완료'),
            backgroundColor: _kPrimary,
          ));
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 요약 바 위젯
// ─────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final int cntAll, cntReady, cntShipping, cntDone;
  const _SummaryBar({
    required this.cntAll,
    required this.cntReady,
    required this.cntShipping,
    required this.cntDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kPrimary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          _statCard(context.loc.t('전체', '전체'), cntAll,
              Icons.local_shipping_rounded, Colors.white70),
          const SizedBox(width: 8),
          _statCard(context.loc.t('출고준비', '출고준비'), cntReady,
              Icons.inventory_2_rounded, _kReady),
          const SizedBox(width: 8),
          _statCard(context.loc.t('배송중', '배송중'), cntShipping,
              Icons.local_shipping_rounded, _kShipping),
          const SizedBox(width: 8),
          _statCard(context.loc.t('완료', '완료'), cntDone,
              Icons.check_circle_rounded, _kDelivered),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text('$count',
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 검색 + 액션 바
// ─────────────────────────────────────────────
class _SearchActionBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  final bool selectMode;
  final int selectedCount;
  final int totalFiltered;
  final VoidCallback onToggleSelect;
  final VoidCallback? onBulkShip;
  final VoidCallback? onBulkDeliver;
  final VoidCallback onSelectAll;

  const _SearchActionBar({
    required this.ctrl,
    required this.onChanged,
    required this.selectMode,
    required this.selectedCount,
    required this.totalFiltered,
    required this.onToggleSelect,
    required this.onBulkShip,
    required this.onBulkDeliver,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색창
          TextField(
            controller: ctrl,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: context.loc
                  .t('주문번호  이름  연락처  운송장 번호 검색', '주문번호 / 이름 / 연락처 / 운송장 번호 검색'),
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18, color: _kGrey),
              suffixIcon: ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        ctrl.clear();
                        onChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          // 액션 버튼 행
          Row(
            children: [
              // 선택 모드 토글
              _actionBtn(
                selectMode
                    ? context.loc.t('선택취소', '선택취소')
                    : context.loc.t('선택모드', '선택모드'),
                selectMode ? Icons.close : Icons.checklist_rounded,
                selectMode ? Colors.grey.shade600 : _kPrimary,
                onToggleSelect,
              ),
              if (selectMode) ...[
                const SizedBox(width: 6),
                _actionBtn(context.loc.t('전체선택', '전체선택'), Icons.select_all,
                    _kGrey, onSelectAll),
                const SizedBox(width: 6),
                _actionBtn(
                  context.loc.t('배송중_', '배송중($selectedCount)'),
                  Icons.local_shipping_rounded,
                  _kShipping,
                  onBulkShip,
                ),
                const SizedBox(width: 6),
                _actionBtn(
                  context.loc.t('완료_', '완료($selectedCount)'),
                  Icons.check_circle_rounded,
                  _kDelivered,
                  onBulkDeliver,
                ),
              ],
              const Spacer(),
              Text(
                context.loc.t('총 _', '총 $totalFiltered건'),
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.shade200
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: onTap == null
                  ? Colors.grey.shade300
                  : color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13, color: onTap == null ? Colors.grey.shade400 : color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: onTap == null ? Colors.grey.shade400 : color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 배송 카드 위젯
// ─────────────────────────────────────────────
class _DeliveryCard extends StatelessWidget {
  final OrderModel order;
  final bool selectMode;
  final bool selected;
  final ValueChanged<bool?> onSelectChanged;
  final Function(OrderModel, OrderStatus) onStatusChanged;
  final Function(OrderModel) onTrackingInput;

  const _DeliveryCard({
    required this.order,
    required this.selectMode,
    required this.selected,
    required this.onSelectChanged,
    required this.onStatusChanged,
    required this.onTrackingInput,
  });

  @override
  Widget build(BuildContext context) {
    // Firestore 실시간 데이터를 StreamBuilder로 가져오기
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .snapshots(),
      builder: (ctx, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final trackingNumber = data?['trackingNumber'] as String? ?? '';
        final shippingCompany = data?['shippingCompany'] as String? ?? '';
        final adminMemo = data?['adminMemo'] as String? ?? '';
        final hasTracking = trackingNumber.isNotEmpty;

        final statusColor = _statusColor(order.status);
        final isShipping = order.status == OrderStatus.shipped;
        final isDelivered = order.status == OrderStatus.delivered;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _kPrimary
                  : (isShipping
                      ? _kShipping.withValues(alpha: 0.3)
                      : Colors.grey.shade200),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // ── 헤더 행
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                child: Row(
                  children: [
                    if (selectMode)
                      Checkbox(
                        value: selected,
                        onChanged: onSelectChanged,
                        activeColor: _kPrimary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    // 상태 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        order.status.label,
                        style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 주문 유형 뱃지
                    if (order.orderType == 'group' ||
                        order.orderType == 'additional')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.orderType == 'additional'
                              ? context.loc.t('추가제작', '추가제작')
                              : context.loc.t('단체', '단체'),
                          style: const TextStyle(
                              fontSize: 10,
                              color: _kPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    const Spacer(),
                    // 날짜
                    Text(
                      _fmtDate(order.createdAt),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              // ── 주문 정보
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 주문자 + 연락처
                              Row(
                                children: [
                                  const Icon(Icons.person_rounded,
                                      size: 13, color: _kGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.userName,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _fmtPhone(order.userPhone),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // 주문 ID
                              Row(
                                children: [
                                  const Icon(Icons.receipt_rounded,
                                      size: 12, color: _kGrey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(
                                            ClipboardData(text: order.id));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(context.loc
                                                  .t('주문번호 복사됨', '주문번호 복사됨')),
                                              duration: Duration(seconds: 1)),
                                        );
                                      },
                                      child: Text(
                                        order.id,
                                        style: const TextStyle(
                                            fontSize: 11, color: _kGrey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // 배송지
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 12, color: _kGrey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      order.userAddress.isEmpty
                                          ? context.loc.t('배송지 없음', '배송지 없음')
                                          : order.userAddress,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 금액
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_fmtWon(order.totalAmount)}원',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _kPrimary),
                            ),
                            Text(
                              order.paymentMethod,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ── 상품 요약
                    const SizedBox(height: 6),
                    _itemSummary(order),
                    if (order.isGroupOrder && order.activeDesignRevisionDeadline != null) ...[
                      const SizedBox(height: 8),
                      DesignRevisionCountdown(
                        deadline: order.activeDesignRevisionDeadline,
                        revisionCount: order.designRevisionCount,
                        compact: true,
                      ),
                    ],
                    // ── 운송장 정보
                    if (hasTracking) ...[
                      const SizedBox(height: 8),
                      _TrackingInfo(
                        trackingNumber: trackingNumber,
                        shippingCompany: shippingCompany,
                        onCopy: () {
                          Clipboard.setData(
                              ClipboardData(text: trackingNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    context.loc.t('운송장 번호 복사됨', '운송장 번호 복사됨')),
                                duration: Duration(seconds: 1)),
                          );
                        },
                        onTrack: () => _launchTracking(
                            context, trackingNumber, shippingCompany),
                      ),
                    ],

                    // ── 관리자 메모
                    if (adminMemo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sticky_note_2_rounded,
                                size: 13, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(adminMemo,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.brown)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── 액션 버튼 행
              const Divider(
                  height: 16, thickness: 0.5, indent: 12, endIndent: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: [
                    // 운송장 입력/수정 버튼
                    _cardBtn(
                      hasTracking
                          ? context.loc.t('운송장 수정', '운송장 수정')
                          : context.loc.t('운송장 입력', '운송장 입력'),
                      hasTracking ? Icons.edit_rounded : Icons.add_box_rounded,
                      hasTracking
                          ? AppColors.warning.withValues(alpha: 0.82)
                          : _kShipping,
                      () => onTrackingInput(order),
                    ),
                    const SizedBox(width: 8),

                    // 상태 변경 버튼
                    if (!isDelivered) ...[
                      if (order.status == OrderStatus.processing)
                        _cardBtn(
                            context.loc.t('배송중 처리', '배송중 처리'),
                            Icons.local_shipping_rounded,
                            _kShipping,
                            () => onStatusChanged(order, OrderStatus.shipped)),
                      if (isShipping)
                        _cardBtn(
                            context.loc.t('배송완료 처리', '배송완료 처리'),
                            Icons.check_circle_rounded,
                            _kDelivered,
                            () =>
                                onStatusChanged(order, OrderStatus.delivered)),
                    ] else
                      _cardBtn(context.loc.t('배송완료', '배송완료 ✓'),
                          Icons.check_circle_rounded, _kDelivered, null),

                    const Spacer(),

                    // 배송 추적 버튼 (운송장 있을 때만)
                    if (hasTracking)
                      _cardBtn(
                        context.loc.t('배송조회', '배송조회'),
                        Icons.open_in_new_rounded,
                        AppColors.primary.withValues(alpha: 0.82),
                        () => _launchTracking(
                            context, trackingNumber, shippingCompany),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _itemSummary(OrderModel order) {
    final items = order.items;
    if (items.isEmpty) {
      final teamName = order.customOptions?['teamName'] as String? ?? '';
      return Text(
        teamName.isNotEmpty ? '단체주문 · \$teamName' : '단체주문',
        style: const TextStyle(fontSize: 12, color: _kGrey),
      );
    }
    final first = items.first;
    final extra = items.length > 1 ? ' 외 ${items.length - 1}건' : '';
    return Text(
      '${first.productName} (${first.size}·${first.color}) ×${first.quantity}$extra',
      style: const TextStyle(fontSize: 12, color: _kGrey),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _cardBtn(
      String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.shade100
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: onTap == null
                  ? Colors.grey.shade300
                  : color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13, color: onTap == null ? Colors.grey.shade400 : color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: onTap == null ? Colors.grey.shade400 : color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  static void _launchTracking(
      BuildContext context, String trackingNumber, String company) async {
    String url;
    final lowerCompany = company.toLowerCase();
    if (lowerCompany.contains(context.loc.t('한진', '한진'))) {
      url =
          'https://www.hanjin.com/kor/CMS/DeliveryMgr/WaybillSch.do?mCode=MN038&schLang=KR&wblnumText2=$trackingNumber';
    } else if (lowerCompany.contains(context.loc.t('롯데', '롯데')) ||
        lowerCompany.contains('lotte')) {
      url =
          'https://www.lotteglogis.com/home/reservation/tracking/index?InvNo=$trackingNumber';
    } else if (lowerCompany.contains(context.loc.t('우체국', '우체국')) ||
        lowerCompany.contains('epost')) {
      url =
          'https://service.epost.go.kr/trace.RetrieveRegiTraceList.comm?sid1=$trackingNumber';
    } else if (lowerCompany.contains('cj') ||
        lowerCompany.contains(context.loc.t('대한통운', '대한통운'))) {
      url =
          'https://www.cjlogistics.com/ko/tool/parcel/tracking?gnbInvcNo=$trackingNumber';
    } else {
      url =
          'https://www.hanjin.com/kor/CMS/DeliveryMgr/WaybillSch.do?mCode=MN038&schLang=KR&wblnumText2=$trackingNumber';
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.loc.t('브라우저 열기 실패 _', '브라우저 열기 실패: $e'))),
        );
      }
    }
  }

  static Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.processing => _kReady,
        OrderStatus.shipped => _kShipping,
        OrderStatus.delivered => _kDelivered,
        _ => _kGrey,
      };

  static String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _fmtPhone(String p) {
    if (p.length == 11)
      return '${p.substring(0, 3)}-${p.substring(3, 7)}-${p.substring(7)}';
    return p;
  }

  static String _fmtWon(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─────────────────────────────────────────────
// 운송장 정보 표시 위젯
// ─────────────────────────────────────────────
class _TrackingInfo extends StatelessWidget {
  final String trackingNumber;
  final String shippingCompany;
  final VoidCallback onCopy;
  final VoidCallback onTrack;

  const _TrackingInfo({
    required this.trackingNumber,
    required this.shippingCompany,
    required this.onCopy,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kShipping.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kShipping.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, size: 15, color: _kShipping),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shippingCompany.isNotEmpty)
                  Text(shippingCompany,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _kShipping,
                          fontWeight: FontWeight.w600)),
                Text(
                  trackingNumber,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 15, color: _kGrey),
            onPressed: onCopy,
            tooltip: context.loc.t('운송장 번호 복사', '운송장 번호 복사'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onTrack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kShipping,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(context.loc.t('조회', '조회'),
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 운송장 입력 다이얼로그
// ─────────────────────────────────────────────
class _TrackingDialog extends StatefulWidget {
  final OrderModel order;
  final TextEditingController companyCtrl;
  final TextEditingController trackingCtrl;
  final TextEditingController memoCtrl;
  final OrderStatus? presetStatus;
  final Function(OrderStatus) onSave;

  const _TrackingDialog({
    required this.order,
    required this.companyCtrl,
    required this.trackingCtrl,
    required this.memoCtrl,
    required this.presetStatus,
    required this.onSave,
  });

  @override
  State<_TrackingDialog> createState() => _TrackingDialogState();
}

class _TrackingDialogState extends State<_TrackingDialog> {
  late OrderStatus _selectedStatus;
  bool _saving = false;

  // 택배사 목록
  static const _companies = ['한진택배', '롯데택배', '우체국', 'CJ대한통운', '로젠택배', '기타'];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.presetStatus ?? widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      title: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, color: _kShipping, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.loc.t('배송 정보 입력', '배송 정보 입력'),
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(
                  '${widget.order.userName} · ${widget.order.id}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // 택배사 선택
            Text(context.loc.t('택배사', '택배사'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _companies.map((c) {
                final isSelected = widget.companyCtrl.text == c;
                return GestureDetector(
                  onTap: () => setState(() => widget.companyCtrl.text = c),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: isSelected ? _kPrimary : Colors.grey.shade300),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // 직접 입력
            TextField(
              controller: widget.companyCtrl,
              decoration: InputDecoration(
                labelText: context.loc.t('택배사 직접 입력', '택배사 직접 입력'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // 운송장 번호
            TextField(
              controller: widget.trackingCtrl,
              decoration: InputDecoration(
                labelText: context.loc.t('운송장 번호', '운송장 번호'),
                hintText: context.loc.t('숫자 입력', '숫자 입력'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                suffixIcon: widget.trackingCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () =>
                            setState(() => widget.trackingCtrl.clear()),
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // 배송 상태 선택
            Text(context.loc.t('배송 상태', '배송 상태'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 6),
            Row(
              children: [
                OrderStatus.processing,
                OrderStatus.shipped,
                OrderStatus.delivered,
              ].map((s) {
                final selected = _selectedStatus == s;
                final color = _statusColor(s);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedStatus = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? color : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: selected ? color : Colors.grey.shade200),
                        ),
                        child: Text(
                          s.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                selected ? Colors.white : Colors.grey.shade600,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // 관리자 메모
            TextField(
              controller: widget.memoCtrl,
              decoration: InputDecoration(
                labelText: context.loc.t('관리자 메모 선택', '관리자 메모 (선택)'),
                hintText: context.loc.t('내부 참고 메모', '내부 참고 메모'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(context.loc.t('취소', '취소'),
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        await widget.onSave(_selectedStatus);
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(context.loc.t('저장', '저장'),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.processing => _kReady,
        OrderStatus.shipped => _kShipping,
        OrderStatus.delivered => _kDelivered,
        _ => _kGrey,
      };
}

// ─────────────────────────────────────────────
// 일괄 운송장 입력 다이얼로그
// ─────────────────────────────────────────────
class _BulkEntry {
  final String orderId;
  final String userName;
  String company;
  String trackingNumber;
  // ignore: unused_element
  _BulkEntry(
      {required this.orderId,
      required this.userName,
      this.company = '한진택배',
      this.trackingNumber = ''});
}

class _BulkTrackingDialog extends StatefulWidget {
  final List<OrderModel> orders;
  final Function(List<_BulkEntry>) onSave;

  const _BulkTrackingDialog({required this.orders, required this.onSave});

  @override
  State<_BulkTrackingDialog> createState() => _BulkTrackingDialogState();
}

class _BulkTrackingDialogState extends State<_BulkTrackingDialog> {
  late final List<_BulkEntry> _entries;
  late final List<TextEditingController> _ctrls;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.orders
        .map((o) => _BulkEntry(orderId: o.id, userName: o.userName))
        .toList();
    _ctrls = _entries.map((_) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, color: _kShipping, size: 22),
          const SizedBox(width: 8),
          Text(context.loc.t('운송장 일괄 입력 _건', '운송장 일괄 입력 (${_entries.length}건)'),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 일괄 택배사 설정 버튼
            Row(
              children: [
                Text(context.loc.t('일괄 택배사', '일괄 택배사:'),
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                ...[
                  context.loc.t('한진택배', '한진택배'),
                  context.loc.t('롯데택배', '롯데택배')
                ].map((c) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          for (final e in _entries) {
                            e.company = c;
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: _kPrimary.withValues(alpha: 0.2)),
                          ),
                          child: Text(c,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _kPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 350),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _entries.length,
                itemBuilder: (_, i) {
                  final e = _entries[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(e.userName,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _ctrls[i],
                            decoration: InputDecoration(
                              hintText: context.loc.t('운송장 번호', '운송장 번호'),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (v) => e.trackingNumber = v,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.loc.t('취소', '취소'),
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        for (int i = 0; i < _entries.length; i++) {
                          _entries[i].trackingNumber = _ctrls[i].text.trim();
                        }
                        await widget.onSave(_entries);
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(context.loc.t('일괄 저장', '일괄 저장'),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 빈 상태
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final OrderStatus? statusFilter;
  const _EmptyState({this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final label = statusFilter == null
        ? context.loc.t('배송 관련 주문이 없습니다', '배송 관련 주문이 없습니다.')
        : '${statusFilter!.label} 주문이 없습니다.';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(label,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
