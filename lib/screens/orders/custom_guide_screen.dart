import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/navigation_helper.dart';
import '../../utils/theme.dart';

class CustomGuideScreen extends StatelessWidget {
  final bool showDesignGallery;

  const CustomGuideScreen({super.key, this.showDesignGallery = false});

  static const _gallery = <Map<String, String>>[
    {
      'asset': 'assets/images/banner_custom_fit.jpg',
      'title': 'Designed for your team',
      'caption': '팀의 컬러와 로고를 담은 커스텀 러닝웨어',
    },
    {
      'asset': 'assets/winter_banner/winter_design_source_65108.png',
      'title': 'Our design reference',
      'caption': '기존 디자인을 바탕으로 팀 스타일을 완성해 보세요',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return wrapWithPopScope(
      context,
      Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(showDesignGallery ? 'USE OUR DESIGN' : 'HOW TO CUSTOM'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(context),
              const SizedBox(height: 24),
              if (!showDesignGallery) ...[
                _sectionTitle('HOW TO CUSTOM', '팀을 위한 디자인을 만드는 방법'),
                const SizedBox(height: 12),
                _step(1, 'Choose your base', '원하는 싱글렛·타이즈·세트 상품을 선택합니다.'),
                _step(2, 'Share your idea',
                    '팀명, 컬러, 로고와 원하는 디자인 방향을 카카오채널로 보내 주세요.'),
                _step(3, 'Review the proof', '상담 후 제작 시안과 견적, 제작 일정을 확인합니다.'),
                _step(4, 'Make it your team', '최종 확정된 디자인으로 제작을 시작합니다.'),
                const SizedBox(height: 24),
                _cta(context),
              ] else ...[
                _sectionTitle('USE OUR DESIGN', '검증된 디자인에서 팀의 스타일을 시작하세요'),
                const SizedBox(height: 12),
                const Text(
                  '아래 디자인을 참고해 팀의 컬러와 로고를 조합할 수 있습니다. 사진 속 디자인을 그대로 사용하거나 원하는 부분을 상담으로 수정할 수 있습니다.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ..._gallery.map(_galleryCard),
                const SizedBox(height: 12),
                _cta(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.asset(
            'assets/images/banner_custom_fit.jpg',
            width: double.infinity,
            height: 210,
            fit: BoxFit.cover,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 48, 18, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
            child: Text(
              showDesignGallery ? 'USE OUR DESIGN' : 'MAKE IT YOUR TEAM',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(subtitle,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _step(int number, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text('$number',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary)),
              ])),
        ],
      ),
    );
  }

  Widget _galleryCard(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Image.asset(item['asset']!,
            width: double.infinity, height: 190, fit: BoxFit.cover),
        Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['title']!,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(item['caption']!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ])),
      ]),
    );
  }

  Widget _cta(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _openKakaoChannel(),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('KAKAO CHANNEL · START A CONSULTATION'),
      ),
    );
  }

  Future<void> _openKakaoChannel() async {
    final uri = Uri.parse('https://pf.kakao.com/_MQxjXX/chat');
    // 카카오채널 CTA는 기존 상담 흐름과 동일한 웹 fallback을 사용합니다.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
