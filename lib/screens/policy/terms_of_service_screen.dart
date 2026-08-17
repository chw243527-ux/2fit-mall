import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LanguageProvider>().triggerTranslation();
    });
  }

  @override
  Widget build(BuildContext context) {
    // LanguageProvider를 watch → 번역 완료 시 자동 rebuild
    context.watch<LanguageProvider>();

    return wrapWithPopScope(context, Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        title: Text(context.loc.t('이용약관', '이용약관'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.loc.t('2FIT_MALL_이용약관', '2FIT MALL 이용약관'),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text(context.loc.t('시행일__2025년_3월_2_62b7e9', '시행일: 2025년 3월 21일  |  최종수정: 2026년 6월 17일'),
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 사업자 정보 카드
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.loc.t('사업자_정보', '사업자 정보'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                SizedBox(height: 10),
                _InfoRow(context.loc.t('회사명', '회사명'), context.loc.t('주식회사_2FIT_Korea', '주식회사 2FIT Korea')),
                _InfoRow(context.loc.t('대표자', '대표자'), context.loc.t('최혜원', '최혜원')),
                _InfoRow(context.loc.t('사업장_주소', '사업장 주소'), context.loc.t('전북_남원시_오들1길_97_205_303', '전북 남원시 오들1길 97, 205-303')),
                _InfoRow(context.loc.t('사업자등록번호', '사업자등록번호'), '787-19-02539'),
                _InfoRow(context.loc.t('통신판매업신고', '통신판매업신고'), context.loc.t('심사_중', '심사 중')),
                _InfoRow(context.loc.t('고객센터', '고객센터'), '010-7227-6914'),
                _InfoRow(context.loc.t('이메일', '이메일'), 'chw243527@gmail.com'),
                _InfoRow(context.loc.t('운영시간', '운영시간'), context.loc.t('평일_10_00_18_00_점심_12_00_14_00', '평일 10:00 ~ 18:00 (점심 12:00~14:00)')),
              ],
            ),
          ),

          _buildSection(
            context.loc.t('제1조_목적', '제1조 (목적)'),
            context.loc.t('이용약관_제1조_목적_내용', '본 약관은 주식회사 2FIT Korea(이하 "회사")가 운영하는 2FIT MALL 쇼핑몰 서비스의 이용조건 및 절차, 회사와 이용자 간의 권리·의무 관계를 규정함을 목적으로 합니다.'),
          ),
          _buildSection(
            context.loc.t('제2조_회원가입', '제2조 (회원가입)'),
            context.loc.t('이용약관_제2조_내용', '• 만 14세 이상 이용 가능합니다.\n• 타인의 정보 도용 가입은 금지됩니다.\n• 허위 정보 제공 시 서비스 이용이 제한될 수 있습니다.'),
          ),
          _buildSection(
            context.loc.t('제3조_서비스_이용', '제3조 (서비스 이용)'),
            context.loc.t('이용약관_제3조_내용', '• 서비스는 연중무휴 24시간 제공을 원칙으로 합니다.\n• 시스템 정기점검, 천재지변 등 불가피한 경우 서비스가 중단될 수 있습니다.\n• 주문 완료 후 카카오 알림톡으로 주문확인·배송 안내를 발송합니다.'),
          ),
          _buildSection(
            context.loc.t('제4조_구매_및_결제', '제4조 (구매 및 결제)'),
            context.loc.t('이용약관_제4조_내용', '• 결제 수단: 신용카드, 가상계좌, 계좌이체, 간편결제 (토스페이먼츠)\n• 주문 완료 후 결제 확인 시 배송이 시작됩니다.\n• 단순 변심에 의한 반품은 수령 후 7일 이내 가능합니다.\n• 상품 하자의 경우 수령 후 3개월 이내 교환/환불이 가능합니다.'),
          ),
          _buildSection(
            context.loc.t('제5조_교환_및_환불', '제5조 (교환 및 환불)'),
            context.loc.t('이용약관_제5조_내용', '• 교환/환불은 수령 후 7일 이내 신청 가능합니다.\n• 단체복/맞춤제작 상품은 교환·환불이 불가합니다.\n• 상품 불량/오배송의 경우 100% 교환 또는 환불 처리합니다.\n• 환불은 결제 취소 후 3~5 영업일 내 처리됩니다.\n• 반품 배송비는 구매자 부담이며, 상품 불량 시 회사가 부담합니다.'),
          ),
          _buildSection(
            context.loc.t('제6조_배송', '제6조 (배송)'),
            context.loc.t('이용약관_제6조_내용', '• 주문 확인 후 1~3 영업일 이내 발송합니다.\n• 단체복 맞춤제작은 제작 기간(14~21일)이 소요됩니다.\n• 배송비는 상품 페이지에 표시된 금액에 따릅니다.\n• 배송 시작 시 카카오 알림톡으로 운송장 번호를 안내합니다.'),
          ),
          _buildSection(
            context.loc.t('제7조_금지행위', '제7조 (금지행위)'),
            context.loc.t('이용약관_제7조_내용', '• 타인의 계정 무단 사용\n• 서비스 운영 방해\n• 허위 리뷰 작성\n• 불법 콘텐츠 유포'),
          ),
          _buildSection(
            context.loc.t('제8조_면책조항', '제8조 (면책조항)'),
            context.loc.t('천재지변_전쟁_등_불가항력_서비스_중단_회사_책임', '천재지변, 전쟁 등 불가항력으로 인한 서비스 중단에 대해 회사는 책임을 지지 않습니다.'),
          ),
          _buildSection(
            context.loc.t('제9조_준거법_및_관할법원', '제9조 (준거법 및 관할법원)'),
            context.loc.t('이용약관_제9조_내용', '본 약관은 대한민국 법률에 따라 규율되며, 서비스 이용과 관련한 분쟁은 회사 소재지 관할 법원(전주지방법원 남원지원)을 전속 관할로 합니다.'),
          ),

          const SizedBox(height: 24),

          // 문의 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(context.loc.t('이용약관_관련_문의', '이용약관 관련 문의'),
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                const Text('chw243527@gmail.com',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(context.loc.t('운영시간__평일_10_00__d8a41f', '운영시간: 평일 10:00 - 18:00'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ));
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
        iconColor: const Color(0xFF6C63FF),
        collapsedIconColor: Colors.grey,
        initiallyExpanded: true,
        children: [
          Text(content,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.6)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF333333))),
          ),
        ],
      ),
    );
  }
}
