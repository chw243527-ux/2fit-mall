import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                _step(1, '판매자에게 문의하기', '상품 상세페이지의 버튼을 선택하면 주문 수량을 입력할 수 있습니다.'),
                _step(2, '주문 수량 선택', '단체주문은 5장 이상부터 가능합니다. 5~9장은 5인용, 10장 이상은 10인용 엑셀 주문서가 선택됩니다.'),
                _step(3, '내부 채팅방 연결', '수량을 선택하면 쇼핑몰 내부 채팅방으로 연결되고 상품명·상품번호·상품 ID·상품 유형·상담 수량이 자동으로 전달됩니다.'),
                _step(4, '엑셀 주문서 작성', '앱에서는 엑셀 앱으로 열고, 웹에서는 다운로드한 주문서를 작성합니다.'),
                _step(5, '주문서·로고 파일 전달', '작성한 주문서와 로고·디자인 파일을 판매자 이메일로 전달합니다.'),
                _step(
                  6,
                  '판매자 확인 및 디자인 제작',
                  '판매자가 주문서와 파일을 확인한 후 디자인을 제작하여 구매자에게 전달합니다.',
                ),
                _step(7, '디자인 수정', '디자인 수정은 총 2회까지 가능합니다.'),
                _step(8, '최종 확정 및 제작', '최종 확정된 디자인으로 제작을 시작합니다.'),
                _step(9, '배송', '제작 시작 후 전체 제작 기간은 약 2~3주입니다.'),
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
              ] else ...[
                _sectionTitle('OUR TEAMS', '우리 쇼핑몰에서 구매한 팀들의 실제 착용 사진'),
                const SizedBox(height: 12),
                const Text(
                  'NEXTR와 함께한 팀들의 사진을 소개합니다. 단체주문 상담은 상품 상세페이지의 판매자에게 문의하기를 이용해 주세요.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _teamGallery(),
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
        final docs = [...snapshot.data!.docs]..sort((a, b) =>
            (b.data()['sortOrder'] as num? ?? 0)
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
              '등록된 구매 팀 사진을 준비 중입니다.\n우리 팀 사진 등록은 쇼핑몰 내부 상담을 통해 문의해 주세요.',
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

}
