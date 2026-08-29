import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';

import '../../utils/theme.dart';

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

    return wrapWithPopScope(
        context,
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 20),
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        context.loc
                            .t('2FIT_MALL_개인정보처_4e637f', '2FIT MALL 개인정보처리방침'),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text(
                        context.loc.t('시행일__2025년_3월_2_62b7e9',
                            '시행일: 2025년 3월 21일  |  최종수정: 2026년 8월 29일'),
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSection(
                context.loc.t('제1조_수집하는_개인정보_항목', '제1조 (수집하는 개인정보 항목)'),
                context.loc.t('개인정보_수집_항목_내용',
                    '2FIT MALL은 회원가입 및 서비스 이용을 위해 아래와 같은 개인정보를 수집합니다.\n\n• 필수항목: 이름, 이메일 주소, 비밀번호, 휴대폰 번호\n• 선택항목: 마케팅 수신 동의\n• 자동수집: 서비스 이용기록, 접속 로그, 쿠키, IP 주소'),
              ),
              _buildSection(
                context.loc.t('제2조_개인정보의_수집_및_이용목적', '제2조 (개인정보의 수집 및 이용목적)'),
                context.loc.t('개인정보_이용목적_내용',
                    '• 회원가입 및 본인 확인\n• 서비스 제공 및 계약 이행\n• 주문/배송/결제 처리\n• 주문 확인·배송 안내 카카오 알림톡 발송\n• 고객 문의 및 불만 처리\n• 마케팅 및 광고 활용 (동의 시)'),
              ),
              _buildSection(
                context.loc.t('제3조_개인정보_보유_및_이용기간', '제3조 (개인정보 보유 및 이용기간)'),
                context.loc.t('개인정보_보유기간_내용',
                    '회원 탈퇴가 완료되면 로그인 계정과 회원정보, 찜·쿠폰·포인트 내역, 사이즈 프로필, 알림, 재입고 신청, 채팅, 리뷰 및 리뷰 이미지를 삭제합니다. 주문·결제 및 교환·반품 기록은 관련 법령 준수와 분쟁 처리에 필요한 범위에서 개인정보를 익명화한 뒤 보관할 수 있습니다.\n\n• 계약 또는 청약철회 기록: 5년\n• 소비자 불만 또는 분쟁 처리 기록: 3년\n• 접속 로그: 3개월\n\n보관 기간이 끝나면 해당 기록을 지체 없이 삭제 또는 파기합니다.'),
              ),
              _buildSection(
                context.loc.t('제4조_개인정보_제3자_제공', '제4조 (개인정보 제3자 제공)'),
                context.loc.t('개인정보_제3자_제공_내용',
                    '2FIT MALL은 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 단, 아래의 경우 최소한의 정보를 제공합니다.\n\n• 배송 처리: 택배사에 수령인·주소·연락처 제공\n• 결제 처리: 토스페이먼츠에 결제 정보 제공\n• 알림톡 발송: SOLAPI를 통해 주문·배송 정보 발송'),
              ),
              _buildSection(
                context.loc.t('제5조_개인정보처리_위탁', '제5조 (개인정보처리 위탁)'),
                context.loc.t('개인정보_위탁_내용',
                    '• Firebase (Google): 회원 인증, 데이터베이스·파일 저장, 서버 기능, 서비스 분석 및 알림 발송\n• Google·Kakao·Naver: 소셜 로그인 본인 확인 및 계정 연동\n• 토스페이먼츠: 결제 처리\n• SOLAPI: 카카오 알림톡 발송 (주문확인·배송안내)\n• EmailJS: 이메일 발송 서비스\n• Cloudflare: 웹 서비스 호스팅 및 보안\n• 택배사: 배송 처리'),
              ),
              _buildSection(
                context.loc.t('제6조_개인정보_파기_및_계정_삭제', '제6조 (개인정보 파기 및 계정 삭제)'),
                context.loc.t('계정삭제_및_익명화_안내',
                    '회원은 앱 또는 웹의 마이페이지에서 회원 탈퇴를 요청할 수 있습니다. 로그인할 수 없는 경우에는 계정 삭제 요청 페이지 또는 고객센터 이메일을 통해 요청할 수 있습니다.\n\n• 즉시 삭제: 로그인 계정, 회원정보, 개인 설정, 채팅, 리뷰 및 알림\n• 익명화 후 보관: 주문·결제, 교환·반품 등 거래 증빙에 필요한 기록\n• 계정 삭제 요청 페이지: https://2fit-mall.co.kr/account-deletion\n\n익명화된 거래 기록에는 성명, 이메일, 전화번호, 배송지 등 개인을 직접 식별할 수 있는 정보를 남기지 않습니다.'),
              ),
              _buildSection(
                context.loc.t('제7조_안전성_확보_조치', '제7조 (개인정보의 안전성 확보 조치)'),
                context.loc.t('개인정보_안전성_조치_내용',
                    '2FIT MALL은 개인정보 보호를 위해 다음 조치를 적용합니다.\n\n• 서비스 통신 구간에 HTTPS 암호화를 사용합니다.\n• 인증, 데이터 접근 및 관리 기능은 권한에 따라 제한합니다.\n• 결제 비밀값과 메시지 발송 비밀값은 앱에 저장하지 않고 서버의 안전한 설정 영역에서 관리합니다.\n• 접근 기록을 점검하고, 권한 없는 접근·변조·유출을 방지하기 위한 기술적·관리적 조치를 운영합니다.'),
              ),
              _buildSection(
                context.loc.t('제8조_이용자의_권리', '제8조 (이용자의 권리)'),
                context.loc.t('개인정보_이용자_권리_내용',
                    '이용자는 언제든지 아래 권리를 행사할 수 있습니다.\n\n• 개인정보 열람 요청\n• 오류 정정 요청\n• 삭제 요청 (회원 탈퇴)\n• 처리 정지 요청\n\n문의: chw243527@gmail.com'),
              ),
              _buildSection(
                context.loc.t('제9조_개인정보_보호책임자', '제9조 (개인정보 보호책임자)'),
                context.loc.t('개인정보_보호책임자_내용',
                    '• 회사명: ${AppConstants.companyName}\n• 대표자: ${AppConstants.ceoName}\n• 사업장 주소: ${AppConstants.companyAddress}\n• 책임자 이메일: ${AppConstants.customerServiceEmail}\n• 고객센터: ${AppConstants.customerServicePhone}\n\n본 방침은 2025년 3월 21일부터 적용됩니다.'),
              ),
              _buildSection(
                context.loc.t('제10조_쿠키_및_자동수집_장치', '제10조 (쿠키 및 자동수집 장치)'),
                context.loc.t('서비스_이용_편의_쿠키_사용_브라우저_거부_제한',
                    '서비스 이용 편의를 위해 쿠키를 사용할 수 있으며, 브라우저 설정을 통해 거부할 수 있습니다. 쿠키 거부 시 일부 서비스 이용이 제한될 수 있습니다.'),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const SizedBox(height: 8),
                    const Text('chw243527@gmail.com',
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        context.loc.t(
                            '운영시간__평일_10_00__d8a41f', '운영시간: 평일 10:00 - 18:00'),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/account-deletion'),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('계정 삭제 요청 페이지로 이동'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
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
                color: AppColors.primary)),
        iconColor: const Color(0xFF6C63FF),
        collapsedIconColor: Colors.grey,
        initiallyExpanded: true,
        children: [
          Text(content,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.6)),
        ],
      ),
    );
  }
}
