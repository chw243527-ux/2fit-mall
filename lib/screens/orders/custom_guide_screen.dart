import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/navigation_helper.dart';
import '../../utils/theme.dart';

class CustomGuideScreen extends StatelessWidget {
  final bool showDesignGallery;

  const CustomGuideScreen({super.key, this.showDesignGallery = false});

  @override
  Widget build(BuildContext context) {
    return wrapWithPopScope(
      context,
      Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(showDesignGallery ? 'OUR TEAMS' : 'HOW TO CUSTOM'),
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
                _step(1, '단체주문 버튼 클릭', '카카오채널로 문의를 시작합니다.'),
                _step(2, '상품 정보 전달', '단체주문 상품번호와 단체주문을 원하는 카테고리를 판매자에게 전달합니다.'),
                _step(3, '주문 서식 받기', '판매자에게 단체주문 서식을 받아 작성합니다.'),
                _step(4, '디자인 정보 전달', '팀명, 컬러번호, 로고, 원하는 디자인 방향을 판매자에게 전달합니다.'),
                _step(5, '시안·견적·일정 확인', '상담 후 제작 시안과 견적, 제작 일정을 확인합니다.'),
                _step(6, '제작 시작', '최종 확정된 디자인으로 제작을 시작합니다.'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: Text(
                    '※ 디자인 수정은 2회만 가능합니다.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),
                _cta(context),
              ] else ...[
                _sectionTitle('OUR TEAMS', '우리 쇼핑몰에서 구매한 팀들의 실제 착용 사진'),
                const SizedBox(height: 12),
                const Text(
                  'NEXTR와 함께한 팀들의 사진을 소개합니다. 우리 팀의 단체주문 상담과 사진 등록은 카카오채널로 문의해 주세요.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _teamGallery(),
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
      child: Image.asset(
        'assets/images/banner_custom_fit_no_text.png',
        width: double.infinity,
        height: 210,
        fit: BoxFit.cover,
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

  Widget _teamGallery() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('team_gallery').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('팀 사진을 불러오지 못했습니다.');
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = [...snapshot.data!.docs]
          ..sort((a, b) => (b.data()['sortOrder'] as num? ?? 0)
              .compareTo(a.data()['sortOrder'] as num? ?? 0));
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '등록된 구매 팀 사진을 준비 중입니다.\n우리 팀 사진 등록은 카카오채널로 문의해 주세요.',
              style: TextStyle(
                  fontSize: 13, height: 1.6, color: AppColors.textSecondary),
            ),
          );
        }
        return Column(
          children: docs.map(_teamGalleryCard).toList(),
        );
      },
    );
  }

  Widget _teamGalleryCard(DocumentSnapshot<Map<String, dynamic>> doc) {
    final item = doc.data() ?? const <String, dynamic>{};
    final imageUrl = item['imageUrl']?.toString() ?? '';
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
        Image.network(imageUrl,
            width: double.infinity, height: 190, fit: BoxFit.cover),
        Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['title']?.toString() ?? 'NEXTR 구매 팀',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(item['caption']?.toString() ?? 'NEXTR와 함께한 팀의 실제 착용 사진입니다.',
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
