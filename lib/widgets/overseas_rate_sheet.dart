import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../screens/chat/chat_screen.dart';

/// 해외 배송비 EMS 요금표 바텀시트
/// checkout_screen, chat_screen 양쪽에서 공용으로 사용
void showOverseasRateSheet(BuildContext context) {
  final loc = context.loc;

  // EMS 비서류 기준 주요 국가 요금 (2025)
  final countries = [
    {'flag': '🇯🇵', 'name': loc.t('일본', '일본'),           'kg1': '25,500', 'kg2': '33,000', 'kg5': '43,000',  'kg10': '60,000'},
    {'flag': '🇨🇳', 'name': loc.t('중국', '중국'),           'kg1': '25,500', 'kg2': '32,000', 'kg5': '45,000',  'kg10': '72,000'},
    {'flag': '🇻🇳', 'name': loc.t('베트남', '베트남'),        'kg1': '20,500', 'kg2': '26,000', 'kg5': '40,000',  'kg10': '62,000'},
    {'flag': '🇲🇾', 'name': loc.t('말레이시아', '말레이시아'), 'kg1': '20,500', 'kg2': '26,000', 'kg5': '40,000',  'kg10': '62,000'},
    {'flag': '🇸🇬', 'name': loc.t('싱가포르', '싱가포르'),    'kg1': '20,500', 'kg2': '26,000', 'kg5': '40,000',  'kg10': '62,000'},
    {'flag': '🇹🇭', 'name': loc.t('태국', '태국'),           'kg1': '20,500', 'kg2': '26,000', 'kg5': '40,000',  'kg10': '62,000'},
    {'flag': '🇦🇺', 'name': loc.t('호주', '호주'),           'kg1': '29,000', 'kg2': '40,500', 'kg5': '70,000',  'kg10': '118,000'},
    {'flag': '🇺🇸', 'name': loc.t('미국', '미국'),           'kg1': '33,500', 'kg2': '51,000', 'kg5': '88,000',  'kg10': '156,000'},
    {'flag': '🇨🇦', 'name': loc.t('캐나다', '캐나다'),        'kg1': '33,000', 'kg2': '43,000', 'kg5': '64,500',  'kg10': '105,500'},
    {'flag': '🇩🇪', 'name': loc.t('독일_유럽', '독일/유럽'),  'kg1': '34,500', 'kg2': '45,000', 'kg5': '72,000',  'kg10': '120,000'},
    {'flag': '🇬🇧', 'name': loc.t('영국', '영국'),           'kg1': '34,500', 'kg2': '45,000', 'kg5': '72,000',  'kg10': '120,000'},
    {'flag': '🇫🇷', 'name': loc.t('프랑스', '프랑스'),        'kg1': '34,500', 'kg2': '45,000', 'kg5': '72,000',  'kg10': '120,000'},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── 핸들 ──
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── 헤더 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text('🌏', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('해외_배송비_요금표', '해외 배송비 요금표'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          loc.t('ems_기준_비서류_2025', 'EMS(우체국 국제특급) 비서류 기준 · 2025년'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            // ── 채팅상담 안내 배너 ──
            GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop(); // 바텀시트 닫기
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_rounded, size: 18, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('배송비_채팅상담_안내', '정확한 배송비는 채팅상담으로 확인하세요'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.t('배송비_채팅상담_부연', '부피·무게·국가에 따라 실제 요금이 달라질 수 있습니다.'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF388E3C),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        loc.t('채팅상담', '채팅상담'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── 의류 무게 참고 배너 ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Text('👕', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.t(
                        '운동복_무게_참고',
                        '운동복 1세트 약 300~500g · 3세트 ≈ 1~1.5kg · 10세트 ≈ 3~5kg',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6A1B9A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // ── 테이블 헤더 ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      loc.t('국가', '국가'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  _th('1kg'),
                  _th('2kg'),
                  _th('5kg'),
                  _th('10kg'),
                ],
              ),
            ),
            // ── 테이블 바디 ──
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: countries.length,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                itemBuilder: (_, i) {
                  final c = countries[i];
                  final isEven = i % 2 == 0;
                  final won = loc.t('원', '원');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isEven ? const Color(0xFFF8F9FA) : Colors.white,
                      border: const Border(
                        left: BorderSide(color: Color(0xFFE0E0E0)),
                        right: BorderSide(color: Color(0xFFE0E0E0)),
                        bottom: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Text(c['flag']!, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  c['name']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _td('${c['kg1']}$won'),
                        _td('${c['kg2']}$won'),
                        _td('${c['kg5']}$won'),
                        _td('${c['kg10']}$won'),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ── 하단: 부피중량 안내 + 채팅상담 버튼 ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('부피중량_안내_제목', '⚠️ 부피중량 계산'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.t(
                      '부피중량_계산식',
                      '가로(cm) × 세로(cm) × 높이(cm) ÷ 6,000\n실무게와 부피중량 중 더 큰 값으로 요금 적용',
                    ),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF777777), height: 1.5),
                  ),
                ],
              ),
            ),
            // ── 채팅상담 하단 CTA 버튼 ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(
                    loc.t('채팅상담으로_배송비_문의하기', '채팅상담으로 배송비 문의하기'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _th(String text) => Expanded(
      flex: 2,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );

Widget _td(String text) => Expanded(
      flex: 2,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: Color(0xFF444444)),
      ),
    );
