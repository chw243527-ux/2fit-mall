import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// 단체주문 디자인 수정 단계의 마감일과 실시간 잔여 시간을 표시합니다.
class DesignRevisionCountdown extends StatefulWidget {
  final DateTime? deadline;
  final int revisionCount;
  final bool compact;

  const DesignRevisionCountdown({
    super.key,
    required this.deadline,
    required this.revisionCount,
    this.compact = false,
  });

  @override
  State<DesignRevisionCountdown> createState() =>
      _DesignRevisionCountdownState();
}

class _DesignRevisionCountdownState extends State<DesignRevisionCountdown> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant DesignRevisionCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.deadline == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (mounted) setState(() => _now = now);
      if (widget.deadline != null && !widget.deadline!.isAfter(now)) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDeadline(DateTime deadline) {
    final local = deadline.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}.$month.$day $hour:$minute까지';
  }

  String _formatRemaining(Duration remaining) {
    final totalSeconds = remaining.inSeconds.clamp(0, 999999999);
    final days = totalSeconds ~/ Duration.secondsPerDay;
    final hours = (totalSeconds % Duration.secondsPerDay) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (days > 0) {
      return '${days}일 ${hours.toString().padLeft(2, '0')}시간 ${minutes.toString().padLeft(2, '0')}분';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.deadline;
    if (deadline == null) return const SizedBox.shrink();

    final remaining = deadline.difference(_now);
    final expired = remaining.isNegative || remaining == Duration.zero;
    final title = widget.revisionCount == 0 ? '1차 디자인 수정 기간' : '2차 디자인 수정 기간';
    final color = expired ? AppColors.textSecondary : AppColors.accent;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 10 : 14,
        vertical: widget.compact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: expired ? Colors.grey.shade100 : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(widget.compact ? 9 : 12),
        border: Border.all(
          color: expired ? Colors.grey.shade300 : const Color(0xFFFFCC02),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            expired ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: widget.compact ? 18 : 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expired ? '$title 종료' : title,
                  style: TextStyle(
                    fontSize: widget.compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  expired
                      ? '디자인 수정 기간이 종료되어 자동 확정 처리됩니다.'
                      : '잔여 ${_formatRemaining(remaining)}',
                  style: TextStyle(
                    fontSize: widget.compact ? 12 : 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '마감 ${_formatDeadline(deadline)}',
                  style: TextStyle(
                    fontSize: widget.compact ? 10 : 11,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
