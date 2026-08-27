import 'package:flutter/material.dart';

import '../../utils/theme.dart';

/// 2FIT MALL의 기성품·단체주문 정책과 러닝웨어 철학을 소개하는 고객용 페이지입니다.
class BrandStoryScreen extends StatelessWidget {
  const BrandStoryScreen({super.key});

  Widget _eyebrow(String text, {Color color = AppColors.accent}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.35,
      ),
    );
  }

  Widget _storyBlock({
    required String index,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(index,
              style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              height: 1.04,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.78,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyCard({
    required String label,
    required String title,
    required String body,
    required bool dark,
  }) {
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? const Color(0xFFD0CEC8) : AppColors.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: dark ? AppColors.primary : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(label,
              color: dark ? const Color(0xFFE8A58E) : AppColors.accent),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: 21,
              height: 1.05,
              letterSpacing: -0.55,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(color: secondary, fontSize: 13, height: 1.7),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        title: const Text(
          '2FIT MALL',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 38),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ABOUT 2FIT',
                  style: TextStyle(
                    color: Color(0xFFE8A58E),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'MADE FOR\nYOUR MOVEMENT.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 0.92,
                    letterSpacing: -1.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  '움직임의 목적과 취향에 맞는 한 장이\n더 나은 하루로 이어진다고 믿습니다.',
                  style: TextStyle(
                      color: Color(0xFFD2D0CA), fontSize: 14, height: 1.65),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow('OUR POINT OF VIEW'),
                const SizedBox(height: 12),
                const Text(
                  '움직임을 위한\n더 분명한 선택.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 27,
                    height: 1.02,
                    letterSpacing: -0.9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 26),
                _storyBlock(
                  index: '01 / PERFORMANCE',
                  title: '움직임에 집중하는 설계',
                  body:
                      '2FIT MALL은 달리고, 훈련하고, 팀으로 도전하는 순간을 위한 스포츠웨어를 만듭니다. 불필요한 요소는 덜고, 활동 목적에 맞는 핏과 소재 정보는 더 명확하게 전합니다.',
                ),
                _storyBlock(
                  index: '02 / MATERIAL',
                  title: '소재는 정확하게',
                  body:
                      '상품 유형마다 실제 사용 소재와 혼용률을 구분해 안내합니다. 싱글렛과 라운드티, 골지타이즈, 펄원단 제품은 각기 다른 움직임과 착용 환경을 고려해 설계됩니다.',
                ),
                _storyBlock(
                  index: '03 / CHOICE',
                  title: '더 많이보다, 더 분명하게',
                  body:
                      '기성품과 단체 맞춤 제작을 구분해 운영합니다. 고객이 필요한 방식으로 선택하고, 구매 전 알아야 할 정보를 깔끔하게 확인할 수 있도록 만드는 것이 2FIT의 기준입니다.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _policyCard(
                  label: 'READY-MADE',
                  title: '기성품 싱글렛은\n디자인당 200장 한정.',
                  body:
                      '기성품 싱글렛 단품은 디자인당 200장 한정으로 운영합니다. 수량과 발매 원칙을 투명하게 알리고, 한 장의 선택이 오래 남을 수 있도록 준비합니다.',
                  dark: true,
                ),
                const SizedBox(height: 8),
                _policyCard(
                  label: 'TEAM ORDER',
                  title: '단체주문은\n팀을 위한 맞춤 제작.',
                  body:
                      '단체주문 상품은 한정 수량 컬렉션이 아닙니다. 팀의 수량, 디자인, 사양을 상담한 뒤 맞춤 제작 흐름으로 진행합니다.',
                  dark: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/products'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('상품 보러가기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 26),
          const Center(
            child: Text(
              '2FIT MALL · SPORTS & FITNESS WEAR',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
