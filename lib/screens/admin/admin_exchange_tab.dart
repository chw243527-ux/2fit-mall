import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/fcm_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// ═══════════════════════════════════════════════════════
// 관리자 교환/반품 관리 탭
// ═══════════════════════════════════════════════════════

class AdminExchangeTab extends StatefulWidget {
  const AdminExchangeTab({super.key});
  @override
  State<AdminExchangeTab> createState() => _AdminExchangeTabState();
}

class _AdminExchangeTabState extends State<AdminExchangeTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 탭바 ──
        Container(
          color: const Color(0xFF1A1A2E),
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: const Color(0xFF4FC3F7),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(icon: Icon(Icons.swap_horiz_rounded, size: 16), text: '교환 목록'),
              Tab(icon: Icon(Icons.assignment_return_outlined, size: 16), text: '반품 목록'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              _ExchangeList(type: 'exchange'),
              _ExchangeList(type: 'return'),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 교환 or 반품 목록 ──
class _ExchangeList extends StatelessWidget {
  final String type; // 'exchange' | 'return'
  const _ExchangeList({required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exchange_requests')
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(type == 'exchange'
                  ? Icons.swap_horiz_rounded
                  : Icons.assignment_return_outlined,
                  size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(type == 'exchange' ? '교환 요청이 없습니다.' : '반품 요청이 없습니다.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _ExchangeCard(docId: doc.id, data: data, type: type);
          },
        );
      },
    );
  }
}

// ── 카드 ──
class _ExchangeCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String type;
  const _ExchangeCard({required this.docId, required this.data, required this.type});

  String get _status => data['status'] as String? ?? 'pending';
  bool get _isDone => _status == 'completed';

  Color get _statusColor {
    switch (_status) {
      case 'completed': return const Color(0xFF16A34A);
      case 'processing': return const Color(0xFF1565C0);
      default: return const Color(0xFFFF8F00);
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'completed': return '완료';
      case 'processing': return '처리중';
      default: return '접수';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = data['orderId'] as String? ?? '';
    final reason = data['reason'] as String? ?? '';
    final detail = data['detail'] as String? ?? '';
    final pickupMethod = data['pickupMethod'] as String? ?? '';
    final shippingBySelf = data['shippingBySelf'] as bool? ?? true;
    final returnTracking = data['returnTrackingNumber'] as String? ?? '';
    final returnCompany = data['returnTrackingCompany'] as String? ?? '';
    final payMethod = data['payMethod'] as String? ?? '';
    final createdAt = data['createdAt'] as String? ?? '';
    final userName = data['userName'] as String? ?? '';
    final userId = data['userId'] as String? ?? '';
    final adminNote = data['adminNote'] as String? ?? '';
    final imageUrls = (data['imageUrls'] as List?)?.cast<String>() ?? [];

    final dateStr = createdAt.length >= 16 ? createdAt.substring(0, 16).replaceAll('T', ' ') : createdAt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isDone ? const Color(0xFFBBF7D0) : Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isDone ? const Color(0xFFF0FFF4) : const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              // 상태 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
              ),
              const SizedBox(width: 8),
              // 유형 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (type == 'exchange'
                      ? const Color(0xFF1565C0)
                      : Colors.orange).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(type == 'exchange' ? '교환' : '반품',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: type == 'exchange' ? const Color(0xFF1565C0) : Colors.orange,
                    )),
              ),
              const Spacer(),
              Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          ),

          // ── 본문 ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 주문번호 + 신청자
              _infoRow('주문번호', orderId, isBold: true),
              if (userName.isNotEmpty) _infoRow('신청자', userName),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // 사유
              _infoRow('사유', reason),
              if (detail.isNotEmpty) _infoRow('상세', detail),
              // 첨부 사진
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('첨부 사진 (${imageUrls.length}장)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                const SizedBox(height: 6),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) => GestureDetector(
                      onTap: () => showDialog(
                        context: ctx,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.black,
                          child: InteractiveViewer(
                            child: Image.network(imageUrls[i], fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrls[i],
                          width: 80, height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80, height: 80,
                            color: Colors.grey[100],
                            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // 수거방법
              _infoRow('수거방법', pickupMethod == 'pickup' ? '직접수거 (택배사 방문)' : '이미 발송'),
              // 운송장 (이미 발송한 경우)
              if (returnTracking.isNotEmpty) ...[
                _infoRow('반송 택배사', returnCompany.isNotEmpty ? returnCompany : '-'),
                _infoRow('반송 운송장', returnTracking),
              ],
              // 배송비
              _infoRow('배송비', shippingBySelf ? '고객 부담' : '판매자 부담 (무료)'),
              // 결제수단 (고객부담인 경우)
              if (shippingBySelf && payMethod.isNotEmpty)
                _infoRow('결제수단', _payLabel(payMethod)),
              // 관리자 메모
              if (adminNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFFF8F00)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(adminNote,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)))),
                  ]),
                ),
              ],
            ]),
          ),

          // ── 버튼 영역 ──
          if (!_isDone)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(children: [
                // 처리중 버튼
                if (_status == 'pending')
                  Expanded(
                    child: _ActionButton(
                      label: '처리중으로 변경',
                      color: const Color(0xFF1565C0),
                      icon: Icons.autorenew_rounded,
                      onTap: () => _changeStatus(context, 'processing', userId, orderId),
                    ),
                  ),
                if (_status == 'pending') const SizedBox(width: 8),
                // 완료처리 버튼
                Expanded(
                  child: _ActionButton(
                    label: '완료 처리',
                    color: const Color(0xFF16A34A),
                    icon: Icons.check_circle_outline_rounded,
                    onTap: () => _showCompleteDialog(context, userId, orderId),
                  ),
                ),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text('처리 완료', style: const TextStyle(fontSize: 13, color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
              ]),
            ),
        ],
      ),
    );
  }

  String _payLabel(String key) {
    const map = {'card': '신용카드', 'kakao': '카카오페이', 'payco': '페이코', 'toss': '토스페이'};
    return map[key] ?? key;
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 72,
        child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ),
      Expanded(
        child: Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              color: isBold ? const Color(0xFF1A1A2E) : Colors.black87,
            )),
      ),
    ]),
  );

  Future<void> _changeStatus(
      BuildContext context, String newStatus, String userId, String orderId) async {
    await FirebaseFirestore.instance
        .collection('exchange_requests')
        .doc(docId)
        .update({'status': newStatus});

    final typeLabel = type == 'exchange' ? '교환' : '반품';
    final statusLabel = newStatus == 'processing' ? '처리중' : '완료';

    // FCM 알림
    if (userId.isNotEmpty) {
      FcmService.sendOrderStatusNotification(
        userId: userId,
        orderId: orderId,
        status: '$typeLabel $statusLabel',
        message: '[$typeLabel 요청] 처리 상태가 "$statusLabel"으로 변경되었습니다.',
      ).catchError((e) {
        if (kDebugMode) debugPrint('FCM error: $e');
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $typeLabel 요청 → $statusLabel 변경 완료'),
          backgroundColor: const Color(0xFF1565C0),
        ),
      );
    }
  }

  void _showCompleteDialog(BuildContext context, String userId, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => _CompleteDialog(
        docId: docId,
        type: type,
        userId: userId,
        orderId: orderId,
      ),
    );
  }
}

// ── 공용 액션 버튼 ──
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

// ── 완료처리 다이얼로그 (StatefulWidget — TextEditingController 안전 관리) ──
class _CompleteDialog extends StatefulWidget {
  final String docId;
  final String type;
  final String userId;
  final String orderId;
  const _CompleteDialog({
    required this.docId, required this.type,
    required this.userId, required this.orderId,
  });
  @override
  State<_CompleteDialog> createState() => _CompleteDialogState();
}

class _CompleteDialogState extends State<_CompleteDialog> {
  final _noteCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = widget.type == 'exchange' ? '교환' : '반품';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 22),
        const SizedBox(width: 8),
        Text('$typeLabel 완료 처리',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$typeLabel 처리를 완료하고\n고객에게 알림을 발송합니다.',
            style: const TextStyle(fontSize: 13, height: 1.6)),
        const SizedBox(height: 14),
        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: '고객에게 전달할 메시지 (선택사항)\n예: $typeLabel 상품이 발송되었습니다. 운송장: 1234567890',
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
          ),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('완료 처리 + 알림 발송'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final typeLabel = widget.type == 'exchange' ? '교환' : '반품';
    final note = _noteCtrl.text.trim();

    try {
      // Firestore 상태 완료
      await FirebaseFirestore.instance
          .collection('exchange_requests')
          .doc(widget.docId)
          .update({
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
        if (note.isNotEmpty) 'adminNote': note,
      });

      // FCM 알림
      if (widget.userId.isNotEmpty) {
        final msg = note.isNotEmpty
            ? '[$typeLabel 완료] $note'
            : '[$typeLabel 요청] 처리가 완료되었습니다.';
        await FcmService.sendOrderStatusNotification(
          userId: widget.userId,
          orderId: widget.orderId,
          status: '$typeLabel 완료',
          message: msg,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Complete error: $e');
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $typeLabel 완료 처리 및 고객 알림 발송 완료'),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
