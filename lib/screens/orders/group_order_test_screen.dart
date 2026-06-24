// group_order_test_screen.dart
// 단체주문 + 기성품 주문 테스트용 화면 — 실제 유저 ID로 Firestore 저장
// 관리자 전용

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/product_service.dart';
import '../../utils/app_localizations.dart';

// ══════════════════════════════════════════════════════════════
// 테스트 프리셋
// ══════════════════════════════════════════════════════════════
class _TestPreset {
  final String label;
  final String icon;
  final Color color;
  final String orderType;   // 'personal' | 'group'
  final OrderStatus status;
  final String teamName;
  final int count;
  final int printType;
  final String mainColor;
  final String paymentMethod;
  final String fabric;
  final String? maleLength;
  final String? femaleLength;
  final double unitPrice;

  const _TestPreset({
    required this.label,
    required this.icon,
    required this.color,
    required this.orderType,
    this.status = OrderStatus.pending,
    required this.teamName,
    required this.count,
    this.printType = 0,
    required this.mainColor,
    required this.paymentMethod,
    this.fabric = '일반 봉제',
    this.maleLength,
    this.femaleLength,
    this.unitPrice = 85000,
  });
}

final List<_TestPreset> _kPresets = [
  // ── 기성품 ────────────────────────────────────────────
  const _TestPreset(
    label: '기성품 — 주문대기',
    icon: '👕',
    color: Color(0xFFE65100),
    orderType: 'personal',
    status: OrderStatus.pending,
    teamName: '기성품테스트',
    count: 1,
    mainColor: '블랙',
    paymentMethod: '카드',
    unitPrice: 49000,
  ),
  const _TestPreset(
    label: '기성품 — 배송중',
    icon: '🚚',
    color: Color(0xFF00838F),
    orderType: 'personal',
    status: OrderStatus.shipped,
    teamName: '기성품테스트',
    count: 2,
    mainColor: '네이비',
    paymentMethod: '카드',
    unitPrice: 49000,
  ),
  const _TestPreset(
    label: '기성품 — 배송완료',
    icon: '📦',
    color: Color(0xFF2E7D32),
    orderType: 'personal',
    status: OrderStatus.delivered,
    teamName: '기성품테스트',
    count: 1,
    mainColor: '화이트',
    paymentMethod: '계좌이체',
    unitPrice: 55000,
  ),
  // ── 단체주문 ──────────────────────────────────────────
  const _TestPreset(
    label: '단체주문 — 5인 (주문대기)',
    icon: '🏃',
    color: Color(0xFF1565C0),
    orderType: 'group',
    status: OrderStatus.pending,
    teamName: '테스트팀A',
    count: 5,
    printType: 0,
    mainColor: '블랙',
    paymentMethod: '계좌이체',
    unitPrice: 85000,
  ),
  const _TestPreset(
    label: '단체주문 — 10인 (제작중)',
    icon: '⚽',
    color: Color(0xFF6A1B9A),
    orderType: 'group',
    status: OrderStatus.processing,
    teamName: 'FC서울드림B',
    count: 10,
    printType: 1,
    mainColor: '레드',
    paymentMethod: '계좌이체',
    unitPrice: 85000,
  ),
  const _TestPreset(
    label: '단체주문 — 20인 (배송완료)',
    icon: '🎽',
    color: Color(0xFF2E7D32),
    orderType: 'group',
    status: OrderStatus.delivered,
    teamName: '종합스포츠C',
    count: 20,
    printType: 2,
    mainColor: '네이비',
    paymentMethod: '카드',
    unitPrice: 85000,
  ),
];

// ══════════════════════════════════════════════════════════════
// 화면
// ══════════════════════════════════════════════════════════════
class GroupOrderTestScreen extends StatefulWidget {
  const GroupOrderTestScreen({super.key});

  @override
  State<GroupOrderTestScreen> createState() => _GroupOrderTestScreenState();
}

class _GroupOrderTestScreenState extends State<GroupOrderTestScreen> {
  bool _isLoading = false;
  final List<String> _results = [];

  // ── 커스텀 입력 ──
  final _teamNameCtrl = TextEditingController(text: '커스텀팀');
  final _managerCtrl  = TextEditingController(text: '홍길동');
  final _phoneCtrl    = TextEditingController(text: '01012345678');
  final _emailCtrl    = TextEditingController(text: 'test@2fit.co.kr');
  int    _customCount   = 5;
  int    _customPrint   = 0;
  String _customColor   = '블랙';
  String _customFabric  = '일반 봉제';
  String _customPay     = '계좌이체';
  double _customPrice   = 85000;
  String _customOrderType = 'group';
  OrderStatus _customStatus = OrderStatus.pending;

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
    const top    = ['S', 'M', 'M', 'L', 'L', 'L', 'XL', 'XL', '2XL', 'M'];
    const bottom = ['S', 'M', 'M', 'L', 'L', 'XL', 'XL', '2XL', 'M', 'L'];
    const gender = ['male', 'female', 'male', 'female', 'male',
                    'male', 'female', 'male', 'female', 'male'];
    return List.generate(count, (i) {
      final g = gender[i % gender.length];
      return {
        'index'     : i,
        'name'      : count >= 10 ? '테스터${i + 1}' : '',
        'gender'    : g,
        'sizeType'  : '성인',
        'topSize'   : top[i % top.length],
        'bottomSize': bottom[i % bottom.length],
        'length'    : g == 'female' ? (femaleLength ?? '숏') : (maleLength ?? '풀'),
        'height': '', 'weight': '', 'waist': '', 'thigh': '',
        'hasCustomMeasure': false,
      };
    });
  }

  // ── 실제 상품 하나 가져오기 (이미지 있는 첫 번째) ──
  ProductModel? _pickProduct(String orderType) {
    final products = ProductService.getAllProductsSync();
    if (products.isEmpty) return null;
    if (orderType == 'personal') {
      return products.firstWhere(
        (p) => p.images.isNotEmpty && p.category != '단체주문' && p.isActive,
        orElse: () => products.first,
      );
    } else {
      return products.firstWhere(
        (p) => p.images.isNotEmpty && p.isActive,
        orElse: () => products.first,
      );
    }
  }

  // ── 핵심 주문 생성 ──
  Future<void> _submit({
    required String orderType,
    required OrderStatus status,
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
  }) async {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      _toast('로그인이 필요합니다', error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now     = DateTime.now();
      // 기성품은 PERS_, 단체주문은 TEST_GRP_
      final prefix  = orderType == 'personal' ? 'TEST_PERS_' : 'TEST_GRP_';
      final orderId = '${prefix}${now.millisecondsSinceEpoch}';
      final total   = unitPrice * count;

      // 실제 상품 데이터 사용
      final product = _pickProduct(orderType);
      final imageUrl = product?.images.isNotEmpty == true ? product!.images.first : '';
      final productName = orderType == 'personal'
          ? (product?.name ?? '테스트 상품')
          : '단체주문 테스트 상품';
      final productId = product?.id ?? 'test_product';

      final List<OrderItem> items;
      if (orderType == 'personal') {
        // 기성품: 1~2개 아이템
        items = [
          OrderItem(
            productId  : productId,
            productName: productName,
            imageUrl   : imageUrl,
            size       : 'M',
            color      : mainColor,
            quantity   : count,
            price      : unitPrice,
          ),
        ];
      } else {
        // 단체주문: 단체 아이템
        items = [
          OrderItem(
            productId  : productId,
            productName: productName,
            imageUrl   : imageUrl,
            size       : '단체',
            color      : mainColor,
            quantity   : count,
            price      : unitPrice,
            customOptions: {
              'productImageUrl': imageUrl,
            },
          ),
        ];
      }

      final persons = orderType == 'group'
          ? _makeDummyPersons(count, maleLength: maleLength, femaleLength: femaleLength)
          : <Map<String, dynamic>>[];

      final customOptions = orderType == 'group' ? <String, dynamic>{
        'orderType'        : 'group',
        'isTest'           : true,
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
        'memo'             : '테스트 주문',
        'persons'          : persons,
        'designFileUrl'    : imageUrl,
        'productImageUrl'  : imageUrl,
      } : null;

      final order = OrderModel(
        id           : orderId,
        userId       : user.id,         // ← 실제 로그인 유저 ID
        userName     : manager.isNotEmpty ? manager : user.name,
        userPhone    : phone.isNotEmpty ? phone : (user.phone ?? ''),
        userEmail    : email.isNotEmpty ? email : (user.email ?? ''),
        userAddress  : '서울시 강남구 테스트로 123 테스트빌딩 4층',
        items        : items,
        totalAmount  : total,
        shippingFee  : (orderType == 'personal' && count == 1) ? 3000 : 0,
        paymentMethod: paymentMethod,
        status       : status,
        orderType    : orderType,
        groupName    : orderType == 'group' ? teamName : null,
        groupCount   : orderType == 'group' ? count    : null,
        customOptions: customOptions,
        createdAt    : now,
      );

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(order.toJson());

      // OrderProvider에도 반영 (실시간 반영)
      if (mounted) {
        await context.read<OrderProvider>().loadUserOrders(user.id);
      }

      final msg = '✅ [${orderType == "personal" ? "기성품" : "단체"} $teamName] '
          '${count}개 | ${_fmt(total)}원 | ${status.label}\n'
          '   ID: $orderId';
      setState(() {
        _results.insert(0, msg);
        _isLoading = false;
      });

      if (kDebugMode) debugPrint('✅ 테스트 주문 저장: $orderId (userId: ${user.id})');
      _toast('[$teamName] 마이페이지에서 확인하세요!');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _results.insert(0, '❌ [$teamName] 실패: $e');
      });
      _toast('오류: $e', error: true);
    }
  }

  // ── 프리셋 실행 ──
  Future<void> _submitPreset(_TestPreset p) => _submit(
    orderType    : p.orderType,
    status       : p.status,
    teamName     : p.teamName,
    manager      : '테스트담당자',
    phone        : '01099998888',
    email        : 'test@2fit.co.kr',
    count        : p.count,
    printType    : p.printType,
    mainColor    : p.mainColor,
    fabric       : p.fabric,
    paymentMethod: p.paymentMethod,
    maleLength   : p.maleLength,
    femaleLength : p.femaleLength,
    unitPrice    : p.unitPrice,
  );

  // ── 전체 프리셋 일괄 실행 ──
  Future<void> _submitAll() async {
    for (final p in _kPresets) {
      await _submitPreset(p);
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  // ── 테스트 주문 전체 삭제 ──
  Future<void> _deleteAllTestOrders() async {
    final user = context.read<UserProvider>().user;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 20),
          SizedBox(width: 8),
          Text(context.loc.t('테스트_주문_삭제', '테스트 주문 삭제'), style: TextStyle(fontSize: 15)),
        ]),
        content: Text(context.loc.t('TEST_GRP____TES_604fd0', 'TEST_GRP_ / TEST_PERS_ 로 시작하는\n테스트 주문을 모두 삭제합니다.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.loc.t('취소', '취소'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
            child: Text(context.loc.t('삭제', '삭제')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      // TEST_GRP_ 삭제
      final snap1 = await FirebaseFirestore.instance.collection('orders')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'TEST_GRP_')
          .where(FieldPath.documentId, isLessThan: 'TEST_GRP_z')
          .get();
      // TEST_PERS_ 삭제
      final snap2 = await FirebaseFirestore.instance.collection('orders')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: 'TEST_PERS_')
          .where(FieldPath.documentId, isLessThan: 'TEST_PERS_z')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in [...snap1.docs, ...snap2.docs]) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // OrderProvider 갱신
      if (mounted && user != null) {
        await context.read<OrderProvider>().loadUserOrders(user.id);
      }

      final total = snap1.docs.length + snap2.docs.length;
      setState(() {
        _isLoading = false;
        _results.clear();
      });
      _toast('테스트 주문 ${total}건 삭제 완료');
    } catch (e) {
      setState(() => _isLoading = false);
      _toast('삭제 오류: $e', error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
      duration: const Duration(seconds: 3),
    ));
  }

  String _fmt(double v) => v.toInt().toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ══════════════════════════════════════════════════════════════
  // UI
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Row(children: [
          Icon(Icons.science_rounded, size: 18),
          SizedBox(width: 8),
          Text(context.loc.t('주문_테스트', '주문 테스트'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFFF7043)),
            tooltip: context.loc.t('테스트_주문_전체_삭제', '테스트 주문 전체 삭제'),
            onPressed: _isLoading ? null : _deleteAllTestOrders,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Color(0xFF1A1A2E)),
              SizedBox(height: 12),
              Text(context.loc.t('처리_중', '처리 중...'), style: TextStyle(color: Color(0xFF666666))),
            ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── 현재 유저 배지 ──
                _userBadge(user),
                const SizedBox(height: 12),

                // ── 안내 배너 ──
                _infoBanner(),
                const SizedBox(height: 14),

                // ── 프리셋 ──
                _sectionTitle('빠른 프리셋', Icons.flash_on_rounded),
                const SizedBox(height: 8),
                ..._kPresets.map((p) => _presetCard(p)),
                const SizedBox(height: 8),
                _allBtn(),
                const SizedBox(height: 20),

                // ── 커스텀 ──
                _sectionTitle('커스텀 주문 생성', Icons.tune_rounded),
                const SizedBox(height: 8),
                _customPanel(),
                const SizedBox(height: 20),

                // ── 로그 ──
                if (_results.isNotEmpty) ...[
                  _sectionTitle('결과 로그', Icons.list_alt_rounded),
                  const SizedBox(height: 8),
                  _logPanel(),
                ],
              ]),
            ),
    );
  }

  // ── 유저 배지 ──
  Widget _userBadge(UserModel? user) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: user != null ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: user != null ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC02)),
    ),
    child: Row(children: [
      Icon(user != null ? Icons.person_rounded : Icons.warning_amber_rounded,
          size: 16,
          color: user != null ? const Color(0xFF2E7D32) : const Color(0xFFF57F17)),
      const SizedBox(width: 6),
      Expanded(
        child: user != null
            ? Text('생성 대상: ${user.name} (${user.id})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600))
            : Text(context.loc.t('로그인_필요___로그인_후__9ac61d', '로그인 필요 — 로그인 후 사용하세요'),
                style: TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
      ),
    ]),
  );

  // ── 안내 배너 ──
  Widget _infoBanner() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFFCC02), width: 1.2),
    ),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 16),
      SizedBox(width: 8),
      Expanded(child: Text(
        '• 생성된 주문은 로그인 유저 ID로 저장 → 마이페이지에서 즉시 확인 가능\n• 기성품/단체주문 둘 다 생성 가능 · 상태(배송중/완료 등) 선택 가능\n• 주문번호 TEST_GRP_ / TEST_PERS_ 로 시작 → 상단 🗑 버튼으로 일괄 삭제',
        style: TextStyle(fontSize: 11, color: Color(0xFF795548), height: 1.6),
      )),
    ]),
  );

  // ── 섹션 타이틀 ──
  Widget _sectionTitle(String t, IconData icon) => Row(children: [
    Icon(icon, size: 15, color: const Color(0xFF1A1A2E)),
    const SizedBox(width: 5),
    Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
  ]);

  // ── 프리셋 카드 ──
  Widget _presetCard(_TestPreset p) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: () => _submitPreset(p),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(p.icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 3),
              Row(children: [
                _chip(p.orderType == 'personal' ? '기성품' : '단체', p.color),
                const SizedBox(width: 4),
                _chip('${p.count}${p.orderType == "personal" ? "개" : "인"}', const Color(0xFF1565C0)),
                const SizedBox(width: 4),
                _chip(p.status.label, _statusColor(p.status)),
                const SizedBox(width: 4),
                _chip(p.paymentMethod, const Color(0xFF37474F)),
              ]),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: p.color, borderRadius: BorderRadius.circular(6)),
            child: Text(context.loc.t('실행', '실행'), style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    ),
  );

  // ── 전체 실행 ──
  Widget _allBtn() => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: _submitAll,
      icon: const Icon(Icons.rocket_launch_rounded, size: 15),
      label: Text('전체 프리셋 일괄 실행 (${_kPresets.length}건)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1A1A2E),
        side: const BorderSide(color: Color(0xFF1A1A2E), width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  // ── 커스텀 패널 ──
  Widget _customPanel() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEEEEEE)),
      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 주문 유형 토글
      _labelText(context.loc.t('주문_유형', '주문 유형')),
      const SizedBox(height: 6),
      Row(children: [
        _toggleBtn('기성품 (personal)', _customOrderType == 'personal',
            () => setState(() { _customOrderType = 'personal'; _customCount = 1; })),
        const SizedBox(width: 8),
        _toggleBtn('단체주문 (group)', _customOrderType == 'group',
            () => setState(() { _customOrderType = 'group'; _customCount = 5; })),
      ]),
      const SizedBox(height: 12),

      // 주문 상태
      _labelText(context.loc.t('주문_상태', '주문 상태')),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6,
        children: OrderStatus.values.map((s) => GestureDetector(
          onTap: () => setState(() => _customStatus = s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _customStatus == s ? _statusColor(s) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _statusColor(s)),
            ),
            child: Text(s.label, style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _customStatus == s ? Colors.white : _statusColor(s),
            )),
          ),
        )).toList(),
      ),
      const SizedBox(height: 12),

      // 팀명/담당자
      Row(children: [
        Expanded(child: _field('팀명 / 구매자명', _teamNameCtrl)),
        const SizedBox(width: 8),
        Expanded(child: _field('담당자', _managerCtrl)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _field('연락처', _phoneCtrl, keyboard: TextInputType.phone)),
        const SizedBox(width: 8),
        Expanded(child: _field('이메일', _emailCtrl, keyboard: TextInputType.emailAddress)),
      ]),
      const SizedBox(height: 12),

      // 수량 / 단가
      Row(children: [
        Expanded(child: _stepper(
          _customOrderType == 'personal' ? '수량 (개)' : '인원수 (명)',
          _customCount, min: 1, max: 100,
          onChanged: (v) => setState(() => _customCount = v),
        )),
        const SizedBox(width: 8),
        Expanded(child: _stepper(
          '단가 (원)', _customPrice.toInt(),
          min: 10000, max: 500000, step: 5000,
          onChanged: (v) => setState(() => _customPrice = v.toDouble()),
        )),
      ]),
      const SizedBox(height: 12),

      // 인쇄타입 (단체주문만)
      if (_customOrderType == 'group') ...[
        _labelText(context.loc.t('인쇄_타입', '인쇄 타입')),
        const SizedBox(height: 6),
        _printSelector(),
        const SizedBox(height: 12),
      ],

      // 색상 / 결제수단
      Row(children: [
        Expanded(child: _dropdown('색상', _customColor,
            ['블랙', '화이트', '네이비', '그레이', '레드', '블루'],
            (v) => setState(() => _customColor = v!))),
        const SizedBox(width: 8),
        Expanded(child: _dropdown('결제수단', _customPay,
            ['계좌이체', '카드', '기타'],
            (v) => setState(() => _customPay = v!))),
      ]),

      // 원단 (단체만)
      if (_customOrderType == 'group') ...[
        const SizedBox(height: 8),
        _dropdown('원단', _customFabric,
            ['일반 봉제', '심리스', '나일론', '폴리에스터'],
            (v) => setState(() => _customFabric = v!)),
      ],

      const SizedBox(height: 14),

      // 합계
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('예상 합계 (${_customCount}${_customOrderType == "personal" ? "개" : "인"})',
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
          Text('${_fmt(_customPrice * _customCount)}원',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFE53935))),
        ]),
      ),
      const SizedBox(height: 12),

      // 생성 버튼
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _submit(
            orderType    : _customOrderType,
            status       : _customStatus,
            teamName     : _teamNameCtrl.text.trim().isEmpty ? '커스텀팀' : _teamNameCtrl.text.trim(),
            manager      : _managerCtrl.text.trim(),
            phone        : _phoneCtrl.text.trim(),
            email        : _emailCtrl.text.trim(),
            count        : _customCount,
            printType    : _customPrint,
            mainColor    : _customColor,
            fabric       : _customFabric,
            paymentMethod: _customPay,
            unitPrice    : _customPrice,
          ),
          icon: const Icon(Icons.send_rounded, size: 15),
          label: Text(context.loc.t('마이페이지에_주문_생성', '마이페이지에 주문 생성'),
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

  // ── 로그 패널 ──
  Widget _logPanel() => Container(
    decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.terminal_rounded, color: Colors.white54, size: 13),
        const SizedBox(width: 5),
        Text(context.loc.t('실행_로그', '실행 로그'), style: TextStyle(color: Colors.white54, fontSize: 11)),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _results.clear()),
          child: Text(context.loc.t('지우기', '지우기'), style: TextStyle(color: Color(0xFF90CAF9), fontSize: 11)),
        ),
      ]),
      const SizedBox(height: 8),
      ..._results.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(r, style: TextStyle(
          fontSize: 10,
          color: r.startsWith('✅') ? const Color(0xFF80CBC4)
              : r.startsWith('❌') ? const Color(0xFFEF9A9A)
              : Colors.white70,
          fontFamily: 'monospace',
          height: 1.5,
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
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
      );

  Widget _stepper(String label, int value,
      {required int min, required int max, int step = 1,
       required void Function(int) onChanged}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _labelText(label),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            _iconBtn(Icons.remove, () { if (value - step >= min) onChanged(value - step); }),
            Expanded(child: Text('$value',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center)),
            _iconBtn(Icons.add, () { if (value + step <= max) onChanged(value + step); }),
          ]),
        ),
      ]);

  Widget _iconBtn(IconData ic, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Padding(padding: const EdgeInsets.all(7), child: Icon(ic, size: 15, color: const Color(0xFF1A1A2E))),
  );

  Widget _dropdown(String label, String value, List<String> items, void Function(String?) onChange) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _labelText(label),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChange,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
        ),
      ]);

  Widget _printSelector() {
    const opts = [(0, '0 색상변경'), (1, '1 단체명+색상'), (2, '2 디자인포함'), (3, '3 풀옵션')];
    return Wrap(spacing: 6, runSpacing: 6,
      children: opts.map((o) {
        final sel = _customPrint == o.$1;
        return GestureDetector(
          onTap: () => setState(() => _customPrint = o.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: sel ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDDD)),
            ),
            child: Text(o.$2, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: sel ? Colors.white : const Color(0xFF555555),
            )),
          ),
        );
      }).toList(),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1A1A2E)),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF1A1A2E),
          )),
        ),
      );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _labelText(String t) =>
      Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF888888)));

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:          return Colors.orange;
      case OrderStatus.confirmed:        return Colors.blue;
      case OrderStatus.processing:       return const Color(0xFF7B1FA2);
      case OrderStatus.shipped:          return const Color(0xFF00838F);
      case OrderStatus.delivered:        return Colors.green;
      case OrderStatus.purchaseConfirmed:return const Color(0xFF1B5E20);
      case OrderStatus.cancelled:        return Colors.red;
      case OrderStatus.refunded:         return Colors.brown;
    }
  }
}
