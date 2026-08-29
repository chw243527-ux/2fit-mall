import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
        title: Text(context.loc.t('개인정보처리방침', '개인정보처리방침'),
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
                Text(context.loc.t('2FIT_MALL_개인정보처_4e637f', '2FIT MALL 개인정보처리방침'),
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

          _buildSection(
            context.loc.t('제1조_수집하는_개인정보_항목', '제1조 (수집하는 개인정보 항목)'),
            context.loc.t('개인정보_수집_항목_내용', '2FIT MALL은 회원가입 및 서비스 이용을 위해 아래와 같은 개인정보를 수집합니다.\n\n• 필수항목: 이름, 이메일 주소, 비밀번호, 휴대폰 번호\n• 선택항목: 마케팅 수신 동의\n• 자동수집: 서비스 이용기록, 접속 로그, 쿠키, IP 주소'),
          ),
          _buildSection(
            context.loc.t('제2조_개인정보의_수집_및_이용목적', '제2조 (개인정보의 수집 및 이용목적)'),
            context.loc.t('개인정보_이용목적_내용', '• 회원가입 및 본인 확인\n• 서비스 제공 및 계약 이행\n• 주문/배송/결제 처리\n• 주문 확인·배송 안내 카카오 알림톡 발송\n• 고객 문의 및 불만 처리\n• 마케팅 및 광고 활용 (동의 시)'),
          ),
          _buildSection(
            context.loc.t('제3조_개인정보_보유_및_이용기간', '제3조 (개인정보 보유 및 이용기간)'),
            context.loc.t('개인정보_보유기간_내용', '회원 탈퇴 시 즉시 삭제합니다. 단, 관련 법령에 따라 아래 기간 동안 보관합니다.\n\n• 계약/청약철회 기록: 5년 (전자상거래법)\n• 소비자 불만/분쟁처리 기록: 3년\n• 접속 로그: 3개월 (통신비밀보호법)'),
          ),
          _buildSection(
            context.loc.t('제4조_개인정보_제3자_제공', '제4조 (개인정보 제3자 제공)'),
            context.loc.t('개인정보_제3자_제공_내용', '2FIT MALL은 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 단, 아래의 경우 최소한의 정보를 제공합니다.\n\n• 배송 처리: 택배사에 수령인·주소·연락처 제공\n• 결제 처리: 토스페이먼츠에 결제 정보 제공\n• 알림톡 발송: SOLAPI를 통해 주문·배송 정보 발송'),
          ),
          _buildSection(
            context.loc.t('제5조_개인정보처리_위탁', '제5조 (개인정보처리 위탁)'),
            context.loc.t('개인정보_위탁_내용', '• Firebase (Google): 회원 인증 및 데이터 저장\n• 토스페이먼츠: 결제 처리\n• SOLAPI: 카카오 알림톡 발송 (주문확인·배송안내)\n• EmailJS: 이메일 발송 서비스\n• Cloudflare: 웹 서비스 호스팅\n• 택배사: 배송 처리'),
          ),
          _buildSection(
            context.loc.t('제6조_이용자의_권리', '제6조 (이용자의 권리)'),
            context.loc.t('개인정보_이용자_권리_내용', '이용자는 언제든지 아래 권리를 행사할 수 있습니다.\n\n• 개인정보 열람 요청\n• 오류 정정 요청\n• 삭제 요청 (회원 탈퇴)\n• 처리 정지 요청\n\n문의: chw243527@gmail.com'),
          ),
          _buildSection(
            context.loc.t('제7조_개인정보_보호책임자', '제7조 (개인정보 보호책임자)'),
            context.loc.t('개인정보_보호책임자_내용', '• 회사명: 주식회사 2FIT Korea\n• 대표자: 최혜원\n• 사업장 주소: 전북 남원시 오들1길 97, 205-303\n• 책임자 이메일: chw243527@gmail.com\n• 고객센터: 010-7227-6914\n\n본 방침은 2025년 3월 21일부터 적용됩니다.'),
          ),
          _buildSection(
            context.loc.t('제8조_쿠키_및_자동수집_장치', '제8조 (쿠키 및 자동수집 장치)'),
            context.loc.t('서비스_이용_편의_쿠키_사용_브라우저_거부_제한', '서비스 이용 편의를 위해 쿠키를 사용할 수 있으며, 브라우저 설정을 통해 거부할 수 있습니다. 쿠키 거부 시 일부 서비스 이용이 제한될 수 있습니다.'),
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
                Text(context.loc.t('개인정보_관련_문의', '개인정보 관련 문의'),
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
