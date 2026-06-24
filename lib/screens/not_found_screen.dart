// not_found_screen.dart
// ══════════════════════════════════════════════════════════════
// 404 에러 페이지 — 잘못된 URL 접근 시 표시
// ══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_localizations.dart';
import '../providers/providers.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 404 아이콘
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 32),

                // 404 텍스트
                const Text(
                  '404',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // 메인 메시지
                Text(
                  context.loc.t('페이지를 찾을 수 없어요', '페이지를 찾을 수 없어요'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),

                // 서브 메시지
                Text(
                  context.loc.t('요청하신 페이지가 존재하지 않거나 이동되었을 수 있습니다', '요청하신 페이지가 존재하지 않거나\n이동되었을 수 있습니다.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.55),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),

                // 홈으로 버튼
                SizedBox(
                  width: 200,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 네비게이터 스택 초기화 후 홈으로
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: Text(
                      context.loc.t('홈으로 돌아가기', '홈으로 돌아가기'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 이전 페이지로 버튼
                SizedBox(
                  width: 200,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: Text(
                      context.loc.t('이전 페이지', '이전 페이지'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A2E),
                      side: const BorderSide(
                        color: Color(0xFF1A1A2E),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // 브랜드 로고
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          '2F',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '2FIT MALL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
