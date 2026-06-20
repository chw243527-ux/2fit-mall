// group_order_test_screen.dart
// 단체주문 테스트용 화면 — 더미 데이터 자동 입력 후 Firestore 저장 테스트
// 관리자 전용 (isAdmin == true 인 경우만 접근)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';

// ── 테스트 프리셋 정의 ──────────────────────────────────────────
class _TestPreset {
  final String label;
  final String icon;
  final Color color;
  final String teamName;
  final int count;
  final int printType; // 0~4
  final String mainColor;
  final String paymentMethod;
  final String fabric;
  final String? maleLength;
  final String? femaleLength;
  final String memo;

  const _TestPreset({
    required this.label,
    required this.icon,
    required this.color,
    required this.teamName,
    required this.count,
    required this.printType,
    required this.mainColor,
    required this.paymentMethod,
    this.fabric = '일반 봉제',
    this.maleLength,
    this.femaleLength,
    this.memo = '',
  });
}

final List<_TestPreset> _kPresets = [
  const _TestPreset(
    label: '소규모 팀 (5인)',
    icon: '👕',
    color: Color(0xFF1565C0),
    teamName: '테스트팀A',
    count: 5,
    printType: 0,
    mainColor: '블랙',
    paymentMethod: '계좌이체',
    memo: '테스트 주문 — 소규모 5인 색상변경만',
  ),
  const _TestPreset(
    label: '중규모 팀 (10인)',
    icon: '🏃',
    color: Color(0xFF2E7D32),
    teamName: '달리기클럽B',
    count: 10,
    printType: 1,
    mainColor: '네이비',
    paymentMethod: '카드',
    memo: '테스트 주문 — 10인 단체명+색상',
  ),
  const _TestPreset(
    label: '대규모 팀 (20인)',
    icon: '⚽',
    color: Color(0xFF6A1B9A),
    teamName: 'FC서울드림C',
    count: 20,
    printType: 2,
    mainColor: '레드',
    paymentMethod: '계좌이체',
    memo: '테스트 주문 — 20인 디자인+단체명+색상',
  ),
  const _TestPreset(
    label: '풀 옵션 (15인)',
    icon: '🎽',
    color: Color(0xFFE53935),
    teamName: '종합스포츠D',
    count: 15,
    printType: 3,
    mainColor: '화이트',
    paymentMethod: '카드',
    fabric: '심리스',
    memo: '테스트 주문 — 풀옵션 심리스 15인',
  ),
  const _TestPreset(
    label: '하의 단체주문 (8인)',
    icon: '🩳',
    color: Color(0xFFF57F17),
    teamName: '배드민턴팀E',
    count: 8,
    printType: 0,
    mainColor: '그레이',
    paymentMethod: '계좌이체',
    maleLength: '7부',
    femaleLength: '숏쇼츠',
    memo: '테스트 주문 — 하의 8인',
  ),
];

// ── 화면 ──────────────────────────────────────────────────────
class GroupOrderTestScreen extends StatefulWidget {
  const GroupOrderTestScreen({super.key});

  @override
  State<GroupOrderTestScreen> createState() => _GroupOrderTestScreenState();
}

class _GroupOrderTestScreenState extends State<GroupOrderTestScreen> {
  bool _isLoading = false;
  String _log = '';
  final List<String> _results = [];

  // 커스텀 입력 컨트롤러
  final _teamNameCtrl  = TextEditingController(text: '커스텀팀F');
  final _managerCtrl   = TextEditingController(text: '홍길동');
  final _phoneCtrl     = TextEditingController(text: '01012345678');
  final _emailCtrl     = TextEditingController(text: 'test@2fit.co.kr');
  int   _customCount   = 7;
  int   _customPrint   = 1;
  String _customColor  = '블랙';
  String _customFabric = '일반 봉제';
  String _customPay    = '계좌이체';
  double _customPrice  = 85000;
  bool   _sendKakao    = false; // 알림톡 발송 여부 (테스트이므로 기본 off)

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _managerCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── 더미 persons 생성 ──
  List<Map<String, dynamic>> _makeDummyPersons(int count, {
    String? maleLength,
    String? femaleLength,
  }) {
    const topSizes    = ['S', 'M', 'M', 'L', 'L', 'L', 'XL', 'XL', '2XL', 'M'];
    const bottomSizes = ['S', 'M', 'M', 'L', 'L', 'XL', 'XL', '2XL', 'M', 'L'];
    final genders     = ['male', 'female', 'male', 'female', 'male',
                         'male', 'female', 'male', 'female', 'male'];
    return List.generate(count, (i) {
      final g = genders[i % genders.length];
      return {
        'index'     : i,
        'name'      : count >= 10 ? '테스터${i + 1}' : '',
        'gender'    : g,
        'sizeType'  : '성인',
        'topSize'   : topSizes[i % topSizes.length],
        'bottomSize': bottomSizes[i % bottomSizes.length],
        'length'    : g == 'female' ? (femaleLength ?? '숏') : (maleLength ?? '풀'),
        'height'    : '',
        'weight'    : '',
        'waist'     : '',
        'thigh'     : '',
        'hasCustomMeasure': false,
      };
    });
  }

  // ── 프리셋으로 주문 생성 ──
  Future<void> _submitPreset(_TestPreset preset) async {
    await _submit(
      teamName    : preset.teamName,
      manager     : '테스트담당자',
      phone       : '01099998888',
      email       : 'test@2fit.co.kr',
      count       : preset.count,
      printType   : preset.printType,
      mainColor   : preset.mainColor,
      fabric      : preset.fabric,
      paymentMethod: preset.paymentMethod,
      maleLength  : preset.maleLength,
      femaleLength: preset.femaleLength,
      unitPrice   : 85000,
      memo        : preset.memo,
    );
  }

  // ── 핵심 주문 생성 로직 ──
  Future<void> _submit({
    required String teamName,
    required String manager,
    required String phone,
    required String email,
    required int count,
    required int printType,
    required String mainColor,
    required String fabric,
    required String paymentMethod,
    String? maleLength,
    String? femaleLength,
    required double unitPrice,
    String memo = '',
  }) async {
    final user = context.read<UserProvider>().user;
    setState(() {
      _isLoading = true;
      _log = '[$teamName] 주문 생성 중...';
    });

    try {
      final orderId = 'TEST_GRP_${DateTime.now().millisecondsSinceEpoch}';
      final now     = DateTime.now();
      final persons = _makeDummyPersons(count,
          maleLength: maleLength, femaleLength: femaleLength);
      final total   = unitPrice * count;

      final customOptions = <String, dynamic>{
        'orderType'        : 'group',
        'isTest'           : true, // ← 테스트 플래그
        'printType'        : printType,
        'mainColor'        : mainColor,
        'adjustedColorHex' : '#1A1A1A',
        'colorLightness'   : 0.3,
        'colorTone'        : '어두운',
        'fabric'           : fabric,
        'weight'           : '80g',
        'pocket'           : false,
        'maleLength'       : maleLength ?? '풀',
        'femaleLength'     : femaleLength ?? '숏',
        'waistbandOption'  : '기본 (변경없음)',
        'waistbandOptions' : [],
        'waistbandExtra'   : 0,
        'waistbandColorHex': '',
        'waistbandRefImages': [],
        'waistbandLogoFileName': '',
        'waistbandLogoBase64'  : '',
        'exclusive'        : false,
        'teamName'         : teamName,
        'manager'          : manager,
        'phone'            : phone,
        'email'            : email,
        'address'          : '서울시 강남구 테스트로 123',
        'addressDetail'    : '테스트빌딩 4층',
        'maleRef'          : false,
        'femaleRef'        : false,
        'designLogoFileName': '',
        'designLogoBase64'  : '',
        'memo'             : memo,
        'persons'          : persons,
        'designFileUrl'    : '',
        'productImageUrl'  : '',
      };

      final items = [
        OrderItem(
          productId  : 'test_group_product',
          productName: '단체주문 테스트 상품',
          imageUrl   : '',
          size       : '단체',
          color      : mainColor,
          quantity   : count,
          price      : unitPrice,
        ),
      ].cast<OrderItem>();

      final order = OrderModel(
        id           : orderId,
        userId       : user?.id ?? 'test_admin',
        userName     : manager.isNotEmpty ? manager : teamName,
        userPhone    : phone,
        userEmail    : email,
        userAddress  : '서울시 강남구 테스트로 123 테스트빌딩 4층',
        items        : items,
        totalAmount  : total,
        shippingFee  : count >= 10 ? 0 : 3000,
        paymentMethod: paymentMethod,
        status       : OrderStatus.pending,
        orderType    : 'group',
        groupName    : teamName,
        groupCount   : count,
        customOptions: customOptions,
        createdAt    : now,
      );

      // Firestore 저장
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(order.toJson());

      // 결과 로그
      final resultMsg =
          '✅ [$teamName] $count인 | ${_fmt(total)}원 | $paymentMethod\n'
          '   주문번호: $orderId';

      setState(() {
        _results.insert(0, resultMsg);
        _log = resultMsg;
        _isLoading = false;
      });

      if (kDebugMode) debugPrint('✅ 테스트 단체주문 저장 완료: $orderId');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('[$teamName] 테스트 주문 생성 완료!'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _log = '❌ 오류: $e';
        _results.insert(0, '❌ [$teamName] 실패: $e');
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류 발생: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  // ── 전체 프리셋 일괄 실행 ──
  Future<void> _submitAll() async {
    for (final preset in _kPresets) {
      await _submitPreset(preset);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // ── 테스트 주문 전체 삭제 ──
  Future<void> _deleteAllTestOrders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 20),
          SizedBox(width: 8),
          Text('테스트 주문 삭제', style: TextStyle(fontSize: 15)),
        ]),
        content: const Text(
            'TEST_GRP_ 로 시작하는 테스트 주문을\n모두 삭제합니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _log = '테스트 주문 삭제 중...';
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'TEST_GRP_')
          .where(FieldPath.documentId, isLessThan: 'TEST_GRP_z')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      setState(() {
        _isLoading = false;
        _results.clear();
        _log = '✅ 테스트 주문 ${snap.docs.length}건 삭제 완료';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('테스트 주문 ${snap.docs.length}건 삭제 완료'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _log = '❌ 삭제 오류: $e';
      });
    }
  }

  String _fmt(double v) => v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ── UI ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Row(children: [
          Icon(Icons.science_rounded, size: 18),
          SizedBox(width: 8),
          Text('단체주문 테스트', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          // 삭제 버튼
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFFF7043)),
            tooltip: '테스트 주문 전체 삭제',
            onPressed: _isLoading ? null : _deleteAllTestOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Color(0xFF1A1A2E)),
                SizedBox(height: 12),
                Text('처리 중...', style: TextStyle(color: Color(0xFF666666))),
              ]),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── 안내 배너 ──
                _infoBanner(),
                const SizedBox(height: 12),

                // ── 빠른 프리셋 ──
                _sectionTitle('빠른 테스트 프리셋', Icons.flash_on_rounded),
                const SizedBox(height: 8),
                ...List.generate(_kPresets.length, (i) =>
                    _presetCard(_kPresets[i])),
                const SizedBox(height: 8),
                _allAtOnceButton(),
                const SizedBox(height: 20),

                // ── 커스텀 주문 ──
                _sectionTitle('커스텀 테스트 주문', Icons.tune_rounded),
                const SizedBox(height: 8),
                _customOrderPanel(),
                const SizedBox(height: 20),

                // ── 결과 로그 ──
                if (_results.isNotEmpty) ...[
                  _sectionTitle('결과 로그 (최신순)', Icons.list_alt_rounded),
                  const SizedBox(height: 8),
                  _logPanel(),
                ],
              ]),
            ),
    );
  }

  // ── 안내 배너 ──
  Widget _infoBanner() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFFCC02), width: 1.2),
    ),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 18),
      SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('테스트 전용 화면',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFFF57F17))),
          SizedBox(height: 4),
          Text(
            '• 생성된 주문은 Firestore orders 컬렉션에 실제로 저장됩니다.\n'
            '• 주문번호는 TEST_GRP_ 로 시작하므로 구분이 쉽습니다.\n'
            '• 주문 확인 후 반드시 [테스트 주문 전체 삭제] 버튼으로 정리하세요.\n'
            '• 알림톡/SMS 발송은 기본 OFF 상태입니다.',
            style: TextStyle(fontSize: 11, color: Color(0xFF795548), height: 1.6),
          ),
        ]),
      ),
    ]),
  );

  // ── 섹션 타이틀 ──
  Widget _sectionTitle(String title, IconData icon) => Row(children: [
    Icon(icon, size: 16, color: const Color(0xFF1A1A2E)),
    const SizedBox(width: 6),
    Text(title,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
  ]);

  // ── 프리셋 카드 ──
  Widget _presetCard(_TestPreset preset) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: () => _submitPreset(preset),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(children: [
          // 아이콘 배지
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: preset.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(preset.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          // 정보
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(preset.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 3),
              Row(children: [
                _chip2('${preset.count}인', const Color(0xFF1565C0)),
                const SizedBox(width: 4),
                _chip2('옵션${preset.printType}', const Color(0xFF6A1B9A)),
                const SizedBox(width: 4),
                _chip2(preset.mainColor, const Color(0xFF37474F)),
                const SizedBox(width: 4),
                _chip2(preset.paymentMethod, const Color(0xFF2E7D32)),
              ]),
            ]),
          ),
          // 실행 버튼
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: preset.color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('실행',
                style: TextStyle(
                    fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    ),
  );

  // ── 전체 실행 버튼 ──
  Widget _allAtOnceButton() => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: _submitAll,
      icon: const Icon(Icons.rocket_launch_rounded, size: 16),
      label: Text('전체 프리셋 일괄 실행 (${_kPresets.length}건)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1A1A2E),
        side: const BorderSide(color: Color(0xFF1A1A2E), width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  // ── 커스텀 주문 패널 ──
  Widget _customOrderPanel() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEEEEEE)),
      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 팀명 / 담당자
      Row(children: [
        Expanded(child: _field('팀명', _teamNameCtrl)),
        const SizedBox(width: 8),
        Expanded(child: _field('담당자', _managerCtrl)),
      ]),
      const SizedBox(height: 8),
      // 연락처 / 이메일
      Row(children: [
        Expanded(child: _field('연락처', _phoneCtrl, keyboard: TextInputType.phone)),
        const SizedBox(width: 8),
        Expanded(child: _field('이메일', _emailCtrl, keyboard: TextInputType.emailAddress)),
      ]),
      const SizedBox(height: 12),
      // 인원수 / 단가
      Row(children: [
        Expanded(child: _numTile('인원수', _customCount, min: 5, max: 100,
            onChanged: (v) => setState(() => _customCount = v))),
        const SizedBox(width: 8),
        Expanded(child: _numTile('단가 (원)', _customPrice.toInt(), min: 10000, max: 500000, step: 5000,
            onChanged: (v) => setState(() => _customPrice = v.toDouble()))),
      ]),
      const SizedBox(height: 12),
      // 인쇄 타입
      _labelRow('인쇄 타입'),
      const SizedBox(height: 6),
      _printTypeSelector(),
      const SizedBox(height: 12),
      // 색상 / 원단 / 결제수단
      Row(children: [
        Expanded(child: _dropdownTile('색상', _customColor,
            ['블랙', '화이트', '네이비', '그레이', '레드', '블루', '그린'],
            (v) => setState(() => _customColor = v!))),
        const SizedBox(width: 8),
        Expanded(child: _dropdownTile('결제수단', _customPay,
            ['계좌이체', '카드', '기타'],
            (v) => setState(() => _customPay = v!))),
      ]),
      const SizedBox(height: 8),
      _dropdownTile('원단', _customFabric,
          ['일반 봉제', '심리스', '나일론', '폴리에스터'],
          (v) => setState(() => _customFabric = v!)),
      const SizedBox(height: 16),
      // 합계 표시
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('예상 합계',
              style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
          Text('${_fmt(_customPrice * _customCount)}원',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: Color(0xFFE53935))),
        ]),
      ),
      const SizedBox(height: 12),
      // 실행
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _submit(
            teamName    : _teamNameCtrl.text.trim().isEmpty
                ? '커스텀팀' : _teamNameCtrl.text.trim(),
            manager     : _managerCtrl.text.trim(),
            phone       : _phoneCtrl.text.trim(),
            email       : _emailCtrl.text.trim(),
            count       : _customCount,
            printType   : _customPrint,
            mainColor   : _customColor,
            fabric      : _customFabric,
            paymentMethod: _customPay,
            unitPrice   : _customPrice,
            memo        : '커스텀 테스트 주문',
          ),
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('커스텀 주문 생성',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ]),
  );

  // ── 인쇄타입 선택기 ──
  Widget _printTypeSelector() {
    const options = [
      (0, '색상변경만'),
      (1, '단체명+색상'),
      (2, '디자인+단체명+색상'),
      (3, '풀옵션(후면이름)'),
    ];
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: options.map((o) {
        final selected = _customPrint == o.$1;
        return GestureDetector(
          onTap: () => setState(() => _customPrint = o.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD),
              ),
            ),
            child: Text('${o.$1} ${o.$2}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? Colors.white : const Color(0xFF555555),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 로그 패널 ──
  Widget _logPanel() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 헤더
      Row(children: [
        const Icon(Icons.terminal_rounded, color: Colors.white54, size: 14),
        const SizedBox(width: 6),
        const Text('실행 로그',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _results.clear()),
          child: const Text('지우기',
              style: TextStyle(color: Color(0xFF90CAF9), fontSize: 11)),
        ),
      ]),
      const SizedBox(height: 8),
      ...List.generate(_results.length, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(_results[i],
            style: TextStyle(
              fontSize: 11,
              color: _results[i].startsWith('✅') ? const Color(0xFF80CBC4)
                  : _results[i].startsWith('❌') ? const Color(0xFFEF9A9A)
                  : Colors.white70,
              fontFamily: 'monospace',
            )),
      )),
    ]),
  );

  // ── 헬퍼 위젯 ──
  Widget _field(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
      );

  Widget _numTile(String label, int value,
      {required int min, required int max, int step = 1,
       required void Function(int) onChanged}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _labelRow(label),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDDDDD)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            _iconBtn(Icons.remove, () {
              if (value - step >= min) onChanged(value - step);
            }),
            Expanded(
              child: Text('$value',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
            ),
            _iconBtn(Icons.add, () {
              if (value + step <= max) onChanged(value + step);
            }),
          ]),
        ),
      ]);

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 16, color: const Color(0xFF1A1A2E)),
    ),
  );

  Widget _dropdownTile(String label, String value, List<String> items,
      void Function(String?) onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _labelRow(label),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
        ),
      ]);

  Widget _labelRow(String label) => Text(label,
      style: const TextStyle(fontSize: 11, color: Color(0xFF888888)));

  Widget _chip2(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );
}
