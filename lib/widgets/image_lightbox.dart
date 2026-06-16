import 'dart:convert';
import 'package:flutter/material.dart';
import 'net_image.dart';

/// 이미지 라이트박스 다이얼로그 오픈 유틸
/// - 어디서든 호출 가능한 공통 함수
/// - product_detail_screen, admin_screen 등에서 공유
void showImageLightbox(
  BuildContext context,
  List<String> images, {
  int initialIndex = 0,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.95),
    builder: (_) => ImageLightboxDialog(
      images: images,
      initialIndex: initialIndex,
    ),
  );
}

/// 이미지 라이트박스 다이얼로그
/// - 핀치줌(InteractiveViewer) + 좌우 스와이프(PageView) + 이전/다음 버튼 + 닫기
/// - base64('data:image/...') 및 네트워크 URL 모두 지원
class ImageLightboxDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const ImageLightboxDialog({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageLightboxDialog> createState() => _ImageLightboxDialogState();
}

class _ImageLightboxDialogState extends State<ImageLightboxDialog> {
  late int _idx;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _ctrl = PageController(initialPage: _idx);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildImage(String src) {
    if (src.startsWith('data:image')) {
      return Image.memory(
        base64Decode(src.split(',').last),
        fit: BoxFit.contain,
      );
    }
    return NetImage(
      src,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── 이미지 PageView (핀치줌 가능)
          PageView.builder(
            controller: _ctrl,
            itemCount: total,
            onPageChanged: (i) => setState(() => _idx = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(child: _buildImage(widget.images[i])),
            ),
          ),

          // ── 닫기 버튼
          Positioned(
            top: 48,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),

          // ── 하단 인디케이터 (2장 이상)
          if (total > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    '${_idx + 1} / $total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(total, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _idx == i ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _idx == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

          // ── 이전 버튼
          if (total > 1)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_idx > 0) {
                      _ctrl.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }
                  },
                  child: AnimatedOpacity(
                    opacity: _idx > 0 ? 1.0 : 0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),

          // ── 다음 버튼
          if (total > 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_idx < total - 1) {
                      _ctrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }
                  },
                  child: AnimatedOpacity(
                    opacity: _idx < total - 1 ? 1.0 : 0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
