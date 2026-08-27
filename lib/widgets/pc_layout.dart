import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// PC/태블릿 기준 breakpoint (main_screen.dart 와 동일)
const double kPcBreak = 900;

/// 현재 화면이 넓은 레이아웃(PC 또는 태블릿)인지 확인
/// - 웹: 너비 900 이상
/// - 앱(태블릿): 너비 900 이상
bool isPcWeb(BuildContext context) =>
    MediaQuery.of(context).size.width >= kPcBreak;

/// PC 화면에서 콘텐츠를 최대 [maxWidth]로 중앙 정렬
/// 모바일에서는 [child]를 그대로 반환
class PcCenterBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? bgColor;
  final EdgeInsets padding;

  const PcCenterBox({
    super.key,
    required this.child,
    this.maxWidth = 1280,
    this.bgColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    if (!isPcWeb(context)) return child;
    return Container(
      color: bgColor ?? AppColors.surfaceGray,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// PC 에서 모달/상세 화면을 중앙 컨테이너로 래핑
/// AppBar 를 없애고 자체 헤더를 제공
class PcScaffoldWrapper extends StatelessWidget {
  final String title;
  final Widget body;
  final double maxWidth;
  final List<Widget>? headerActions;

  const PcScaffoldWrapper({
    super.key,
    required this.title,
    required this.body,
    this.maxWidth = 1280,
    this.headerActions,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPcWeb(context)) return body;
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: Column(
        children: [
          // 상단 페이지 헤더
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: const Icon(Icons.chevron_left_rounded, size: 26),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (headerActions != null) ...headerActions!,
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: body,
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
