import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_localizations.dart';
import '../../providers/providers.dart';
import '../../widgets/pc_layout.dart';
import 'group_order_guide_screen.dart';

/// 사이드바 "단체주문하기" 전용 랜딩 페이지
/// - 단체주문 안내 + 주문서 작성 바로가기
class GroupOrderLandingScreen extends StatefulWidget {
  const GroupOrderLandingScreen({super.key});

  @override
  State<GroupOrderLandingScreen> createState() => _GroupOrderLandingScreenState();
}

class _GroupOrderLandingScreenState extends State<GroupOrderLandingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  AppLocalizations get loc => context.watch<LanguageProvider>().loc;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isPcWeb(context)) return _buildPcLayout();
    return _buildMobileLayout();
  }

  // ══════════════════════════════════════════════════════════
  // 모바일 레이아웃
  // ══════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('단체주문하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFFF6B35),
          labelColor: const Color(0xFFFF6B35),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: '단체주문 안내'),
            Tab(text: '주문서 바로가기'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildGuideTab(),
          _buildOrderFormTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PC 레이아웃
  // ══════════════════════════════════════════════════════════
  Widget _buildPcLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('단체주문하기',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측: 안내
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: _buildGuideTab(),
                  ),
                ),
                const SizedBox(width: 20),
                // 우측: 주문서 바로가기
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: _buildOrderFormTab(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 단체주문 안내 탭
  // ══════════════════════════════════════════════════════════
  Widget _buildGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('GROUP ORDER',
                      style: TextStyle(color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 10),
                const Text('단체주문 안내',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('10인 이상 단체 맞춤 제작 전문\n최고의 품질로 특별한 유니폼을 만들어드립니다.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 주문 절차
          _buildSectionTitle('📋 주문 절차', const Color(0xFF1A1A1A)),
          const SizedBox(height: 12),
          _buildStepCard('1', '상품 선택', '원하는 상품을 선택하고 단체주문서를 작성합니다.', const Color(0xFFFF6B35)),
          _buildStepCard('2', '디자인 협의', '컬러, 로고, 마킹 등 맞춤 디자인을 협의합니다.', const Color(0xFF1565C0)),
          _buildStepCard('3', '견적 확인', '수량별 최종 견적을 확인하고 주문을 확정합니다.', const Color(0xFF2E7D32)),
          _buildStepCard('4', '제작 & 배송', '제작 후 일괄 배송 또는 분배 배송을 선택합니다.', const Color(0xFF6A1B9A)),
          const SizedBox(height: 20),

          // 핵심 정보
          _buildSectionTitle('✅ 주문 조건', const Color(0xFF1A1A1A)),
          const SizedBox(height: 12),
          _buildInfoCard([
            {'icon': Icons.group_rounded, 'title': '최소 주문 수량', 'desc': '10벌 이상'},
            {'icon': Icons.local_shipping_rounded, 'title': '배송', 'desc': '무료 배송 (단체주문 전용)'},
            {'icon': Icons.schedule_rounded, 'title': '제작 기간', 'desc': '주문 확정 후 14~21일'},
            {'icon': Icons.discount_rounded, 'title': '단체 할인', 'desc': '30인 이상 5% / 50인 이상 10%'},
          ]),
          const SizedBox(height: 20),

          // 주의사항
          _buildSectionTitle('⚠️ 주의사항', const Color(0xFFE53935)),
          const SizedBox(height: 12),
          _buildNoticeBox([
            '주문 확정 후 디자인 변경 시 추가 비용이 발생할 수 있습니다.',
            '색상은 모니터 환경에 따라 실제와 다소 차이가 있을 수 있습니다.',
            '단체주문 상품은 교환/환불이 불가합니다.',
            '사이즈 측정은 주문서 작성 전 반드시 확인해주세요.',
          ]),
          const SizedBox(height: 20),

          // 문의
          _buildSectionTitle('📞 문의', const Color(0xFF1A1A1A)),
          const SizedBox(height: 12),
          _buildContactCard(),
          const SizedBox(height: 20),

          // CTA 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_tabCtrl.index != 1) {
                  _tabCtrl.animateTo(1);
                } else {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const GroupOrderGuideScreen(),
                  ));
                }
              },
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: const Text('단체주문서 바로 작성하기',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 주문서 바로가기 탭
  // ══════════════════════════════════════════════════════════
  Widget _buildOrderFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('📝 단체주문서 작성', const Color(0xFF1A1A1A)),
          const SizedBox(height: 12),
          const Text('상품을 선택하지 않고 바로 단체주문서를 작성할 수 있습니다.\n아래 카테고리에서 원하는 상품 유형을 선택해주세요.',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.6)),
          const SizedBox(height: 20),

          // 상품 유형별 주문서 선택
          _buildOrderTypeCard(
            icon: Icons.sports_rounded,
            title: '싱글렛 A타입 세트',
            subtitle: '싱글렛 + 타이즈 세트 / 육상·인라인·마라톤',
            color: const Color(0xFF1565C0),
            category: '싱글렛세트A타입',
          ),
          const SizedBox(height: 10),
          _buildOrderTypeCard(
            icon: Icons.fitness_center_rounded,
            title: '싱글렛 B타입',
            subtitle: '싱글렛 단품 / 헬스·크로스핏·복싱',
            color: const Color(0xFF6A1B9A),
            category: '싱글렛 B타입',
          ),
          const SizedBox(height: 10),
          _buildOrderTypeCard(
            icon: Icons.directions_run_rounded,
            title: '스킨슈트',
            subtitle: '원피스 전신 경기복 / 사이클·트라이애슬론',
            color: const Color(0xFF2E7D32),
            category: '스킨슈트',
          ),
          const SizedBox(height: 10),
          _buildOrderTypeCard(
            icon: Icons.dry_cleaning_rounded,
            title: '트레이닝복 세트',
            subtitle: '상의 + 하의 트레이닝 세트 / 팀복·동호회복',
            color: const Color(0xFFE65100),
            category: '트레이닝복세트',
          ),
          const SizedBox(height: 10),
          _buildOrderTypeCard(
            icon: Icons.list_alt_rounded,
            title: '기타 / 직접 작성',
            subtitle: '위에 없는 상품이나 복합 주문',
            color: const Color(0xFF546E7A),
            category: '기타',
          ),
          const SizedBox(height: 24),

          // 안내
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFFE65100)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '상품 상세 페이지에서 단체주문서 작성 시 상품 정보가 자동으로 입력됩니다.\n'
                    '더 빠른 주문을 원하시면 상품을 먼저 선택해주세요.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6D4C41), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 공통 위젯들
  // ══════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title, Color color) {
    return Text(title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color));
  }

  Widget _buildStepCard(String step, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(step,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: const Color(0xFF1A1A1A)),
                    const SizedBox(width: 12),
                    Text(item['title'] as String,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A))),
                    const Spacer(),
                    Text(item['desc'] as String,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF444444))),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, color: Color(0xFFE8E8E8)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoticeBox(List<String> notices) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notices.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w800)),
              Expanded(child: Text(n, style: const TextStyle(fontSize: 11, color: Color(0xFF444444), height: 1.5))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.chat_rounded, size: 16, color: Color(0xFFFF6B35)),
              SizedBox(width: 8),
              Text('카카오톡 채널: @2FIT KOREA',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email_rounded, size: 16, color: Color(0xFFFF6B35)),
              SizedBox(width: 8),
              Text('이메일: admin@2fit.co.kr',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: Color(0xFFFF6B35)),
              SizedBox(width: 8),
              Text('운영시간: 평일 09:00 ~ 18:00',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String category,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const GroupOrderGuideScreen(),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
