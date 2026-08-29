import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/constants.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/theme.dart';

/// Google Play의 외부 계정 삭제 요청 URL에 사용하는 공개 화면입니다.
/// 로그인하지 않은 방문자도 삭제 절차를 확인하고 고객센터로 요청을 시작할 수 있습니다.
class AccountDeletionScreen extends StatelessWidget {
  const AccountDeletionScreen({super.key});

  static final Uri _deletionRequestEmail = Uri(
    scheme: 'mailto',
    path: AppConstants.customerServiceEmail,
    queryParameters: {
      'subject': '[2FIT MALL] 계정 삭제 요청',
      'body': '안녕하세요. 2FIT MALL 계정 삭제를 요청합니다.\n\n'
          '가입 이메일 또는 휴대폰 번호: \n'
          '성함: \n\n'
          '※ 비밀번호, 주민등록번호, 카드번호는 이메일에 적지 마세요.\n'
          '본인 확인을 위해 고객센터에서 별도로 안내드릴 수 있습니다.',
    },
  );

  Future<void> _openDeletionRequestEmail(BuildContext context) async {
    final opened = await launchUrl(
      _deletionRequestEmail,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일 앱을 열 수 없습니다. 고객센터 이메일로 직접 요청해 주세요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return wrapWithPopScope(
      context,
      Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
          title: const Text(
            '계정 삭제 요청',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 44),
                children: [
                  _HeaderCard(),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: '앱 또는 웹에서 바로 탈퇴하기',
                    icon: Icons.delete_forever_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '로그인할 수 있다면 앱 또는 웹에서 즉시 탈퇴할 수 있습니다. '
                          '로그인 후 마이페이지의 회원 탈퇴 메뉴를 선택해 주세요.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/login'),
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('로그인 후 회원 탈퇴하기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '로그인할 수 없는 경우',
                    icon: Icons.support_agent_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '비밀번호 분실, 소셜 로그인 문제 등으로 직접 탈퇴할 수 없다면 '
                          '아래 버튼으로 고객센터에 계정 삭제를 요청할 수 있습니다. '
                          '요청 접수 후 본인 확인을 거쳐 처리합니다.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openDeletionRequestEmail(context),
                            icon: const Icon(Icons.email_outlined),
                            label: Text(
                                '${AppConstants.customerServiceEmail}로 삭제 요청'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '보안을 위해 비밀번호, 주민등록번호, 카드번호는 이메일에 보내지 마세요.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '삭제 또는 익명화되는 정보',
                    icon: Icons.privacy_tip_outlined,
                    child: const _BulletList([
                      '삭제: 로그인 계정, 회원정보, 찜·쿠폰·포인트 내역, 사이즈 프로필, 알림, 재입고 신청, 채팅, 리뷰 및 리뷰 이미지',
                      '익명화 후 보관: 주문·결제 및 교환·반품 기록 중 법령상 또는 분쟁 처리에 필요한 거래 정보',
                      '회원 탈퇴 후에는 같은 계정으로 로그인하거나 삭제된 정보를 복구할 수 없습니다.',
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: '처리 기준',
                    icon: Icons.info_outline_rounded,
                    child: const _BulletList([
                      '직접 탈퇴: 보안 확인이 끝나면 즉시 처리됩니다.',
                      '이메일 요청: 본인 확인이 필요한 경우 고객센터에서 안내드립니다.',
                      '보존되는 거래 기록의 범위와 기간은 개인정보처리방침에 따릅니다.',
                    ]),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/privacy-policy'),
                    child: const Text('개인정보처리방침 확인하기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.manage_accounts_outlined, color: Colors.white, size: 30),
          SizedBox(height: 14),
          Text(
            '2FIT MALL 계정 삭제 요청',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '이 페이지에서 계정 삭제 방법을 확인하고 요청을 시작할 수 있습니다.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;

  const _BulletList(this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child:
                        Icon(Icons.circle, size: 5, color: AppColors.primary),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
