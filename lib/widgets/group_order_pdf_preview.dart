import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../services/order_excel_service.dart';

/// 단체주문 상세 PDF를 실제 페이지 형태로 미리 보고
/// 같은 화면에서 인쇄·공유·PDF 저장까지 할 수 있는 컴포넌트입니다.
class GroupOrderPdfPreview extends StatelessWidget {
  final OrderModel order;
  final bool showAppBar;

  const GroupOrderPdfPreview({
    super.key,
    required this.order,
    this.showAppBar = true,
  });

  String get _fileName {
    final options = order.customOptions ?? <String, dynamic>{};
    final rawTeam = (options['teamName']?.toString().trim().isNotEmpty == true
            ? options['teamName'].toString()
            : order.groupName?.trim().isNotEmpty == true
                ? order.groupName!
                : order.userName.trim().isNotEmpty
                    ? order.userName
                    : order.id)
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final date = order.createdAt;
    final dateText =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '단체주문_${dateText}_$rawTeam.pdf';
  }

  @override
  Widget build(BuildContext context) {
    final preview = PdfPreview(
      build: (format) => OrderExcelService.generateGroupOrderPdf(order),
      pdfFileName: _fileName,
      canChangePageFormat: false,
      canChangeOrientation: false,
      allowPrinting: true,
      allowSharing: true,
      allowSave: true,
      maxPageWidth: 900,
      padding: const EdgeInsets.all(16),
      pdfPreviewPageDecoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      loadingWidget: const Center(
        child: CircularProgressIndicator(color: Color(0xFF00897B)),
      ),
      onError: (context, error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'PDF 미리보기를 불러오지 못했습니다.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    if (!showAppBar) return preview;

    return Scaffold(
      appBar: AppBar(
        title: const Text('단체주문 PDF 미리보기'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _fileName,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
      body: preview,
    );
  }
}
