// group_order_sidebar_screen.dart
// 사이드바 전용 단체주문 안내 + 주문서식 페이지 (독립 페이지)
// GroupOrderGuideScreen과는 완전히 분리된 별도 페이지

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../widgets/pc_layout.dart';
import 'group_order_form_screen.dart';

class GroupOrderSidebarScreen extends StatefulWidget {
  const GroupOrderSidebarScreen({super.key});

  @override
  State<GroupOrderSidebarScreen> createState() =>
      _GroupOrderSidebarScreenState();
}

class _GroupOrderSidebarScreenState extends State<GroupOrderSidebarScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;
  late TabController _tab;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this, initialIndex: 0);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout(context);
    return _buildMobileLayout(context);
  }

  // ══════════════════════════════════════
  // 모바일 레이아웃
  // ══════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '단체주문 안내 & 주문서식',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: TabBar(
              controller: _tab,
              labelColor: const Color(0xFF6A1B9A),
              unselectedLabelColor: const Color(0xFF888888),
              indicatorColor: const Color(0xFF6A1B9A),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: '주문 안내'),
                Tab(text: '주문 서식'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildGuideTab(context),
                _buildFormTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // PC 레이아웃
  // ══════════════════════════════════════
  Widget _buildPcLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '단체주문 안내 & 주문서식',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 52,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측: 탭 컨텐츠
                Expanded(
                  flex: 7,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Color(0xFFE0E0E0))),
                          ),
                          child: TabBar(
                            controller: _tab,
                            labelColor: const Color(0xFF6A1B9A),
                            unselectedLabelColor: const Color(0xFF888888),
                            indicatorColor: const Color(0xFF6A1B9A),
                            indicatorWeight: 3,
                            tabs: const [
                              Tab(text: '📋 주문 안내'),
                              Tab(text: '📝 주문 서식'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tab,
                            children: [
                              _buildGuideTab(context),
                              _buildFormTab(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // 우측: 퀵 안내
                SizedBox(
                  width: 280,
                  child: _buildPcSidebar(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPcSidebar(BuildContext context) {
    return Column(
      children: [
        _buildInfoBox(
          icon: Icons.groups_rounded,
          color: const Color(0xFF6A1B9A),
          title: '단체주문 안내',
          items: const [
            '최소 1장부터 주문 가능',
            '5장 이상 무료 배송',
            '10명 이상 이름 인쇄',
            '커스텀 제작 2~3주',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoBox(
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFF1565C0),
          title: '배송 안내',
          items: const [
            '5장 이상: 무료 배송',
            '5장 미만: 배송비 3,000원',
            '단체주문은 일괄 배송',
            '추가제작 5장 미만 +4,000원',
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 16, color: Color(0xFFE65100)),
                  SizedBox(width: 6),
                  Text('문의',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100))),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '주문 관련 문의는\n채팅 또는 카카오채널로\n연락 주세요.',
                style: TextStyle(
                    fontSize: 12, height: 1.6, color: Color(0xFF555555)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 12, color: color.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF444444))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 탭1: 주문 안내
  // ══════════════════════════════════════
  Widget _buildGuideTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏆 2FIT 단체주문',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                SizedBox(height: 6),
                Text('팀·단체 맞춤 제작 서비스\n주문 안내와 서식을 확인해 주세요.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 최소 수량 안내
          _buildInfoCard(
            icon: Icons.group_outlined,
            iconBg: const Color(0xFFEDE7F6),
            iconColor: const Color(0xFF6A1B9A),
            title: '최소 주문 수량',
            content: '1장부터 주문 가능합니다.\n5장 이상부터 커스텀 옵션 선택 가능합니다.',
          ),
          const SizedBox(height: 10),

          // 제작 기간
          _buildInfoCard(
            icon: Icons.schedule_outlined,
            iconBg: const Color(0xFFF3E5F5),
            iconColor: const Color(0xFF7B1FA2),
            title: '제작 기간',
            content: '주문 확정 후 약 2~3주 소요됩니다.\n(디자인 확정 후 제작 시작)',
          ),
          const SizedBox(height: 10),

          // 배송 안내
          _buildInfoCard(
            icon: Icons.local_shipping_outlined,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
            title: '배송 안내',
            contentWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• 5장 이상: 무료 배송',
                    style: TextStyle(fontSize: 13, height: 1.6)),
                Text('• 5장 미만: 배송비 3,000원',
                    style: TextStyle(fontSize: 13, height: 1.6)),
                Text('• 추가 제작 5장 미만: 배송비 4,000원',
                    style: TextStyle(fontSize: 13, height: 1.6)),
                Text('• 단체주문은 일괄 배송됩니다.',
                    style: TextStyle(fontSize: 13, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 커스텀 옵션
          _buildSectionHeader('💰', '커스텀 옵션'),
          const SizedBox(height: 12),
          _buildCustomOptionCards(),
          const SizedBox(height: 16),

          // 허리밴드 옵션
          _buildSectionHeader('⚡', '허리밴드 옵션'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('• 허리밴드 변경 옵션 선택 가능',
                    style: TextStyle(fontSize: 13, height: 1.7)),
                Text('• 단체명 인쇄 또는 색상 변경 선택',
                    style: TextStyle(fontSize: 13, height: 1.7)),
                SizedBox(height: 4),
                Text('• 옵션 추가 시 별도 견적 안내',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE65100))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 디자인 파일 안내
          _buildSectionHeader('📎', '디자인 파일 안내'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '팀 로고·단체명 이미지를 첨부해 주세요.',
                  style: TextStyle(fontSize: 13, height: 1.7),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.attach_file_rounded,
                          size: 16, color: Color(0xFF1565C0)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '지원 파일: AI, PDF, PNG, JPG',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1565C0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 인쇄 타입
          _buildSectionHeader('🖨️', '인쇄 타입'),
          const SizedBox(height: 12),
          _buildPrintTypeCards(),
          const SizedBox(height: 24),

          // 추가 주문 안내
          _buildSectionHeader('➕', '추가 주문 안내'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCE93D8)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• 최초 주문 완료 후 추가 제작 가능',
                    style: TextStyle(fontSize: 13, height: 1.7)),
                Text('• 기존 디자인 그대로 추가 주문',
                    style: TextStyle(fontSize: 13, height: 1.7)),
                Text('⚠️ 추가 주문은 마이페이지에서 가능합니다.',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        color: Color(0xFF880E4F))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 사이즈 안내
          _buildSectionHeader('📏', '사이즈 안내'),
          const SizedBox(height: 12),
          _buildSizeTable(context),
          const SizedBox(height: 24),

          // 동의 체크박스 + 주문서식 이동 버튼
          _buildAgreementSection(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 탭2: 주문 서식 (직접 주문서 작성)
  // ══════════════════════════════════════
  Widget _buildFormTab(BuildContext context) {
    if (!_agreed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outlined,
                  size: 64, color: Color(0xFFCCCCCC)),
              const SizedBox(height: 16),
              const Text(
                '주문 안내를 먼저 확인하고\n동의 후 주문서식을 작성해 주세요.',
                style: TextStyle(fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tab.animateTo(0),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('주문 안내 보기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 동의 완료 → GroupOrderFormScreen으로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GroupOrderFormScreen(product: null),
          ),
        ).then((_) {
          if (mounted) {
            _tab.animateTo(0);
            setState(() => _agreed = false);
          }
        });
      }
    });

    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
    );
  }

  // ══════════════════════════════════════
  // 동의 + 주문서 이동 버튼
  // ══════════════════════════════════════
  Widget _buildAgreementSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _agreed ? const Color(0xFFF3E5F5) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _agreed
              ? const Color(0xFF6A1B9A)
              : const Color(0xFFDDDDDD),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _agreed
                        ? const Color(0xFF6A1B9A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _agreed
                          ? const Color(0xFF6A1B9A)
                          : const Color(0xFFBBBBBB),
                      width: 2,
                    ),
                  ),
                  child: _agreed
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '주문 안내 사항을 모두 확인하였으며,\n내용에 동의합니다.',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          if (_agreed) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _tab.animateTo(1),
                icon: const Icon(Icons.edit_document, size: 18),
                label: const Text(
                  '주문서 작성하기',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              '동의 후 주문서 작성이 가능합니다.',
              style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // 공통 위젯들
  // ══════════════════════════════════════
  Widget _buildSectionHeader(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? content,
    Widget? contentWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (content != null)
                  Text(content,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                          height: 1.6)),
                if (contentWidget != null) contentWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomOptionCards() {
    final options = [
      {
        'icon': '🎨',
        'title': '팀 로고/마킹 추가 (5장 이상)',
        'desc': '팀 로고 파일 첨부 필수 (AI/PDF/PNG)',
        'badge': '5장↑ FREE',
        'color': const Color(0xFF1565C0),
      },
      {
        'icon': '👕',
        'title': '단체명(전면) 인쇄',
        'desc': '앞면 팀/단체명 인쇄 변경',
        'badge': '5장↑ FREE',
        'color': const Color(0xFF2E7D32),
      },
      {
        'icon': '🎯',
        'title': '단체명+색상 변경',
        'desc': '단체명 인쇄 + 상하의 색상 변경',
        'badge': '5장↑ FREE',
        'color': const Color(0xFF6A1B9A),
      },
      {
        'icon': '✏️',
        'title': '단체명+색상+이름 인쇄',
        'desc': '전면 단체명+색상 + 후면 개인 이름',
        'badge': '10장↑ FREE',
        'color': const Color(0xFFC62828),
      },
    ];

    return Column(
      children: options.map((opt) {
        final color = opt['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Text(opt['icon'] as String,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt['title'] as String,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    const SizedBox(height: 3),
                    Text(opt['desc'] as String,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opt['badge'] as String,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrintTypeCards() {
    final types = [
      {
        'no': '①',
        'title': '색상변경 (단체명 변경 없음)',
        'badge': '5장↑ FREE',
        'desc': '상의·하의 동일 색상으로 변경',
        'color': const Color(0xFF1565C0),
      },
      {
        'no': '②',
        'title': '단체명변경(전면) + 색상변경 없음',
        'badge': '5장↑ FREE',
        'desc': '앞면 팀/단체명 인쇄',
        'color': const Color(0xFF2E7D32),
      },
      {
        'no': '③',
        'title': '단체명변경(전면) + 색상변경',
        'badge': '5장↑ FREE',
        'desc': '단체명 + 상하의 동일 색상 변경',
        'color': const Color(0xFF6A1B9A),
      },
      {
        'no': '④',
        'title': '단체명+색상+이름변경(후면)',
        'badge': '10장↑ FREE',
        'desc': '전면 단체명+색상 + 후면 개인 이름 인쇄',
        'color': const Color(0xFFC62828),
      },
    ];

    return Column(
      children: types.map((t) {
        final color = t['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    t['no'] as String,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['title'] as String,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(t['desc'] as String,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF777777))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  t['badge'] as String,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeTable(BuildContext context) {
    final adultSizes = [
      ['사이즈', '권장 신장', '권장 체중'],
      ['XXXS', '145~150', '42~46'],
      ['XXS', '150~155', '46~50'],
      ['XS', '155~160', '50~55'],
      ['S', '160~165', '55~60'],
      ['M', '165~170', '60~65'],
      ['L', '170~175', '65~72'],
      ['XL', '175~180', '72~80'],
      ['XXL', '180~185', '80~90'],
      ['XXXL', '185+', '90+'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('성인 사이즈 (단위: cm / kg)',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF888888))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            children: adultSizes.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              final isHeader = i == 0;
              return Container(
                decoration: BoxDecoration(
                  color: isHeader
                      ? const Color(0xFF6A1B9A)
                      : i % 2 == 0
                          ? const Color(0xFFFAFAFA)
                          : Colors.white,
                  borderRadius: i == 0
                      ? const BorderRadius.vertical(top: Radius.circular(9))
                      : i == adultSizes.length - 1
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(9))
                          : BorderRadius.zero,
                ),
                child: Row(
                  children: row.map((cell) {
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Text(
                          cell,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isHeader
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isHeader
                                ? Colors.white
                                : const Color(0xFF333333),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
