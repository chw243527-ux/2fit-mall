import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('이용약관',
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2FIT MALL 이용약관',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text('시행일: 2025년 3월 21일',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSection(
            '제1조 (목적)',
            '본 약관은 2FIT MALL(이하 "회사")이 제공하는 쇼핑몰 서비스의 이용조건 및 절차, '
                '회사와 이용자 간의 권리·의무 관계를 규정함을 목적으로 합니다.',
          ),
          _buildSection(
            '제2조 (회원가입)',
            '• 만 14세 이상 이용 가능합니다.\n'
                '• 타인의 정보 도용 가입은 금지됩니다.\n'
                '• 허위 정보 제공 시 서비스 이용이 제한될 수 있습니다.',
          ),
          _buildSection(
            '제3조 (서비스 이용)',
            '• 서비스는 연중무휴 24시간 제공을 원칙으로 합니다.\n'
                '• 시스템 정기점검, 천재지변 등 불가피한 경우 서비스가 중단될 수 있습니다.',
          ),
          _buildSection(
            '제4조 (구매 및 결제)',
            '• 주문 후 입금 확인 시 배송이 시작됩니다.\n'
                '• 단순 변심에 의한 반품은 수령 후 7일 이내 가능합니다.\n'
                '• 상품 하자의 경우 수령 후 3개월 이내 교환/환불이 가능합니다.',
          ),
          _buildSection(
            '제5조 (교환 및 환불)',
            '• 교환/환불은 수령 후 7일 이내 신청 가능합니다.\n'
                '• 단체복/맞춤제작 상품은 교환·환불이 불가합니다.\n'
                '• 상품 불량/오배송의 경우 100% 교환 또는 환불 처리합니다.\n'
                '• 환불은 결제 취소 후 3-5 영업일 내 처리됩니다.',
          ),
          _buildSection(
            '제6조 (금지행위)',
            '• 타인의 계정 무단 사용\n'
                '• 서비스 운영 방해\n'
                '• 허위 리뷰 작성\n'
                '• 불법 콘텐츠 유포',
          ),
          _buildSection(
            '제7조 (면책조항)',
            '천재지변, 전쟁 등 불가항력으로 인한 서비스 중단에 대해 회사는 책임을 지지 않습니다.',
          ),
          _buildSection(
            '제8조 (준거법 및 관할법원)',
            '본 약관은 대한민국 법률에 따라 규율되며, '
                '서비스 이용과 관련한 분쟁은 회사 소재지 관할 법원을 전속 관할로 합니다.',
          ),

          const SizedBox(height: 24),

          // 문의 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Text('이용약관 관련 문의',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                const Text('cs@2fitkorea.com',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('운영시간: 평일 10:00 - 18:00',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
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
