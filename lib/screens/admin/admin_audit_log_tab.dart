import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/theme.dart';

/// admin_audit_logs 문서 스키마
///
/// id: Firestore document id
/// action: 고정된 작업 식별자 (예: member_profile_deleted)
/// targetId: 작업 대상 UID/주문번호/문서 ID
/// actorUid, actorEmail: 작업을 수행한 관리자
/// details: 작업별 부가 정보(Map)
/// createdAt: FieldValue.serverTimestamp()로 기록하는 Timestamp
class AdminAuditLogTab extends StatefulWidget {
  const AdminAuditLogTab({super.key});

  @override
  State<AdminAuditLogTab> createState() => _AdminAuditLogTabState();
}

class _AdminAuditLogTabState extends State<AdminAuditLogTab> {
  static const _pageSize = 30;
  static const _actions = <String>[
    '전체',
    'member_profile_deleted',
    'staff_admin_granted',
    'staff_admin_revoked',
    'staff_role_changed',
    'group_order_pdf_generation',
  ];

  final _searchController = TextEditingController();
  final _logs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  String _action = '전체';
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs({required bool reset}) async {
    if (_loading || (!reset && !_hasMore)) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _logs.clear();
        _lastDocument = null;
        _hasMore = true;
      }
    });
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('admin_audit_logs')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);
      final cursor = _lastDocument;
      if (cursor != null) query = query.startAfterDocument(cursor);
      final snapshot = await query.get();
      if (!mounted) return;
      setState(() {
        _logs.addAll(snapshot.docs);
        _lastDocument =
            snapshot.docs.isEmpty ? _lastDocument : snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '감사 로그를 불러오지 못했습니다. Firestore 인덱스와 관리자 권한을 확인해 주세요.';
      });
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredLogs {
    final search = _searchController.text.trim().toLowerCase();
    return _logs.where((doc) {
      final data = doc.data();
      final matchesAction = _action == '전체' || data['action'] == _action;
      if (!matchesAction) return false;
      if (search.isEmpty) return true;
      return [
        data['action'],
        data['targetId'],
        data['actorUid'],
        data['actorEmail'],
      ]
          .map((value) => '$value'.toLowerCase())
          .any((value) => value.contains(search));
    }).toList();
  }

  String _date(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate().toLocal();
      return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '기록 중';
  }

  String _summary(Map<String, dynamic> data) {
    final action = data['action'] ?? 'unknown';
    final target = data['targetId'] ?? '-';
    final actor = data['actorEmail'] ?? data['actorUid'] ?? '-';
    return '$action · 대상 $target · 작업자 $actor';
  }

  void _showDetails(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data());
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감사 로그 상세'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert({
                'id': '문서 ID는 아래 데이터에 포함되지 않음',
                ...<String, dynamic>{'record': data},
              }),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search, size: 18),
                      hintText: '작업·대상 ID·관리자 검색',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _action,
                  items: _actions
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _action = value ?? '전체'),
                ),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _loadLogs(reset: true),
                  icon: const Icon(Icons.refresh, size: 17),
                  label: const Text('새로고침'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                    child: Text('감사 로그 ${logs.length}건 · 최신순',
                        style: const TextStyle(fontSize: 12))),
                if (_loading)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
            )
          else
            Expanded(
              child: logs.isEmpty && !_loading
                  ? const Center(child: Text('감사 로그가 없습니다.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final doc = logs[index];
                        final data = doc.data();
                        return Card(
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.history_rounded,
                                color: AppColors.primary),
                            title: Text(_summary(data),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(_date(data['createdAt'])),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showDetails(doc),
                          ),
                        );
                      },
                    ),
            ),
          if (!_loading && _hasMore)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                onPressed: () => _loadLogs(reset: false),
                child: const Text('다음 30건 불러오기'),
              ),
            ),
        ],
      ),
    );
  }
}
