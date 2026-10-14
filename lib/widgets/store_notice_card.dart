import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';

/// 쇼핑몰 전반에서 사용하는 구매·이미지 안내 카드입니다.
/// 디자인 이미지는 실제 상품 디자인을 확인하기 위한 이미지이므로
/// AI 생성 이미지 고지의 대상에서 제외한다는 점을 명시합니다.
class StoreNoticeCard extends StatelessWidget {
  final bool showPurchaseGuide;
  final bool showAiImageGuide;
  final bool compact;

  const StoreNoticeCard({
    super.key,
    this.showPurchaseGuide = true,
    this.showAiImageGuide = true,
    this.compact = false,
  });

  static const _purchaseItems = <String>[
    '상품 이미지와 실제 상품의 색상은 촬영 환경, 조명 및 모니터 설정에 따라 다르게 보일 수 있습니다.',
    '사이즈는 측정 방법과 측정 위치에 따라 1~2cm 정도 오차가 발생할 수 있으므로, 상세 사이즈표를 함께 확인해 주세요.',
    '개인의 체형과 착용 방식에 따라 실제 핏과 착용감이 다르게 느껴질 수 있습니다.',
    '생산 시기와 생산 로트에 따라 퀼팅 간격, 패치 위치 및 그래픽 위치가 일부 달라질 수 있습니다.',
    '충전재 특성상 개봉 직후 상품의 볼륨감이나 형태가 다르게 느껴질 수 있습니다. 가볍게 털어주고 충분히 펴주면 자연스럽게 회복됩니다.',
  ];

  @override
  Widget build(BuildContext context) {
    if (!showPurchaseGuide && !showAiImageGuide) {
      return const SizedBox.shrink();
    }
    final r = Responsive.of(context);
    final horizontal = compact ? r.w(16) : r.w(20);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: compact ? r.w(12) : r.w(16),
        vertical: compact ? r.h(10) : r.h(14),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontal,
        compact ? r.h(14) : r.h(18),
        horizontal,
        compact ? r.h(14) : r.h(18),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showPurchaseGuide) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: r.sp(compact ? 17 : 19), color: AppColors.primary),
                SizedBox(width: r.w(7)),
                Text(
                  '구매 전 꼭 확인해 주세요',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: r.sp(compact ? 14 : 15),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: r.h(9)),
            Text(
              '상품 주문 전 아래 안내사항을 확인해 주시기 바랍니다.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: r.sp(compact ? 11 : 12),
                height: 1.45,
              ),
            ),
            SizedBox(height: r.h(8)),
            ..._purchaseItems.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: r.h(5)),
                    child: Text(
                      '${entry.key + 1}. ${entry.value}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: r.sp(compact ? 11 : 12),
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
          ],
          if (showPurchaseGuide && showAiImageGuide)
            Padding(
              padding: EdgeInsets.symmetric(vertical: r.h(9)),
              child: const Divider(height: 1, color: AppColors.border),
            ),
          if (showAiImageGuide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: r.sp(compact ? 16 : 18), color: AppColors.accent),
                SizedBox(width: r.w(7)),
                Expanded(
                  child: Text(
                    '디자인 이미지를 제외한 상품 사진은 AI로 생성된 이미지입니다. 실제 상품의 디자인은 디자인 이미지를 반드시 확인해 주세요.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: r.sp(compact ? 11 : 12),
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
